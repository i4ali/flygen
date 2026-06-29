# Design‑Expert Engine Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the backend conversation/reasoning engine that turns a plain‑language request into a finished flyer by behaving like a senior designer (extract → ask only what it can't infer → run a design checklist → drive the existing image pipeline).

**Architecture:** A Claude Opus 4.8 tool‑use agent. Claude reasons/converses and produces a valid `FlyerProject` + design rationale; the **existing** `FlyerPromptBuilder` compiles the image prompt and the **existing** `FlyerImageGenerator` calls Gemini‑3‑Pro‑image as a tool. Exposed as a `POST /chat` SSE service. Engine is stateless per request (history + state in/out); persistence is out of scope.

**Tech Stack:** Python 3, `anthropic` (official SDK, Opus 4.8, adaptive thinking, structured outputs, prompt caching), `fastapi` + `uvicorn` (SSE), `pydantic` (structured I/O), `pytest`. Reuses existing `models.py` / `prompt_builder.py` / `image_generator.py`.

**Design reference:** `docs/plans/2026-06-18-design-expert-engine-design.md` (the PRD) and `mockups/chat-v2/`.

**Conventions for the executing engineer:**
- The repo root is the FlyGen project dir. Existing pipeline modules (`models.py`, `prompt_builder.py`, `image_generator.py`) live at the root; **do not modify them except where a task says so.** New code lives in a new `engine/` package; tests in `tests/engine/`.
- Run tests with `python -m pytest tests/engine -v` from the repo root. The `.venv` is the project venv.
- **Never call the real Anthropic or OpenRouter APIs in unit tests** — mock `anthropic.Anthropic` and `FlyerImageGenerator`. Real‑API behaviour is checked only by the eval harness (Task 11) and manual runs.
- Model id is exactly `claude-opus-4-8`. Use `thinking={"type": "adaptive"}` — **never** `budget_tokens`, `temperature`, `top_p` (they 400 on 4.8). Structured extraction uses `client.messages.parse(..., output_format=Model)` → `.parsed_output`.

---

## Task 0: Branch, package scaffold, dependencies

**Files:**
- Create: `engine/__init__.py`
- Create: `tests/engine/__init__.py`
- Create: `tests/engine/conftest.py`
- Modify: `requirements.txt`

**Step 1: Create the feature branch**

```bash
git checkout -b feat/design-expert-engine
```

**Step 2: Add dependencies**

Append to `requirements.txt`:

```
anthropic>=0.69
fastapi>=0.115
uvicorn>=0.30
pydantic>=2.7
pytest>=8.0
httpx>=0.27
```

Install: `pip install -r requirements.txt`

**Step 3: Create empty package files**

`engine/__init__.py` and `tests/engine/__init__.py` are empty.

`tests/engine/conftest.py`:

```python
import sys, os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
```

**Step 4: Verify the toolchain**

Run: `python -m pytest tests/engine -v`
Expected: PASS (0 tests collected, exit 0) — confirms collection works.

**Step 5: Commit**

```bash
git add engine tests/engine requirements.txt
git commit -m "chore: scaffold engine package and deps"
```

---

## Task 1: Structured I/O schema + `FlyerProject` converter

The engine's structured outputs are pydantic models; the compiler wants the existing dataclass `FlyerProject`. This task defines the bridge.

**Files:**
- Create: `engine/schema.py`
- Test: `tests/engine/test_schema.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_schema.py
from engine.schema import ExtractedBrief, to_flyer_project
from models import FlyerProject, FlyerCategory, AspectRatio

def test_extracted_brief_converts_to_flyer_project():
    brief = ExtractedBrief(
        category="nonprofit_charity",
        headline="Bake Sale",
        date="Sat Jun 14 · 10–2",
        venue_name="Grace Hall",
        cta_text="Donate online",
    )
    project = to_flyer_project(brief)
    assert isinstance(project, FlyerProject)
    assert project.category == FlyerCategory.NONPROFIT_CHARITY
    assert project.text_content.headline == "Bake Sale"
    assert project.text_content.venue_name == "Grace Hall"
    # sane default format when the engine hasn't decided yet
    assert project.output.aspect_ratio == AspectRatio.PORTRAIT_4_5

def test_unknown_category_falls_back_to_announcement():
    project = to_flyer_project(ExtractedBrief(category="not_a_real_category", headline="Hi"))
    assert project.category == FlyerCategory.ANNOUNCEMENT
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_schema.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'engine.schema'`

