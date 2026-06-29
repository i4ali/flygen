import re

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, field_validator
from models import (
    FlyerProject, FlyerCategory, TextContent, OutputSettings, AspectRatio,
)


# Meta/non-answers that carry no renderable content. A user replying "No"/"Yes"/"idk" to an
# optional question must not have it printed as a literal field value ("PRICE: No"). Real
# values like "Free", "Unpaid", or "TBD" are intentionally NOT matched.
_NON_VALUE = {
    # bare declines
    "no", "none", "na", "notapplicable", "nope", "nothanks", "nothankyou",
    "skip", "nothing", "-", "--", "—",
    # bare affirmations (a "yes" with no actual value attached)
    "yes", "yeah", "yep", "yup", "sure", "ok", "okay",
    # "I don't know" / "you decide" non-answers
    "idk", "dunno", "dontknow", "idontknow", "notsure", "unsure",
    "youdecide", "yourchoice", "yourcall", "uptoyou", "whatever",
    "doesntmatter", "dontcare", "idontcare", "anything", "any",
}


def is_non_value(value) -> bool:
    """True for a meta/non-answer ('No', 'Yes', 'idk', 'you decide', ...) that has no
    renderable content. Used to keep such answers off the flyer and out of review."""
    norm = re.sub(r"[.\s/'’]", "", str(value or "").strip().lower())
    return norm in _NON_VALUE


# A website is accepted at face value as long as it's WELL-FORMED (scheme/www optional, one+
# dot-separated labels, an alpha TLD, optional port/path/query). We deliberately do NOT judge
# whether the domain "matches" the business — a 3rd-party link (e.g. ticketmaster.com) is the
# user's prerogative. This only keeps non-URLs ('ask in store', 'idk') from rendering as a site.
_WEBSITE_RE = re.compile(
    r"^(?:https?://)?(?:www\.)?"
    r"(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+"   # one or more domain labels
    r"[a-z]{2,24}"                                    # alpha TLD
    r"(?:[:/?#]\S*)?$",                               # optional port/path/query/fragment
    re.IGNORECASE,
)


def is_valid_website(value) -> bool:
    """True when `value` is a well-formed web address (format only — any domain is accepted)."""
    return bool(_WEBSITE_RE.match(str(value or "").strip()))


# A contact answer often comes back tagged with the wrong channel: a question that offers
# "website, phone, or email" binds to ONE field key, so a phone the user typed can land under
# `website`. These two recognise an UNAMBIGUOUS phone/email so the answer can be routed to its
# real slot (see engine/answers._route_contact). Kept strict — whole-string matches only — so a
# real, if malformed, website ('Ticketmaster') is never mistaken for a phone/email.
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[a-z]{2,}$", re.IGNORECASE)
_PHONE_CHARS_RE = re.compile(r"^\+?[\d\s().\-]+$")


def looks_like_email(value) -> bool:
    """True for a bare, well-formed email address (no surrounding words)."""
    return bool(_EMAIL_RE.match(str(value or "").strip()))


def looks_like_phone(value) -> bool:
    """True for a bare phone number — only phone characters and 7–15 digits. Excludes URLs (have
    letters) and prices (too few digits / a '$'), so it never collides with website/email."""
    s = str(value or "").strip()
    if not s or not _PHONE_CHARS_RE.match(s):
        return False
    return 7 <= len(re.sub(r"\D", "", s)) <= 15


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
        # The model may return null category for ultra-vague briefs; fall back to the
        # default (to_flyer_project already maps unknown categories to ANNOUNCEMENT).
        return v or "announcement"

    @field_validator("additional_info", mode="before")
    @classmethod
    def _coerce_additional_info(cls, v):
        # The model sometimes returns additional_info as a bare string ("Featuring lots of local
        # vendors") instead of a list. Coerce a string to a single-item list, drop null/empty
        # items from a list, and never reject — a list_type error here crashed the whole turn.
        if v is None:
            return None
        if isinstance(v, str):
            v = v.strip()
            return [v] if v else None
        if isinstance(v, list):
            items = [s.strip() for s in v if isinstance(s, str) and s.strip()]
            return items or None
        return None

    @field_validator("field_sources", mode="before")
    @classmethod
    def _clean_field_sources(cls, v):
        # The model is told to "use null for any value you cannot infer" and applies that
        # inside field_sources too (mapping un-populated fields to null, or emitting the
        # whole map as null). Drop the nulls instead of rejecting them — absent keys fall
        # back to "inferred" via field_source(); a null source carries no information.
        if not isinstance(v, dict):
            return {}
        return {k: val for k, val in v.items() if isinstance(val, str)}


def field_source(brief: "ExtractedBrief", key: str) -> str:
    """stated if the model said the value came from the user; inferred otherwise (conservative)."""
    return brief.field_sources.get(key, "inferred")


