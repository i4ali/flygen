import base64
import logging
import os
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Iterator, Optional
from engine.turn import TurnResult
from engine import interpret as _interpret
from engine.gate import is_flyer_request as _is_flyer_request
from engine.review import assemble_review, to_brief_dict, to_question_set
from engine.compile_project import build_project
from engine import tools as _tools
import engine.qr_intent as _qr_intent


# Shown (as a plain assistant line) when the gate decides a typed message isn't a flyer request.
# Firm but warm, and reversible - if the gate misjudged a real-but-unusual brief, the invitation
# to "tell me about a flyer" lets the user simply restate it.
DEFLECTION = ("I only design flyers here, so I can't help with that one. Tell me about a flyer "
              "you'd like - an event, a sale, an announcement - and I'll take it from there.")


@dataclass
class Event:
    kind: str            # parsed_fields | questions | review | note | qr | qr_offer
                         # | concepts | refined | resized | error
    payload: Any = None


@contextmanager
def _resolved_image(path, b64):
    """Yield a filesystem path the generator can read. Concepts come back as base64
    (no disk), so for refine/resize we materialize that base64 to a temp file and
    clean it up afterwards. A real path is passed through untouched."""
    if path:
        yield path
        return
    if b64:
        fd, tmp = tempfile.mkstemp(suffix=".png")
        try:
            with os.fdopen(fd, "wb") as f:
                f.write(base64.b64decode(b64))
            yield tmp
        finally:
            try:
                os.remove(tmp)
            except OSError:
                pass
        return
    yield None


@contextmanager
def _materialized_images(b64_list):
    """Write a list of base64 images to temp PNGs, yield their paths, and clean them up.
    Uploaded photos arrive as base64 (no disk); the generator wants file paths."""
    paths = []
    try:
        for b64 in (b64_list or []):
            if not b64:
                continue
            # iOS normalizes uploads to JPEG; .jpg suffix => the generator labels the data URL image/jpeg.
            fd, tmp = tempfile.mkstemp(suffix=".jpg")
            with os.fdopen(fd, "wb") as f:
                f.write(base64.b64decode(b64))
            paths.append(tmp)
        yield paths
    finally:
        for p in paths:
            try:
                os.remove(p)
            except OSError:
                pass


def _with_qr(concept, qr):
    """Composite the real QR onto a concept's base64. Fail open: any error returns the
    concept untouched - a flyer without a QR beats a failed turn."""
    if not (qr and qr.get("enabled") and qr.get("value")):
        return concept
    if concept is None or not getattr(concept, "image_base64", None):
        return concept
    try:
        from qr_service import build_qr_payload, composite_qr_onto_bytes
        raw = base64.b64decode(concept.image_base64)
        out = composite_qr_onto_bytes(raw, build_qr_payload(qr.get("kind", "website"), qr["value"]),
                                      qr.get("corner", "bottom_right"))
        concept.image_base64 = base64.b64encode(out).decode("ascii")
    except Exception as e:
        logging.getLogger(__name__).warning("qr composite failed, returning bare flyer: %s", e)
    return concept


def _qr_offer(turn, brief, current_qr):
    """Build a proactive QR offer from this turn, or None.

    The brain proposes a QR via a `qr` question (it never enables one unprompted) - even on a
    ready draft, where questions are otherwise dropped. We surface that as a tappable Yes/No offer
    for an UNAMBIGUOUS target (a website or social handle), deriving kind+value from the brief so
    the client sets the state on Yes with no extra round-trip. A phone-only brief is skipped here
    (tel: vs WhatsApp needs a follow-up); the explicit ask still handles phones. Suppressed once
    any QR state exists, so a decline is never re-offered."""
    if current_qr is not None:
        return None
    q = next((q for q in turn.questions if q.field == "qr"), None)
    if not q:
        return None
    website = (brief or {}).get("website")
    social = (brief or {}).get("social_handle")
    if website:
        kind, value = "website", website
    elif social:
        kind, value = "instagram", social
    else:
        return None
    text = q.text or f"Want a scannable QR code that opens {value}?"
    return {"kind": kind, "value": value, "corner": "bottom_right", "text": text}


