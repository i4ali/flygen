import base64
import os
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Iterator
from engine import (
    extract as _extract,
    gaps as _gaps,
    plan as _plan,
    rubrics as _rubrics,
    tools as _tools,
    decide as _decide,
    schema as _schema,
    answers as _answers,
)
from engine.schema import build_field_proposals, ReviewProposal


@dataclass
class Event:
    kind: str            # parsed_fields | questions | design_brief | review
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


def _design_question_text(q) -> str:
    """The model reliably names the must-fix field but sometimes omits the question text;
    use its text when present, else a humane fallback derived from the field key."""
    text = (getattr(q, "text", None) or "").strip()
    if text:
        return text
    f = q.field
    return _gaps.QUESTION_TEXT.get(f, f"Could you share the {f.replace('_', ' ')}?")


class Engine:
    def __init__(self, client, extract=None, build_questions=None,
                 build_design_brief=None, rubric_for=None,
                 generator=None, generate_concepts=None, refine_concept=None,
                 resize_concept=None, apply_decisions=None, to_flyer_project=None):
        self.client = client
        self._extract = extract or _extract.extract_brief
        self._build_questions = build_questions or _gaps.build_questions
        self._build_brief = build_design_brief or _plan.build_design_brief
        self._rubric_for = rubric_for or _rubrics.rubric_for
        # generation tools — None means resolve the module function at call time (patchable)
        self._generator = generator
        self._generate_concepts = generate_concepts
        self._refine_concept = refine_concept
        self._resize_concept = resize_concept
        self._apply_decisions = apply_decisions or _decide.apply_decisions
        self._to_flyer_project = to_flyer_project or _schema.to_flyer_project
        # accumulated state (in/out per request; persistence is out of scope)
        self.brief = None
        self.rubric = None
        self.answers = {}
        self.project = None
        self.design = None    # the cached design brief — drives review proposals + generation emphasis
        self.floor_reasked = False   # the critical-field floor is re-asked at most once, then we proceed

    # --- turn 1: describe -------------------------------------------------
    def handle_user_message(self, text: str) -> Iterator[Event]:
        try:
            self.brief = self._extract(text, client=self.client)
        except Exception as e:                      # pragma: no cover - defensive
            yield Event("error", str(e)); return
        self.floor_reasked = False                  # new flyer — the floor re-ask is available again
        yield Event("parsed_fields", self.brief)

        qs = self._build_questions(self.brief, client=self.client)
        # Always ask the output size up-front, as a platform-labeled choice (pre-set to 4:5),
        # alongside any content gaps. Asked only here, so it never loops.
        questions = list(qs.questions) + [
            _gaps.Question("format", "What size should I make it?", options=_decide.format_options())
        ]
        yield Event("questions", _gaps.QuestionSet(questions, stage=qs.stage))
        # gate: wait for the size pick (+ any answers), then plan in handle_answers

    # --- turn 2a: answers to the gap questions ----------------------------
    def handle_answers(self, answers) -> Iterator[Event]:
        answers = answers or {}
        self.answers = {**self.answers, **answers}
        if self.brief is not None:
            _answers.apply_answers(self.brief, answers)   # no silent drop of clarification keys
        yield Event("parsed_fields", self.brief)

        qs = self._build_questions(self.brief, client=self.client, clarify=False)
        if qs.questions and not self.floor_reasked:
            self.floor_reasked = True            # insist once more on the floor, then never loop
            yield Event("questions", qs)
            return
        yield from self._plan_and_await()

    def _plan_and_await(self) -> Iterator[Event]:
        self.rubric = self._rubric_for(self.brief.category)
        design = self._build_brief(self.brief, self.rubric, answers=self.answers, client=self.client)
        self.design = design   # cache so the review proposals + generation emphasis can use it
        yield Event("design_brief", design)
        # The plan pass may surface generation-blocking gaps (a vague date, no way to act).
        # Ask those once, before review. (isinstance guard: a mocked design brief in tests
        # exposes a truthy MagicMock for `.questions` — treat non-lists as "no questions".)
        dq = getattr(design, "questions", None)
        dq = dq if isinstance(dq, list) else []
        dq = [q for q in dq if getattr(q, "field", None)]   # field = what to ask; text phrased below
        # Drop must-fixes the user already answered this session (under any alias) so we
        # never re-ask for, e.g., an address that was given in the gap round.
        answered = {_answers.canonical_key(k) for k, v in (self.answers or {}).items()
                    if v and str(v).strip()}
        dq = [q for q in dq if _answers.canonical_key(q.field) not in answered]
        if dq:
            yield Event("note", "This is really coming together. Before I start designing, "
                                "a couple of quick must-haves —")
            yield Event("questions", _gaps.QuestionSet(
                [_gaps.Question(q.field, _design_question_text(q)) for q in dq], stage="design"))
            return                                   # gate: wait for the must-fix answers
        # Only claim completeness when it's true — we can arrive here with a still-blank critical
        # field once the floor re-ask is spent (see handle_answers), so stay honest.
        if _gaps.missing_critical_fields(self.brief):
            yield Event("note", "Thanks — I'll design with what we have; fill in anything that's "
                                "still blank in the review, then I'll generate your concepts.")
        else:
            yield Event("note", "Love it — I've got everything I need. Here's exactly what I'll use; "
                                "change anything that's off, then I'll generate your concepts.")
        yield from self._emit_review(design)

    def _emit_review(self, design=None) -> Iterator[Event]:
        design = design or self.design               # reuse the cached plan across the must-fix detour
        proposal = ReviewProposal(
            fields=build_field_proposals(self.brief),
            decisions=_decide.propose_decisions(self.brief, self.rubric, design),
            plan=design,
        )
        yield Event("review", proposal)              # consolidated review gate

    # --- turn 2c: answers to the design brief's must-fix questions ---------
    def handle_design_answers(self, answers) -> Iterator[Event]:
        if self.brief is None:
            yield Event("error", "no brief to finalize"); return
        answers = answers or {}
        self.answers = {**self.answers, **answers}
        _answers.apply_answers(self.brief, answers)       # no silent drop of clarification keys
        yield Event("parsed_fields", self.brief)
        self.rubric = self.rubric or self._rubric_for(self.brief.category)
        # #2: re-run the plan against the now-updated brief so the review's notes, recommendations,
        # and palette/style/mood reflect the answer just given (the old code reused the pre-answer
        # plan, so notes could still say e.g. "the date is too vague"). Ask-once: we deliberately do
        # NOT re-gate on any question the recomputed plan surfaces, so this can't loop.
        self.design = self._build_brief(self.brief, self.rubric, answers=self.answers, client=self.client)
        yield Event("design_brief", self.design)
        # Ask once -> straight to review (no loop). Only claim completeness when it's actually true.
        if _gaps.missing_critical_fields(self.brief):
            note = ("Thanks — I'll work with what we have. Here's the plan; fill in anything "
                    "that's still blank, then I'll generate your concepts.")
        else:
            note = ("Perfect — that's everything I needed. Here's the final plan; "
                    "change anything, then I'll generate your concepts.")
        yield Event("note", note)
        yield from self._emit_review(self.design)

    # --- turn 2b: approval -> generate concepts ---------------------------
    def handle_approval(self, field_overrides=None, decision_overrides=None,
                        answers=None, user_photos_b64=None) -> Iterator[Event]:
        if self.brief is None:
            yield Event("error", "no brief to generate from"); return
        # apply confirmed/edited fields onto the brief
        for k, v in (field_overrides or {}).items():
            if hasattr(self.brief, k):
                setattr(self.brief, k, v)
        self.answers = {**self.answers, **(answers or {})}
        self.rubric = self.rubric or self._rubric_for(self.brief.category)
        project = self._to_flyer_project(self.brief)
        project = _decide.apply_proposed(project, decision_overrides or {}, self.rubric)
        # Carry the design pass's emphasis (rubric hierarchy + its recommendations) into the
        # image prompt so the plan's intent — e.g. the discount as the loudest element —
        # actually reaches generation instead of dying at the review screen.
        emphasis = _decide.emphasis_note(self.rubric, self.design)
        if emphasis:
            project.special_instructions = ". ".join(
                p for p in [project.special_instructions, emphasis] if p)
        self.project = project
        generate = self._generate_concepts or _tools.generate_concepts
        with _materialized_images(user_photos_b64) as photo_paths:
            extra = {}
            if photo_paths:
                project.user_photo_path = photo_paths[0]   # fires the prompt's "feature the photo(s)" instruction
                extra["user_photo_paths"] = photo_paths
            concepts = generate(project, generator=self._generator, n=3, **extra)
        yield Event("concepts", concepts)

    # --- turn 3: refine ---------------------------------------------------
    def handle_refine(self, prior_image_path=None, instruction="", mode="edit",
                      prior_image_b64=None) -> Iterator[Event]:
        project = self.project or (self._to_flyer_project(self.brief) if self.brief else None)
        if project is None:
            yield Event("error", "no project to refine"); return
        refine = self._refine_concept or _tools.refine_concept
        concept = None
        with _resolved_image(prior_image_path, prior_image_b64) as path:
            if path is None:
                yield Event("error", "no prior image to refine"); return
            concept = refine(project, path, instruction, generator=self._generator, mode=mode)
        yield Event("refined", concept)

    # --- turn 4: resize ---------------------------------------------------
    def handle_resize(self, prior_image_path=None, aspect_ratio="",
                      prior_image_b64=None) -> Iterator[Event]:
        resize = self._resize_concept or _tools.resize_concept
        concept = None
        with _resolved_image(prior_image_path, prior_image_b64) as path:
            if path is None:
                yield Event("error", "no prior image to resize"); return
            concept = resize(path, aspect_ratio, generator=self._generator)
        yield Event("resized", concept)
