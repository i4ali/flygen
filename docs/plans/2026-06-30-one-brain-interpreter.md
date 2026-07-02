# One-Brain Interpreter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the engine's deterministic validation/cleanup pile with a single LLM "design director" call that returns one finished, typed `TurnResult` per turn; deterministic code shrinks to a typed edge (validate + assemble + compile) plus the existing image pipeline.

**Architecture:** One brain interprets language (extraction + answer-merging + design decisions + proactive creative ideas) into a `TurnResult`. The orchestrator projects that onto the existing wire events (`parsed_fields` / `questions` / `review` / `concepts`), so the iOS client keeps working. A thin validator checks enum membership (off-vocabulary is surfaced, never snapped); an assembler builds the review payload; a compiler maps approved values to `FlyerProject` and calls the unchanged `FlyerPromptBuilder` -> `FlyerImageGenerator`.

**Tech Stack:** Python 3, pydantic, FastAPI, pytest. Reasoning model `claude-sonnet-4-6` via the existing OpenRouter shim (`engine/openrouter_client.py`, `.messages.parse(...).parsed_output`). Gemini image generation unchanged.

**Design reference:** `docs/plans/2026-06-30-one-brain-interpreter-design.md`.

## Global Constraints

- **Model & transport:** `claude-sonnet-4-6` via `engine/openrouter_client.py` only. NO Anthropic SDK. All LLM calls use `client.messages.parse(model=MODEL, max_tokens=MAX_TOKENS, system=..., messages=[...], thinking=THINKING, output_config=EFFORT, output_format=<PydanticModel>)` and read `.parsed_output`. The shim already does tolerant prompt-driven JSON parsing, which is our structured-output strategy.
- **Wire contract is frozen (iOS is out of scope):** the SSE `Event.kind` values (`parsed_fields`, `questions`, `design_brief`, `review`, `note`, `concepts`, `refined`, `resized`, `error`) and their payload shapes (`ExtractedBrief` dict, `QuestionSet`, `ReviewProposal`, `Concept`) stay byte-compatible with today, EXCEPT additive new fields. `creative_elements` is added to `ReviewProposal` (additive; old clients ignore it). `ChatIn` only gains optional fields. `ExtractedBrief` keeps its current field names (it is persisted in/out via `ChatIn.brief`).
- **No silent defaults:** every inferred field and every design choice is surfaced in the `review`. Off-vocabulary values are flagged in the review, never silently snapped or dropped.
- **Do NOT modify** `models.py`, `prompt_builder.py`, `image_generator.py`.
- **Testing:** mock the LLM client and `FlyerImageGenerator` in unit tests - never call a real API in `pytest`. Run tests from repo root: `.venv/bin/python -m pytest tests/engine -v`.
- **Process:** work on `main`; do NOT commit unless the owner asks (no co-author line); never use an em dash (use " - "). Verify by running the engine + the eval harness, plus the unit tests on deterministic pieces.

---

## File Structure

