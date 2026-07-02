"""Contract tests: drive the REAL model-output parse path (OpenRouterClient.parse -> TurnResult)
and assert the SSE event shapes the iOS app decodes. Guards the frozen wire DTOs and tolerance
for model-emitted nulls that once crashed the device."""
import json
from unittest.mock import patch, MagicMock

from fastapi.testclient import TestClient

from engine.app import app
from engine.openrouter_client import OpenRouterClient
from engine.interpret import interpret
from engine.tools import Concept


def _fake_oai(content: str):
    oai = MagicMock()
    msg = MagicMock(); msg.content = content
    choice = MagicMock(); choice.message = msg
    resp = MagicMock(); resp.choices = [choice]
    oai.chat.completions.create.return_value = resp
    return oai


def _fake_oai_seq(*responses):
    """OAI stub that returns (content, finish_reason) pairs across successive create() calls
    and records each call's kwargs (so a test can assert it retried with a bigger budget).
    The last pair is reused if create() is called more times than pairs given."""
    oai = MagicMock()
    calls = []

    def _create(**kwargs):
        calls.append(kwargs)
        content, finish = responses[min(len(calls) - 1, len(responses) - 1)]
        msg = MagicMock(); msg.content = content
        choice = MagicMock(); choice.message = msg; choice.finish_reason = finish
        resp = MagicMock(); resp.choices = [choice]
        return resp

    oai.chat.completions.create.side_effect = _create
    oai._calls = calls
    return oai


# A model answer cut off mid-array (the real device failure: an inner object closed, but the
# enclosing `creative_elements` array and the outer object never did). Mirrors the screenshot.
_TRUNCATED_JSON = ('{\n  "status": "ready",\n  "category": "event",\n'
                   '  "creative_elements": [\n    {"what": "Gold accents", "sensitivity": "safe"}')


def test_parse_retries_and_recovers_when_output_truncated():
    """finish_reason=='length' means the JSON answer was chopped off; the shim must retry once
    with a larger budget and return the recovered turn instead of raising."""
    complete = json.dumps({"status": "ready", "category": "event", "headline": "Majlis Program"})
    oai = _fake_oai_seq((_TRUNCATED_JSON, "length"), (complete, "stop"))
    client = OpenRouterClient(api_key="test")
    client.messages._oai = oai
    turn = interpret(prior_brief=None, user_text="big multi-night program", answers=None, client=client)
    assert turn.headline == "Majlis Program"                          # recovered via the retry
    assert len(oai._calls) == 2                                       # it actually retried
    assert oai._calls[1]["max_tokens"] > oai._calls[0]["max_tokens"]  # ...with more room


def test_unparseable_model_output_surfaces_friendly_error_frame():
    """Even when the answer is still unusable after the retry, the user must get a friendly,
    recoverable message - never the raw Pydantic/JSON dump that reached the device."""
    oai = _fake_oai_seq((_TRUNCATED_JSON, "length"))   # every attempt truncates
    client_obj = OpenRouterClient(api_key="test"); client_obj.messages._oai = oai
    with patch("engine.app.get_client", return_value=client_obj):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "big multi-night majlis program",
                                                   "action": "describe"}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["error"]
    err = dict(fs)["error"]
    assert "validation error" not in err.lower() and "json" not in err.lower()   # no raw internals
    assert "again" in err.lower()                                                 # friendly + recoverable


def _frames(body: str):
    out = []
    for block in body.split("\n\n"):
        block = block.strip("\n")
        if not block:
            continue
        ev, data = "message", []
        for line in block.split("\n"):
            if line.startswith("event:"):
                ev = line[6:].strip()
            elif line.startswith("data:"):
                data.append(line[5:].lstrip(" "))
        out.append((ev, json.loads("\n".join(data))))
    return out


def test_interpret_survives_model_nulls():
    raw = json.dumps({
        "status": "ready", "category": None, "headline": "Bake Sale",
        "field_sources": {"headline": "stated", "category": "inferred", "address": None},
    })
    client = OpenRouterClient(api_key="test")
    client.messages._oai = _fake_oai(raw)
    turn = interpret(prior_brief=None, user_text="bake sale flyer", answers=None, client=client)
    assert turn.headline == "Bake Sale"
    assert turn.category == "announcement"                       # null category -> default
    assert turn.field_sources == {"headline": "stated", "category": "inferred"}  # nulls dropped


def test_describe_event_shapes_match_ios_dtos():
    from engine.turn import TurnResult, TurnQuestion
    turn = TurnResult(status="need_input", category="nonprofit_charity", headline="Bake Sale",
                      questions=[TurnQuestion(field="date", text="What day?")])
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.interpret.interpret", return_value=turn):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "bake sale", "action": "describe"}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["parsed_fields", "questions"]
    questions = dict(fs)["questions"]["questions"]
    assert questions and all(isinstance(q["field"], str) and isinstance(q["text"], str) for q in questions)


def test_review_event_shape_matches_ios_dto():
    from engine.turn import TurnResult, TurnDecision, CreativeElement
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      field_sources={"headline": "stated"},
                      decisions=[TurnDecision(key="format", value="4:5", options=["4:5", "letter"], reason="feeds")],
                      creative_elements=[CreativeElement(what="Gold accents", sensitivity="safe")])
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.interpret.interpret", return_value=turn):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "gala", "action": "describe"}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["parsed_fields", "review"]
    rev = dict(fs)["review"]
    assert all({"key", "value", "source"} <= f.keys() for f in rev["fields"])
    assert all({"key", "label", "value", "options", "option_labels", "reason", "supported"} <= x.keys() for x in rev["decisions"])
    assert all({"what", "why", "sensitivity", "selected"} <= e.keys() for e in rev["creative_elements"])


def test_approve_concepts_event_shape_matches_ios_dto():
    brief_dict = {"category": "nonprofit_charity", "headline": "Bake Sale", "field_sources": {}}
    fake_concepts = [Concept("v1", "QUJD"), Concept("v2", "QUJD"), Concept("v3", None, "boom")]
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", return_value=fake_concepts):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"action": "approve", "brief": brief_dict}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["concepts"]
    cs = dict(fs)["concepts"]
    assert len(cs) == 3 and all(isinstance(c["version_id"], str) and "image_base64" in c and "error" in c for c in cs)
