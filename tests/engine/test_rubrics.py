from engine.rubrics import (rubric_for, briefing_for, Rubric, GENERIC_RUBRIC,
                            SEASONAL_PALETTE_DIRECTIONS)
from models import FlyerCategory


def test_seasonal_set_is_the_expected_four_seasons():
    assert SEASONAL_PALETTE_DIRECTIONS == [
        "Winter frost", "Evergreen pine", "Autumn harvest", "Spring bloom", "Summer bright"]


def test_seasonal_palette_directions_added_to_sale_and_event_only():
    # Seasonal vocabulary stays on Sale/Promo and Events (a winter sale can pick a cool palette).
    for cat in (FlyerCategory.SALE_PROMO, FlyerCategory.EVENT):
        dirs = rubric_for(cat).palette_directions
        for season in SEASONAL_PALETTE_DIRECTIONS:
            assert season in dirs, (cat, season)
    # the original category palettes are kept, not replaced
    assert "High-energy red/yellow" in rubric_for(FlyerCategory.SALE_PROMO).palette_directions


def test_generic_fallback_has_no_palette_nudge():
    # Owner decision (2026-07-01): the generic fallback must NOT nudge palette in any direction -
    # the brain chooses colors from the occasion. A canned seasonal set previously offered green
    # ("Evergreen pine") for a solemn Shia mourning Majlis.
    generic = rubric_for(FlyerCategory.RESTAURANT_FOOD).palette_directions   # uncovered -> GENERIC
    assert generic == []
    assert not any(s in generic for s in SEASONAL_PALETTE_DIRECTIONS)


def test_briefing_with_no_palette_directions_tells_model_to_decide():
    briefing = briefing_for(FlyerCategory.RESTAURANT_FOOD)   # uncovered -> GENERIC (empty palette)
    assert "no preset direction" in briefing
    assert "Recommended palette directions:" not in briefing


def test_church_religious_rubric_steers_mourning_palette():
    r = rubric_for(FlyerCategory.CHURCH_RELIGIOUS)
    assert r is not GENERIC_RUBRIC and r.checklist and r.recommendations
    prose = " ".join(r.recommendations).lower()
    assert "mourning" in prose and "burgundy" in prose      # names the somber register
    assert "eid" in prose or "christmas" in prose           # ...and the celebratory one too
    briefing = briefing_for(FlyerCategory.CHURCH_RELIGIOUS)
    assert "Solemn black, burgundy & gold" in briefing


def test_seasonal_directions_not_added_to_nonprofit():
    # scope excluded Nonprofit — it keeps its warm/hopeful set untouched.
    dirs = rubric_for(FlyerCategory.NONPROFIT_CHARITY).palette_directions
    assert not any(s in dirs for s in SEASONAL_PALETTE_DIRECTIONS)


def test_rubric_for_known_category_has_content():
    r = rubric_for(FlyerCategory.NONPROFIT_CHARITY)
    assert isinstance(r, Rubric)
    assert r.checklist            # non-empty checklist
    assert r.recommendations      # non-empty default recommendations


def test_rubric_for_unknown_category_returns_generic():
    assert rubric_for("not_a_real_category") is GENERIC_RUBRIC


def test_rubric_for_accepts_string_category():
    r = rubric_for("event")
    assert r.checklist
