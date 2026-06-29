# No Silent Defaults — "Review Everything" Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the engine's bare `awaiting_approval` step with a structured `review` gate that surfaces the engine's *complete interpretation* — every extracted field (tagged stated/inferred) plus every design default (format, palette, style, mood, quality, model, QR) plus the plan — for one consolidated human approval before any flyer is generated.

**Architecture:** Extraction self-reports per-field `stated`/`inferred` (folded into the existing extract call — no new LLM round-trip). `decide.propose_decisions` proposes each design choice *without applying it*. The orchestrator composes a `ReviewProposal` after the design brief and emits a `review` event; `handle_approval(overrides)` applies the user's confirmed/overridden values, then generates. Generation stays gated.

**Tech Stack:** Python 3, pydantic, FastAPI, pytest. Reuses the existing `engine/` package. Reasoning runs Claude Opus 4.8 via the OpenRouter adapter (`engine/openrouter_client.py`).

**Design reference:** `docs/plans/2026-06-19-no-silent-defaults-design.md`.

**Conventions for the executing engineer:**
- Run tests from the repo root with `.venv/bin/python -m pytest tests/engine -v`.
- **Never call real APIs in unit tests** — mock the LLM client and `FlyerImageGenerator`.
- **Commits are at the owner's discretion** — the owner has asked not to commit during this work, so treat the `git commit` steps as optional. Still stage/verify per task.
- Do **not** modify `models.py` / `prompt_builder.py` / `image_generator.py`.

---

## Task 1: Extraction self-reports field sources + destination

Teach extraction to (a) report whether each field was `stated` or `inferred`, and (b) capture a `destination` hint when the user mentions a channel/medium. Both ride the existing extract call.

**Files:**
- Modify: `engine/schema.py` (add `destination`, `field_sources` to `ExtractedBrief`; add `field_source()` helper)
- Modify: `engine/llm.py` (`EXTRACT_SYSTEM` — explain the new fields)
- Test: `tests/engine/test_schema.py`

**Step 1: Write the failing test**

```python
# add to tests/engine/test_schema.py
from engine.schema import field_source

def test_field_sources_round_trip_and_helper_defaults_to_inferred():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", destination="instagram",
        field_sources={"headline": "stated", "category": "inferred"},
    )
    assert brief.destination == "instagram"
    assert field_source(brief, "headline") == "stated"
    assert field_source(brief, "category") == "inferred"
    assert field_source(brief, "venue_name") == "inferred"   # unknown -> conservative
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_schema.py::test_field_sources_round_trip_and_helper_defaults_to_inferred -v`
Expected: FAIL — `cannot import name 'field_source'` / unexpected kwargs.

**Step 3: Implement**

In `engine/schema.py`: change the import to `from typing import Optional, List, Dict`, add two fields to `ExtractedBrief` (after `purpose`):

```python
    destination: Optional[str] = None          # channel/medium hint, when the user states one
    field_sources: Dict[str, str] = {}         # field name -> "stated" | "inferred"
```

Add a module-level helper (after `ExtractedBrief`):

```python
def field_source(brief: "ExtractedBrief", key: str) -> str:
    """stated if the model said the value came from the user; inferred otherwise (conservative)."""
    return brief.field_sources.get(key, "inferred")
```

In `engine/llm.py`, extend `EXTRACT_SYSTEM`'s text (append before the closing `"`):

```
"\n\nAlso capture `destination` if the user names a channel or medium (e.g. Instagram, "
"story, print/printed, poster) — otherwise leave it null. In `field_sources`, map every "
"field you populate to either \"stated\" (the user explicitly provided it) or \"inferred\" "
"(you deduced it, e.g. the category)."
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_schema.py -v`
Expected: PASS (existing schema tests + the new one). `to_flyer_project` ignores the new fields, so it stays green.

**Step 5: Commit (optional)**

```bash
git add engine/schema.py engine/llm.py tests/engine/test_schema.py
git commit -m "feat(engine): extraction self-reports field sources + destination"
```