**New files:**
- `engine/turn.py` - the `TurnResult` model (the brain's single output contract) + sub-models + `validate_decisions`.
- `engine/interpret.py` - `interpret(...)` (the one LLM call) and the prompt assembly.
- `engine/review.py` - `assemble_review(turn) -> ReviewProposal`.
- `engine/compile_project.py` - `build_project(...) -> FlyerProject` (approved values + creative elements).

**Modified:**
- `engine/llm.py` - add `INTERPRET_SYSTEM` + enum-catalog helpers.
- `engine/rubrics.py` - add `MUST_HAVE_FACTS`, palette swatches, and briefing prose; keep `Rubric`/`rubric_for`.
- `engine/orchestrator.py` - `Engine` rebuilt around `interpret`/`TurnResult` (same Event kinds out).
- `engine/schema.py` - reduced to the wire models (`ExtractedBrief`, `FieldProposal`, `DesignQuestion`, `DesignBrief`, `ReviewProposal` + new `creative_elements`); validators/cleanup removed.
- `engine/app.py` - serialize the review (creative elements ride along); `ChatIn` gains `selected_elements`.

**Deleted:**
- `engine/answers.py`, `engine/extract.py`, `engine/plan.py`, `engine/gaps.py`, and the table guts of `engine/decide.py`. Their tests are removed/replaced.

**Kept untouched:** `engine/openrouter_client.py`, `engine/config.py`, `engine/tools.py`, `models.py`, `prompt_builder.py`, `image_generator.py`.

---

## Task 1: `TurnResult` schema + enum validator (the typed edge)

The single contract the brain returns and the only gatekeeping deterministic code does.

**Files:**
- Create: `engine/turn.py`
- Test: `tests/engine/test_turn.py`

**Interfaces:**
- Produces: `TurnResult` (pydantic), `TurnQuestion`, `TurnDecision`, `CreativeElement`, and `validate_decisions(turn: TurnResult) -> TurnResult` (annotates each decision's `supported: bool` in place and returns the turn). `DECISION_KEYS = ["format","palette","visual_style","mood","quality"]`.

- [ ] **Step 1: Write `engine/turn.py`**

```python
"""The one object the brain returns each turn, plus the only deterministic gate."""
from typing import Dict, List, Optional
from pydantic import BaseModel, field_validator
from models import AspectRatio, VisualStyle, Mood

# Content fields the brief carries (same names as engine.schema.ExtractedBrief -> wire-compatible).
BRIEF_FIELDS = [
    "category", "headline", "subheadline", "body_text", "date", "time",
    "venue_name", "address", "price", "discount_text", "cta_text",
    "phone", "email", "website", "social_handle",
]
DECISION_KEYS = ["format", "palette", "visual_style", "mood", "quality"]
QUALITY_VALUES = ["low", "medium", "high", "hd"]


class TurnQuestion(BaseModel):
    field: str = ""          # the brief key this question fills (e.g. "date")
    text: str = ""           # the user-facing question


class TurnDecision(BaseModel):
    key: str                 # one of DECISION_KEYS
    value: str = ""          # the brain's chosen value (enum value OR display name)
    options: List[str] = []  # alternatives to show as chips
    reason: str = ""         # one-line why
    supported: bool = True   # set by validate_decisions; False => surfaced as unsupported


class CreativeElement(BaseModel):
    what: str                # "Silhouette of the Imam Hussain Shrine"
    why: str = ""            # "evokes Karbala, sets a reverent tone"
    sensitivity: str = "safe"  # "safe" => pre-selected; "sensitive" => opt-in


class TurnResult(BaseModel):
    status: str = "ready"    # "need_input" | "ready"
    # --- brief (content) ---
    category: str = "announcement"
    headline: Optional[str] = None
    subheadline: Optional[str] = None
    body_text: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    venue_name: Optional[str] = None
    address: Optional[str] = None
    price: Optional[str] = None
    discount_text: Optional[str] = None
    cta_text: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    social_handle: Optional[str] = None
    additional_info: Optional[List[str]] = None
    purpose: Optional[str] = None
    field_sources: Dict[str, str] = {}        # field -> "stated" | "inferred"
    warnings: Dict[str, str] = {}             # field -> brain-reported note (e.g. malformed website)
    # --- when status == need_input ---
    questions: List[TurnQuestion] = []
    # --- when status == ready (the confident draft) ---
    decisions: List[TurnDecision] = []
    creative_elements: List[CreativeElement] = []
    notes: str = ""
    checklist: List[str] = []
    recommendations: List[str] = []

    @field_validator("category", mode="before")
    @classmethod
    def _default_category(cls, v):
        return v or "announcement"

    @field_validator("field_sources", "warnings", mode="before")
    @classmethod
    def _clean_str_map(cls, v):
        if not isinstance(v, dict):
            return {}
        return {k: val for k, val in v.items() if isinstance(val, str)}


def _is_supported(key: str, value: str) -> bool:
    """True if `value` is a real member of the enum/set for this decision key.
    Accepts either the wire value ("4:5", "modern_minimal") or the display name
    ("Portrait (4:5) - Instagram", "Modern Minimal")."""
    if not value:
        return False
    if key == "format":
        return any(value in (a.value, a.display_name) for a in AspectRatio)
    if key == "visual_style":
        return any(value in (s.value, s.display_name) for s in VisualStyle)
    if key == "mood":
        return any(value in (m.value, m.display_name) for m in Mood)
    if key == "quality":
        return value in QUALITY_VALUES
    if key == "palette":
        return True   # palette is a free-text named direction; the rubric supplies swatches
    return True


def validate_decisions(turn: TurnResult) -> TurnResult:
    """The only gatekeeping: mark each decision supported/unsupported. Never drops or snaps."""
    for d in turn.decisions:
        d.supported = _is_supported(d.key, d.value)
    return turn
```

- [ ] **Step 2: Write `tests/engine/test_turn.py`**

```python
from engine.turn import TurnResult, TurnDecision, CreativeElement, validate_decisions

def test_turnresult_parses_minimal():
    t = TurnResult.model_validate({"status": "ready", "category": "event", "headline": "Gala"})
    assert t.status == "ready" and t.headline == "Gala"

def test_validate_decisions_flags_offvocab_format():
    t = TurnResult(decisions=[
        TurnDecision(key="format", value="letter"),       # real AspectRatio value
        TurnDecision(key="format", value="billboard"),    # not supported
        TurnDecision(key="visual_style", value="Modern Minimal"),  # display name ok
    ])
    validate_decisions(t)
    by = {(d.key, d.value): d.supported for d in t.decisions}
    assert by[("format", "letter")] is True
    assert by[("format", "billboard")] is False
    assert by[("visual_style", "Modern Minimal")] is True

def test_category_defaults_when_null():
    assert TurnResult.model_validate({"category": None}).category == "announcement"
```

- [ ] **Step 3: Run the tests**

Run: `.venv/bin/python -m pytest tests/engine/test_turn.py -v`
Expected: 3 passed.

---

## Task 2: The interpret call + the design-director briefing

One LLM call that reads the conversation and returns a `TurnResult`. This is where the "rule pile" is replaced by judgment.

**Files:**
- Create: `engine/interpret.py`
- Modify: `engine/llm.py` (add `INTERPRET_SYSTEM` + `_enum_catalog` helpers)
- Modify: `engine/rubrics.py` (add `MUST_HAVE_FACTS`, `PALETTE_SWATCHES`, `briefing_for`)
- Test: `tests/engine/test_interpret.py`

**Interfaces:**
- Consumes: `TurnResult` (Task 1); `OpenRouterClient` (`.messages.parse`); `rubric_for`, `MUST_HAVE_FACTS`, `briefing_for` (rubrics).
- Produces: `interpret(prior_brief: Optional[dict], user_text: Optional[str], answers: Optional[dict], client) -> TurnResult`. (No rubric arg - `interpret` looks up the rubric from the brain's category internally after a first pass, OR includes all category briefings; see Step 2 note.) `INTERPRET_SYSTEM` (list-of-blocks, cached). `_enum_catalog(EnumCls) -> str`.

- [ ] **Step 1: Add enum catalog helpers + `INTERPRET_SYSTEM` to `engine/llm.py`**

Keep `get_client()` as-is. Add:

```python
from models import FlyerCategory, VisualStyle, Mood, AspectRatio

def _enum_catalog(enum_cls) -> str:
    return "\n".join(f"- {m.value}: {m.display_name}" for m in enum_cls)

INTERPRET_SYSTEM = [{
    "type": "text",
    "text": (
        "You are a senior graphic designer running a flyer intake and design pass. "
        "You OWN all interpretation of the user's words - there is no code that cleans up after you.\n\n"
        "RESPONSIBILITIES every turn:\n"
        "1. EXTRACT every content field from the whole conversation. Put each value in its correct field "
        "(a phone in `phone`, a URL in `website`, an email in `email`), normalize prices to a clean form "
        "(e.g. \"$18\"), and take contact details at FACE VALUE - never reject a well-formed value because a "
        "brand or domain seems unexpected. If the user declines or defers a field (\"no\", \"idk\", \"you decide\"), "
        "do NOT store that phrase - leave the field null and let your inference fill it. In `field_sources` map "
        "each populated field to \"stated\" or \"inferred\". If a contact looks malformed, keep it AND add a short "
        "note in `warnings[field]`.\n"
        "2. COMPLETENESS. Ask ONLY for must-have facts you cannot confidently infer (see the must-have list per "
        "category below). If anything required is missing and not inferable, set status=\"need_input\" and return "
        "`questions` (at most 3). Otherwise set status=\"ready\" and infer the rest.\n"
        "3. CONFIDENT DRAFT. When ready, pick the single best value for each design decision "
        "(format, palette, visual_style, mood, quality) and return it in `decisions` with 2-4 `options` and a "
        "one-line `reason`. Use the exact enum values from the catalogs below. Never leave a decision blank.\n"
        "4. PROACTIVE IDEAS. Propose 2-3 high-impact `creative_elements` the user did not ask for but should have, "
        "each with `what` + `why`. Tag `sensitivity=\"safe\"` for palette/tone/abstract motifs; tag "
        "`sensitivity=\"sensitive\"` for specific, representational, or religious imagery (a shrine, a deity, a flag). "
        "Think about the occasion: what it evokes, the appropriate motifs, color symbolism, and tone - especially for "
        "cultural or religious events. Do NOT guess wildly; be tasteful and respectful.\n"
        "5. PLAN. Return brief `notes`, a concrete `checklist`, and `recommendations`.\n\n"
        "CATALOGS (use the value on the left):\n"
        "Categories:\n" + _enum_catalog(FlyerCategory) + "\n"
        "Formats:\n" + _enum_catalog(AspectRatio) + "\n"
        "Visual styles:\n" + _enum_catalog(VisualStyle) + "\n"
        "Moods:\n" + _enum_catalog(Mood) + "\n"
        "Quality: low | medium | high | hd\n"
    ),
    "cache_control": {"type": "ephemeral"},
}]
```

> The wording above is the v1 deliverable; it is tuned against the eval harness in Task 8 (acceptance = the eval behaviors pass). Treat the eval cases, not exact prose, as the contract.

- [ ] **Step 2: Add the briefing data to `engine/rubrics.py`**

Keep `Rubric`, `RUBRICS`, `GENERIC_RUBRIC`, `rubric_for`. Add:

```python
from models import FlyerCategory

