from dataclasses import dataclass, field
from typing import List
from models import FlyerCategory


@dataclass
class Rubric:
    """Structured per-category design knowledge a senior designer would apply."""
    checklist: List[str] = field(default_factory=list)
    hierarchy: List[str] = field(default_factory=list)
    default_format_reason: str = ""
    recommendations: List[str] = field(default_factory=list)
    palette_directions: List[str] = field(default_factory=list)


# A shared cool/seasonal palette vocabulary appended to the season-driven rubrics (sale, event)
# and the generic fallback, so a winter sale (etc.) can pre-select a fitting palette instead of
# only the category's loud defaults. Each name carries a keyword that decide._PALETTE_PRESETS
# maps to concrete swatches (winter→navy/ice, evergreen→forest, autumn/spring/summer).
SEASONAL_PALETTE_DIRECTIONS = [
    "Winter frost", "Evergreen pine", "Autumn harvest", "Spring bloom", "Summer bright",
]


GENERIC_RUBRIC = Rubric(
    checklist=[
        "One clear focal point / headline readable at a glance",
        "Strong visual hierarchy: headline > key detail > supporting info",
        "Legible type contrast against the background",
        "Generous margins; nothing critical near the edges",
        "A single, obvious call to action",
    ],
    hierarchy=["headline", "key_detail", "cta", "supporting_info"],
    default_format_reason="Portrait 4:5 reads well in social feeds and prints cleanly.",
    recommendations=[
        "Lead with the single most important message.",
        "Keep the palette to 2-3 colors for cohesion.",
    ],
    # No palette nudge on the generic fallback. For categories we haven't authored, the brain's
    # own judgment reads the occasion better than a one-size-fits-all color list would - a canned
    # "warm/seasonal" set actively misled solemn briefs (e.g. it offered "Evergreen pine" green for
    # a Shia mourning Majlis). Leave this empty and let the model choose. [[no-silent-defaults]]
    palette_directions=[],
)


# Top categories authored concretely; everything else inherits GENERIC_RUBRIC.
RUBRICS = {
    FlyerCategory.NONPROFIT_CHARITY: Rubric(
        checklist=[
            "Emotional hook up top (human story or photo)",
            "Crystal-clear donate / RSVP call to action",
            "Cause / beneficiary stated plainly",
            "Trust signals: org name, logo, where the money goes",
            "Date, time, and venue if it's an event",
        ],
        hierarchy=["headline", "cause", "cta", "logistics"],
        default_format_reason="Portrait 4:5 suits both a shared post and a printed bulletin insert.",
        recommendations=[
            "Show the impact ('feeds 50 families'), not just the ask.",
            "Make the donate action and link unmissable.",
        ],
        palette_directions=["Warm & hopeful", "Earthy & grounded", "Trust-blue & clean"],
    ),
    FlyerCategory.EVENT: Rubric(
        checklist=[
            "Event name as the dominant element",
            "Date, time, and venue grouped and scannable",
            "A reason-to-attend hook (subhead or imagery)",
            "Clear RSVP / get-tickets call to action",
            "Organizer / brand mark for credibility",
        ],
        hierarchy=["headline", "date_venue", "cta", "details"],
        default_format_reason="Portrait 4:5 works for both feed posts and printed posters.",
        recommendations=[
            "Put date and venue in one tight block so it's instantly scannable.",
            "Give the CTA its own breathing room.",
        ],
        palette_directions=["Vibrant & festive", "Sleek & modern", "Classic & elegant"]
                           + SEASONAL_PALETTE_DIRECTIONS,
    ),
    FlyerCategory.SALE_PROMO: Rubric(
        checklist=[
            "The offer (discount %) is the loudest element",
            "Urgency: dates / 'limited time'",
            "What's on sale is obvious",
            "Clear redeem / shop call to action",
            "Fine print legible but secondary",
        ],
        hierarchy=["discount", "what", "cta", "fine_print"],
        default_format_reason="Portrait 4:5 maximizes the offer's screen real estate in feeds.",
        recommendations=[
            "Make the discount number the single biggest thing on the flyer.",
            "Add a deadline to create urgency.",
        ],
        palette_directions=["High-energy red/yellow", "Premium black & gold", "Fresh & modern"]
                           + SEASONAL_PALETTE_DIRECTIONS,
    ),
    FlyerCategory.CHURCH_RELIGIOUS: Rubric(
        checklist=[
            "Occasion and its purpose clear at a glance (worship, remembrance, or celebration)",
            "Tone matches the occasion's emotional register and stays reverent throughout",
            "Sacred names and phrases spelled and placed respectfully",
            "Date, time, venue - include any religious-calendar date (Hijri, liturgical) if given",
            "Symbolic, non-figurative imagery; do not depict sacred/holy figures",
        ],
        hierarchy=["headline", "occasion", "date_venue", "details"],
        default_format_reason="Portrait 4:5 suits both a shared post and a printed bulletin or notice-board flyer.",
        recommendations=[
            "Match the palette to the occasion's emotional register. Mourning and remembrance "
            "(Muharram, Ashura, Majlis-e-Aza, Arbaeen, Chehlum, Good Friday, memorials, funerals) "
            "call for a somber, dignified palette - deep black or charcoal base, deep burgundy or "
            "maroon, muted antique gold, ivory text - never festive, bright, neon, or green. Joyful "
            "observances (Eid, Christmas, Easter, weddings, baptisms, anniversaries) allow warmer, "
            "celebratory color while staying tasteful and reverent.",
            "Keep ornament symbolic and abstract - geometric borders, calligraphy, soft light, "
            "domes or arches in silhouette - rather than literal depictions of holy figures.",
        ],
        # Register-spanning options: the recommendations tell the brain WHEN to use each. Mourning
        # briefs should land on the first; celebratory ones on the last.
        palette_directions=[
            "Solemn black, burgundy & gold",
            "Reverent ivory & antique gold",
            "Celebratory jewel tones",
        ],
    ),
}