---

## Task 2: Field proposals for the review

Turn an `ExtractedBrief` into the `fields` half of the review payload.

**Files:**
- Modify: `engine/schema.py` (`FieldProposal`, `build_field_proposals`)
- Test: `tests/engine/test_schema.py`

**Step 1: Write the failing test**

```python
from engine.schema import FieldProposal, build_field_proposals

def test_build_field_proposals_includes_populated_fields_with_source():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", venue_name="Grace Hall",
        field_sources={"headline": "stated", "venue_name": "stated", "category": "inferred"},
    )
    props = build_field_proposals(brief)
    by_key = {p.key: p for p in props}
    assert isinstance(props[0], FieldProposal)
    assert by_key["headline"].value == "Bake Sale" and by_key["headline"].source == "stated"
    assert by_key["category"].source == "inferred"
    assert "subheadline" not in by_key          # empty fields are omitted
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_schema.py::test_build_field_proposals_includes_populated_fields_with_source -v`
Expected: FAIL — `cannot import name 'FieldProposal'`.

**Step 3: Implement** (in `engine/schema.py`)

```python
class FieldProposal(BaseModel):
    key: str
    value: str
    source: str            # stated | inferred


# content fields shown in the review, in display order (category first)
_REVIEW_FIELDS = [
    "category", "headline", "subheadline", "body_text", "date", "time",
    "venue_name", "address", "price", "discount_text", "cta_text",
    "phone", "email", "website",
]


def build_field_proposals(brief: ExtractedBrief) -> List[FieldProposal]:
    out = []
    for key in _REVIEW_FIELDS:
        value = getattr(brief, key, None)
        if value:
            out.append(FieldProposal(key=key, value=str(value), source=field_source(brief, key)))
    return out
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_schema.py -v`
Expected: PASS

**Step 5: Commit (optional)**

```bash
git add engine/schema.py tests/engine/test_schema.py
git commit -m "feat(engine): FieldProposal + build_field_proposals"
```

---

## Task 3: Decision proposals (propose + apply) — the format-bug fix

Propose every design choice with alternatives, *without applying* — and apply the user's chosen values at approval.

**Files:**
- Modify: `engine/decide.py` (`DecisionProposal`, `propose_decisions`, `apply_proposed`)
- Test: `tests/engine/test_decide.py`

**Step 1: Write the failing test**

```python
from engine.decide import propose_decisions, apply_proposed, DecisionProposal
from engine.schema import ExtractedBrief, to_flyer_project
from models import AspectRatio

def test_propose_decisions_always_includes_format_with_options():
    brief = ExtractedBrief(category="event", headline="Gala")          # no destination
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert "format" in decs                                            # always present (the bug fix)
    assert decs["format"].value == "4:5"                               # sensible default when not stated
    assert decs["format"].options and "letter" in decs["format"].options
    assert "palette" in decs and decs["palette"].options

def test_propose_decisions_infers_format_from_destination():
    brief = ExtractedBrief(category="event", headline="Gala", destination="printed")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert decs["format"].value == "letter"                           # inferred from the brief

def test_apply_proposed_sets_aspect_ratio_from_override():
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala"))
    apply_proposed(project, {"format": "letter"}, rubric_for(FlyerCategory.EVENT))
    assert project.output.aspect_ratio == AspectRatio.LETTER
```

(Existing `test_decide.py` already imports `rubric_for`, `FlyerCategory` — keep those imports.)

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_decide.py -v`
Expected: FAIL — `cannot import name 'propose_decisions'`.

**Step 3: Implement** (append to `engine/decide.py`)

```python
@dataclass
class DecisionProposal:
    key: str
    label: str
    value: str
    options: List[str]
    reason: str


_ASPECT_OPTIONS = ["4:5", "9:16", "1:1", "letter", "a4", "16:9"]


