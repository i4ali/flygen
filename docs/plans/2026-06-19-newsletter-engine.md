# Newsletter Engine Path Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `newsletter` content type to the engine — a thin but real end-to-end path (`describe → outline + design defaults (review gate) → approve → render one Letter page → section refine`) that mirrors the flyer milestone and reuses the flyer spine + image pipeline.

**Architecture:** A new `engine/newsletter/` subpackage parallel to the flyer modules. Extraction parses a free-text brain-dump into a `NewsletterBrief`; `build_outline` (one Opus call) proposes ordered, drafted sections; the orchestrator emits the full `outline` (for state round-trip) plus a consolidated `review` (sections tagged stated/suggested + every design default + the editorial plan) — generation is gated behind `approve`. Rendering reuses `FlyerImageGenerator` to paint one Letter page; the schema stays renderer-agnostic so a structured renderer can replace the render step later.

**Tech Stack:** Python 3, pydantic, FastAPI, pytest. Reuses `engine/` (`DecisionProposal`, `DesignBrief`, `Concept`, `Event`, `_resolved_image`, `_to_jsonable`, `QuestionSet`/`Question`, `Rubric`) and `image_generator.FlyerImageGenerator`. Reasoning runs Claude Opus 4.8 via `engine/openrouter_client.py`.

**Design reference:** `docs/plans/2026-06-19-newsletter-engine-design.md`.

**Conventions for the executing engineer:**
- Run tests from the repo root: `.venv/bin/python -m pytest tests/engine -v`.
- **Never call real APIs in unit tests** — mock the LLM client (`MagicMock`) and the generator.
- Work **in-place** on the current tree (the `engine/` package is untracked WIP). **Commits are at the owner's discretion** — treat `git commit` steps as optional; still stage/verify per task.
- Do **not** modify `models.py` / `prompt_builder.py` / `image_generator.py`. The newsletter prompt builder is engine-side.
- Reuse, don't duplicate: import `DecisionProposal` from `engine.decide`, `DesignBrief` from `engine.schema`, `Concept`/`_to_concept` from `engine.tools`, `Event`/`_resolved_image` from `engine.orchestrator`, `QuestionSet`/`Question` from `engine.gaps`, `Rubric` from `engine.rubrics`.

---

## Task 1: Newsletter schema — core types

Create the subpackage and the extraction/structure types.

**Files:**
- Create: `engine/newsletter/__init__.py` (empty)
- Create: `engine/newsletter/schema.py`
- Test: `tests/engine/test_newsletter_schema.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_schema.py
from engine.newsletter.schema import (
    NewsletterItem, NewsletterBrief, Masthead, Section, NewsletterOutline,
    newsletter_field_source,
)


def test_newsletter_brief_round_trip_and_source_helper():
    b = NewsletterBrief(
        org_name="Grace Community Church", title="The Messenger",
        items=[NewsletterItem(topic="summer camp signups", source="stated")],
        field_sources={"org_name": "stated", "title": "inferred"},
    )
    assert b.org_name == "Grace Community Church"
    assert b.items[0].topic == "summer camp signups"
    assert newsletter_field_source(b, "org_name") == "stated"
    assert newsletter_field_source(b, "title") == "inferred"
    assert newsletter_field_source(b, "issue_label") == "inferred"   # unknown -> conservative


def test_section_defaults_and_outline():
    s = Section(key="lead", heading="Welcome Pastor Dale", order=1)
    assert s.kind == "brief" and s.origin == "stated" and s.body == ""
    o = NewsletterOutline(masthead=Masthead(title="The Messenger"), sections=[s])
    assert o.masthead.title == "The Messenger" and o.sections[0].key == "lead"
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_schema.py -v`
Expected: FAIL — `ModuleNotFoundError: engine.newsletter` / cannot import.

**Step 3: Implement** — `engine/newsletter/__init__.py` empty; `engine/newsletter/schema.py`:

```python
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class NewsletterItem(BaseModel):
    topic: str
    note: Optional[str] = None
    source: str = "stated"           # stated | inferred


class NewsletterBrief(BaseModel):
    org_name: Optional[str] = None
    title: Optional[str] = None
    issue_label: Optional[str] = None
    audience: Optional[str] = None
    purpose: Optional[str] = None
    destination: Optional[str] = None
    items: List[NewsletterItem] = []
    field_sources: Dict[str, str] = {}


class Masthead(BaseModel):
    title: str = ""
    org_name: Optional[str] = None
    issue_label: Optional[str] = None


class Section(BaseModel):
    key: str
    heading: str
    body: str = ""
    kind: str = "brief"              # lead | brief | events | footer
    origin: str = "stated"           # stated | suggested
    order: int = 0


class NewsletterOutline(BaseModel):
    masthead: Masthead = Field(default_factory=Masthead)
    sections: List[Section] = []


def newsletter_field_source(brief: "NewsletterBrief", key: str) -> str:
    """stated if the model said it came from the user; inferred otherwise (conservative)."""
    return brief.field_sources.get(key, "inferred")
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_schema.py -v`
Expected: PASS

**Step 5: Commit (optional)** — `git add engine/newsletter/ tests/engine/test_newsletter_schema.py && git commit -m "feat(newsletter): core schema types"`

---

## Task 2: Project, converter, proposals, review payload

