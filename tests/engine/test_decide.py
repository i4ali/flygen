from engine.decide import (
    map_format, propose_palette_directions, apply_decisions, Direction,
    propose_decisions, apply_proposed, DecisionProposal, format_options,
)
from engine.schema import ExtractedBrief, to_flyer_project
from engine.rubrics import rubric_for
from models import AspectRatio, ColorSchemePreset, FlyerCategory


def test_instagram_maps_to_portrait_4_5():
    assert map_format("instagram") == AspectRatio.PORTRAIT_4_5


def test_print_maps_to_letter():
    assert map_format("printed") == AspectRatio.LETTER


def test_both_prefers_portrait():
    assert map_format("both") == AspectRatio.PORTRAIT_4_5


def test_swatches_for_maps_seasonal_names_to_their_presets():
    from engine.decide import _swatches_for, _DEFAULT_SWATCHES
    cases = {"Winter frost": "#1B3A5B", "Evergreen pine": "#1E3D2F", "Autumn harvest": "#8C3B0E",
             "Spring bloom": "#6FA86B", "Summer bright": "#FF6B5C"}
    for name, lead_hex in cases.items():
        sw = _swatches_for(name)
        assert sw[0] == lead_hex and sw != _DEFAULT_SWATCHES, name   # own preset, not the fallback


def test_propose_palette_directions_surfaces_seasonal_with_real_swatches():
    dirs = {d.name: d for d in propose_palette_directions(rubric_for(FlyerCategory.SALE_PROMO))}
    assert "Winter frost" in dirs
    assert dirs["Winter frost"].swatches[0] == "#1B3A5B"            # cool navy, not the default


def test_winter_sale_can_now_propose_a_cool_palette():
    # the audit's #2 in full: a winter-sale design can finally pre-select a cool palette
    # (previously the SALE_PROMO vocabulary offered only high-energy / premium / fresh).
    from engine.schema import DesignBrief
    brief = ExtractedBrief(category="sale_promo", headline="Big Winter Sale",
                           discount_text="60% off", cta_text="Shop")
    design = DesignBrief(notes="deep winter palette", recommended_palette="Winter frost")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.SALE_PROMO), design)}
    assert decs["palette"].value == "Winter frost"


def test_propose_palette_directions_returns_named_swatches():
    dirs = propose_palette_directions(rubric_for(FlyerCategory.EVENT))
    assert dirs and all(isinstance(d, Direction) for d in dirs)
    assert all(d.name and d.swatches for d in dirs)


def test_apply_decisions_sets_format_palette_and_qr():
    project = to_flyer_project(ExtractedBrief(category="event", headline="Bake Sale"))
    rubric = rubric_for(FlyerCategory.EVENT)
    answers = {
        "destination": "printed",
        "palette": rubric.palette_directions[0],
        "qr_url": "https://example.org/rsvp",
    }
    out = apply_decisions(project, answers, rubric)
    assert out.output.aspect_ratio == AspectRatio.LETTER
    assert out.colors.preset == ColorSchemePreset.CUSTOM
    assert out.colors.primary_color  # a hex was assigned from the chosen direction
    assert out.qr_settings and out.qr_settings.enabled
    assert out.qr_settings.url == "https://example.org/rsvp"


def test_propose_decisions_always_includes_format_with_options():
    brief = ExtractedBrief(category="event", headline="Gala")          # no destination
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert "format" in decs                                            # always present (the bug fix)
    assert decs["format"].value == "4:5"                               # sensible default when not stated
    assert decs["format"].options and "letter" in decs["format"].options
    assert "palette" in decs and decs["palette"].options


def test_propose_decisions_omits_internal_model_choice():
    # the image model (nano-banana-pro) is an internal implementation detail, not a
    # user-facing decision — it must not surface in the review.
    brief = ExtractedBrief(category="event", headline="Gala")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert "model" not in decs
    assert "format" in decs and "palette" in decs   # the genuine decisions remain


def test_propose_decisions_infers_format_from_destination():
    brief = ExtractedBrief(category="event", headline="Gala", destination="printed")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert decs["format"].value == "letter"                           # inferred from the brief


def test_apply_proposed_sets_aspect_ratio_from_override():
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala"))
    apply_proposed(project, {"format": "letter"}, rubric_for(FlyerCategory.EVENT))
    assert project.output.aspect_ratio == AspectRatio.LETTER


def test_format_options_are_platform_labeled_with_default_first():
    opts = format_options()
    by = {o["value"]: o["label"] for o in opts}
    assert opts[0]["value"] == "4:5"                 # default first
    assert "Instagram" in by["4:5"]
    assert "TikTok" in by["9:16"]
    assert "letter" in by                            # a print option is offered