def propose_decisions(brief, rubric) -> List["DecisionProposal"]:
    # format: inferred from the brief's destination when stated, else the 4:5 default
    if getattr(brief, "destination", None):
        fmt = map_format(brief.destination).value
        fmt_reason = f"inferred from your brief ({brief.destination})"
    else:
        fmt = AspectRatio.PORTRAIT_4_5.value
        fmt_reason = "default — reads well in feeds and prints cleanly"

    directions = [d.name for d in propose_palette_directions(rubric)]
    palette = directions[0] if directions else "Warm & inviting"

    return [
        DecisionProposal("format", "Size / format", fmt, _ASPECT_OPTIONS, fmt_reason),
        DecisionProposal("palette", "Color palette", palette, directions,
                         "from the category's recommended directions"),
        DecisionProposal("visual_style", "Visual style", VisualStyle.MODERN_MINIMAL.value,
                         [s.value for s in VisualStyle], "a clean, safe default"),
        DecisionProposal("mood", "Mood", Mood.FRIENDLY.value, [m.value for m in Mood],
                         "approachable default"),
        DecisionProposal("quality", "Quality", "hd", ["low", "medium", "high", "hd"], "print-ready"),
        DecisionProposal("model", "Model", "nano-banana-pro", ["nano-banana", "nano-banana-pro"],
                         "highest-fidelity image model"),
    ]


def apply_proposed(project, decisions: dict, rubric) -> "FlyerProject":
    """Apply the user's confirmed/overridden decision values (keyed as in propose_decisions)."""
    decisions = decisions or {}
    if decisions.get("format"):
        try:
            project.output.aspect_ratio = AspectRatio(decisions["format"])
        except ValueError:
            pass
    if decisions.get("palette"):
        apply_decisions(project, {"palette": decisions["palette"]}, rubric)
    if decisions.get("visual_style"):
        try:
            project.visuals.style = VisualStyle(decisions["visual_style"])
        except ValueError:
            pass
    if decisions.get("mood"):
        try:
            project.visuals.mood = Mood(decisions["mood"])
        except ValueError:
            pass
    if decisions.get("quality"):
        project.output.quality = decisions["quality"]
    if decisions.get("model"):
        project.output.model = decisions["model"]
    if decisions.get("qr_url"):
        from models import QRCodeSettings
        project.qr_settings = QRCodeSettings(enabled=True, url=decisions["qr_url"])
    return project
```

> Note: `apply_decisions` (the original) stays for backward compatibility; `apply_proposed` is the proposal-keyed entry point used by approval.

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_decide.py -v`
Expected: PASS

**Step 5: Commit (optional)**

```bash
git add engine/decide.py tests/engine/test_decide.py
git commit -m "feat(engine): propose_decisions/apply_proposed — format always surfaced"
```

---

## Task 4: ReviewProposal + orchestrator emits `review`

Compose the consolidated proposal and replace the bare `awaiting_approval` event.

**Files:**
- Modify: `engine/schema.py` (`ReviewProposal`)
- Modify: `engine/orchestrator.py` (`_plan_and_await` → build + emit `review`)
- Test: `tests/engine/test_orchestrator.py` (update the awaiting_approval expectation; add a review test)

**Step 1: Write the failing test**

Update `test_complete_brief_reaches_design_brief_then_awaits_approval` to expect `review`, and add:

```python
def test_review_payload_has_fields_decisions_and_plan():
    from engine.gaps import QuestionSet
    from engine.schema import ReviewProposal
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale", date="Sat",
                       venue_name="Hall", cta_text="Come",
                       field_sources={"headline": "stated", "category": "inferred"}),
        QuestionSet([]),
    )
    events = list(eng.handle_user_message("..."))
    kinds = [e.kind for e in events]
    assert "design_brief" in kinds
    assert "review" in kinds and "awaiting_approval" not in kinds
    assert "concepts" not in kinds
    review = next(e.payload for e in events if e.kind == "review")
    assert isinstance(review, ReviewProposal)
    assert any(f.key == "headline" for f in review.fields)
    assert any(d.key == "format" for d in review.decisions)   # format always surfaced
    assert review.plan is not None
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_orchestrator.py -v`
Expected: FAIL — `cannot import name 'ReviewProposal'` / `review` not emitted.