# The tiny declarative "must-ask" floor: facts that, if missing AND not inferable, must be asked.
# Grows with categories, never with user phrasings.
MUST_HAVE_FACTS: dict[FlyerCategory, list[str]] = {
    FlyerCategory.EVENT: ["date", "venue_name"],
    FlyerCategory.SALE_PROMO: ["discount_text", "date"],
    FlyerCategory.PARTY_CELEBRATION: ["date", "venue_name"],
    FlyerCategory.MUSIC_CONCERT: ["date", "venue_name"],
    FlyerCategory.CLASS_WORKSHOP: ["date"],
    FlyerCategory.GRAND_OPENING: ["date", "venue_name"],
    FlyerCategory.NONPROFIT_CHARITY: ["cta_text"],
    FlyerCategory.JOB_POSTING: ["cta_text"],
    FlyerCategory.REAL_ESTATE: ["address", "price"],
    FlyerCategory.CHURCH_RELIGIOUS: ["date"],
    # categories not listed have no hard floor (everything inferable) -> never blocks.
}

# Named palette directions -> swatch hexes, so colors stay curated (replaces _PALETTE_PRESETS keyword table).
# Keyed by the lowercased direction name the brain returns; unknown directions fall back at compile time.
PALETTE_SWATCHES: dict[str, list[str]] = {
    "warm & inviting": ["#C2410C", "#F59E0B", "#FFF7ED"],
    "cool & modern": ["#0369A1", "#0891B2", "#F0F9FF"],
    "high-contrast bold": ["#111111", "#E11D48", "#FFFFFF"],
    # ... author one entry per direction used in RUBRICS + SEASONAL_PALETTE_DIRECTIONS.
}

def must_have_facts(category) -> list[str]:
    try:
        cat = category if isinstance(category, FlyerCategory) else FlyerCategory(category)
    except ValueError:
        return []
    return MUST_HAVE_FACTS.get(cat, [])

def briefing_for(category) -> str:
    """A compact, model-facing briefing string: the rubric's how-to-think + this category's must-haves."""
    r = rubric_for(category)
    floor = ", ".join(must_have_facts(category)) or "none"
    return (
        f"Design checklist: {'; '.join(r.checklist)}\n"
        f"Hierarchy (loudest first): {' > '.join(r.hierarchy)}\n"
        f"Recommended palette directions: {', '.join(r.palette_directions)}\n"
        f"Must-have facts (ask if missing and not inferable): {floor}"
    )
```

- [ ] **Step 3: Write `engine/interpret.py`**

```python
"""The single design-director call: conversation -> TurnResult."""
import json
from typing import Optional
from engine.turn import TurnResult, validate_decisions
from engine.llm import INTERPRET_SYSTEM, get_client
from engine.config import MODEL, MAX_TOKENS, THINKING, EFFORT
from engine.rubrics import briefing_for