Complete the schema: the renderable project, the converter, and the `review` payload pieces.

**Files:**
- Modify: `engine/newsletter/schema.py`
- Test: `tests/engine/test_newsletter_schema.py`

**Step 1: Write the failing test** (append)

```python
from engine.newsletter.schema import (
    NewsletterProject, to_newsletter_project, SectionProposal, build_section_proposals,
    NewsletterReviewProposal, OutlinePlan,
)
from unittest.mock import MagicMock


def test_to_newsletter_project_defaults_letter_two_col():
    outline = NewsletterOutline(masthead=Masthead(title="The Messenger"),
                                sections=[Section(key="lead", heading="L", order=1)])
    p = to_newsletter_project(NewsletterBrief(), outline)
    assert isinstance(p, NewsletterProject)
    assert p.format == "letter" and p.columns == 2
    assert p.sections[0].key == "lead" and p.masthead.title == "The Messenger"


def test_build_section_proposals_preserves_order_and_origin():
    outline = NewsletterOutline(sections=[
        Section(key="foot", heading="Footer", kind="footer", origin="suggested", order=2, body="contact us"),
        Section(key="lead", heading="Welcome", kind="lead", origin="stated", order=1, body="a" * 200),
    ])
    props = build_section_proposals(outline)
    assert [p.key for p in props] == ["lead", "foot"]          # sorted by order
    assert props[0].origin == "stated" and props[1].origin == "suggested"
    assert len(props[0].preview) <= 80                          # body truncated to a preview


def test_review_proposal_accepts_mock_plan_and_serializes():
    from engine.decide import DecisionProposal
    rp = NewsletterReviewProposal(
        sections=[SectionProposal(key="lead", heading="W", kind="lead", origin="stated", order=1)],
        decisions=[DecisionProposal("format", "Page format", "letter", ["letter", "a4"], "x")],
        plan=MagicMock(),                                       # production passes a DesignBrief
    )
    dumped = rp.model_dump()
    assert dumped["sections"][0]["key"] == "lead"
    assert dumped["decisions"][0]["key"] == "format"           # dataclass -> dict
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_schema.py -v`
Expected: FAIL — cannot import `NewsletterProject` / `OutlinePlan`.

**Step 3: Implement** (append to `engine/newsletter/schema.py`)

```python
class NewsletterProject(BaseModel):
    """Renderer-agnostic document: structured content + design settings (no pixels)."""
    masthead: Masthead = Field(default_factory=Masthead)
    sections: List[Section] = []
    format: str = "letter"           # letter | a4
    columns: int = 2
    palette: Optional[str] = None
    visual_style: str = "modern_minimal"
    quality: str = "hd"
    model: str = "nano-banana-pro"


def to_newsletter_project(brief: NewsletterBrief, outline: NewsletterOutline) -> NewsletterProject:
    return NewsletterProject(masthead=outline.masthead, sections=list(outline.sections))


class SectionProposal(BaseModel):
    key: str
    heading: str
    kind: str
    origin: str                      # stated | suggested
    order: int
    preview: str = ""


def build_section_proposals(outline: NewsletterOutline) -> List[SectionProposal]:
    out = []
    for s in sorted(outline.sections, key=lambda x: x.order):
        out.append(SectionProposal(key=s.key, heading=s.heading, kind=s.kind,
                                   origin=s.origin, order=s.order, preview=(s.body or "")[:80]))
    return out


class OutlinePlan(BaseModel):
    """What build_outline returns from one LLM call: structure + editorial rationale."""
    masthead: Masthead = Field(default_factory=Masthead)
    sections: List[Section] = []
    notes: str = ""
    checklist: List[str] = []
    recommendations: List[str] = []


class NewsletterReviewProposal(BaseModel):
    """The consolidated review — the newsletter twin of ReviewProposal (sections, not fields)."""
    masthead: Masthead = Field(default_factory=Masthead)
    sections: List[SectionProposal] = []
    decisions: list = []             # list[DecisionProposal] (dataclass) — loosely typed
    plan: Optional[Any] = None       # DesignBrief in production; loose so a mock never trips validation
    model_config = {"arbitrary_types_allowed": True}
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_schema.py -v`
Expected: PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): project, converter, section/review proposals"`

---

## Task 3: Rubric + decisions

The newsletter's design knowledge and the surfaced design defaults.

**Files:**
- Create: `engine/newsletter/rubric.py`
- Create: `engine/newsletter/decide.py`
- Test: `tests/engine/test_newsletter_decide.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_decide.py
from engine.newsletter.rubric import newsletter_rubric
from engine.newsletter.decide import propose_newsletter_decisions, apply_newsletter_proposed
from engine.newsletter.schema import NewsletterProject


def test_rubric_has_checklist_and_palette():
    r = newsletter_rubric()
    assert r.checklist and r.palette_directions


def test_propose_always_surfaces_format_and_columns():
    decs = {d.key: d for d in propose_newsletter_decisions(newsletter_rubric())}
    assert decs["format"].value == "letter" and "a4" in decs["format"].options
    assert decs["columns"].value == "2" and "1" in decs["columns"].options
    assert decs["palette"].options and "model" in decs


def test_apply_overrides_format_and_columns():
    p = NewsletterProject()
    apply_newsletter_proposed(p, {"format": "a4", "columns": "1", "palette": "Trust-blue & clean"},
                              newsletter_rubric())
    assert p.format == "a4" and p.columns == 1 and p.palette == "Trust-blue & clean"
```

