from unittest.mock import MagicMock
from engine.schema import ExtractedBrief
from engine.extract import extract_brief


def test_extract_brief_calls_parse_with_sonnet_and_returns_parsed():
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(
        parsed_output=ExtractedBrief(category="event", headline="Bake Sale", date="Sat")
    )
    brief = extract_brief("Flyer for our bake sale Saturday", client=fake)
    assert brief.headline == "Bake Sale"
    kwargs = fake.messages.parse.call_args.kwargs
    assert kwargs["model"] == "claude-sonnet-4-6"
    assert kwargs["output_format"] is ExtractedBrief
    assert kwargs["thinking"] == {"type": "adaptive"}      # deliberates before extracting
    assert kwargs["output_config"] == {"effort": "high"}


def test_extract_brief_sanitizes_non_value_fields():
    # A stray meta/non-answer the model captured ("price": "No") is dropped before review.
    fake = MagicMock()
    fake.messages.parse.return_value = MagicMock(
        parsed_output=ExtractedBrief(category="event", headline="Gala", price="No"))
    brief = extract_brief("a community gala", client=fake)
    assert brief.price is None
