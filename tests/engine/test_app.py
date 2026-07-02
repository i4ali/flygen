import json
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from engine.app import app
from engine.orchestrator import Event


def test_chat_streams_events_as_sse():
    fake_events = [Event("parsed_fields", {"headline": "Bake Sale"}), Event("questions", {"questions": []})]
    with patch("engine.app.run_turn", return_value=iter(fake_events)):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "bake sale flyer"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: parsed_fields" in body
    assert "event: questions" in body


def test_describe_turn_streams_parsed_fields_then_questions():
    from engine.turn import TurnResult, TurnQuestion
    turn = TurnResult(status="need_input", category="event", headline="Bake Sale",
                      questions=[TurnQuestion(field="date", text="What day?")])
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.interpret.interpret", return_value=turn):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "bake sale", "action": "describe"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: parsed_fields" in body
    assert "event: questions" in body
    assert "Bake Sale" in body


def test_chat_routes_approve_to_concepts_event():
    from engine.tools import Concept
    fake_concepts = [Concept("v1", "b64"), Concept("v2", "b64"), Concept("v3", "b64")]
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", return_value=fake_concepts):
        client = TestClient(app)
        body = {
            "action": "approve",
            "brief": {"category": "event", "headline": "Bake Sale", "date": "Sat",
                      "venue_name": "Hall", "cta_text": "Come"},
            "answers": {"destination": "instagram"},
        }
        with client.stream("POST", "/chat", json=body) as r:
            out = "".join(chunk for chunk in r.iter_text())
    assert "event: concepts" in out


def test_review_event_serializes_with_creative_elements():
    from engine.orchestrator import Event
    from engine.schema import ReviewProposal, FieldProposal, CreativeProposal
    proposal = ReviewProposal(
        fields=[FieldProposal(key="headline", value="Gala", source="stated")],
        decisions=[{"key": "format", "label": "Size / format", "value": "4:5",
                    "options": ["4:5", "letter"], "reason": "feeds", "supported": True}],
        creative_elements=[CreativeProposal(what="Gold accents", sensitivity="safe", selected=True)],
        plan=None)
    with patch("engine.app.run_turn", return_value=iter([Event("review", proposal)])):
        with TestClient(app).stream("POST", "/chat", json={"message": "x"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: review" in body
    data = json.loads([l for l in body.splitlines() if l.startswith("data: ")][0][6:])
    assert data["fields"][0]["key"] == "headline"
    assert data["creative_elements"][0]["what"] == "Gold accents"


def test_chat_approve_threads_user_photos_to_generation():
    # uploaded photos arrive as base64 on the approve turn and reach generate_concepts.
    import base64
    from engine.tools import Concept
    captured = {}

    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["paths"] = list(user_photo_paths or [])
        return [Concept("v1", "b64"), Concept("v2", "b64"), Concept("v3", "b64")]

    b64 = base64.b64encode(b"img-bytes").decode()
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", fake_gen):
        client = TestClient(app)
        body = {"action": "approve",
                "brief": {"category": "music_concert", "headline": "Show"},
                "user_photos_b64": [b64]}
        with client.stream("POST", "/chat", json=body) as r:
            out = "".join(chunk for chunk in r.iter_text())
    assert "event: concepts" in out
    assert len(captured["paths"]) == 1


def test_approve_threads_selected_elements_to_imagery():
    from engine.tools import Concept
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["imagery"] = project.imagery_description
        return [Concept("v1", "b64")]
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", fake_gen):
        client = TestClient(app)
        body = {"action": "approve",
                "brief": {"category": "event", "headline": "Gala"},
                "selected_elements": ["Gold foil accents", "Shrine silhouette"]}
        with client.stream("POST", "/chat", json=body) as r:
            "".join(chunk for chunk in r.iter_text())
    assert "Gold foil accents" in captured["imagery"] and "Shrine silhouette" in captured["imagery"]


def test_get_generator_uses_openrouter():
    # the real image model (nano-banana-pro) lives on OpenRouter; the generator must be
    # built with use_openrouter=True or it looks for OPENAI_API_KEY and the wrong model id.
    with patch("image_generator.FlyerImageGenerator") as FG:
        from engine.app import get_generator
        get_generator()
    assert FG.call_args.kwargs.get("use_openrouter") is True
