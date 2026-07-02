from engine.turn import TurnResult, TurnDecision, CreativeElement
from engine.compile_project import build_project
from models import AspectRatio, VisualStyle, Mood

def _ready_turn():
    return TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="letter"),
                                 TurnDecision(key="visual_style", value="Elegant Luxury"),
                                 TurnDecision(key="mood", value="elegant"),
                                 TurnDecision(key="quality", value="hd")],
                      creative_elements=[CreativeElement(what="Gold foil accents", sensitivity="safe"),
                                         CreativeElement(what="Shrine silhouette", sensitivity="sensitive")])

def test_build_project_applies_decisions():
    p = build_project(_ready_turn(), {}, {})
    assert p.output.aspect_ratio == AspectRatio.LETTER
    assert p.visuals.style == VisualStyle.ELEGANT_LUXURY and p.visuals.mood == Mood.ELEGANT
    assert p.text_content.headline == "Gala"

def test_decision_override_wins():
    p = build_project(_ready_turn(), {}, {"format": "4:5"})
    assert p.output.aspect_ratio == AspectRatio.PORTRAIT_4_5

def test_only_safe_elements_in_imagery_by_default():
    p = build_project(_ready_turn(), {}, {})
    assert "Gold foil accents" in p.imagery_description
    assert "Shrine silhouette" not in p.imagery_description       # sensitive => opt-in only

def test_selected_elements_override_default():
    p = build_project(_ready_turn(), {}, {}, selected_elements=["Gold foil accents", "Shrine silhouette"])
    assert "Shrine silhouette" in p.imagery_description

def test_palette_text_flows_into_color_description():
    # The brain's free-text palette must reach ColorSettings.description (not be dropped when it
    # isn't an exact swatch key) - this is what fixes the old warm/light-background bug.
    turn = TurnResult(status="ready", category="church_religious", headline="Majlis",
                      decisions=[TurnDecision(key="palette",
                                              value="midnight black base, deep burgundy, antique gold")])
    p = build_project(turn, {}, {})
    assert p.colors.description == "midnight black base, deep burgundy, antique gold"