**Step 2: Run to verify it fails**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_decide.py -v`
Expected: FAIL — cannot import `newsletter_rubric`.

**Step 3: Implement**

`engine/newsletter/rubric.py`:

```python
from engine.rubrics import Rubric

NEWSLETTER_RUBRIC = Rubric(
    checklist=[
        "Masthead identity clear (org + issue)",
        "Lead story first — the most important / most human item",
        "Briefs glanceable, in scan order",
        "One clear primary action",
        "Footer with contact / give details",
    ],
    hierarchy=["masthead", "lead", "briefs", "events", "footer"],
    default_format_reason="US Letter prints and pins; reflows to email later.",
    recommendations=[
        "Lead with the single most important story.",
        "Keep each brief to a few lines; link out for detail.",
    ],
    palette_directions=["Warm & hopeful", "Earthy & grounded", "Trust-blue & clean"],
)


def newsletter_rubric() -> Rubric:
    return NEWSLETTER_RUBRIC
```

`engine/newsletter/decide.py`:

```python
from typing import List
from engine.decide import DecisionProposal
from engine.newsletter.schema import NewsletterProject

_FORMAT_OPTIONS = ["letter", "a4"]
_COLUMN_OPTIONS = ["1", "2"]
_STYLE_OPTIONS = ["modern_minimal", "corporate_professional", "elegant_luxury"]


def propose_newsletter_decisions(rubric) -> List[DecisionProposal]:
    directions = list(getattr(rubric, "palette_directions", []) or [])
    palette = directions[0] if directions else "Warm & hopeful"
    return [
        DecisionProposal("format", "Page format", "letter", _FORMAT_OPTIONS,
                         "prints + pins; reflows for email later"),
        DecisionProposal("columns", "Columns", "2", _COLUMN_OPTIONS,
                         "two columns scan well on Letter"),
        DecisionProposal("palette", "Color palette", palette, directions,
                         "from the newsletter's recommended directions"),
        DecisionProposal("visual_style", "Visual style", "modern_minimal", _STYLE_OPTIONS,
                         "readable, uncluttered default"),
        DecisionProposal("quality", "Quality", "hd", ["low", "medium", "high", "hd"], "print-ready"),
        DecisionProposal("model", "Model", "nano-banana-pro", ["nano-banana", "nano-banana-pro"],
                         "highest-fidelity image model"),
    ]


def apply_newsletter_proposed(project: NewsletterProject, decisions: dict, rubric=None) -> NewsletterProject:
    decisions = decisions or {}
    if decisions.get("format"):
        project.format = decisions["format"]
    if decisions.get("columns"):
        try:
            project.columns = int(decisions["columns"])
        except (TypeError, ValueError):
            pass
    if decisions.get("palette"):
        project.palette = decisions["palette"]
    if decisions.get("visual_style"):
        project.visual_style = decisions["visual_style"]
    if decisions.get("quality"):
        project.quality = decisions["quality"]
    if decisions.get("model"):
        project.model = decisions["model"]
    return project
```

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_decide.py -v`
Expected: PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): rubric + decision proposals"`

---

## Task 4: Gaps (light)

Ask only what can't be inferred (masthead identity / any items).

**Files:**
- Create: `engine/newsletter/gaps.py`
- Test: `tests/engine/test_newsletter_gaps.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_gaps.py
from engine.newsletter.gaps import build_newsletter_questions
from engine.newsletter.schema import NewsletterBrief, NewsletterItem


def test_complete_brief_no_questions():
    b = NewsletterBrief(org_name="Grace", items=[NewsletterItem(topic="camp")])
    assert build_newsletter_questions(b).questions == []


def test_missing_identity_asks():
    qs = build_newsletter_questions(NewsletterBrief(items=[NewsletterItem(topic="camp")]))
    assert any(q.field == "org_name" for q in qs.questions)
```

**Step 2: Run to verify it fails** — `cannot import build_newsletter_questions`.

**Step 3: Implement** — `engine/newsletter/gaps.py`:

```python
from engine.gaps import QuestionSet, Question
from engine.newsletter.schema import NewsletterBrief


def build_newsletter_questions(brief: NewsletterBrief, max_questions: int = 2) -> QuestionSet:
    qs = []
    if not (brief.org_name or brief.title):
        qs.append(Question("org_name", "Who's it from — your org or brand name?"))
    if not brief.items:
        qs.append(Question("items", "What's going in this issue? A few bullet points."))
    return QuestionSet(qs[:max_questions])
```

**Step 4: Run to verify it passes** — `.venv/bin/python -m pytest tests/engine/test_newsletter_gaps.py -v` → PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): adaptive gap questions"`

---

## Task 5: Extraction

Parse the brain-dump into a `NewsletterBrief` (one cheap Opus call).

