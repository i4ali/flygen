from unittest.mock import MagicMock
from engine.gate import is_flyer_request, GateVerdict, GATE_SYSTEM
from engine.config import GATE_MODEL


def _client_returning(is_flyer):
    c = MagicMock()
    c.messages.parse.return_value = MagicMock(parsed_output=GateVerdict(is_flyer=is_flyer))
    return c


def test_true_routes_to_the_designer():
    assert is_flyer_request("make me an eid flyer", _client_returning(True)) is True


def test_explicit_false_deflects():
    assert is_flyer_request("what's the weather today?", _client_returning(False)) is False


def test_null_fails_open_to_flyer():
    # The model is unsure and returns null -> we treat it as a flyer. A false "not a flyer" would
    # turn a real customer away; a false "is a flyer" costs at most one wasted call.
    assert is_flyer_request("something nice for saturday", _client_returning(None)) is True


def test_transport_error_fails_open_to_flyer():
    c = MagicMock()
    c.messages.parse.side_effect = RuntimeError("openrouter 503")
    assert is_flyer_request("birthday bash flyer", c) is True


def test_calls_the_cheap_model_with_the_verdict_schema():
    c = _client_returning(True)
    is_flyer_request("x", c)
    kw = c.messages.parse.call_args.kwargs
    assert kw["model"] == GATE_MODEL           # the cheap gate model, not the design model
    assert kw["output_format"] is GateVerdict
    assert kw["system"] is GATE_SYSTEM