**Step 3: Implement**

In `engine/schema.py`:

```python
class ReviewProposal(BaseModel):
    fields: List[FieldProposal] = []
    decisions: list = []          # list[DecisionProposal] (dataclass) — kept loosely typed
    plan: Optional[DesignBrief] = None

    model_config = {"arbitrary_types_allowed": True}
```

In `engine/orchestrator.py`, import the pieces and rewrite `_plan_and_await`:

```python
from engine.schema import build_field_proposals, ReviewProposal

    def _plan_and_await(self) -> Iterator[Event]:
        self.rubric = self._rubric_for(self.brief.category)
        design = self._build_brief(self.brief, self.rubric, answers=self.answers, client=self.client)
        yield Event("design_brief", design)
        proposal = ReviewProposal(
            fields=build_field_proposals(self.brief),
            decisions=_decide.propose_decisions(self.brief, self.rubric),
            plan=design,
        )
        yield Event("review", proposal)        # replaces awaiting_approval; gate still holds
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_orchestrator.py -v`
Expected: PASS

**Step 5: Commit (optional)**

```bash
git add engine/schema.py engine/orchestrator.py tests/engine/test_orchestrator.py
git commit -m "feat(engine): consolidated review event replaces awaiting_approval"
```

---

## Task 5: `handle_approval` applies field + decision overrides

Approval now carries the user's confirmed/overridden interpretation.

**Files:**
- Modify: `engine/orchestrator.py` (`handle_approval`)
- Test: `tests/engine/test_orchestrator.py`

**Step 1: Write the failing test**

```python
def test_handle_approval_applies_field_and_decision_overrides():
    from engine.tools import Concept
    captured = {}
    def fake_generate(project, generator=None, n=3):
        captured["headline"] = project.text_content.headline
        captured["aspect"] = project.output.aspect_ratio
        return [Concept("v1", "b64")]
    eng = Engine(client=MagicMock(), generate_concepts=fake_generate, generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Bake Sale", cta_text="Come")
    events = list(eng.handle_approval(
        field_overrides={"headline": "Spring Bake Sale"},
        decision_overrides={"format": "letter"},
    ))
    from models import AspectRatio
    assert "concepts" in [e.kind for e in events]
    assert captured["headline"] == "Spring Bake Sale"       # field override applied
    assert captured["aspect"] == AspectRatio.LETTER          # decision override applied
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_orchestrator.py::test_handle_approval_applies_field_and_decision_overrides -v`
Expected: FAIL — `handle_approval()` got an unexpected keyword argument.

**Step 3: Implement** — replace `handle_approval` in `engine/orchestrator.py`:

```python
    def handle_approval(self, field_overrides=None, decision_overrides=None,
                        answers=None) -> Iterator[Event]:
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
        self.project = project
        generate = self._generate_concepts or _tools.generate_concepts
        concepts = generate(project, generator=self._generator, n=3)
        yield Event("concepts", concepts)
```