**Files:**
- Create: `engine/newsletter/extract.py`
- Test: `tests/engine/test_newsletter_extract.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_extract.py
from unittest.mock import MagicMock
from engine.newsletter.extract import extract_newsletter, NEWSLETTER_SYSTEM
from engine.newsletter.schema import NewsletterBrief


def test_extract_newsletter_parses_with_shared_cached_system():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(parsed_output=NewsletterBrief(org_name="Grace"))
    out = extract_newsletter("June church newsletter — camp, new pastor, picnic", client=fake)
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["system"] is NEWSLETTER_SYSTEM                  # one stable cached block
    assert kwargs["output_format"] is NewsletterBrief
    assert kwargs.get("output_config", {}) != {"effort": "high"}  # extraction stays cheap
    assert out.org_name == "Grace"
```

**Step 2: Run to verify it fails** — `cannot import extract_newsletter`.

**Step 3: Implement** — `engine/newsletter/extract.py`:

```python
from engine.llm import MODEL, get_client
from engine.newsletter.schema import NewsletterBrief

# One stable, cached system block (shared by extraction + outline turns, like the flyer's EXTRACT_SYSTEM).
NEWSLETTER_SYSTEM = [{
    "type": "text",
    "text": (
        "You are a newsletter editor's intake assistant. From the user's plain-language brain-dump, "
        "extract a NewsletterBrief: the org/brand (org_name), a masthead title if stated or a fitting "
        "suggestion, an issue label (e.g. month/year), audience, purpose, and destination "
        "(print, email, or both). Break the contents into discrete `items` (each a topic with an "
        "optional note). In `field_sources`, map each masthead field you populate to \"stated\" "
        "(the user said it) or \"inferred\" (you deduced it). Leave unknowns null; do not invent."
    ),
    "cache_control": {"type": "ephemeral"},
}]


def extract_newsletter(text: str, client=None) -> NewsletterBrief:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL, max_tokens=1500, system=NEWSLETTER_SYSTEM,
        messages=[{"role": "user", "content": text}],
        output_format=NewsletterBrief,
    )
    return resp.parsed_output
```

**Step 4: Run to verify it passes** — PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): extraction + cached system block"`

---

## Task 6: Outline — the editor's eye

One Opus call (high effort + adaptive thinking) that orders + drafts sections and adds a missing footer, returning an `OutlinePlan`; helpers split it into the outline and the editorial `DesignBrief`.

**Files:**
- Create: `engine/newsletter/outline.py`
- Test: `tests/engine/test_newsletter_outline.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_outline.py
from unittest.mock import MagicMock
from engine.newsletter.outline import build_outline, outline_of, brief_of
from engine.newsletter.rubric import newsletter_rubric
from engine.newsletter.schema import NewsletterBrief, OutlinePlan, Masthead, Section
from engine.schema import DesignBrief


def _plan():
    return OutlinePlan(
        masthead=Masthead(title="The Messenger", org_name="Grace"),
        sections=[Section(key="lead", heading="Welcome Pastor Dale", kind="lead", order=1),
                  Section(key="foot", heading="Give & contact", kind="footer", origin="suggested", order=2)],
        notes="led with the human story; added a footer", checklist=["c"], recommendations=["r"])


def test_build_outline_high_effort_and_split_helpers():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(parsed_output=_plan())
    plan = build_outline(NewsletterBrief(org_name="Grace"), newsletter_rubric(), {}, client=fake)
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["output_config"] == {"effort": "high"}
    assert kwargs["thinking"] == {"type": "adaptive"}
    assert outline_of(plan).masthead.title == "The Messenger"
    assert [s.key for s in outline_of(plan).sections] == ["lead", "foot"]
    b = brief_of(plan)
    assert isinstance(b, DesignBrief) and b.notes.startswith("led with")
```

**Step 2: Run to verify it fails** — `cannot import build_outline`.

**Step 3: Implement** — `engine/newsletter/outline.py`:

```python
import json
from engine.llm import MODEL, get_client
from engine.schema import DesignBrief
from engine.newsletter.extract import NEWSLETTER_SYSTEM
from engine.newsletter.schema import OutlinePlan, NewsletterOutline


def _user_prompt(brief, rubric, answers) -> str:
    return (
        "Act as a newsletter editor. Structure this issue top-down (lead story first, briefs "
        "glanceable, one clear action), draft short copy for each section, and ADD a footer section "
        "(contact / give) if the brief doesn't already have one.\n\n"
        f"BRIEF (JSON): {brief.model_dump_json()}\n"
        f"CHECKLIST: {rubric.checklist}\nHIERARCHY: {rubric.hierarchy}\n"
        f"USER ANSWERS: {json.dumps(answers or {})}\n\n"
        "Return an OutlinePlan: masthead (title/org/issue); ordered sections (key, heading, a short "
        "body, kind in [lead|brief|events|footer], origin in [stated|suggested], order starting at 1); "
        "plus notes (rationale), checklist (applied to THIS issue), and >=1 recommendation."
    )


def build_outline(brief, rubric, answers=None, client=None) -> OutlinePlan:
    client = client or get_client()
    resp = client.messages.parse(
        model=MODEL, max_tokens=2500, system=NEWSLETTER_SYSTEM,
        messages=[{"role": "user", "content": _user_prompt(brief, rubric, answers or {})}],
        thinking={"type": "adaptive"}, output_config={"effort": "high"},
        output_format=OutlinePlan,
    )
    return resp.parsed_output


def outline_of(plan: OutlinePlan) -> NewsletterOutline:
    return NewsletterOutline(masthead=plan.masthead, sections=list(plan.sections))


def brief_of(plan: OutlinePlan) -> DesignBrief:
    return DesignBrief(notes=plan.notes, checklist=list(plan.checklist),
                       recommendations=list(plan.recommendations))
```