class Engine:
    def __init__(self, client, interpret_fn=None, assemble_fn=None, build_project_fn=None,
                 generate_concepts=None, generator=None, refine_concept=None, resize_concept=None,
                 gate_fn=None, edit_reference=None, annotated_edit=None):
        self.client = client
        self._gate = gate_fn or _is_flyer_request
        self._interpret = interpret_fn or _interpret.interpret
        self._assemble = assemble_fn or assemble_review
        self._build_project = build_project_fn or build_project
        self._generate_concepts = generate_concepts or _tools.generate_concepts
        self._generator = generator
        self._refine = refine_concept or _tools.refine_concept
        self._resize = resize_concept or _tools.resize_concept
        self._edit_reference = edit_reference or _tools.edit_reference
        self._annotated_edit = annotated_edit or _tools.annotated_edit
        self.turn: Optional[TurnResult] = None
        self.brief: dict = {}        # wire state (ExtractedBrief-shaped), persisted in/out
        self.project = None
        self.qr: Optional[dict] = None   # standalone QR wire state {enabled, kind, value, corner}

    def _run(self, user_text=None, answers=None) -> Iterator[Event]:
        try:
            turn = self._interpret(self.brief or None, user_text, answers, qr=self.qr, client=self.client)
        except Exception as e:                       # never surface a raw internal error to the user
            logging.getLogger(__name__).warning("interpret failed: %s", e)
            yield Event("error", "Sorry - I had trouble putting that together. "
                                 "Mind trying again, or rephrasing it a little?")
            return
        self.turn = turn
        self.brief = to_brief_dict(turn)             # ExtractedBrief-shaped dict for persistence
        yield Event("parsed_fields", self.brief)
        # QR is separate wire state. The brain's word wins unless it dropped it (None = untouched);
        # echo the current state each turn so the client keeps it in sync.
        if turn.qr is not None:
            self.qr = turn.qr.model_dump()
        if self.qr is not None:
            yield Event("qr", self.qr)
        # The brain offers a QR via a "qr" question even on a ready draft (where questions are
        # otherwise dropped). Surface it as its own tappable offer and keep it OUT of the generic
        # questions card; the client sets the qr state on Yes/No, so nothing here enables it.
        offer = _qr_offer(turn, self.brief, self.qr)
        if turn.status == "need_input" and any(q.field != "qr" for q in turn.questions):
            yield Event("questions", to_question_set(turn))
        else:
            yield Event("review", self._assemble(turn))
        if offer:
            yield Event("qr_offer", offer)

    def handle_user_message(self, text: str) -> Iterator[Event]:
        # Cheap gate first: a non-flyer message (a question about the app, a greeting, small talk,
        # off-topic) is deflected here, before the expensive design brain runs. Only the typed
        # "describe" turn is gated - answers/approve/refine/resize are always mid-flyer, so they
        # skip it. The gate fails open (see engine/gate.py), so a real request is never dropped.
        if text and not self._gate(text, client=self.client):
            yield Event("note", DEFLECTION)
            return
        yield from self._run(user_text=text)

    def handle_answers(self, answers) -> Iterator[Event]:
        yield from self._run(answers=answers)

    def handle_reference(self, reference_b64, instruction="", annotated=False) -> Iterator[Event]:
        # The user uploaded a flyer to reuse. Hand the flyer plus their own words straight to the
        # image model (no brain, no extraction) and return the edited flyer. Each further edit is
        # another such turn on the latest image, so this stays stateless. When `annotated`, the
        # flyer carries numbered circles and the annotated-edit prompt is used instead (both edit
        # functions share a signature, so the call site is identical).
        if not reference_b64:
            yield Event("error", "I didn't get that flyer - want to try attaching it again?")
            return
        if not (instruction or "").strip():
            yield Event("note", "Got your flyer. What would you like to change?")
            return
        # QR is brain-free here too: the scoped extractor fires ONLY when the edit mentions "QR".
        if _qr_intent.mentions_qr(instruction):
            new_qr, instruction, ask = _qr_intent.qr_update(instruction, self.qr, self.client)
            if ask:
                yield Event("note", ask); return
            if new_qr is not None:
                self.qr = new_qr
                yield Event("qr", self.qr)
        with _materialized_images([reference_b64]) as ref_paths:
            if not ref_paths:
                yield Event("error", "I couldn't read that flyer - want to try attaching it again?")
                return
            edit = self._annotated_edit if annotated else self._edit_reference
            concept = edit(ref_paths[0], self._generator, instruction)
        yield Event("concepts", [_with_qr(concept, self.qr)])

    def handle_approval(self, field_overrides=None, decision_overrides=None,
                        answers=None, user_photos_b64=None, selected_elements=None,
                        language=None) -> Iterator[Event]:
        # Each HTTP request builds a fresh Engine, so self.turn is usually None on an approve
        # turn; rebuild it from the brief the client posts back. The final design decisions
        # arrive via decision_overrides, so a content-only rebuilt turn is sufficient.
        turn = self.turn
        if turn is None and self.brief:
            turn = TurnResult(**{k: v for k, v in self.brief.items() if k in TurnResult.model_fields})
        if turn is None:
            yield Event("error", "no interpretation to generate from"); return
        project = self._build_project(turn, field_overrides or {}, decision_overrides or {},
                                      selected_elements=selected_elements, language=language,
                                      qr=self.qr)
        self.project = project
        with _materialized_images(user_photos_b64) as photo_paths:
            extra = {}
            if photo_paths:
                project.user_photo_path = photo_paths[0]   # fires the prompt's "feature the photo(s)" instruction
                extra["user_photo_paths"] = photo_paths
            concepts = self._generate_concepts(project, generator=self._generator, n=3, **extra)
        concepts = [_with_qr(c, self.qr) for c in concepts]   # composite the real QR as the last step
        yield Event("concepts", concepts)

    def handle_refine(self, prior_image_path=None, instruction="", mode="edit",
                      prior_image_b64=None, annotated=False, language=None) -> Iterator[Event]:
        # Annotated edits are self-contained (marked image + numbered instructions), like a
        # reference edit - no project/brief needed, and the light annotated-edit prompt replaces
        # the full design prompt. See docs/plans/2026-07-04-annotate-to-edit-design.md.
        # QR is brain-free here: the scoped extractor fires ONLY when the edit mentions "QR";
        # every other edit stays pure trust-the-model. It augments `instruction` (keep-clear /
        # remove) and updates self.qr; if a QR is requested with no target it asks and returns.
        if _qr_intent.mentions_qr(instruction):
            new_qr, instruction, ask = _qr_intent.qr_update(instruction, self.qr, self.client)
            if ask:
                yield Event("note", ask); return
            if new_qr is not None:
                self.qr = new_qr
                yield Event("qr", self.qr)
        if annotated:
            with _resolved_image(prior_image_path, prior_image_b64) as path:
                if path is None:
                    yield Event("error", "no prior image to refine"); return
                concept = self._annotated_edit(path, self._generator, instruction)
            yield Event("refined", _with_qr(concept, self.qr))
            return
        # Each HTTP request builds a fresh Engine, so self.project is usually None on a refine
        # turn; rebuild it from the brief the client posts back (mirrors the old engine's
        # self.project-or-rebuild-from-brief behavior, now via TurnResult + build_project).
        project = self.project
        if project is None and self.brief:
            turn = TurnResult(**{k: v for k, v in self.brief.items() if k in TurnResult.model_fields})
            project = self._build_project(turn, {}, {}, None, language=language, qr=self.qr)
        if project is None:
            yield Event("error", "no project to refine"); return
        concept = None
        with _resolved_image(prior_image_path, prior_image_b64) as path:
            if path is None:
                yield Event("error", "no prior image to refine"); return
            concept = self._refine(project, path, instruction, generator=self._generator, mode=mode)
        yield Event("refined", _with_qr(concept, self.qr))

    def handle_resize(self, prior_image_path=None, aspect_ratio="",
                      prior_image_b64=None) -> Iterator[Event]:
        # Resize is project-independent (resize_concept reformats the prior image by aspect ratio
        # only), so no project/brief is needed - it works on a fresh, stateless Engine.
        concept = None
        with _resolved_image(prior_image_path, prior_image_b64) as path:
            if path is None:
                yield Event("error", "no prior image to resize"); return
            concept = self._resize(path, aspect_ratio, generator=self._generator)
        yield Event("resized", _with_qr(concept, self.qr))