**Step 3: Write minimal implementation**

```python
# engine/schema.py
from typing import Optional, List
from pydantic import BaseModel
from models import (
    FlyerProject, FlyerCategory, TextContent, OutputSettings, AspectRatio,
)

class ExtractedBrief(BaseModel):
    """What the model extracts from the user's free text. All optional except category."""
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
    purpose: Optional[str] = None  # free-text intent, used by rubric reasoning

def _category(value: str) -> FlyerCategory:
    try:
        return FlyerCategory(value)
    except ValueError:
        return FlyerCategory.ANNOUNCEMENT

def to_flyer_project(brief: ExtractedBrief) -> FlyerProject:
    tc = TextContent(
        headline=brief.headline or "",
        subheadline=brief.subheadline,
        body_text=brief.body_text,
        date=brief.date,
        time=brief.time,
        venue_name=brief.venue_name,
        address=brief.address,
        price=brief.price,
        discount_text=brief.discount_text,
        cta_text=brief.cta_text,
        phone=brief.phone,
        email=brief.email,
        website=brief.website,
    )
    return FlyerProject(
        category=_category(brief.category),
        text_content=tc,
        output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5, model="nano-banana-pro"),
        special_instructions=brief.purpose or None,
    )
```

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_schema.py -v`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add engine/schema.py tests/engine/test_schema.py
git commit -m "feat(engine): ExtractedBrief schema + FlyerProject converter"
```

---

## Task 2: Pipeline‑as‑tools (in‑process, base64, no disk)

Wrap the existing generator so the engine can call it as a tool and get base64 back without touching the filesystem.

**Files:**
- Create: `engine/tools.py`
- Test: `tests/engine/test_tools.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_tools.py
from unittest.mock import MagicMock
from engine.schema import ExtractedBrief, to_flyer_project
from engine.tools import generate_concepts, Concept

def test_generate_concepts_builds_prompt_and_returns_base64():
    fake_result = MagicMock(success=True, image_base64="ZmFrZQ==", image_path=None, error_message=None)
    fake_generator = MagicMock()
    fake_generator.generate.return_value = [fake_result, fake_result, fake_result]

    project = to_flyer_project(ExtractedBrief(category="event", headline="Bake Sale"))
    concepts = generate_concepts(project, generator=fake_generator, n=3)

    assert len(concepts) == 3
    assert all(isinstance(c, Concept) for c in concepts)
    assert concepts[0].image_base64 == "ZmFrZQ=="
    # the wrapper compiled a prompt via FlyerPromptBuilder and asked for no disk writes
    _, kwargs = fake_generator.generate.call_args
    assert kwargs["save_images"] is False
    assert kwargs["n"] == 3
    assert isinstance(kwargs["prompt"], str) and len(kwargs["prompt"]) > 0
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_tools.py -v`
Expected: FAIL — `No module named 'engine.tools'`

**Step 3: Write minimal implementation**

```python
# engine/tools.py
from dataclasses import dataclass
from typing import List, Optional
from models import FlyerProject
from prompt_builder import FlyerPromptBuilder

@dataclass
class Concept:
    version_id: str
    image_base64: Optional[str]
    error: Optional[str] = None

def generate_concepts(project: FlyerProject, generator, n: int = 3) -> List[Concept]:
    """Compile the project to a prompt and generate N concepts as base64 (no disk)."""
    package = FlyerPromptBuilder(project).build()
    input_images = [project.logo_path] if project.logo_path else None
    results = generator.generate(
        prompt=package["main_prompt"],
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"],
        n=n,
        save_images=False,
        input_images=input_images,
    )
    concepts = []
    for i, r in enumerate(results):
        concepts.append(Concept(
            version_id=f"v{i+1}",
            image_base64=getattr(r, "image_base64", None) if r.success else None,
            error=None if r.success else r.error_message,
        ))
    return concepts
```

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_tools.py -v`
Expected: PASS

**Step 5: Add refine + resize wrappers (repeat the TDD cycle)**

Write `test_refine_concept_passes_prior_image_in_edit_mode` and `test_resize_concept_uses_target_aspect`, then add `refine_concept(project, prior_image_path, instruction, generator, mode="edit")` and `resize_concept(prior_image_path, aspect_ratio, generator)` to `engine/tools.py`, mirroring `main.py`'s edit‑mode (`EDIT MODE: …` + prior image in `input_images`) and `reformat_image()` logic. Mock the generator; assert the prior image is passed and the instruction/aspect is honoured.

> Note for the engineer: `FlyerImageGenerator.generate()` already returns `image_base64` for `nano-banana`/`nano-banana-pro` and accepts `save_images=False`. No change to `image_generator.py` is required for this task.

**Step 6: Commit**

```bash
git add engine/tools.py tests/engine/test_tools.py
git commit -m "feat(engine): in-process generate/refine/resize tool wrappers"
```

---

## Task 3: Gap analysis + adaptive questioning (pure logic — full TDD)

This is the deterministic backbone of "asks only what it can't infer." No LLM.

**Files:**
- Create: `engine/gaps.py`
- Test: `tests/engine/test_gaps.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_gaps.py
from engine.schema import ExtractedBrief
from engine.gaps import missing_critical_fields, build_questions

