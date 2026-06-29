import json
from dataclasses import dataclass, field
from typing import List, Optional
from pydantic import BaseModel, field_validator
from models import CATEGORY_TEXT_FIELDS, FlyerCategory
from engine.schema import ExtractedBrief
from engine.answers import MERGEABLE_FIELDS
from engine.config import MODEL, THINKING, EFFORT, MAX_TOKENS

# A small per-category set of fields that materially change the design if absent.
# (Subset of CATEGORY_TEXT_FIELDS — the "must-haves", curated.) These form the
# deterministic floor: always asked, never dropped.
CRITICAL_FIELDS = {
    FlyerCategory.EVENT: ["date", "venue_name", "cta_text"],
    FlyerCategory.NONPROFIT_CHARITY: ["cta_text"],
    FlyerCategory.SALE_PROMO: ["discount_text", "cta_text"],
    # ... extend per category; fall back to first 3 of CATEGORY_TEXT_FIELDS otherwise
}

# Static fallback wording — used only when no client is available or the model doesn't
# return a question for a floor field. The primary path phrases these per-brief via the LLM.
QUESTION_TEXT = {
    "date": "What day is it on?",
    "time": "What time does it start (and end)?",
    "venue_name": "Where's it being held?",
    "cta_text": "What's the one thing you want people to do — RSVP, buy, call, or visit? "
                "Add a link or number if you have one.",
    "discount_text": "What's the offer exactly? (e.g. \"40% off\" or \"buy one get one free\")",
    "destination": "Where will this mostly go — Instagram, a printed flyer, or both?",
}

# What each floor field means, handed to the model so its questions are accurate.
_FIELD_MEANINGS = {
    "date": "the date it takes place",
    "time": "the start (and end) time",
    "venue_name": "the venue or place name",
    "address": "the street address",
    "cta_text": "the call to action — what people should do and how (RSVP, buy, call, visit a link)",
    "discount_text": "the offer or discount",
    "price": "the price, or whether it's free",
    "phone": "a contact phone number",
    "email": "a contact email",
    "website": "the website or link to share",
    "destination": "where the flyer will mostly be shared (Instagram, printed, etc.)",
}

QUESTION_SYSTEM = (
    "You are a warm, friendly graphic designer chatting with a customer about the flyer they "
    "want. You ask short, natural questions the way a helpful human would — referencing what "
    "they already told you and specific to THIS flyer, never generic or robotic. You also "
    "judge WHICH questions are worth asking: ask only what genuinely improves the design, and "
    "if nothing beyond the essentials is needed, add nothing. Keep each question to one sentence, "
    "phrased as a genuine question ending in a single question mark — never a statement with a "
    "question mark tacked on the end."
)


@dataclass
class Question:
    field: str
    text: str
    options: Optional[List[dict]] = None   # when set, rendered as a labeled picker (e.g. size)


@dataclass
class QuestionSet:
    questions: List[Question] = field(default_factory=list)
    stage: str = "gaps"   # "gaps" (up-front intake) | "design" (must-fixes after the design brief)


def _default_text(f: str) -> str:
    return QUESTION_TEXT.get(f, f"What's the {f.replace('_', ' ')}?")


# --- LLM question selection + phrasing (primary path; degrades to the static floor) ---

class _GenQ(BaseModel):
    field: Optional[str] = None
    text: Optional[str] = None


class _GenQuestions(BaseModel):
    questions: List[_GenQ] = []

    @field_validator("questions", mode="before")
    @classmethod
    def _drop_non_objects(cls, v):
        # tolerate the model emitting null, or null items inside the list
        if not isinstance(v, list):
            return []
        return [x for x in v if isinstance(x, dict)]


