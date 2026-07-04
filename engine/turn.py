"""The one object the brain returns each turn, plus the only deterministic gate."""
from typing import Dict, List, Optional
from pydantic import BaseModel, field_validator, model_validator
from models import AspectRatio, VisualStyle, Mood
from facts import dedup_facts, without_represented

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
    photo_suggestion: Optional[str] = None    # nudge naming a subject worth photographing, or null
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

    @field_validator("additional_info", mode="before")
    @classmethod
    def _dedup_additional_info(cls, v):
        # Coerce (bare string -> list; non-list -> None) and dedup within the list via the shared
        # normalizer (case, all whitespace incl. nbsp, surrounding punctuation). The prior brief
        # round-trips every turn ("update it"), so the model re-emits these; normalized dedup keeps
        # drifting punctuation/case variants from re-accumulating. Cross-field reconciliation -
        # dropping an extra that echoes a dedicated field - happens in the model validator below.
        return dedup_facts(v)

    @model_validator(mode="after")
    def _drop_facts_already_in_fields(self):
        # additional_info is the catch-all for facts with NO dedicated field. Drop any extra that
        # (normalized) matches a populated content field, so a fact never renders both in its own
        # field and as an extra - on the "what I got" card, the review, and the flyer. body_text
        # (free prose) is intentionally excluded; the prompt keeps it from restating fields.
        if self.additional_info:
            fields = [getattr(self, f) for f in BRIEF_FIELDS if f not in ("category", "body_text")]
            self.additional_info = without_represented(self.additional_info, fields)
        return self


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