**Step 4: Run to verify it passes** — PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): outline turn + split helpers"`

---

## Task 7: Prompt builder

Compile a `NewsletterProject` into one render prompt package (engine-side; `prompt_builder.py` is off-limits).

**Files:**
- Create: `engine/newsletter/prompt.py`
- Test: `tests/engine/test_newsletter_prompt.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_prompt.py
from engine.newsletter.prompt import build_newsletter_prompt
from engine.newsletter.schema import NewsletterProject, Masthead, Section


def test_prompt_includes_masthead_sections_and_letter():
    p = NewsletterProject(masthead=Masthead(title="The Messenger", org_name="Grace"),
                          sections=[Section(key="lead", heading="Welcome", kind="lead", order=1, body="Hi"),
                                    Section(key="foot", heading="Contact", kind="footer", order=2)],
                          palette="Warm & hopeful")
    pkg = build_newsletter_prompt(p)
    assert "The Messenger" in pkg["main_prompt"]
    assert "Welcome" in pkg["main_prompt"] and "Contact" in pkg["main_prompt"]
    assert "two-column" in pkg["main_prompt"] and "LETTER" in pkg["main_prompt"].upper()
    assert pkg["aspect_ratio"] == "letter" and pkg["model"] == "nano-banana-pro"
    assert pkg["quality"] == "hd"
```

**Step 2: Run to verify it fails** — `cannot import build_newsletter_prompt`.

**Step 3: Implement** — `engine/newsletter/prompt.py`:

```python
def build_newsletter_prompt(project) -> dict:
    cols = "single-column" if project.columns == 1 else "two-column"
    lines = [f"Design a clean, print-ready {cols} US {project.format.upper()} newsletter page."]
    m = project.masthead
    head = f"Masthead: '{m.title}'"
    if m.org_name:
        head += f" — {m.org_name}"
    if m.issue_label:
        head += f" — {m.issue_label}"
    lines.append(head)
    for s in sorted(project.sections, key=lambda x: x.order):
        emph = {"lead": "LEAD STORY (largest)", "footer": "FOOTER (small, bottom)"}.get(s.kind, s.kind)
        lines.append(f"- [{emph}] {s.heading}: {(s.body or '').strip()}")
    if project.palette:
        lines.append(f"Palette direction: {project.palette}. Visual style: {project.visual_style}.")
    lines.append("Legible body text, clear hierarchy, generous margins, consistent fonts throughout.")
    return {
        "main_prompt": "\n".join(lines),
        "negative_prompt": "garbled text, unreadable text, lorem ipsum, clip art",
        "model": project.model,
        "aspect_ratio": project.format,      # 'letter' / 'a4' — supported by FlyerImageGenerator
        "quality": project.quality,
    }
```

**Step 4: Run to verify it passes** — PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): page prompt builder"`

---

## Task 8: Generation tools

Render one Letter page and section-scoped refine, reusing `FlyerImageGenerator` + `Concept`.

**Files:**
- Create: `engine/newsletter/tools.py`
- Test: `tests/engine/test_newsletter_tools.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_tools.py
from unittest.mock import MagicMock
from engine.newsletter.tools import generate_newsletter, refine_section
from engine.newsletter.schema import NewsletterProject, Section
from engine.tools import Concept


def _gen(success_b64="b64data"):
    g = MagicMock()
    g.generate.return_value = [MagicMock(success=True, image_base64=success_b64, error_message=None)]
    return g


def test_generate_newsletter_renders_letter_base64():
    g = _gen()
    out = generate_newsletter(NewsletterProject(sections=[Section(key="lead", heading="L", order=1)]),
                              generator=g, n=1)
    kwargs = g.generate.call_args.kwargs
    assert kwargs["aspect_ratio"] == "letter" and kwargs["save_images"] is False and kwargs["n"] == 1
    assert isinstance(out[0], Concept) and out[0].image_base64 == "b64data"


def test_refine_section_passes_prior_image_and_scopes():
    g = _gen()
    refine_section(NewsletterProject(), "/tmp/prev.png", "camp", "shorten to a link", generator=g)
    kwargs = g.generate.call_args.kwargs
    assert "/tmp/prev.png" in kwargs["input_images"]
    assert "camp" in kwargs["prompt"] and "shorten to a link" in kwargs["prompt"]
```

**Step 2: Run to verify it fails** — `cannot import generate_newsletter`.

**Step 3: Implement** — `engine/newsletter/tools.py`:

```python
from typing import List
from engine.tools import Concept, _to_concept
from engine.newsletter.prompt import build_newsletter_prompt


def generate_newsletter(project, generator, n: int = 1) -> List[Concept]:
    pkg = build_newsletter_prompt(project)
    results = generator.generate(
        prompt=pkg["main_prompt"], negative_prompt=pkg["negative_prompt"], model=pkg["model"],
        aspect_ratio=pkg["aspect_ratio"], quality=pkg["quality"], n=n, save_images=False,
    )
    return [_to_concept(r, "page" if n == 1 else f"page-{i+1}") for i, r in enumerate(results)]


def refine_section(project, prior_image_path, section_key, instruction, generator) -> Concept:
    pkg = build_newsletter_prompt(project)
    prompt = (
        f"{pkg['main_prompt']}\n\nEDIT MODE: change ONLY the '{section_key}' section as follows: "
        f"{instruction}. Preserve every other section exactly as it appears in the provided image."
    )
    results = generator.generate(
        prompt=prompt, negative_prompt=pkg["negative_prompt"], model=pkg["model"],
        aspect_ratio=pkg["aspect_ratio"], quality=pkg["quality"], n=1, save_images=False,
        input_images=[prior_image_path],
    )
    return _to_concept(results[0], "refined")
```

**Step 4: Run to verify it passes** — PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): render + section refine tools"`

---

## Task 9: Orchestrator — describe → outline + review (gated)

**Files:**
- Create: `engine/newsletter/orchestrator.py`
- Test: `tests/engine/test_newsletter_orchestrator.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_orchestrator.py
from unittest.mock import MagicMock
from engine.gaps import QuestionSet, Question
from engine.newsletter.orchestrator import NewsletterEngine
from engine.newsletter.schema import NewsletterBrief, NewsletterItem, OutlinePlan, Masthead, Section

OUTLINE = OutlinePlan(masthead=Masthead(title="The Messenger"),
                      sections=[Section(key="lead", heading="Welcome", kind="lead", order=1),
                                Section(key="foot", heading="Footer", kind="footer", origin="suggested", order=2)],
                      notes="n", checklist=["c"], recommendations=["r"])


def _engine_with(brief, questions, **deps):
    deps.setdefault("extract", lambda text, client=None: brief)
    deps.setdefault("build_questions", lambda b, **k: questions)
    deps.setdefault("build_outline", lambda b, r, answers=None, client=None: OUTLINE)
    return NewsletterEngine(client=MagicMock(), **deps)


def test_describe_reaches_review_not_page():
    eng = _engine_with(NewsletterBrief(org_name="Grace", items=[NewsletterItem(topic="camp")]), QuestionSet([]))
    kinds = [e.kind for e in eng.handle_user_message("...")]
    assert "parsed_items" in kinds and "outline" in kinds and "review" in kinds
    assert "page" not in kinds


def test_review_payload_has_sections_decisions_plan():
    eng = _engine_with(NewsletterBrief(org_name="Grace", items=[NewsletterItem(topic="camp")]), QuestionSet([]))
    review = next(e.payload for e in eng.handle_user_message("...") if e.kind == "review")
    assert any(s.key == "lead" for s in review.sections)
    assert any(d.key == "format" for d in review.decisions)
    assert review.plan is not None


def test_missing_identity_gates_with_questions():
    eng = _engine_with(NewsletterBrief(items=[]), QuestionSet([Question("org_name", "Who from?")]))
    kinds = [e.kind for e in eng.handle_user_message("...")]
    assert "questions" in kinds and "review" not in kinds
```

**Step 2: Run to verify it fails** — `cannot import NewsletterEngine`.

**Step 3: Implement** — `engine/newsletter/orchestrator.py`:

```python
from typing import Any, Iterator
from engine.orchestrator import Event, _resolved_image
from engine.newsletter import (
    extract as _extract, outline as _outline, decide as _decide,
    rubric as _rubric, gaps as _gaps, tools as _tools, schema as _schema,
)


class NewsletterEngine:
    def __init__(self, client, generator=None, extract=None, build_outline=None,
                 rubric=None, build_questions=None, generate=None, refine=None):
        self.client = client
        self._extract = extract or _extract.extract_newsletter
        self._build_outline = build_outline or _outline.build_outline
        self._rubric = rubric or _rubric.newsletter_rubric
        self._build_questions = build_questions or _gaps.build_newsletter_questions
        self._generator = generator
        self._generate = generate
        self._refine = refine
        self.brief = None
        self.outline = None
        self.project = None
        self.answers = {}
        self.rubric_obj = None

    def handle_user_message(self, text) -> Iterator[Event]:
        try:
            self.brief = self._extract(text, client=self.client)
        except Exception as e:                       # pragma: no cover - defensive
            yield Event("error", str(e)); return
        yield Event("parsed_items", self.brief)
        qs = self._build_questions(self.brief)
        if qs.questions:
            yield Event("questions", qs); return       # gate: wait for answers
        yield from self._plan_and_await()

    def handle_answers(self, answers) -> Iterator[Event]:
        answers = answers or {}
        self.answers = {**self.answers, **answers}
        if self.brief is not None:
            for k, v in answers.items():
                if v and hasattr(self.brief, k):
                    setattr(self.brief, k, v)
        yield Event("parsed_items", self.brief)
        qs = self._build_questions(self.brief)
        if qs.questions:
            yield Event("questions", qs); return
        yield from self._plan_and_await()

    def _plan_and_await(self) -> Iterator[Event]:
        self.rubric_obj = self._rubric()
        plan = self._build_outline(self.brief, self.rubric_obj, answers=self.answers, client=self.client)
        self.outline = _outline.outline_of(plan)
        yield Event("outline", self.outline)           # full structure (client holds it for approve)
        proposal = _schema.NewsletterReviewProposal(
            masthead=self.outline.masthead,
            sections=_schema.build_section_proposals(self.outline),
            decisions=_decide.propose_newsletter_decisions(self.rubric_obj),
            plan=_outline.brief_of(plan),
        )
        yield Event("review", proposal)                # gate: no blind jump to render
```