def _question_prompt(brief: ExtractedBrief, floor: List[str], max_questions: int, clarify: bool) -> str:
    known = {k: v for k, v in brief.model_dump().items() if v and k != "field_sources"}
    if floor:
        required = "\n".join(f"- {f}: {_FIELD_MEANINGS.get(f, f.replace('_', ' '))}" for f in floor)
        req_block = f"You MUST ask about these missing essentials (use these exact field keys):\n{required}\n\n"
    else:
        req_block = "There are no required missing fields.\n\n"
    if clarify:
        reuse = ", ".join(sorted(MERGEABLE_FIELDS))
        add_block = (
            "Then, as a senior designer, you MAY add a few more clarifying questions that would "
            "materially sharpen THIS flyer — e.g. a sale's end date for urgency, a way to redeem "
            "(address or link), or a key missing specific. Only add ones the customer likely knows "
            "and that change the design; if nothing else is needed, add none. Don't repeat fields "
            "already provided. REUSE one of these existing field keys whenever it fits, so the "
            f"answer maps to the right slot: {reuse}. Only invent a new short snake_case key "
            "(e.g. sale_end_date) when none of those fit. Ask for the VALUE itself (e.g. "
            "\"What's the starting wage, if you'd like to show one?\"), never as a yes/no like "
            "\"Do you want to include a wage?\" — a yes/no answer leaves nothing to print.\n\n"
        )
    else:
        add_block = "Do not add any other questions beyond those essentials.\n\n"
    return (
        f"The flyer so far (JSON): {json.dumps(known)}\n\n"
        f"{req_block}{add_block}"
        f"Return at most {max_questions} questions total, most important first, as JSON "
        '{"questions": [{"field": "<key>", "text": "<one friendly sentence>"}]}.'
    )


def _select_questions(brief, floor, client, max_questions, clarify):
    """Model-selected + phrased questions as ordered [(field, text)]. Returns None on no
    client / model error / malformed output, signalling the caller to use the static floor."""
    if not client:
        return None
    try:
        resp = client.messages.parse(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            system=QUESTION_SYSTEM,
            messages=[{"role": "user", "content": _question_prompt(brief, floor, max_questions, clarify)}],
            thinking=THINKING,
            output_config=EFFORT,
            output_format=_GenQuestions,
        )
        items = []
        for q in (resp.parsed_output.questions or []):
            f = (q.field or "").strip()
            t = (q.text or "").strip()
            if f and t:
                items.append((f, t))
        return items
    except Exception:
        return None


def _merge(floor, selected, brief, max_questions, clarify):
    """Combine the guaranteed floor (model-phrased or static) with model clarifications.
    Floor is always present and ordered first; additions follow only when clarify=True."""
    if selected is None:
        return [(f, _default_text(f)) for f in floor][:max_questions]
    by, order = {}, []
    for f, t in selected:
        if f not in by:
            by[f] = t
            order.append(f)
    out = [(f, by.get(f) or _default_text(f)) for f in floor]   # floor guaranteed
    if clarify:
        floor_set = set(floor)
        for f in order:
            if f not in floor_set and not getattr(brief, f, None):
                out.append((f, by[f]))
    return out[:max_questions]


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


def build_questions(brief: ExtractedBrief, client=None, max_questions: int = 3,
                    clarify: bool = True) -> QuestionSet:
    """Decide what to ask and phrase it like a human designer.

    The deterministic floor (missing critical fields) is always asked. With a `client` and
    `clarify=True` (the describe turn), the model phrases the floor AND may add a few sharp,
    brief-specific clarifications (capped at `max_questions`, floor prioritised). With
    `clarify=False` (a follow-up turn) it only insists on the remaining floor — never piling
    on new questions, so the conversation can't loop. Any model failure degrades to the
    static floor. The `field` key is always machine-readable so answers map back."""
    floor = missing_critical_fields(brief)[:max_questions]
    if not clarify and not floor:
        return QuestionSet([])                       # follow-up with nothing required: proceed
    selected = _select_questions(brief, floor, client, max_questions, clarify)
    chosen = _merge(floor, selected, brief, max_questions, clarify)
    return QuestionSet([Question(f, t) for f, t in chosen])