def test_complete_brief_yields_no_questions():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", date="Sat", venue_name="Grace Hall",
        cta_text="Come by", website="x.org",
    )
    assert missing_critical_fields(brief) == []
    assert build_questions(brief).questions == []

def test_vague_brief_asks_for_critical_gaps_only():
    brief = ExtractedBrief(category="event", headline="Bake Sale")  # missing date, venue, cta
    missing = missing_critical_fields(brief)
    assert "date" in missing and "venue_name" in missing
    qs = build_questions(brief)
    assert 0 < len(qs.questions) <= 3            # adaptive: a few, never a fixed script
    assert any("date" in q.field for q in qs.questions)
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_gaps.py -v`
Expected: FAIL — `No module named 'engine.gaps'`

**Step 3: Write minimal implementation**

```python
# engine/gaps.py
from dataclasses import dataclass, field
from typing import List
from models import CATEGORY_TEXT_FIELDS, FlyerCategory
from engine.schema import ExtractedBrief

# A small per-category set of fields that materially change the design if absent.
# (Subset of CATEGORY_TEXT_FIELDS — the "must-haves", curated.)
CRITICAL_FIELDS = {
    FlyerCategory.EVENT: ["date", "venue_name", "cta_text"],
    FlyerCategory.NONPROFIT_CHARITY: ["cta_text"],
    FlyerCategory.SALE_PROMO: ["discount_text", "cta_text"],
    # ... extend per category; fall back to first 3 of CATEGORY_TEXT_FIELDS otherwise
}

QUESTION_TEXT = {
    "date": "When is it?",
    "time": "What time?",
    "venue_name": "Where's it happening?",
    "cta_text": "What should people do — and how?",
    "discount_text": "What's the offer?",
    "destination": "Where's it mostly headed — Instagram, or printed?",
}

@dataclass
class Question:
    field: str
    text: str

@dataclass
class QuestionSet:
    questions: List[Question] = field(default_factory=list)

def _critical_for(category: FlyerCategory) -> List[str]:
    if category in CRITICAL_FIELDS:
        return CRITICAL_FIELDS[category]
    return CATEGORY_TEXT_FIELDS.get(category, [])[:3]

def missing_critical_fields(brief: ExtractedBrief) -> List[str]:
    try:
        category = FlyerCategory(brief.category)
    except ValueError:
        category = FlyerCategory.ANNOUNCEMENT
    out = []
    for f in _critical_for(category):
        if not getattr(brief, f, None):
            out.append(f)
    return out

def build_questions(brief: ExtractedBrief, max_questions: int = 3) -> QuestionSet:
    missing = missing_critical_fields(brief)[:max_questions]
    return QuestionSet([Question(f, QUESTION_TEXT.get(f, f"Tell me the {f}.")) for f in missing])
```

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_gaps.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add engine/gaps.py tests/engine/test_gaps.py
git commit -m "feat(engine): adaptive gap analysis + question builder"
```

---

## Task 4: Extraction step (LLM — mock the client)

**Files:**
- Create: `engine/llm.py` (shared client factory + cached system prompt)
- Create: `engine/extract.py`
- Test: `tests/engine/test_extract.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_extract.py
from unittest.mock import MagicMock
from engine.schema import ExtractedBrief
from engine.extract import extract_brief

def test_extract_brief_calls_parse_with_opus_and_returns_parsed():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(
        parsed_output=ExtractedBrief(category="event", headline="Bake Sale", date="Sat")
    )
    brief = extract_brief("Flyer for our bake sale Saturday", client=fake)
    assert brief.headline == "Bake Sale"
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["model"] == "claude-opus-4-8"
    assert kwargs["output_format"] is ExtractedBrief
    assert "thinking" not in kwargs or kwargs["thinking"] == {"type": "adaptive"}
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_extract.py -v`
Expected: FAIL — `No module named 'engine.extract'`