> The existing `test_handle_approval_generates_concepts` calls `handle_approval({"destination": "instagram"})` positionally. Update that call to `handle_approval(decision_overrides={})` (or keep it valid by leaving `field_overrides` first and passing `{}`). Adjust that one test so the first positional arg is still accepted.

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_orchestrator.py -v`
Expected: PASS

**Step 5: Commit (optional)**

```bash
git add engine/orchestrator.py tests/engine/test_orchestrator.py
git commit -m "feat(engine): approval applies field + decision overrides"
```

---

## Task 6: `/chat` — serialize `review`, route `approve` overrides

Wire the new event and action through the SSE service.

**Files:**
- Modify: `engine/app.py` (`ChatIn`, `run_turn`, `_sse` serialization)
- Test: `tests/engine/test_app.py`

**Step 1: Write the failing test**

```python
def test_review_event_serializes_fields_and_decisions():
    import json
    from engine.orchestrator import Event
    from engine.schema import ReviewProposal, FieldProposal
    from engine.decide import DecisionProposal
    proposal = ReviewProposal(
        fields=[FieldProposal(key="headline", value="Bake Sale", source="stated")],
        decisions=[DecisionProposal("format", "Size / format", "4:5", ["4:5", "letter"], "default")],
        plan=None,
    )
    with patch("engine.app.run_turn", return_value=iter([Event("review", proposal)])):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "x"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: review" in body
    data_line = [l for l in body.splitlines() if l.startswith("data: ")][0][6:]
    data = json.loads(data_line)
    assert data["fields"][0]["key"] == "headline"
    assert data["decisions"][0]["key"] == "format"
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_app.py::test_review_event_serializes_fields_and_decisions -v`
Expected: FAIL — the data is stringified (not real JSON with `fields`/`decisions`).

**Step 3: Implement** in `engine/app.py`:

Add fields to `ChatIn`:

```python
    field_overrides: Optional[dict] = None
    decision_overrides: Optional[dict] = None
```

Route `approve`:

```python
    if action == "approve":
        return eng.handle_approval(field_overrides=body.field_overrides,
                                   decision_overrides=body.decision_overrides,
                                   answers=body.answers or {})
```

Replace `_sse` with a version that serializes pydantic models and dataclasses properly:

```python
from dataclasses import is_dataclass, asdict
from pydantic import BaseModel

def _to_jsonable(obj):
    if obj is None or isinstance(obj, (str, int, float, bool)):
        return obj
    if isinstance(obj, BaseModel):
        return obj.model_dump()
    if is_dataclass(obj):
        return asdict(obj)
    if isinstance(obj, dict):
        return {k: _to_jsonable(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_to_jsonable(v) for v in obj]
    return getattr(obj, "__dict__", str(obj))

def _sse(events):
    for e in events:
        yield f"event: {e.kind}\ndata: {json.dumps(_to_jsonable(e.payload), default=str)}\n\n"
```

> `ReviewProposal.model_dump()` recurses into `FieldProposal` (pydantic) but `decisions` are dataclasses — `model_dump` leaves them as objects, so `_to_jsonable` handles the list by mapping `asdict` over each. Verify the test sees `decisions[0]["key"]`.

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_app.py -v`
Expected: PASS (existing app tests still green — `concepts` serialization now uses `_to_jsonable`).

**Step 5: Commit (optional)**

```bash
git add engine/app.py tests/engine/test_app.py
git commit -m "feat(engine): serialize review event + route approve overrides"
```

---

## Task 7: Full suite + manual smoke

**Step 1:** `.venv/bin/python -m pytest tests/engine -v` — all green.

**Step 2 (optional, real API):** with `OPENROUTER_API_KEY` loaded, run a live describe flow and confirm the event sequence is now `parsed_fields → design_brief → review` (not `awaiting_approval`), and that the `review` payload contains a `format` decision:

```bash
.venv/bin/python -c "
from engine.orchestrator import Engine; from engine.llm import get_client
for e in Engine(client=get_client()).handle_user_message('flyer for our church bake sale Saturday 10-2 at Grace Hall, donate at hope.org'):
    print(e.kind, '|', getattr(e.payload,'decisions',None) and [d.key for d in e.payload.decisions])
"
```
Expected: a `review` line listing `['format','palette','visual_style','mood','quality','model']`.

---

## Done criteria

- `.venv/bin/python -m pytest tests/engine -v` is green.
- The engine emits a `review` event (never bare `awaiting_approval`); `format` is always in the proposal (inferred-or-default, never silent).
- `handle_approval` applies field + decision overrides before generating; concepts only after approve.
- `/chat` streams the `review` event as real JSON and accepts `field_overrides` / `decision_overrides` on `approve`.
- No changes to `models.py` / `prompt_builder.py` / `image_generator.py`.
