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


def test_describe_turn_runs_orchestrator_and_gates_at_questions():
    # Exercises the real describe path (run_turn -> Engine.handle_user_message) with no
    # network: the LLM client is a mock and extract is faked. A sparse event brief leaves
    # critical fields missing, so the turn streams parsed_fields then gates at questions
    # (never reaching the design_brief LLM call).
    from engine.schema import ExtractedBrief
    fake_brief = ExtractedBrief(category="event", headline="Bake Sale")
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.extract.extract_brief", return_value=fake_brief):
        client = TestClient(app)
        with client.stream("POST", "/chat",
                           json={"message": "bake sale flyer", "action": "describe"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: parsed_fields" in body
    assert "event: questions" in body
    assert "Bake Sale" in body          # the parsed brief was serialized into the stream


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


def test_stateless_clarification_answers_reach_generation_across_turns():
    # End-to-end through the stateless HTTP boundary, mirroring the real client: the brief is
    # echoed back between turns. Clarification answers with model-invented keys must survive
    # the answers turn AND the approve round-trip and reach generate_concepts — this is the
    # audit's headline data-loss bug, guarded at the level it actually occurs.
    import json
    from engine.tools import Concept
    from engine.schema import DesignBrief
    captured = {}

    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["project"] = project
        return [Concept("v1", "b64")]

    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", fake_gen), \
         patch("engine.plan.build_design_brief", return_value=DesignBrief(notes="n")):
        client = TestClient(app)
        answers_body = {
            "action": "answers",
            "brief": {"category": "job_posting", "headline": "Now Hiring Baristas",
                      "subheadline": "Join the team", "body_text": "We need baristas"},
            "answers": {"pay_rate": "$18/hr", "venue_address": "88 Front Street",
                        "experience_required": "No experience needed"},
        }
        with client.stream("POST", "/chat", json=answers_body) as r:
            out = "".join(chunk for chunk in r.iter_text())
        # capture the updated brief the server streamed back (what the client resends next turn)
        updated = None
        for block in out.split("\n\n"):
            if "event: parsed_fields" in block:
                for ln in block.splitlines():
                    if ln.startswith("data: "):
                        updated = json.loads(ln[6:])
        assert updated is not None and updated.get("price") == "$18/hr"   # merged + streamed back
        with client.stream("POST", "/chat",
                           json={"action": "approve", "brief": updated, "answers": {}}) as r:
            "".join(chunk for chunk in r.iter_text())

    tc = captured["project"].text_content
    assert tc.price == "$18/hr"                       # alias -> price, survived the round-trip
    assert tc.address == "88 Front Street"            # alias -> address, survived the round-trip
    assert any("experience" in i.lower() for i in (tc.additional_info or []))   # captured, not lost


def test_chat_routes_design_stage_answers_to_review_without_re_asking():
    # action=answers + stage=design must finalize (go to review) without re-asking. It now
    # re-runs the plan once (#2) so the review isn't stale — but never loops back to questions.
    with patch("engine.app.get_client", return_value=MagicMock()):
        client = TestClient(app)
        body = {"action": "answers", "stage": "design",
                "brief": {"category": "event", "headline": "Gala", "venue_name": "Hall", "cta_text": "Come"},
                "answers": {"date": "Sat June 28, 10am"}}
        with client.stream("POST", "/chat", json=body) as r:
            out = "".join(chunk for chunk in r.iter_text())
    assert "event: review" in out
    assert "event: questions" not in out         # no re-ask -> no loop
    assert "event: design_brief" in out          # #2: plan re-run against the updated brief


def test_review_event_serializes_fields_and_decisions():
    import json
    from engine.orchestrator import Event
    from engine.schema import ReviewProposal, FieldProposal
    from engine.decide import DecisionProposal
    proposal = ReviewProposal(
        fields=[FieldProposal(key="headline", value="Bake Sale", source="stated")],
        decisions=[DecisionProposal("format", "Size / format", "4:5", ["4:5", "letter"], "default")],
        plan=None,
    )
    with patch("engine.app.run_turn", return_value=iter([Event("review", proposal)])):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "x"}) as r:
            body = "".join(chunk for chunk in r.iter_text())
    assert "event: review" in body
    data_line = [l for l in body.splitlines() if l.startswith("data: ")][0][6:]
    data = json.loads(data_line)
    assert data["fields"][0]["key"] == "headline"
    assert data["decisions"][0]["key"] == "format"


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


def test_get_generator_uses_openrouter():
    # the real image model (nano-banana-pro) lives on OpenRouter; the generator must be
    # built with use_openrouter=True or it looks for OPENAI_API_KEY and the wrong model id.
    with patch("image_generator.FlyerImageGenerator") as FG:
        from engine.app import get_generator
        get_generator()
    assert FG.call_args.kwargs.get("use_openrouter") is True
