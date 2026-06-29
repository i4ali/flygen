from unittest.mock import MagicMock
from engine.llm import EXTRACT_SYSTEM
from engine.config import THINKING, EFFORT
from engine.schema import ExtractedBrief, DesignBrief
from engine.extract import extract_brief
from engine.plan import build_design_brief
from engine.rubrics import rubric_for
from models import FlyerCategory


def test_system_prompt_is_one_stable_cached_block():
    assert isinstance(EXTRACT_SYSTEM, list) and len(EXTRACT_SYSTEM) == 1
    block = EXTRACT_SYSTEM[0]
    assert block["type"] == "text"
    assert block["cache_control"] == {"type": "ephemeral"}


def test_system_prompt_bakes_in_the_category_catalog():
    text = EXTRACT_SYSTEM[0]["text"]
    # enum catalog appended into the single cached block
    assert "nonprofit_charity" in text
    assert "event" in text


def test_extraction_turn_uses_configured_reasoning():
    # Extraction now deliberates too — adaptive thinking + the effort set in engine/config.py.
    # (Drive both turns from one config; lower EFFORT there to make extraction cheaper again.)
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(parsed_output=ExtractedBrief(category="event"))
    extract_brief("x", client=fake)
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["thinking"] == THINKING
    assert kwargs["output_config"] == EFFORT
    assert kwargs["system"] is EXTRACT_SYSTEM                       # shared cached prefix


def test_design_brief_turn_uses_high_effort_and_same_prefix():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(
        parsed_output=DesignBrief(notes="n", checklist=["c"], recommendations=["r"])
    )
    build_design_brief(
        ExtractedBrief(category="event", headline="x"),
        rubric_for(FlyerCategory.EVENT), {}, client=fake,
    )
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["output_config"] == {"effort": "high"}
    assert kwargs["thinking"] == {"type": "adaptive"}
    assert kwargs["system"] is EXTRACT_SYSTEM   # identical prefix -> cache reused across turns