class FieldProposal(BaseModel):
    key: str
    value: str
    source: str            # stated | inferred
    warning: Optional[str] = None   # set when the value needs the user's attention (e.g. a
                                     # website that isn't a well-formed URL) — the review highlights it


# content fields shown in the review, in display order (category first)
_REVIEW_FIELDS = [
    "category", "headline", "subheadline", "body_text", "date", "time",
    "venue_name", "address", "price", "discount_text", "cta_text",
    "phone", "email", "website",
]


_WEBSITE_WARNING = ("Doesn't look like a complete web address — add a full link "
                    "(e.g. ticketmaster.com), or it'll print as entered.")


def build_field_proposals(brief: ExtractedBrief) -> List[FieldProposal]:
    out = []
    for key in _REVIEW_FIELDS:
        value = getattr(brief, key, None)
        if value:
            display = _category(brief.category).display_name if key == "category" else str(value)
            # Flag a website the user gave that isn't a well-formed URL so the review can
            # highlight it — never silently drop what they entered.
            warning = _WEBSITE_WARNING if (key == "website" and not is_valid_website(value)) else None
            out.append(FieldProposal(key=key, value=display, source=field_source(brief, key), warning=warning))
    return out


def reconcile_field_sources(brief: "ExtractedBrief", user_text: str) -> "ExtractedBrief":
    """Deterministically mark a field 'stated' when its value appears verbatim in the user's
    text. The extraction model's provenance is a single best-guess that flip-flops between
    runs (the audit's "Now Hiring Baristas" tagged INFERRED then STATED); this pass is precise
    and conservative — it only ever UPGRADES on a substring match, never downgrades a 'stated',
    and never touches category (always a deduction)."""
    text = " ".join((user_text or "").lower().split())
    if not text:
        return brief
    for key in _REVIEW_FIELDS:
        if key == "category":
            continue
        value = getattr(brief, key, None)
        if not value:
            continue
        norm = " ".join(str(value).lower().split())
        if norm and norm in text:
            brief.field_sources[key] = "stated"
    return brief


def sanitize_brief(brief: "ExtractedBrief") -> "ExtractedBrief":
    """Null out any content field holding a meta/non-answer ('No', 'idk', ...) so it neither
    shows in the review nor prints on the flyer. Applied on every path that fills the brief."""
    for key in _REVIEW_FIELDS:
        if key == "category":
            continue
        value = getattr(brief, key, None)
        if value is not None and is_non_value(value):
            setattr(brief, key, None)
    return brief


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


class ReviewProposal(BaseModel):
    """The engine's complete interpretation, surfaced for one consolidated human approval."""
    fields: List[FieldProposal] = []
    decisions: list = []          # list[DecisionProposal] (dataclass) — kept loosely typed
    plan: Optional[Any] = None    # DesignBrief in production; loosely typed so it never
                                  # rejects (e.g. a mocked brief in tests)

    model_config = {"arbitrary_types_allowed": True}


def _category(value: str) -> FlyerCategory:
    try:
        return FlyerCategory(value)            # exact wire value ("job_posting")
    except ValueError:
        pass
    s = str(value or "").strip().lower()       # tolerate a display name ("Job Posting")
    for c in FlyerCategory:
        if c.display_name.lower() == s:
            return c
    return FlyerCategory.ANNOUNCEMENT


def to_flyer_project(brief: ExtractedBrief) -> FlyerProject:
    # Last-mile guard: drop any meta/non-answer value on EVERY path into generation
    # (extraction, answers, or a review edit), so the flyer never renders "No"/"idk".
    c = lambda v: None if (v is not None and is_non_value(v)) else v
    tc = TextContent(
        headline=c(brief.headline) or "",
        subheadline=c(brief.subheadline),
        body_text=c(brief.body_text),
        date=c(brief.date),
        time=c(brief.time),
        venue_name=c(brief.venue_name),
        address=c(brief.address),
        price=c(brief.price),
        discount_text=c(brief.discount_text),
        cta_text=c(brief.cta_text),
        phone=c(brief.phone),
        email=c(brief.email),
        website=c(brief.website),   # kept at face value (review flagged it if malformed); only non-values dropped
        additional_info=[i for i in (brief.additional_info or []) if i and not is_non_value(i)] or None,
    )
    try:
        ar = AspectRatio(brief.aspect_ratio) if getattr(brief, "aspect_ratio", None) else AspectRatio.PORTRAIT_4_5
    except ValueError:
        ar = AspectRatio.PORTRAIT_4_5
    return FlyerProject(
        category=_category(brief.category),
        text_content=tc,
        output=OutputSettings(aspect_ratio=ar, model="nano-banana-pro"),
        special_instructions=brief.purpose or None,
    )
