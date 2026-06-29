from unittest.mock import MagicMock
from engine.schema import ExtractedBrief, DesignBrief
from engine.rubrics import rubric_for
from engine.plan import build_design_brief, _user_prompt
from models import FlyerCategory


def test_plan_prompt_takes_wellformed_contact_details_at_face_value():
    # #1: the design pass must not raise false "conflict / resolve before production" alarms
    # about validly-provided details (e.g. a 3rd-party website) — accept them at face value.
    brief = ExtractedBrief(category="sale_promo", headline="Big Winter Sale", website="ticketmaster.com")
    prompt = _user_prompt(brief, rubric_for(FlyerCategory.SALE_PROMO), {})
    assert "face value" in prompt.lower()


def test_plan_prompt_requests_palette_style_mood_from_the_offered_options():
    # #2/#3: the design pass picks palette/style/mood from the actual options so its choice can
    # pre-select the review controls — so the prompt must name the fields AND list the options.
    rubric = rubric_for(FlyerCategory.SALE_PROMO)
    prompt = _user_prompt(ExtractedBrief(category="sale_promo", headline="Sale"), rubric, {})
    assert "recommended_palette" in prompt and "recommended_style" in prompt and "recommended_mood" in prompt
    assert rubric.palette_directions[0] in prompt          # the palette options are offered to choose from
    assert "Modern Minimal" in prompt and "Friendly" in prompt   # style + mood options offered


def test_build_design_brief_returns_designbrief_and_uses_sonnet_high_effort():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(
        parsed_output=DesignBrief(
            notes="Lead with the cause.",
            checklist=["Emotional hook up top", "Clear donate CTA"],
            recommendations=["Show impact ('feeds 50 families'), not just the ask."],
        )
    )
    brief = ExtractedBrief(category="nonprofit_charity", headline="Bake Sale", cta_text="Donate")
    rubric = rubric_for(FlyerCategory.NONPROFIT_CHARITY)
    design = build_design_brief(brief, rubric, answers={}, client=fake)

    assert isinstance(design, DesignBrief)
    assert design.checklist            # applied checklist
    assert design.recommendations      # >=1 proactive recommendation

    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["model"] == "claude-sonnet-4-6"
    assert kwargs["thinking"] == {"type": "adaptive"}
    assert kwargs["output_config"] == {"effort": "high"}
    assert kwargs["output_format"] is DesignBrief