def test_propose_decisions_format_carries_platform_labels():
    brief = ExtractedBrief(category="event", headline="Gala")
    fmt = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}["format"]
    assert fmt.value == "4:5"
    assert fmt.option_labels and "Instagram" in fmt.option_labels["4:5"]


def test_propose_decisions_format_defaults_to_the_size_the_user_picked():
    brief = ExtractedBrief(category="event", headline="Gala", aspect_ratio="9:16")
    fmt = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}["format"]
    assert fmt.value == "9:16"                        # pre-selects the early pick at review


def test_propose_decisions_uses_human_readable_style_and_mood_labels():
    # #5: the review must not leak raw enum values like "modern_minimal" / "friendly".
    brief = ExtractedBrief(category="event", headline="Gala")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT))}
    assert decs["visual_style"].value == "Modern Minimal"
    assert "Modern Minimal" in decs["visual_style"].options and "Bold Vibrant" in decs["visual_style"].options
    assert decs["mood"].value == "Friendly"
    assert "Exciting" in decs["mood"].options


def test_apply_proposed_resolves_human_readable_style_and_mood():
    from models import VisualStyle, Mood
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala"))
    apply_proposed(project, {"visual_style": "Bold Vibrant", "mood": "Exciting"},
                   rubric_for(FlyerCategory.EVENT))
    assert project.visuals.style == VisualStyle.BOLD_VIBRANT
    assert project.visuals.mood == Mood.EXCITING


def test_propose_decisions_uses_design_recommended_palette_style_mood():
    # #2/#3: when the design pass recommends a palette/style/mood (chosen from the offered
    # options), those become the proposed defaults — not the blind directions[0] / hard-coded.
    from engine.schema import DesignBrief
    brief = ExtractedBrief(category="sale_promo", headline="Big Winter Sale",
                           discount_text="Up to 60% off", cta_text="Shop now")
    rubric = rubric_for(FlyerCategory.SALE_PROMO)
    design = DesignBrief(notes="winter — go cool & premium, not high-energy red",
                         recommended_palette="Premium black & gold",
                         recommended_style="Elegant Luxury", recommended_mood="Festive")
    decs = {d.key: d for d in propose_decisions(brief, rubric, design)}
    assert decs["palette"].value == "Premium black & gold"     # not directions[0] ("High-energy red/yellow")
    assert decs["visual_style"].value == "Elegant Luxury"      # not the hard-coded Modern Minimal
    assert decs["mood"].value == "Festive"                     # not the hard-coded Friendly


def test_propose_decisions_falls_back_to_defaults_without_design_or_on_unknown_values():
    from engine.schema import DesignBrief
    brief = ExtractedBrief(category="sale_promo", headline="Sale",
                           discount_text="50% off", cta_text="Go")
    rubric = rubric_for(FlyerCategory.SALE_PROMO)
    base = {d.key: d for d in propose_decisions(brief, rubric)}            # no design at all
    assert base["palette"].value == rubric.palette_directions[0]
    assert base["visual_style"].value == "Modern Minimal" and base["mood"].value == "Friendly"
    odd = DesignBrief(notes="n", recommended_palette="Ultraviolet moon",   # not an offered direction
                      recommended_style="Bogus", recommended_mood="Nope")
    fb = {d.key: d for d in propose_decisions(brief, rubric, odd)}
    assert fb["palette"].value == rubric.palette_directions[0]             # unmatched -> default
    assert fb["visual_style"].value == "Modern Minimal" and fb["mood"].value == "Friendly"


def test_propose_decisions_ignores_non_string_recommendations():
    # defensive: a mocked/garbled design brief (e.g. a MagicMock in tests, or a parse miss)
    # must not crash or leak a non-option value into the review.
    from unittest.mock import MagicMock
    brief = ExtractedBrief(category="event", headline="Gala")
    decs = {d.key: d for d in propose_decisions(brief, rubric_for(FlyerCategory.EVENT), MagicMock())}
    assert decs["visual_style"].value == "Modern Minimal"
    assert decs["mood"].value == "Friendly"
    assert decs["palette"].value == rubric_for(FlyerCategory.EVENT).palette_directions[0]


def test_apply_proposed_still_accepts_raw_enum_values():
    # backward-compat: the wire value still resolves if it ever comes through
    from models import VisualStyle
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala"))
    apply_proposed(project, {"visual_style": "bold_vibrant"}, rubric_for(FlyerCategory.EVENT))
    assert project.visuals.style == VisualStyle.BOLD_VIBRANT
