from unittest.mock import MagicMock
from engine.turn import TurnResult
from engine.interpret import interpret
from engine.llm import INTERPRET_SYSTEM
from engine.config import MODEL, MAX_TOKENS, THINKING, EFFORT

def _client_returning(turn: TurnResult):
    c = MagicMock()
    c.messages.parse.return_value = MagicMock(parsed_output=turn)
    return c

def test_interpret_returns_validated_turn():
    canned = TurnResult(status="ready", category="event", headline="Gala",
                        decisions=[{"key": "format", "value": "billboard"}])
    c = _client_returning(canned)
    out = interpret(prior_brief={"category": "event"}, user_text="gala", answers=None, client=c)
    assert out.headline == "Gala"
    assert out.decisions[0].supported is False          # validate_decisions ran
    # the call carried our system + output_format
    kwargs = c.messages.parse.call_args.kwargs
    assert kwargs["system"] is INTERPRET_SYSTEM and kwargs["output_format"] is TurnResult
    assert kwargs["model"] == MODEL and kwargs["max_tokens"] == MAX_TOKENS
    assert kwargs["thinking"] == THINKING and kwargs["output_config"] == EFFORT

def test_interpret_prompt_includes_must_have_floor():
    c = _client_returning(TurnResult())
    interpret(prior_brief={"category": "event"}, user_text="x", answers=None, client=c)
    content = c.messages.parse.call_args.kwargs["messages"][0]["content"]
    assert "Must-have facts" in content and "date" in content
