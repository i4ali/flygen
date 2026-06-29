from engine.rubrics import rubric_for, Rubric, GENERIC_RUBRIC, SEASONAL_PALETTE_DIRECTIONS
from models import FlyerCategory


def test_seasonal_set_is_the_expected_four_seasons():
    assert SEASONAL_PALETTE_DIRECTIONS == [
        "Winter frost", "Evergreen pine", "Autumn harvest", "Spring bloom", "Summer bright"]


def test_seasonal_palette_directions_added_to_sale_event_and_generic():
    # owner-approved scope: a four-season cool/seasonal vocabulary on Sale/Promo, Events, and
    # the generic fallback — so a winter sale can pick a cool palette, not just high-energy red.
    for cat in (FlyerCategory.SALE_PROMO, FlyerCategory.EVENT):
        dirs = rubric_for(cat).palette_directions
        for season in SEASONAL_PALETTE_DIRECTIONS:
            assert season in dirs, (cat, season)
    generic = rubric_for(FlyerCategory.RESTAURANT_FOOD).palette_directions   # uncovered -> GENERIC
    assert all(s in generic for s in SEASONAL_PALETTE_DIRECTIONS)
    # the original category palettes are kept, not replaced
    assert "High-energy red/yellow" in rubric_for(FlyerCategory.SALE_PROMO).palette_directions


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
