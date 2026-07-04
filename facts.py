"""Canonical fact normalization + dedup - the single source of truth for deciding whether
two brief facts are "the same".

Every place that stores or renders brief facts (the interpreter's TurnResult validators, the
legacy ExtractedBrief, and the flyer prompt builder) routes through here, so duplication is
judged identically everywhere instead of via copy-pasted, drifting logic. Matching is
deterministic and conservative: two facts collapse only when identical after ignoring case,
all whitespace (including non-breaking spaces), invisible format characters (zero-width
spaces/joiners, BOM, directional marks - they render as nothing, so they must not make
identical-looking facts distinct), and surrounding punctuation/bullets. Interior content is
preserved, so genuinely different facts always stay distinct.
"""
from typing import List, Optional
import unicodedata

# Stripped only from the ENDS of a fact when comparing/cleaning: bullets, quotes, and the
# terminal punctuation the model sprinkles inconsistently. Interior punctuation is preserved.
_EDGE = " \t\r\n\"'“”‘’`*_~-–—•·.,:;!?()[]{}"


def _clean(s: str) -> str:
    """NFKC-normalize (folds nbsp and compatibility forms) and collapse every run of
    whitespace to a single space, trimming the edges. Preserves case and interior text -
    this is the display form."""
    return " ".join(unicodedata.normalize("NFKC", s).split())


def _without_format_chars(s: str) -> str:
    """Drop Unicode format characters (category Cf: ZWSP, word joiner, BOM, directional marks).
    They have no glyph, so an LLM sprinkling them yields facts that LOOK identical but compare
    unequal - and every such "variant" would survive dedup as a duplicate row. Key-side only:
    the display form keeps its original characters (removing e.g. a ZWJ could break emoji)."""
    return "".join(ch for ch in s if unicodedata.category(ch) != "Cf")


def normalize_fact(s) -> str:
    """A canonical comparison KEY for a fact string: cleaned, invisible format chars dropped,
    edge punctuation/bullets stripped, casefolded. Two facts with the same key are duplicates.
    Returns "" for non-strings/blank."""
    if not isinstance(s, str):
        return ""
    # Format chars are removed BEFORE the whitespace collapse so "a <ZWSP> b" folds to
    # "a b", not "a  b"; a format char between letters (renders as one word) keeps them joined.
    folded = _without_format_chars(unicodedata.normalize("NFKC", s))
    return " ".join(folded.split()).strip(_EDGE).casefold()


def dedup_facts(items) -> Optional[List[str]]:
    """Keep-first dedup of a list of fact strings using normalize_fact. Coerces a bare string to
    a single item, skips non-strings and blanks, and keeps the cleaned display text of the first
    occurrence. Returns None when nothing survives (matches the Optional[List[str]] fields).

    A non-list, non-string input returns None rather than passing through - this also closes the
    pydantic list_type crash the old validators guarded against inconsistently."""
    if items is None:
        return None
    if isinstance(items, str):
        items = [items]
    if not isinstance(items, list):
        return None
    seen, out = set(), []
    for item in items:
        key = normalize_fact(item)
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(_clean(item))
    return out or None


def without_represented(items, field_values) -> Optional[List[str]]:
    """Return the deduped facts that are NOT already represented by a dedicated field.

    Drops any item whose normalized key equals a normalized value in `field_values`, so a
    catch-all list (additional_info) means "facts with no dedicated home" and a fact never
    renders both as its own field and as an extra. Exact-normalized match only - conservative
    by design, never fuzzy."""
    items = dedup_facts(items)
    if not items:
        return items
    represented = {normalize_fact(v) for v in field_values}
    represented.discard("")
    out = [it for it in items if normalize_fact(it) not in represented]
    return out or None