def _user_prompt(prior_brief, user_text, answers) -> str:
    parts = []
    if prior_brief:
        parts.append("Conversation so far, as the brief you produced last turn (update it):\n"
                     + json.dumps(prior_brief, ensure_ascii=False))
    if user_text:
        parts.append("User said:\n" + user_text)
    if answers:
        parts.append("User answered your questions:\n" + json.dumps(answers, ensure_ascii=False))
    # The category may already be known; include its briefing so the model applies it.
    cat = (prior_brief or {}).get("category") or "announcement"
    parts.append("Design briefing for the likely category:\n" + briefing_for(cat))
    parts.append("Return ONE TurnResult JSON. If must-have facts are missing and not inferable, "
                 "status=need_input with questions; otherwise status=ready with decisions, "
                 "creative_elements, and the plan.")
    return "\n\n".join(parts)

def interpret(prior_brief: Optional[dict], user_text: Optional[str],
              answers: Optional[dict], client=None) -> TurnResult:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        system=INTERPRET_SYSTEM,
        messages=[{"role": "user", "content": _user_prompt(prior_brief, user_text, answers)}],
        thinking=THINKING,
        output_config=EFFORT,
        output_format=TurnResult,
    )
    return validate_decisions(resp.parsed_output)
```

- [ ] **Step 4: Write `tests/engine/test_interpret.py` (mocked client, no real API)**

```python
from unittest.mock import MagicMock
from engine.turn import TurnResult
from engine.interpret import interpret
from engine.llm import INTERPRET_SYSTEM

def _client_returning(turn: TurnResult):
    c = MagicMock()
    c.messages.parse.return_value = MagicMock(parsed_output=turn)
    return c

def test_interpret_returns_validated_turn():
    canned = TurnResult(status="ready", category="event", headline="Gala",
                        decisions=[{"key": "format", "value": "billboard"}])
    c = _client_returning(canned)
    out = interpret(prior_brief={"category": "event"}, user_text="gala", answers=None, client=c)
    assert out.headline == "Gala"
    assert out.decisions[0].supported is False          # validate_decisions ran
    # the call carried our system + output_format
    kwargs = c.messages.parse.call_args.kwargs
    assert kwargs["system"] is INTERPRET_SYSTEM and kwargs["output_format"] is TurnResult

def test_interpret_prompt_includes_must_have_floor():
    c = _client_returning(TurnResult())
    interpret(prior_brief={"category": "event"}, user_text="x", answers=None, client=c)
    content = c.messages.parse.call_args.kwargs["messages"][0]["content"]
    assert "Must-have facts" in content and "date" in content
```

- [ ] **Step 5: Run the tests**

Run: `.venv/bin/python -m pytest tests/engine/test_interpret.py tests/engine/test_turn.py -v`
Expected: all passed.

---

## Task 3: Orchestrator rebuilt around `TurnResult`

Same Event kinds out (wire-frozen); the pile of collaborators collapses to `interpret` + the Task 4/5 helpers.

**Files:**
- Modify: `engine/orchestrator.py`
- Test: `tests/engine/test_orchestrator.py` (replace)

**Interfaces:**
- Consumes: `interpret` (Task 2), `assemble_review` (Task 4), `build_project` (Task 5), `generate_concepts` (tools), `to_brief_dict` (Task 4 helper, `TurnResult -> ExtractedBrief-shaped dict`).
- Produces: `Engine(client, interpret_fn=None, assemble_fn=None, build_project_fn=None, generate_concepts=None, generator=None)` with `handle_user_message(text)`, `handle_answers(answers)`, `handle_approval(field_overrides, decision_overrides, answers, user_photos_b64)`, `handle_refine(...)`, `handle_resize(...)`. State: `self.turn: Optional[TurnResult]`, `self.brief: dict`, `self.project`.

- [ ] **Step 1: Rewrite the `Engine` (keep `Event`, `handle_refine`, `handle_resize` exactly as today)**

```python
from dataclasses import dataclass
from typing import Any, Iterator, Optional
from engine.turn import TurnResult
from engine import interpret as _interpret
from engine.review import assemble_review, to_brief_dict
from engine.compile_project import build_project
from engine import tools as _tools

@dataclass
class Event:
    kind: str
    payload: Any = None

class Engine:
    def __init__(self, client, interpret_fn=None, assemble_fn=None, build_project_fn=None,
                 generate_concepts=None, generator=None, refine_concept=None, resize_concept=None):
        self.client = client
        self._interpret = interpret_fn or _interpret.interpret
        self._assemble = assemble_fn or assemble_review
        self._build_project = build_project_fn or build_project
        self._generate_concepts = generate_concepts or _tools.generate_concepts
        self._generator = generator
        self._refine = refine_concept or _tools.refine_concept
        self._resize = resize_concept or _tools.resize_concept
        self.turn: Optional[TurnResult] = None
        self.brief: dict = {}        # wire state (ExtractedBrief-shaped), persisted in/out
        self.project = None

    def _run(self, user_text=None, answers=None) -> Iterator[Event]:
        try:
            turn = self._interpret(self.brief or None, user_text, answers, client=self.client)
        except Exception as e:                       # keep the wire contract on failure
            yield Event("error", str(e)); return
        self.turn = turn
        self.brief = to_brief_dict(turn)             # ExtractedBrief-shaped dict for persistence
        yield Event("parsed_fields", self.brief)
        if turn.status == "need_input" and turn.questions:
            from engine.review import to_question_set
            yield Event("questions", to_question_set(turn))
        else:
            yield Event("review", self._assemble(turn))

    def handle_user_message(self, text: str) -> Iterator[Event]:
        yield from self._run(user_text=text)

    def handle_answers(self, answers) -> Iterator[Event]:
        yield from self._run(answers=answers)

    def handle_approval(self, field_overrides=None, decision_overrides=None,
                        answers=None, user_photos_b64=None) -> Iterator[Event]:
        if self.turn is None:
            yield Event("error", "no interpretation to generate from"); return
        project = self._build_project(self.turn, field_overrides or {}, decision_overrides or {},
                                      selected_elements=None)
        self.project = project
        concepts = self._generate_concepts(project, generator=self._generator, n=3,
                                           user_photo_paths=None)  # photos wired in Task 6
        yield Event("concepts", concepts)
