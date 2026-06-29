from unittest.mock import MagicMock
from engine.openrouter_client import OpenRouterClient, _Messages, _MODEL_MAP
from engine.schema import ExtractedBrief, DesignBrief


def _client_returning(json_text):
    msg = MagicMock()
    msg.content = json_text
    oai = MagicMock()
    oai.chat.completions.create.return_value = MagicMock(choices=[MagicMock(message=msg)])
    c = OpenRouterClient.__new__(OpenRouterClient)  # bypass __init__ (no key needed)
    c._oai = oai
    c.messages = _Messages(oai)
    return c, oai


def test_parse_maps_model_flattens_system_and_returns_validated_pydantic():
    c, oai = _client_returning('{"category": "event", "headline": "Bake Sale"}')
    out = c.messages.parse(
        model="claude-sonnet-4-6",
        system=[{"type": "text", "text": "sys prefix", "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": "hi"}],
        output_format=ExtractedBrief,
    )
    assert isinstance(out.parsed_output, ExtractedBrief)
    assert out.parsed_output.headline == "Bake Sale"
    kwargs = oai.chat.completions.create.call_args.kwargs
    assert kwargs["model"] == _MODEL_MAP["claude-sonnet-4-6"]        # -> anthropic/claude-sonnet-4.6
    sys_msg = kwargs["messages"][0]
    assert sys_msg["role"] == "system"
    assert isinstance(sys_msg["content"], str)                       # blocks flattened
    assert "sys prefix" in sys_msg["content"]                        # original system kept
    assert "JSON" in sys_msg["content"] and "headline" in sys_msg["content"]  # JSON instruction injected
    # response_format json_schema is intentionally NOT used (unreliable on OpenRouter)
    assert "response_format" not in kwargs


def test_parse_translates_effort_to_openrouter_reasoning():
    c, oai = _client_returning('{"notes": "n", "checklist": ["c"], "recommendations": ["r"]}')
    c.messages.parse(
        model="claude-sonnet-4-6",
        system="s",
        messages=[{"role": "user", "content": "x"}],
        output_format=DesignBrief,
        thinking={"type": "adaptive"},
        output_config={"effort": "high"},
    )
    kwargs = oai.chat.completions.create.call_args.kwargs
    assert kwargs["extra_body"]["reasoning"]["effort"] == "high"


def test_ts_type_renders_json_types_from_annotations():
    from engine.openrouter_client import _ts_type
    f = ExtractedBrief.model_fields
    assert _ts_type(f["category"].annotation) == "string"
    assert _ts_type(f["headline"].annotation) == "string | null"
    assert _ts_type(f["additional_info"].annotation) == "string[] | null"   # the field that crashed
    assert _ts_type(f["field_sources"].annotation) == "{ [key: string]: string }"
    d = DesignBrief.model_fields
    assert _ts_type(d["checklist"].annotation) == "string[]"
    assert _ts_type(d["questions"].annotation) == "{ field: string | null, text: string | null }[]"


def test_parse_instruction_carries_per_field_types_and_array_guard():
    # hardening: the JSON instruction now states each field's TYPE (not just its name) and
    # explicitly forbids a bare string for array fields — the root cause of the additional_info crash.
    c, oai = _client_returning('{"category": "event", "headline": "X"}')
    c.messages.parse(model="claude-sonnet-4-6", system="s",
                     messages=[{"role": "user", "content": "x"}], output_format=ExtractedBrief)
    sys_msg = oai.chat.completions.create.call_args.kwargs["messages"][0]["content"]
    assert '"additional_info": string[] | null' in sys_msg        # type stated, not just the key
    assert "array" in sys_msg.lower() and "never a bare string" in sys_msg.lower()


def test_parse_handles_fenced_json():
    c, _ = _client_returning('```json\n{"category": "sale_promo"}\n```')
    out = c.messages.parse(
        model="claude-sonnet-4-6", system="s",
        messages=[{"role": "user", "content": "x"}], output_format=ExtractedBrief,
    )
    assert out.parsed_output.category == "sale_promo"