**Step 4: Run to verify it passes** — `.venv/bin/python -m pytest tests/engine/test_newsletter_orchestrator.py -v` → PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): orchestrator describe -> review gate"`

---

## Task 10: Orchestrator — approval (overrides → render) + section refine

**Files:**
- Modify: `engine/newsletter/orchestrator.py`
- Test: `tests/engine/test_newsletter_orchestrator.py`

**Step 1: Write the failing test** (append)

```python
from engine.tools import Concept
from engine.newsletter.schema import NewsletterOutline


def test_approval_renders_only_after_approve_with_overrides():
    captured = {}
    def fake_generate(project, generator=None, n=1):
        captured["format"] = project.format
        captured["columns"] = project.columns
        captured["sections"] = [s.key for s in project.sections]
        return [Concept("page", "b64")]
    eng = NewsletterEngine(client=MagicMock(), generate=fake_generate, generator=MagicMock())
    eng.brief = NewsletterBrief(org_name="Grace")
    eng.outline = NewsletterOutline(masthead=Masthead(title="X"), sections=[
        Section(key="lead", heading="L", kind="lead", order=1),
        Section(key="foot", heading="F", kind="footer", order=2)])
    events = list(eng.handle_approval(section_overrides={"drop": ["foot"]},
                                      decision_overrides={"format": "a4", "columns": "1"}))
    assert "page" in [e.kind for e in events]
    assert captured["format"] == "a4" and captured["columns"] == 1
    assert "foot" not in captured["sections"]


def test_render_gated_until_approval():
    gen = MagicMock()
    eng = _engine_with(NewsletterBrief(org_name="Grace", items=[NewsletterItem(topic="x")]),
                       QuestionSet([]), generate=gen)
    list(eng.handle_user_message("..."))               # describe flow only
    assert not gen.called


def test_refine_section_uses_prior_image():
    rmock = MagicMock(return_value=Concept("refined", "b64"))
    eng = NewsletterEngine(client=MagicMock(), refine=rmock, generator=MagicMock())
    eng.brief = NewsletterBrief()
    eng.outline = NewsletterOutline(sections=[Section(key="lead", heading="L", order=1)])
    events = list(eng.handle_refine(section_key="lead", instruction="shorten", prior_image_path="/tmp/p.png"))
    assert any(e.kind == "refined" for e in events) and rmock.called
    assert "/tmp/p.png" in rmock.call_args.args
```

**Step 2: Run to verify it fails** — `handle_approval` not defined.

**Step 3: Implement** (append methods to `NewsletterEngine`)

```python
    def handle_approval(self, section_overrides=None, decision_overrides=None,
                        answers=None) -> Iterator[Event]:
        if self.outline is None:
            yield Event("error", "no outline to render from"); return
        self._apply_section_overrides(section_overrides or {})
        self.answers = {**self.answers, **(answers or {})}
        self.rubric_obj = self.rubric_obj or self._rubric()
        project = _schema.to_newsletter_project(self.brief, self.outline)
        project = _decide.apply_newsletter_proposed(project, decision_overrides or {}, self.rubric_obj)
        self.project = project
        generate = self._generate or _tools.generate_newsletter
        page = generate(project, generator=self._generator, n=1)
        yield Event("page", page)

    def _apply_section_overrides(self, ov: dict) -> None:
        """ov: {'order': [keys...], 'drop': [keys...], 'headings': {key: new_heading}}."""
        if not ov:
            return
        secs = {s.key: s for s in self.outline.sections}
        for key, heading in (ov.get("headings") or {}).items():
            if key in secs:
                secs[key].heading = heading
        for key in (ov.get("drop") or []):
            secs.pop(key, None)
        order = ov.get("order")
        if order:
            kept = [secs[k] for k in order if k in secs]
            for i, s in enumerate(kept):
                s.order = i + 1
            self.outline.sections = kept
        else:
            self.outline.sections = list(secs.values())

    def handle_refine(self, section_key="", instruction="", prior_image_path=None,
                      prior_image_b64=None) -> Iterator[Event]:
        project = self.project or (
            _schema.to_newsletter_project(self.brief, self.outline) if self.outline else None)
        if project is None:
            yield Event("error", "no project to refine"); return
        refine = self._refine or _tools.refine_section
        with _resolved_image(prior_image_path, prior_image_b64) as path:
            if path is None:
                yield Event("error", "no prior image to refine"); return
            concept = refine(project, path, section_key, instruction, generator=self._generator)
        yield Event("refined", concept)
```

**Step 4: Run to verify it passes** — `.venv/bin/python -m pytest tests/engine/test_newsletter_orchestrator.py -v` → PASS

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): approval overrides + section refine"`

---

## Task 11: `/chat` — route `kind=newsletter` + state round-trip

The server is stateless per request; the client sends back `brief` and `outline` (like the flyer sends `brief`).

**Files:**
- Modify: `engine/app.py` (`ChatIn`, `run_turn`)
- Test: `tests/engine/test_newsletter_app.py`

**Step 1: Write the failing test**