```

> Keep the existing `handle_refine`, `handle_resize`, and the `_resolved_image`/`_materialized_images` context managers verbatim from the current file. The `stage`/`handle_design_answers` ask-once machinery is GONE - the brain decides `need_input` each turn, so `handle_answers` covers both gap and design re-asks. (`app.py` Task 6 drops the `stage=="design"` branch.)

- [ ] **Step 2: Write `tests/engine/test_orchestrator.py` (mock interpret + generate)**

```python
from unittest.mock import MagicMock
from engine.orchestrator import Engine, Event
from engine.turn import TurnResult, TurnQuestion, TurnDecision
from engine.tools import Concept

def _engine_with(turn, generate=None):
    eng = Engine(client=MagicMock(), interpret_fn=lambda *a, **k: turn,
                 generate_concepts=generate or (lambda *a, **k: [Concept("v1", "b64")]),
                 generator=MagicMock())
    return eng

def test_need_input_emits_questions_not_review():
    turn = TurnResult(status="need_input", category="event",
                      questions=[TurnQuestion(field="date", text="What day?")])
    kinds = [e.kind for e in _engine_with(turn).handle_user_message("party")]
    assert "questions" in kinds and "review" not in kinds

def test_ready_emits_review():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="4:5")])
    events = list(_engine_with(turn).handle_user_message("gala sat at hall"))
    assert "review" in [e.kind for e in events]

def test_approval_generates_concepts():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="letter")])
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["aspect"] = project.output.aspect_ratio
        return [Concept("v1", "b64")]
    eng = _engine_with(turn, generate=fake_gen)
    list(eng.handle_user_message("gala"))          # establishes self.turn
    events = list(eng.handle_approval(decision_overrides={"format": "letter"}))
    from models import AspectRatio
    assert "concepts" in [e.kind for e in events]
    assert captured["aspect"] == AspectRatio.LETTER
```

- [ ] **Step 3: Run the tests** (will fail until Tasks 4 and 5 land their helpers - run after Task 5).

Run: `.venv/bin/python -m pytest tests/engine/test_orchestrator.py -v`
Expected after Task 5: passed.

---

## Task 4: Review assembler + wire projections

Turn the `TurnResult` into the frozen `ReviewProposal` wire payload (plus the `parsed_fields` dict and `QuestionSet`).

**Files:**
- Create: `engine/review.py`
- Modify: `engine/schema.py` (add `creative_elements` to `ReviewProposal`; keep `FieldProposal`, `DesignQuestion`, `DesignBrief`)
- Test: `tests/engine/test_review.py`

**Interfaces:**
- Produces: `assemble_review(turn) -> ReviewProposal`, `to_brief_dict(turn) -> dict`, `to_question_set(turn) -> QuestionSet`. Display order `REVIEW_FIELDS` (same as today's `_REVIEW_FIELDS`).

- [ ] **Step 1: Add `creative_elements` to `ReviewProposal` in `engine/schema.py`**

Reduce `ReviewProposal` to (keep the class, add one field):

```python
class CreativeProposal(BaseModel):
    what: str
    why: str = ""
    sensitivity: str = "safe"
    selected: bool = True          # safe -> pre-selected; sensitive -> False

class ReviewProposal(BaseModel):
    fields: List[FieldProposal] = []
    decisions: list = []                       # list of dicts (key/label/value/options/reason/supported)
    creative_elements: List[CreativeProposal] = []
    plan: Optional[Any] = None                 # DesignBrief-shaped
    model_config = {"arbitrary_types_allowed": True}
```

- [ ] **Step 2: Write `engine/review.py`**

```python
"""Project a TurnResult onto the frozen wire payloads (review / parsed_fields / questions)."""
from engine.turn import TurnResult, BRIEF_FIELDS
from engine.schema import FieldProposal, DesignQuestion, DesignBrief, ReviewProposal, CreativeProposal
from engine.gaps_compat import QuestionSet, Question   # see note below
from models import AspectRatio, VisualStyle, Mood

REVIEW_FIELDS = ["category", "headline", "subheadline", "body_text", "date", "time",
                 "venue_name", "address", "price", "discount_text", "cta_text",
                 "phone", "email", "website", "social_handle"]

_DECISION_LABELS = {"format": "Size / format", "palette": "Color palette",
                    "visual_style": "Visual style", "mood": "Mood", "quality": "Quality"}

def to_brief_dict(turn: TurnResult) -> dict:
    """ExtractedBrief-shaped dict (wire state). Only the content + sources travel."""
    d = {k: getattr(turn, k) for k in
         ["category", "headline", "subheadline", "body_text", "date", "time", "venue_name",
          "address", "price", "discount_text", "cta_text", "phone", "email", "website",
          "additional_info", "purpose"]}
    d["field_sources"] = turn.field_sources
    return {k: v for k, v in d.items() if v is not None}

def to_question_set(turn: TurnResult) -> QuestionSet:
    return QuestionSet(questions=[Question(field=q.field, text=q.text) for q in turn.questions],
                       stage="gaps")

def assemble_review(turn: TurnResult) -> ReviewProposal:
    fields = []
    for key in REVIEW_FIELDS:
        value = getattr(turn, key, None)
        if value:
            fields.append(FieldProposal(key=key, value=str(value),
                                        source=turn.field_sources.get(key, "inferred"),
                                        warning=turn.warnings.get(key)))
    decisions = [{"key": d.key, "label": _DECISION_LABELS.get(d.key, d.key),
                  "value": d.value, "options": d.options, "reason": d.reason,
                  "supported": d.supported} for d in turn.decisions]
    elements = [CreativeProposal(what=e.what, why=e.why, sensitivity=e.sensitivity,
                                 selected=(e.sensitivity == "safe")) for e in turn.creative_elements]
    plan = DesignBrief(notes=turn.notes, checklist=turn.checklist, recommendations=turn.recommendations)
    return ReviewProposal(fields=fields, decisions=decisions, creative_elements=elements, plan=plan)
