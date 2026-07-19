"""Project a TurnResult onto the frozen wire payloads (review / parsed_fields / questions)."""
from engine.turn import TurnResult
from engine.schema import FieldProposal, DesignBrief, ReviewProposal, CreativeProposal
from engine.gaps_compat import QuestionSet, Question
from models import FlyerCategory, AspectRatio, VisualStyle, Mood

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
          "social_handle", "additional_info", "purpose"]}
    d["field_sources"] = turn.field_sources
    d["photo_suggestion"] = turn.photo_suggestion   # dropped by the null-filter below when unset
    return {k: v for k, v in d.items() if v is not None}


def to_question_set(turn: TurnResult) -> QuestionSet:
    # The `qr` question is surfaced separately as a tappable QR offer (see orchestrator._qr_offer),
    # so keep it out of the generic must-answer questions card.
    return QuestionSet(questions=[Question(field=q.field, text=q.text)
                                  for q in turn.questions if q.field != "qr"],
                       stage="gaps")


_OPTION_ENUM = {"format": AspectRatio, "visual_style": VisualStyle, "mood": Mood}


def _category_display(value) -> str:
    """The category's human label for the review (raw token stays in to_brief_dict)."""
    try:
        return FlyerCategory(value).display_name
    except (ValueError, TypeError):
        return str(value)


def _option_label(key, opt) -> str:
    """Human label for a decision option chip; falls back to the raw option for
    palette/quality and any off-vocabulary value."""
    enum_cls = _OPTION_ENUM.get(key)
    if enum_cls:
        for m in enum_cls:
            if opt in (m.value, m.display_name):
                return m.display_name
    return str(opt)


def assemble_review(turn: TurnResult) -> ReviewProposal:
    fields = []
    for key in REVIEW_FIELDS:
        value = getattr(turn, key, None)
        if value:
            display = _category_display(value) if key == "category" else str(value)
            fields.append(FieldProposal(key=key, value=display,
                                        source=turn.field_sources.get(key, "inferred"),
                                        warning=turn.warnings.get(key)))
    decisions = [{"key": d.key, "label": _DECISION_LABELS.get(d.key, d.key),
                  "value": d.value, "options": d.options,
                  "option_labels": {o: _option_label(d.key, o) for o in d.options},
                  "reason": d.reason, "supported": d.supported} for d in turn.decisions]
    elements = [CreativeProposal(what=e.what, why=e.why, sensitivity=e.sensitivity,
                                 selected=(e.sensitivity == "safe")) for e in turn.creative_elements]
    plan = DesignBrief(notes=turn.notes, checklist=turn.checklist, recommendations=turn.recommendations)
    return ReviewProposal(fields=fields, decisions=decisions, creative_elements=elements, plan=plan)
