from unittest.mock import MagicMock
from engine.orchestrator import Engine, Event
from engine.turn import TurnResult, TurnQuestion, TurnDecision
from engine.tools import Concept


def _engine_with(turn, generate=None):
    eng = Engine(client=MagicMock(), interpret_fn=lambda *a, **k: turn,
                 gate_fn=lambda *a, **k: True,   # bypass the flyer-vs-not gate; these test the brain
                 generate_concepts=generate or (lambda *a, **k: [Concept("v1", "b64")]),
                 generator=MagicMock())
    return eng


def test_interpret_failure_yields_friendly_error_not_raw_exception():
    # The model call can blow up (e.g. truncated JSON -> Pydantic ValidationError). The user must
    # never see that raw text (the device once showed "1 validation error for TurnResult ...").
    def boom(*a, **k):
        raise ValueError("1 validation error for TurnResult\nInvalid JSON: EOF while parsing a list")
    eng = Engine(client=MagicMock(), interpret_fn=boom, gate_fn=lambda *a, **k: True)
    events = list(eng.handle_user_message("big religious multi-night program"))
    assert [e.kind for e in events] == ["error"]                       # nothing leaks past the catch
    msg = events[0].payload
    assert "validation error" not in msg.lower() and "json" not in msg.lower()   # no raw internals
    assert "again" in msg.lower()                                                # friendly + recoverable


def test_need_input_emits_questions_not_review():
    turn = TurnResult(status="need_input", category="event",
                      questions=[TurnQuestion(field="date", text="What day?")])
    kinds = [e.kind for e in _engine_with(turn).handle_user_message("party")]
    assert "questions" in kinds and "review" not in kinds


def test_ready_emits_review():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="4:5")])
    events = list(_engine_with(turn).handle_user_message("gala sat at hall"))
    assert "review" in [e.kind for e in events]


def test_non_flyer_message_deflects_without_running_the_brain():
    # A question / greeting / off-topic message never reaches the expensive design brain: the gate
    # deflects it with a single assistant `note`, and interpret is never called.
    def brain_must_not_run(*a, **k):
        raise AssertionError("interpret must not run for a deflected message")
    eng = Engine(client=MagicMock(), interpret_fn=brain_must_not_run,
                 gate_fn=lambda *a, **k: False)
    events = list(eng.handle_user_message("do you accept photos as samples?"))
    assert [e.kind for e in events] == ["note"]        # only the deflection, no parsed_fields/review
    assert "flyer" in events[0].payload.lower()        # points the user back to flyers


def test_approval_generates_concepts():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="letter")])
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["aspect"] = project.output.aspect_ratio
        return [Concept("v1", "b64")]
    eng = _engine_with(turn, generate=fake_gen)
    list(eng.handle_user_message("gala"))          # establishes self.turn
    events = list(eng.handle_approval(decision_overrides={"format": "letter"}))
    from models import AspectRatio
    assert "concepts" in [e.kind for e in events]
    assert captured["aspect"] == AspectRatio.LETTER


def test_approval_passes_user_photos_to_generate():
    import base64, os
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      decisions=[TurnDecision(key="format", value="4:5")])
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["photo_paths"] = user_photo_paths
        captured["user_photo_path"] = project.user_photo_path
        captured["existed_during_gen"] = bool(user_photo_paths) and os.path.exists(user_photo_paths[0])
        return [Concept("v1", "b64")]
    eng = Engine(client=MagicMock(), interpret_fn=lambda *a, **k: turn,
                 generate_concepts=fake_gen, generator=MagicMock())
    list(eng.handle_user_message("gala"))            # sets self.turn
    b64 = base64.b64encode(b"fakeimage").decode()
    list(eng.handle_approval(user_photos_b64=[b64]))
    assert captured["photo_paths"] and captured["user_photo_path"] == captured["photo_paths"][0]
    assert captured["existed_during_gen"]                       # temp file present during generation
    assert not os.path.exists(captured["photo_paths"][0])       # and cleaned up afterwards


def test_approval_rebuilds_turn_from_brief_when_stateless():
    from models import AspectRatio
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["aspect"] = project.output.aspect_ratio
        captured["headline"] = project.text_content.headline
        return [Concept("v1", "b64")]
    eng = Engine(client=MagicMock(), generate_concepts=fake_gen, generator=MagicMock())
    eng.brief = {"category": "event", "headline": "Gala"}      # stateless: no self.turn
    events = list(eng.handle_approval(decision_overrides={"format": "letter"}))
    assert "concepts" in [e.kind for e in events]              # not an error
    assert captured["aspect"] == AspectRatio.LETTER            # decision_overrides applied on rebuilt turn
    assert captured["headline"] == "Gala"


def test_stateless_approve_round_trips_social_handle_to_generation():
    from engine.review import to_brief_dict
    turn = TurnResult(status="ready", category="beauty_salon", headline="Glow", social_handle="@glowbar",
                      decisions=[TurnDecision(key="format", value="4:5")])
    brief = to_brief_dict(turn)
    assert brief.get("social_handle") == "@glowbar"               # survives persistence
    captured = {}
    def fake_gen(project, generator=None, n=3, user_photo_paths=None):
        captured["handle"] = project.text_content.social_handle
        return [Concept("v1", "b64")]
    eng = Engine(client=MagicMock(), generate_concepts=fake_gen, generator=MagicMock())
    eng.brief = brief                                             # stateless approve: only brief posted back
    list(eng.handle_approval())
    assert captured["handle"] == "@glowbar"                       # reached generation


def test_refine_rebuilds_project_from_brief_when_stateless():
    import base64
    captured = {}
    def fake_refine(project, path, instruction, generator=None, mode="edit"):
        captured["project"] = project
        return Concept("refined", "b64")
    eng = Engine(client=MagicMock(), refine_concept=fake_refine, generator=MagicMock())
    eng.brief = {"category": "event", "headline": "Gala"}        # client posts brief back; no self.project
    b64 = base64.b64encode(b"img").decode()
    events = list(eng.handle_refine(prior_image_b64=b64, instruction="brighter"))
    assert [e.kind for e in events] == ["refined"]               # not an error
    assert captured["project"].text_content.headline == "Gala"   # project rebuilt from brief
