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