**Step 3: Write minimal implementation**

```python
# engine/llm.py
import anthropic

MODEL = "claude-opus-4-8"

def get_client() -> anthropic.Anthropic:
    return anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env

# Large, stable → cached. Persona + enum catalogs + rubrics get appended here in later tasks.
EXTRACT_SYSTEM = [{
    "type": "text",
    "text": (
        "You are a senior graphic designer's intake assistant. Extract structured "
        "fields from the user's plain-language flyer request. Infer the single best "
        "FlyerCategory. Leave fields you cannot infer null — do not invent them."
    ),
    "cache_control": {"type": "ephemeral"},
}]
```

```python
# engine/extract.py
from engine.schema import ExtractedBrief
from engine.llm import get_client, MODEL, EXTRACT_SYSTEM

def extract_brief(user_text: str, client=None) -> ExtractedBrief:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL,
        max_tokens=2000,
        system=EXTRACT_SYSTEM,
        messages=[{"role": "user", "content": user_text}],
        output_format=ExtractedBrief,
    )
    return resp.parsed_output
```

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_extract.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add engine/llm.py engine/extract.py tests/engine/test_extract.py
git commit -m "feat(engine): LLM extraction of ExtractedBrief"
```

---

## Task 5: Rubrics + design brief ("plans like a pro")

**Files:**
- Create: `engine/rubrics.py` (structured per‑category design knowledge + generic fallback)
- Create: `engine/plan.py` (`build_design_brief`)
- Test: `tests/engine/test_rubrics.py`, `tests/engine/test_plan.py`

**Step 1 (rubrics — pure logic, TDD):** test `rubric_for(FlyerCategory.NONPROFIT_CHARITY)` returns a `Rubric` with non‑empty `checklist`, `default_recommendations`, and that an unknown category returns the generic fallback. Implement `engine/rubrics.py` as a dict of `Rubric(checklist: list[str], hierarchy: list[str], default_format_reason: str, recommendations: list[str], palette_directions: list[str])` keyed by `FlyerCategory`, with `GENERIC_RUBRIC` fallback. Author the top 2–3 categories concretely (fundraiser/event/sale); the rest inherit generic.

**Step 2 (design brief — LLM, mock client):** test that `build_design_brief(brief, rubric, answers, client=fake)` returns a `DesignBrief(notes, checklist, recommendations)` and that it calls `client.messages.create` (or `.parse` with a `DesignBrief` pydantic model) on `claude-opus-4-8` with `thinking={"type": "adaptive"}` and `output_config={"effort": "high"}`. The model turns the rubric + the specific brief into the applied checklist + a proactive recommendation. Add `DesignBrief` to `engine/schema.py`.

**Step 3:** implement, run, commit:

```bash
git add engine/rubrics.py engine/plan.py engine/schema.py tests/engine/test_rubrics.py tests/engine/test_plan.py
git commit -m "feat(engine): design rubrics + applied design-brief generation"
```

---

## Task 6: Decision mapping → enums + named directions

**Files:**
- Create: `engine/decide.py`
- Test: `tests/engine/test_decide.py`

**Step 1: Write the failing test (deterministic mappings first)**

```python
# tests/engine/test_decide.py
from engine.decide import map_format
from models import AspectRatio

def test_instagram_maps_to_portrait_4_5():
    assert map_format("instagram") == AspectRatio.PORTRAIT_4_5
def test_print_maps_to_letter():
    assert map_format("printed") == AspectRatio.LETTER
def test_both_prefers_portrait():
    assert map_format("both") == AspectRatio.PORTRAIT_4_5
```

**Step 2–4:** implement `map_format`, plus `propose_palette_directions(rubric) -> list[Direction]` (named swatch directions from the rubric) and `apply_decisions(project, answers, rubric) -> FlyerProject` (fills `VisualSettings`/`ColorSettings`/`OutputSettings` + `QRCodeSettings` from answers). The aesthetic choice (which of the named directions) is the user's tap; `apply_decisions` just records it. Keep the deterministic mappings fully tested; the only LLM‑ish part (free‑text palette → hexes) can defer to the rubric's presets. Run, verify PASS.

**Step 5: Commit**

```bash
git add engine/decide.py tests/engine/test_decide.py
git commit -m "feat(engine): decision mapping to format/colour/QR settings"
```

---

## Task 7: Orchestrator state machine (ties it together — mock sub‑steps)

The manual agentic loop. Deterministic state machine; LLM sub‑steps are injected so it's fully testable.

**Files:**
- Create: `engine/orchestrator.py`
- Test: `tests/engine/test_orchestrator.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_orchestrator.py
from unittest.mock import MagicMock
from engine.schema import ExtractedBrief
from engine.orchestrator import Engine, Event

