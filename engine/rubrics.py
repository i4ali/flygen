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
    palette_directions=["Warm & inviting", "Cool & modern", "High-contrast bold"]
                       + SEASONAL_PALETTE_DIRECTIONS,
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
}


def rubric_for(category) -> Rubric:
    """Look up the rubric for a category (enum or string); generic fallback otherwise."""
    try:
        cat = category if isinstance(category, FlyerCategory) else FlyerCategory(category)
    except ValueError:
        return GENERIC_RUBRIC
    return RUBRICS.get(cat, GENERIC_RUBRIC)