```

> `QuestionSet`/`Question` currently live in `engine/gaps.py`, which Task 7 deletes. Move those two dataclasses into a tiny `engine/gaps_compat.py` (verbatim copy of the `Question` and `QuestionSet` dataclasses from the digest) so the wire shape survives the deletion. Update this import accordingly.

- [ ] **Step 3: Write `tests/engine/test_review.py`**

```python
from engine.turn import TurnResult, TurnDecision, CreativeElement
from engine.review import assemble_review, to_brief_dict, to_question_set

def test_assemble_review_fields_decisions_elements():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      field_sources={"headline": "stated", "category": "inferred"},
                      decisions=[TurnDecision(key="format", value="4:5", options=["4:5", "letter"], reason="feeds")],
                      creative_elements=[CreativeElement(what="Shrine silhouette", sensitivity="sensitive"),
                                         CreativeElement(what="Crimson palette", sensitivity="safe")])
    r = assemble_review(turn)
    assert any(f.key == "headline" and f.source == "stated" for f in r.fields)
    assert r.decisions[0]["key"] == "format" and r.decisions[0]["label"] == "Size / format"
    sel = {e.what: e.selected for e in r.creative_elements}
    assert sel["Crimson palette"] is True and sel["Shrine silhouette"] is False

def test_to_brief_dict_drops_nulls_keeps_sources():
    turn = TurnResult(category="event", headline="Gala", field_sources={"headline": "stated"})
    d = to_brief_dict(turn)
    assert d["headline"] == "Gala" and "subheadline" not in d and d["field_sources"]["headline"] == "stated"
```

- [ ] **Step 4: Run the tests**

Run: `.venv/bin/python -m pytest tests/engine/test_review.py -v`
Expected: passed.

---

## Task 5: Compiler mapper (approved values -> `FlyerProject`)

Replaces `schema.to_flyer_project` + `decide.apply_proposed`/`emphasis_note`. No `is_non_value` cleanup (the brain handles declines; the review confirmed the values).

**Files:**
- Create: `engine/compile_project.py`
- Test: `tests/engine/test_compile_project.py`

**Interfaces:**
- Produces: `build_project(turn, field_overrides: dict, decision_overrides: dict, selected_elements: Optional[list]) -> FlyerProject`.

- [ ] **Step 1: Write `engine/compile_project.py`**

```python
"""Approved TurnResult + user overrides -> FlyerProject (then the unchanged FlyerPromptBuilder runs)."""
from typing import Optional
from models import (FlyerProject, FlyerCategory, TextContent, OutputSettings, VisualSettings,
                    ColorSettings, ColorSchemePreset, AspectRatio, VisualStyle, Mood)
from engine.rubrics import PALETTE_SWATCHES

_CONTENT_FIELDS = ["headline", "subheadline", "body_text", "date", "time", "venue_name",
                   "address", "price", "discount_text", "cta_text", "phone", "email",
                   "website", "social_handle"]

def _category(value) -> FlyerCategory:
    try:
        return FlyerCategory(value)
    except (ValueError, TypeError):
        return FlyerCategory.ANNOUNCEMENT

def _decisions_map(turn, overrides: dict) -> dict:
    """key -> final value: the brain's decision, overridden by the user's review edits."""
    out = {d.key: d.value for d in turn.decisions}
    out.update({k: v for k, v in (overrides or {}).items() if v})
    return out

def _aspect(value) -> AspectRatio:
    for a in AspectRatio:
        if value in (a.value, a.display_name):
            return a
    return AspectRatio.PORTRAIT_4_5            # unsupported was flagged at review; safe fallback

def _enum_by_value_or_label(enum_cls, value, default):
    for m in enum_cls:
        if value in (m.value, m.display_name):
            return m
    return default

def _colors_for(palette_name: Optional[str]) -> ColorSettings:
    hexes = PALETTE_SWATCHES.get((palette_name or "").lower())
    if not hexes:
        return ColorSettings()                 # dataclass defaults
    primary, secondary, *rest = hexes + [None, None]
    return ColorSettings(preset=ColorSchemePreset.CUSTOM, primary_color=primary,
                         secondary_color=secondary, accent_color=rest[0] if rest else None)

def build_project(turn, field_overrides: dict, decision_overrides: dict,
                  selected_elements: Optional[list] = None) -> FlyerProject:
    fo = field_overrides or {}
    tc = TextContent(**{f: (fo.get(f) if f in fo else getattr(turn, f, None)) for f in _CONTENT_FIELDS})
    tc.headline = tc.headline or ""
    tc.additional_info = turn.additional_info or None

    dec = _decisions_map(turn, decision_overrides)
    output = OutputSettings(aspect_ratio=_aspect(dec.get("format")),
                            quality=dec.get("quality") or "hd", model="nano-banana-pro")
    visuals = VisualSettings(style=_enum_by_value_or_label(VisualStyle, dec.get("visual_style"),
                                                           VisualStyle.MODERN_MINIMAL),
                             mood=_enum_by_value_or_label(Mood, dec.get("mood"), Mood.FRIENDLY))
    colors = _colors_for(dec.get("palette"))

    # Approved creative elements -> free-text imagery the existing compiler already supports.
    chosen = selected_elements if selected_elements is not None else \
        [e.what for e in turn.creative_elements if e.sensitivity == "safe"]
    imagery = "; ".join(chosen) or None
    instructions = turn.purpose or None

    return FlyerProject(category=_category(turn.category), text_content=tc, output=output,
                        visuals=visuals, colors=colors,
                        imagery_description=imagery, special_instructions=instructions)
```

- [ ] **Step 2: Write `tests/engine/test_compile_project.py`**

```python
from engine.turn import TurnResult, TurnDecision, CreativeElement
from engine.compile_project import build_project
from models import AspectRatio, VisualStyle, Mood