def _engine_with(brief, questions, deps=None):
    deps = deps or {}
    deps.setdefault("extract", lambda text, client=None: brief)
    deps.setdefault("build_questions", lambda b, **k: questions)
    return Engine(client=MagicMock(), **deps)

def test_vague_brief_emits_questions_and_does_not_generate():
    from engine.gaps import QuestionSet, Question
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale"),
        QuestionSet([Question("date", "When is it?")]),
    )
    events = list(eng.handle_user_message("bake sale flyer"))
    kinds = [e.kind for e in events]
    assert "parsed_fields" in kinds
    assert "questions" in kinds
    assert "concepts" not in kinds   # gated: must answer / approve first

def test_complete_brief_reaches_design_brief_then_awaits_approval():
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale", date="Sat", venue_name="Hall", cta_text="Come"),
        QuestionSet([]),
    )
    events = list(eng.handle_user_message("..."))
    kinds = [e.kind for e in events]
    assert "design_brief" in kinds   # "plans like a pro" turn
    assert "awaiting_approval" in kinds
    assert "concepts" not in kinds   # no blind jump to generate
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_orchestrator.py -v`
Expected: FAIL — `No module named 'engine.orchestrator'`

**Step 3: Write minimal implementation**

```python
# engine/orchestrator.py
from dataclasses import dataclass
from typing import Any, Iterator, Optional
from engine import extract as _extract, gaps as _gaps, plan as _plan, rubrics as _rubrics

@dataclass
class Event:
    kind: str            # parsed_fields | questions | design_brief | awaiting_approval | concepts | error
    payload: Any = None

class Engine:
    def __init__(self, client, extract=None, build_questions=None,
                 build_design_brief=None, rubric_for=None):
        self.client = client
        self._extract = extract or _extract.extract_brief
        self._build_questions = build_questions or _gaps.build_questions
        self._build_brief = build_design_brief or _plan.build_design_brief
        self._rubric_for = rubric_for or _rubrics.rubric_for
        self.brief = None  # accumulated ExtractedBrief

    def handle_user_message(self, text: str) -> Iterator[Event]:
        try:
            self.brief = self._extract(text, client=self.client)
        except Exception as e:                      # pragma: no cover - defensive
            yield Event("error", str(e)); return
        yield Event("parsed_fields", self.brief)

        qs = self._build_questions(self.brief)
        if qs.questions:
            yield Event("questions", qs)
            return                                   # gate: wait for answers

        rubric = self._rubric_for(self.brief.category)
        design = self._build_brief(self.brief, rubric, answers={}, client=self.client)
        yield Event("design_brief", design)
        yield Event("awaiting_approval")             # gate: no blind jump to generate
```

> The "answers" and "approval" follow‑up turns are handled by sibling methods (`handle_answers`, `handle_approval` → calls `generate_concepts`). Add them with their own TDD cycles: `handle_approval` should emit `concepts` after calling `engine.tools.generate_concepts`.

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_orchestrator.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add engine/orchestrator.py tests/engine/test_orchestrator.py
git commit -m "feat(engine): orchestrator state machine with generation gate"
```

---

## Task 8: `POST /chat` SSE service

**Files:**
- Create: `engine/app.py`
- Test: `tests/engine/test_app.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_app.py
from unittest.mock import patch
from fastapi.testclient import TestClient
from engine.app import app
from engine.orchestrator import Event

def test_chat_streams_events_as_sse():
    fake_events = [Event("parsed_fields", {"headline": "Bake Sale"}), Event("questions", {"questions": []})]
    with patch("engine.app.run_turn", return_value=iter(fake_events)):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "bake sale flyer"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: parsed_fields" in body
    assert "event: questions" in body
```

**Step 2: Run to verify it fails**

Run: `python -m pytest tests/engine/test_app.py -v`
Expected: FAIL — `No module named 'engine.app'`

**Step 3: Write minimal implementation**