```python
# tests/engine/test_newsletter_app.py
import json
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from engine.app import app
from engine.orchestrator import Event


def test_newsletter_review_serializes_sections_and_decisions():
    from engine.newsletter.schema import NewsletterReviewProposal, SectionProposal
    from engine.decide import DecisionProposal
    proposal = NewsletterReviewProposal(
        sections=[SectionProposal(key="lead", heading="Welcome", kind="lead", origin="stated", order=1)],
        decisions=[DecisionProposal("format", "Page format", "letter", ["letter", "a4"], "x")],
        plan=None)
    with patch("engine.app.run_turn", return_value=iter([Event("review", proposal)])):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"kind": "newsletter", "message": "x"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: review" in body
    data = json.loads([l for l in body.splitlines() if l.startswith("data: ")][0][6:])
    assert data["sections"][0]["key"] == "lead" and data["decisions"][0]["key"] == "format"


def test_newsletter_kind_routes_to_newsletter_engine():
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.newsletter.orchestrator.NewsletterEngine.handle_user_message",
               return_value=iter([Event("parsed_items", {"org_name": "Grace"})])) as h:
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"kind": "newsletter", "message": "june issue"}) as r:
            out = "".join(chunk for chunk in r.iter_text())
    assert "event: parsed_items" in out and h.called
```

**Step 2: Run to verify it fails** — newsletter not routed (`run_turn` builds the flyer `Engine`).

**Step 3: Implement** in `engine/app.py`:

Add to `ChatIn`:

```python
    kind: Optional[str] = "flyer"            # flyer | newsletter
    outline: Optional[dict] = None           # accumulated NewsletterOutline (state in/out)
    section_overrides: Optional[dict] = None
    section_key: Optional[str] = None
```

In `run_turn`, branch on `kind` **before** the flyer logic:

```python
def run_turn(body: ChatIn):
    kind = (body.kind or "flyer").lower()
    action = (body.action or "describe").lower()
    needs_gen = action in ("approve", "refine", "resize")

    if kind == "newsletter":
        from engine.newsletter.orchestrator import NewsletterEngine
        from engine.newsletter.schema import NewsletterBrief, NewsletterOutline
        eng = NewsletterEngine(client=get_client(),
                               generator=get_generator() if needs_gen else None)
        if body.brief:
            eng.brief = NewsletterBrief(**body.brief)
        if body.outline:
            eng.outline = NewsletterOutline(**body.outline)
        if action == "answers":
            return eng.handle_answers(body.answers or {})
        if action == "approve":
            return eng.handle_approval(section_overrides=body.section_overrides,
                                       decision_overrides=body.decision_overrides,
                                       answers=body.answers or {})
        if action == "refine":
            return eng.handle_refine(section_key=body.section_key or "",
                                     instruction=body.instruction or "",
                                     prior_image_path=body.prior_image_path,
                                     prior_image_b64=body.prior_image_b64)
        return eng.handle_user_message(body.message or "")

    # ---- existing flyer routing below, unchanged ----
    eng = Engine(client=get_client(), generator=get_generator() if needs_gen else None)
    ...
```

> The `_sse` / `_to_jsonable` serializer is unchanged — it already handles the pydantic `NewsletterReviewProposal`/`SectionProposal` and the dataclass `DecisionProposal`/`Concept`.

**Step 4: Run to verify it passes**

Run: `.venv/bin/python -m pytest tests/engine/test_newsletter_app.py tests/engine/test_app.py -v`
Expected: PASS (newsletter routes; existing flyer app tests still green).

**Step 5: Commit (optional)** — `git commit -m "feat(newsletter): /chat kind routing + outline round-trip"`

---

## Task 12: Full suite + manual smoke

**Step 1:** `.venv/bin/python -m pytest tests/engine -v` — all green (flyer 46 + the new newsletter tests).

**Step 2 (optional, real API):** with `OPENROUTER_API_KEY` loaded, start the server and run a newsletter turn:

```bash
.venv/bin/python -m uvicorn engine.app:app --port 8000   # terminal A
# terminal B:
curl -N -s -X POST http://127.0.0.1:8000/chat -H 'Content-Type: application/json' \
  -d '{"kind":"newsletter","message":"June church newsletter — summer camp signups, welcome our new pastor, garden volunteers needed, parish picnic on the 28th"}'
```
Expected: `parsed_items → outline → review` (sections + `format`/`columns`/`palette` decisions + editorial plan; never a silent jump to `page`). Then `approve` (sending back `brief` + `outline`) renders one Letter page as base64.

---

## Done criteria

- `.venv/bin/python -m pytest tests/engine -v` is green.
- `kind=newsletter` flows `describe → parsed_items → (questions?) → outline → review`; **render only on `approve`** (no path straight to `page`).
- The `review` surfaces sections (tagged stated/suggested) **and** every design default (format, columns, palette, style, quality, model) with reasons — no silent defaults.
- `handle_approval` applies `section_overrides` + `decision_overrides` before rendering; `/chat` round-trips `brief` + `outline`.
- Rendering reuses `FlyerImageGenerator` at `aspect_ratio="letter"`, base64 only (no disk).
- No changes to `models.py` / `prompt_builder.py` / `image_generator.py`.
- Export / recurrence / multi-page remain out of scope (client/later).