def rubric_for(category) -> Rubric:
    """Look up the rubric for a category (enum or string); generic fallback otherwise."""
    try:
        cat = category if isinstance(category, FlyerCategory) else FlyerCategory(category)
    except ValueError:
        return GENERIC_RUBRIC
    return RUBRICS.get(cat, GENERIC_RUBRIC)


# The tiny declarative "must-ask" floor: facts that, if missing AND not inferable, must be asked.
# Grows with categories, never with user phrasings.
MUST_HAVE_FACTS: dict[FlyerCategory, list[str]] = {
    FlyerCategory.EVENT: ["date", "venue_name"],
    FlyerCategory.SALE_PROMO: ["discount_text", "date"],
    FlyerCategory.PARTY_CELEBRATION: ["date", "venue_name"],
    FlyerCategory.MUSIC_CONCERT: ["date", "venue_name"],
    FlyerCategory.CLASS_WORKSHOP: ["date"],
    FlyerCategory.GRAND_OPENING: ["date", "venue_name"],
    FlyerCategory.NONPROFIT_CHARITY: ["cta_text"],
    FlyerCategory.JOB_POSTING: ["cta_text"],
    FlyerCategory.REAL_ESTATE: ["address", "price"],
    FlyerCategory.CHURCH_RELIGIOUS: ["date"],
    # categories not listed have no hard floor (everything inferable) -> never blocks.
}

# Named palette directions -> swatch hexes, so colors stay curated (replaces _PALETTE_PRESETS keyword table).
# Keyed by the lowercased direction name the brain returns; unknown directions fall back at compile time.
PALETTE_SWATCHES: dict[str, list[str]] = {
    # GENERIC_RUBRIC
    "warm & inviting": ["#C2410C", "#F59E0B", "#FFF7ED"],
    "cool & modern": ["#0369A1", "#0891B2", "#F0F9FF"],
    "high-contrast bold": ["#111111", "#E11D48", "#FFFFFF"],
    # SEASONAL_PALETTE_DIRECTIONS (shared across EVENT, SALE_PROMO, GENERIC_RUBRIC)
    "winter frost": ["#93C5FD", "#E0F2FE", "#F8FAFC"],
    "evergreen pine": ["#166534", "#4ADE80", "#F0FDF4"],
    "autumn harvest": ["#D97706", "#B45309", "#FEF3C7"],
    "spring bloom": ["#F472B6", "#C084FC", "#FDF4FF"],
    "summer bright": ["#FDE047", "#38BDF8", "#FEFCE8"],
    # NONPROFIT_CHARITY
    "warm & hopeful": ["#EA580C", "#F59E0B", "#FFFBEB"],
    "earthy & grounded": ["#78350F", "#65A30D", "#F7F4EF"],
    "trust-blue & clean": ["#1D4ED8", "#BFDBFE", "#F8FAFC"],
    # EVENT
    "vibrant & festive": ["#7C3AED", "#EC4899", "#FCD34D"],
    "sleek & modern": ["#1F2937", "#9CA3AF", "#F9FAFB"],
    "classic & elegant": ["#1E3A5F", "#C9A84C", "#FAF8F1"],
    # SALE_PROMO
    "high-energy red/yellow": ["#DC2626", "#FBBF24", "#111111"],
    "premium black & gold": ["#0A0A0A", "#D4AF37", "#FAFAFA"],
    "fresh & modern": ["#0D9488", "#2DD4BF", "#F0FDFA"],
    # CHURCH_RELIGIOUS
    "solemn black, burgundy & gold": ["#0A0A0A", "#7F1D1D", "#C9A84C"],   # mourning / remembrance
    "reverent ivory & antique gold": ["#FAF8F1", "#C9A84C", "#3F2A1E"],   # dignified worship
    "celebratory jewel tones": ["#065F46", "#7C3AED", "#FCD34D"],         # Eid / Christmas / joyful
}


def must_have_facts(category) -> list[str]:
    try:
        cat = category if isinstance(category, FlyerCategory) else FlyerCategory(category)
    except ValueError:
        return []
    return MUST_HAVE_FACTS.get(cat, [])


def briefing_for(category) -> str:
    """A compact, model-facing briefing string: the rubric's how-to-think + this category's must-haves."""
    r = rubric_for(category)
    floor = ", ".join(must_have_facts(category)) or "none"
    if r.palette_directions:
        palette_line = f"Recommended palette directions: {', '.join(r.palette_directions)}\n"
    else:
        # No preset directions: trust the model to choose colors that fit the specific occasion.
        palette_line = ("Palette: no preset direction - choose colors that genuinely fit this "
                        "occasion, audience, and mood.\n")
    return (
        f"Design checklist: {'; '.join(r.checklist)}\n"
        f"Hierarchy (loudest first): {' > '.join(r.hierarchy)}\n"
        f"{palette_line}"
        f"Must-have facts (ask if missing and not inferable): {floor}"
    )