```python
# engine/app.py
import json
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from engine.llm import get_client
from engine.orchestrator import Engine

app = FastAPI()

class ChatIn(BaseModel):
    message: str

def run_turn(message: str):
    return Engine(client=get_client()).handle_user_message(message)

def _sse(events):
    for e in events:
        payload = e.payload
        data = payload if isinstance(payload, (dict, list, str, type(None))) else getattr(payload, "__dict__", str(payload))
        yield f"event: {e.kind}\ndata: {json.dumps(data, default=str)}\n\n"

@app.post("/chat")
def chat(body: ChatIn):
    return StreamingResponse(_sse(run_turn(body.message)), media_type="text/event-stream")
```

**Step 4: Run to verify it passes**

Run: `python -m pytest tests/engine/test_app.py -v`
Expected: PASS

**Step 5: Manual smoke test (real APIs — optional, needs keys)**

```bash
ANTHROPIC_API_KEY=… OPENROUTER_API_KEY=… python -m uvicorn engine.app:app --reload
# then: curl -N -X POST localhost:8000/chat -H 'content-type: application/json' \
#   -d '{"message":"Flyer for our church bake sale Saturday 10-2 at Grace Hall, proceeds to youth camp"}'
```
Expected: a stream of `parsed_fields` → `questions` (or `design_brief` → `awaiting_approval`).

**Step 6: Commit**

```bash
git add engine/app.py tests/engine/test_app.py
git commit -m "feat(engine): POST /chat SSE service wired to orchestrator"
```

---

## Task 9: Approval → concepts, then refine & resize turns

**Files:**
- Modify: `engine/orchestrator.py` (add `handle_approval`, `handle_refine`, `handle_resize`)
- Modify: `engine/app.py` (route follow‑up actions: `answers`, `approve`, `refine`, `resize`)
- Test: extend `tests/engine/test_orchestrator.py`, `tests/engine/test_app.py`

For each: write the failing test (mock `engine.tools.generate_concepts` / `refine_concept` / `resize_concept`), assert the right tool is called and a `concepts`/`refined`/`resized` event is emitted, implement, verify PASS, commit. Keep the generation gate: concepts only after `approve`.

```bash
git commit -m "feat(engine): approval-gated generation, refine and resize turns"
```

---

## Task 10: Prompt caching + per‑turn effort tuning

**Files:**
- Modify: `engine/llm.py`, `engine/plan.py`, `engine/extract.py`
- Test: `tests/engine/test_llm.py`

**Step 1:** test that the assembled system prompt block carries `cache_control: {"type": "ephemeral"}` and that the rubric/enums are appended to one stable cached block (so the prefix is reused across turns). Test that the design‑brief turn passes `output_config={"effort": "high"}` and the extraction turn omits high effort (cheaper). Implement, verify PASS, commit.

```bash
git commit -m "perf(engine): cache stable system prefix, tune effort per turn"
```

---

## Task 11: Eval harness (validation gate — not unit tests)

**Files:**
- Create: `engine/eval/briefs.jsonl` (≥20 representative briefs: complete, vague, multi‑detail, non‑English, fundraiser/event/sale)
- Create: `engine/eval/run_eval.py`
- Create: `tests/engine/test_eval_smoke.py` (mock‑backed; proves the harness runs)

**The harness** (run manually against the real API) reports, per brief:
- extraction: did it find the fields a human marked present?
- question count: 0 for complete briefs, 1–3 for vague ones (never fixed)?
- compile: does `to_flyer_project(brief)` build a prompt via `FlyerPromptBuilder` without error?
- (optional) generate one concept and eyeball it.

`tests/engine/test_eval_smoke.py` runs `run_eval` with a mocked client over 2 briefs and asserts it produces a summary dict — so the harness itself is covered without burning API calls.

**Acceptance for the whole engine:** the harness over the corpus shows correct extraction at the agreed target, adaptive (not fixed) question counts, every brief compiling cleanly through `FlyerPromptBuilder`, and the design‑brief turn always emitting a checklist + ≥1 recommendation.

```bash
git add engine/eval tests/engine/test_eval_smoke.py
git commit -m "test(engine): eval harness over representative brief corpus"
```

---

## Done criteria

- `python -m pytest tests/engine -v` is green.
- The eval harness (Task 11) meets the acceptance bar on the brief corpus.
- A manual `curl` to `/chat` walks describe → (questions) → design brief → approve → three concepts → refine → resize, on the real pipeline.
- No changes to `models.py` / `prompt_builder.py` / `image_generator.py` beyond the `save_images=False` path already supported.

**Then:** the iOS chat‑UI spec and the subscription spec consume this engine (separate plans).
