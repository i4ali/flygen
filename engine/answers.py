import re
from models import AspectRatio
from engine.schema import (
    ExtractedBrief, is_non_value, is_valid_website, looks_like_phone, looks_like_email,
)

# The early size picker answers under one of these keys; route it to aspect_ratio.
_FORMAT_ANSWER_KEYS = {"format", "aspect_ratio", "size"}

# Answer-key aliases -> canonical ExtractedBrief field. The question model is nudged to
# reuse existing field keys, but it still invents synonyms for added clarifications; map
# the common ones so the value lands in its semantic slot (a price renders as a price, an
# address as an address) instead of generic additional info.
_ALIASES = {
    "pay_rate": "price", "wage": "price", "salary": "price", "rate": "price", "pay": "price",
    "hours": "time", "store_hours": "time", "opening_hours": "time", "business_hours": "time",
    "venue_address": "address", "full_address": "address", "street_address": "address",
    "location": "address",
    "contact_phone": "phone", "phone_number": "phone",
    "contact_email": "email",
    "link": "website", "url": "website", "redeem_link": "website",
}

# Canonical content fields on ExtractedBrief an answer may set directly. category is
# deliberately excluded — an answer must not silently change the flyer's category.
_MERGEABLE = {
    "headline", "subheadline", "body_text", "date", "time", "venue_name", "address",
    "price", "discount_text", "cta_text", "phone", "email", "website", "destination",
}

# Public view of the canonical content slots — the question prompt offers these so the
# model reuses a real key (pay rate -> price) instead of inventing one that gets dropped.
MERGEABLE_FIELDS = frozenset(_MERGEABLE)


def canonical_key(key: str) -> str:
    """Map an answer key to its canonical ExtractedBrief field, or return it unchanged."""
    k = (key or "").strip().lower()
    if k in _MERGEABLE:
        return k
    return _ALIASES.get(k, key)


# The three interchangeable contact channels. A single question often offers all three but
# binds to one key, so the channel a user actually gives can disagree with the key.
_CONTACT_KEYS = {"website", "phone", "email"}


def _route_contact(key: str, value: str) -> str:
    """Re-route a contact answer to the channel its VALUE actually is, so a phone given to a
    'website, phone, or email' question lands in `phone` — not `website`, where the review would
    flag it as a malformed URL. Only acts within the contact family and only on an unambiguous
    match; anything else (incl. a malformed website name) keeps the question's key."""
    if key not in _CONTACT_KEYS:
        return key
    if looks_like_email(value):
        return "email"
    if looks_like_phone(value):
        return "phone"
    if is_valid_website(value):
        return "website"
    return key


def _normalize_price(value: str) -> str:
    """Light, safe currency tidy: a trailing-dollar amount like '18$' becomes '$18'."""
    m = re.fullmatch(r"\s*(\d[\d,.]*)\s*\$\s*", value or "")
    return f"${m.group(1)}" if m else value


def apply_answers(brief: ExtractedBrief, answers: dict) -> list:
    """Merge user answers onto the brief WITHOUT silent loss.

    A matching (or aliased) canonical field is set directly and marked 'stated' (the user
    just stated it). Any answer with no semantic home is appended to additional_info so
    the generator still renders it. Returns the original keys that had no canonical home.
    """
    unmapped = []
    for raw_key, value in (answers or {}).items():
        if value is None or not str(value).strip():
            continue
        value = str(value).strip()
        if is_non_value(value):
            continue                # meta/non-answer ("No", "idk"...) -> omit, don't store it
        if raw_key.strip().lower() in _FORMAT_ANSWER_KEYS:
            try:
                brief.aspect_ratio = AspectRatio(value).value
                brief.field_sources["aspect_ratio"] = "stated"
            except ValueError:
                pass                # an unrecognized size is ignored, not stored as junk
            continue
        key = _route_contact(canonical_key(raw_key), value)
        if key in _MERGEABLE and hasattr(brief, key):
            if key == "price":
                value = _normalize_price(value)
            setattr(brief, key, value)
            brief.field_sources[key] = "stated"
        else:
            label = raw_key.replace("_", " ").strip()
            if brief.additional_info is None:
                brief.additional_info = []
            brief.additional_info.append(f"{label}: {value}")
            unmapped.append(raw_key)
    return unmapped