def _ready_turn():
    return TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="letter"),
                                 TurnDecision(key="visual_style", value="Elegant Luxury"),
                                 TurnDecision(key="mood", value="elegant"),
                                 TurnDecision(key="quality", value="hd")],
                      creative_elements=[CreativeElement(what="Gold foil accents", sensitivity="safe"),
                                         CreativeElement(what="Shrine silhouette", sensitivity="sensitive")])

def test_build_project_applies_decisions():
    p = build_project(_ready_turn(), {}, {})
    assert p.output.aspect_ratio == AspectRatio.LETTER
    assert p.visuals.style == VisualStyle.ELEGANT_LUXURY and p.visuals.mood == Mood.ELEGANT
    assert p.text_content.headline == "Gala"

def test_decision_override_wins():
    p = build_project(_ready_turn(), {}, {"format": "4:5"})
    assert p.output.aspect_ratio == AspectRatio.PORTRAIT_4_5

def test_only_safe_elements_in_imagery_by_default():
    p = build_project(_ready_turn(), {}, {})
    assert "Gold foil accents" in p.imagery_description
    assert "Shrine silhouette" not in p.imagery_description       # sensitive => opt-in only

def test_selected_elements_override_default():
    p = build_project(_ready_turn(), {}, {}, selected_elements=["Gold foil accents", "Shrine silhouette"])
    assert "Shrine silhouette" in p.imagery_description
```

- [ ] **Step 3: Run Tasks 3-5 tests together**

Run: `.venv/bin/python -m pytest tests/engine/test_compile_project.py tests/engine/test_orchestrator.py tests/engine/test_review.py -v`
Expected: all passed.

---

## Task 6: Wire `app.py` (SSE + approve routing)

Keep the route/dispatcher; drop the dead `stage=="design"` branch; pass selected creative elements through approve.

**Files:**
- Modify: `engine/app.py`
- Test: `tests/engine/test_app.py` (update)

**Interfaces:**
- Consumes: the new `Engine` (Task 3). `ChatIn` gains `selected_elements: Optional[List[dict]] = None`.

- [ ] **Step 1: Update `ChatIn` and `run_turn` in `engine/app.py`**

Add to `ChatIn`: `selected_elements: Optional[List[str]] = None`. Rewrite the dispatcher body (keep `chat`, `_sse`, `_to_jsonable`, `get_client`, `get_generator` verbatim):

```python
def run_turn(body: ChatIn):
    action = (body.action or "describe").lower()
    needs_gen = action in ("approve", "refine", "resize")
    eng = Engine(client=get_client(), generator=get_generator() if needs_gen else None)
    if body.brief:
        eng.brief = dict(body.brief)             # ExtractedBrief-shaped wire state
    if action == "answers":
        return eng.handle_answers(body.answers or {})   # stage branch removed
    if action == "approve":
        return eng.handle_approval(field_overrides=body.field_overrides,
                                   decision_overrides=body.decision_overrides,
                                   answers=body.answers or {},
                                   user_photos_b64=body.user_photos_b64)
    if action == "refine":
        return eng.handle_refine(body.prior_image_path, body.instruction or "",
                                 prior_image_b64=body.prior_image_b64)
    if action == "resize":
        return eng.handle_resize(body.prior_image_path, body.aspect_ratio or "",
                                 prior_image_b64=body.prior_image_b64)
    return eng.handle_user_message(body.message or "")
```

> Note: `eng.brief` is now a plain dict (not `ExtractedBrief(**...)`), because the wire brief is produced by `to_brief_dict`. If the iOS client still posts an older brief dict, it round-trips fine (extra keys are ignored by `interpret`'s prompt). Wire `selected_elements` into `handle_approval` -> `build_project(selected_elements=...)` by threading the param through `Engine.handle_approval` (add `selected_elements=None` arg, pass to `_build_project`).

- [ ] **Step 2: Update `tests/engine/test_app.py`**

```python
import json
from unittest.mock import patch
from fastapi.testclient import TestClient
from engine.app import app
from engine.orchestrator import Event
from engine.schema import ReviewProposal, FieldProposal, CreativeProposal

def test_review_event_serializes_with_creative_elements():
    proposal = ReviewProposal(
        fields=[FieldProposal(key="headline", value="Gala", source="stated")],
        decisions=[{"key": "format", "label": "Size / format", "value": "4:5",
                    "options": ["4:5", "letter"], "reason": "feeds", "supported": True}],
        creative_elements=[CreativeProposal(what="Gold accents", sensitivity="safe", selected=True)],
        plan=None)
    with patch("engine.app.run_turn", return_value=iter([Event("review", proposal)])):
        with TestClient(app).stream("POST", "/chat", json={"message": "x"}) as r:
            body = "".join(r.iter_text())
    assert "event: review" in body
    data = json.loads([l for l in body.splitlines() if l.startswith("data: ")][0][6:])
    assert data["fields"][0]["key"] == "headline"
    assert data["creative_elements"][0]["what"] == "Gold accents"
