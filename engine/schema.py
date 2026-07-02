from typing import Optional, List, Dict, Any
from pydantic import BaseModel, field_validator
from facts import dedup_facts


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
    additional_info: Optional[List[str]] = None  # answers with no dedicated slot land here
    purpose: Optional[str] = None  # free-text intent, used by rubric reasoning
    destination: Optional[str] = None          # channel/medium hint, when the user states one
    aspect_ratio: Optional[str] = None         # the size the user picked early (e.g. "9:16")
    field_sources: Dict[str, str] = {}         # field name -> "stated" | "inferred"

    @field_validator("category", mode="before")
    @classmethod
    def _coerce_null_category(cls, v):
        # The model may return null category for ultra-vague briefs; fall back to the default.
        return v or "announcement"

    @field_validator("additional_info", mode="before")
    @classmethod
    def _coerce_additional_info(cls, v):
        # Shared normalizer (facts.dedup_facts): coerce a bare string to a list, drop blanks, and
        # dedup. NOTE: ExtractedBrief is a wire-shape reference and is NOT on the live turn path
        # (interpret() uses TurnResult) - routed through the same helper so the two never drift.
        return dedup_facts(v)

    @field_validator("field_sources", mode="before")
    @classmethod
    def _clean_field_sources(cls, v):
        # The model is told to "use null for any value you cannot infer" and applies that
        # inside field_sources too (mapping un-populated fields to null, or emitting the
        # whole map as null). Drop the nulls instead of rejecting them - absent keys are
        # treated as "inferred" by downstream callers; a null source carries no information.
        if not isinstance(v, dict):
            return {}
        return {k: val for k, val in v.items() if isinstance(val, str)}


class FieldProposal(BaseModel):
    key: str
    value: str
    source: str            # stated | inferred
    warning: Optional[str] = None   # set when the value needs the user's attention (e.g. a
                                     # website that isn't a well-formed URL) - the review highlights it


class DesignQuestion(BaseModel):
    """A generation-blocking gap the design pass wants resolved before designing."""
    field: Optional[str] = None
    text: Optional[str] = None


class DesignBrief(BaseModel):
    """The 'plans like a pro' turn: the rubric applied to the specific brief."""
    notes: str = ""                       # short design rationale
    checklist: List[str] = []             # rubric applied concretely to this brief
    recommendations: List[str] = []       # >=1 proactive, specific suggestion
    questions: List[DesignQuestion] = []  # must-fix clarifications to ask before designing
    # The pass's brief-specific aesthetic picks (chosen from the offered options). These
    # pre-select the review's palette/style/mood controls so the proposals match the
    # rationale instead of blind category/hard-coded defaults. Still user-approvable.
    recommended_palette: Optional[str] = None
    recommended_style: Optional[str] = None
    recommended_mood: Optional[str] = None

    @field_validator("questions", mode="before")
    @classmethod
    def _drop_null_questions(cls, v):
        if not isinstance(v, list):
            return []
        return [x for x in v if isinstance(x, (dict, DesignQuestion))]

    @field_validator("notes", mode="before")
    @classmethod
    def _notes_null_to_empty(cls, v):
        # the model is told to "use null for any value you cannot infer"
        return v if isinstance(v, str) else ""

    @field_validator("checklist", "recommendations", mode="before")
    @classmethod
    def _list_null_to_empty(cls, v):
        # tolerate a null list, or null items inside an otherwise-populated list
        if not isinstance(v, list):
            return []
        return [x for x in v if isinstance(x, str)]


class CreativeProposal(BaseModel):
    what: str
    why: str = ""
    sensitivity: str = "safe"
    selected: bool = True          # safe -> pre-selected; sensitive -> False


class ReviewProposal(BaseModel):
    """The engine's complete interpretation, surfaced for one consolidated human approval."""
    fields: List[FieldProposal] = []
    decisions: list = []          # list[DecisionProposal] (dataclass) - kept loosely typed
    creative_elements: List[CreativeProposal] = []
    plan: Optional[Any] = None    # DesignBrief in production; loosely typed so it never
                                  # rejects (e.g. a mocked brief in tests)

    model_config = {"arbitrary_types_allowed": True}