```

- [ ] **Step 3: Run the app tests**

Run: `.venv/bin/python -m pytest tests/engine/test_app.py -v`
Expected: passed.

---

## Task 7: Delete the pile

Remove the dead interpretation/cleanup code now that the brain owns it. Do this only after Tasks 1-6 are green.

**Files:**
- Delete: `engine/answers.py`, `engine/extract.py`, `engine/plan.py`, `engine/gaps.py`
- Create: `engine/gaps_compat.py` (the `Question` + `QuestionSet` dataclasses, verbatim from the digest)
- Modify: `engine/decide.py` (delete `map_format`, `_FORMAT_OPTIONS`, `_PALETTE_PRESETS`, `_resolve_enum`, `propose_decisions`, `apply_proposed`, `apply_decisions`, `emphasis_note`; if nothing remains used, delete the file and its imports)
- Modify: `engine/schema.py` (delete `_WEBSITE_RE`, `_EMAIL_RE`, `_PHONE_CHARS_RE`, `_NON_VALUE`, `is_non_value`, `is_valid_website`, `looks_like_email`, `looks_like_phone`, `reconcile_field_sources`, `sanitize_brief`, `to_flyer_project`, `build_field_proposals`; keep `ExtractedBrief`, `FieldProposal`, `DesignQuestion`, `DesignBrief`, `ReviewProposal`, `CreativeProposal`)
- Delete tests: `tests/engine/test_answers.py`, `test_decide.py`, `test_extract.py`, `test_gaps.py`, `test_plan.py`, and the old `test_schema.py` cases that referenced deleted helpers (keep/trim to `ExtractedBrief` round-trip only)

- [ ] **Step 1: Create `engine/gaps_compat.py`** with the `Question` and `QuestionSet` dataclasses (copy verbatim from the digest's gaps.py contract block).

- [ ] **Step 2: Delete the dead modules and prune `decide.py`/`schema.py`** per the file list above. Grep for stragglers:

Run: `grep -rn "from engine.answers\|from engine.extract\|from engine.plan\|from engine.gaps import\|import gaps\|to_flyer_project\|propose_decisions\|apply_proposed\|is_non_value\|reconcile_field_sources\|sanitize_brief" engine tests`
Expected: no hits except `engine/gaps_compat.py` and the new modules' own references.

- [ ] **Step 3: Run the full engine suite**

Run: `.venv/bin/python -m pytest tests/engine -v`
Expected: green (deleted-module tests removed; new tests pass).

- [ ] **Step 4: Live smoke (real API, manual)**

Run (with `OPENROUTER_API_KEY` loaded):
```bash
.venv/bin/python -c "
from engine.orchestrator import Engine
from engine.llm import get_client
eng = Engine(client=get_client())
for e in eng.handle_user_message('flyer for our church bake sale Saturday 10-2 at Grace Hall, donate at hope.org'):
    print(e.kind, '|', getattr(e.payload, 'decisions', None) or getattr(e.payload, 'questions', None) or e.payload)
"
```
Expected: `parsed_fields` then `review` (a complete brief), the review carrying `decisions` for format/palette/visual_style/mood/quality and at least one `creative_elements` entry.

---

## Task 8: Eval harness over the brief corpus

Lock the behaviors the prompt must hold (this is the acceptance contract for Task 2's prompt).

**Files:**
- Modify/Create: `engine/eval/briefs.jsonl`, `engine/eval/run_eval.py`

**Interfaces:**
- `run_eval.py` runs `interpret`/`Engine` against each brief and asserts the behavior column.

- [ ] **Step 1: Author `engine/eval/briefs.jsonl`** - one JSON object per line:

```jsonl
{"id":"complete_event","text":"flyer for our church bake sale Saturday 10-2 at Grace Hall, donate at hope.org","expect":"ready, 0 questions, format+palette+style+mood+quality decisions"}
{"id":"thin","text":"make me a flyer","expect":"need_input, asks what it's for / date / place"}
{"id":"floor_event_no_date","text":"birthday party flyer at Sunset Hall","expect":"need_input, asks date"}
{"id":"offvocab_format","text":"event flyer, make it billboard size","expect":"ready, format decision flagged unsupported"}
{"id":"contact_routing","text":"plumber flyer, reach me 0300-1234567 or pipes.example","expect":"phone in phone, website in website, no re-route needed"}
{"id":"sensitive_muharram","text":"flyer for our Muharram majlis, 9th night, Imambargah Al-Zahra","expect":"ready, creative_elements include a sensitive one (shrine/Ya Hussain) selected=false by default; somber tone"}
```

- [ ] **Step 2: Write `engine/eval/run_eval.py`** - load the corpus, call `interpret(None, text, None, client=get_client())` per row, print `id`, `status`, question count, decision keys, and the `creative_elements` (with sensitivity). It prints a table for human judgment against `expect` (the owner verifies by reading - [[skip-tdd-favor-momentum]]). Include one hard assertion that does not need a real API by also running the `sensitive_muharram` row through a recorded/mocked `TurnResult` if `OPENROUTER_API_KEY` is unset (skip live calls in CI).

- [ ] **Step 3: Run the eval (manual, real API)**

Run: `.venv/bin/python -m engine.eval.run_eval`
Expected: each row's printed behavior matches its `expect`. Tune `INTERPRET_SYSTEM` (Task 2) until they do - especially: thin brief asks rather than inventing, the floor triggers a date question, off-vocabulary format is flagged, and the Muharram row proposes a sensitive shrine element that is NOT pre-selected.

---

## Self-Review

- **Spec coverage:** TurnResult/typed edge (Task 1), one-brain interpret + briefing + floor + sensitivity + confident-draft (Task 2), state machine (Task 3), assembler (Task 4), compiler mapper (Task 5), app wiring (Task 6), delete-the-pile + OpenRouter-stays + website-flag-now-brain-reported (Task 7), eval incl. thin/floor/off-vocab/sensitive (Task 8). Off-vocabulary-surfaced (Task 1 `supported` + Task 4 carries it + Task 5 safe fallback). Wire stability (Global Constraints + Tasks 4/6). All design sections map to a task.
- **Type consistency:** `TurnResult`/`TurnDecision`/`CreativeElement` (Task 1) are consumed with the same field names in Tasks 3-5; `ReviewProposal`/`CreativeProposal`/`FieldProposal` (Task 4) are produced and asserted identically in Task 6; `build_project(turn, field_overrides, decision_overrides, selected_elements)` signature matches its caller in Task 3 (note: thread `selected_elements` through `handle_approval` per Task 6 Step 1).
- **Open follow-ups (not in this plan):** iOS rendering of `creative_elements` and the opt-in toggle UI; removing the legacy iOS wizard; engine hosting before TestFlight.
