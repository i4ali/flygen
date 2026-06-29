"""Contract tests that exercise the REAL model-output parse path and the SSE event shapes
the iOS app decodes.

Why this file exists: an earlier smoke test mocked `extract_brief` wholesale, so it never
saw the actual GLM output and missed that the model emits `null` inside `field_sources`
(and for non-optional DesignBrief fields). These tests drive the real OpenRouterClient
parse path with realistic raw JSON, and assert every streamed event matches the iOS DTOs.
"""
import json
from unittest.mock import patch, MagicMock

from fastapi.testclient import TestClient

from engine.app import app
from engine.openrouter_client import OpenRouterClient
from engine.extract import extract_brief
from engine.plan import build_design_brief
from engine.rubrics import rubric_for
from engine.schema import ExtractedBrief, DesignBrief
from engine.tools import Concept


def _fake_oai(content: str):
    """An OpenAI-compatible stand-in whose chat.completions.create returns `content`
    as the assistant message — i.e. a recorded raw model response, no network."""
    oai = MagicMock()
    msg = MagicMock(); msg.content = content
    choice = MagicMock(); choice.message = msg
    resp = MagicMock(); resp.choices = [choice]
    oai.chat.completions.create.return_value = resp
    return oai


# --- real parse path tolerates the model's nulls (the bugs that reached the device) ---

def test_extract_brief_survives_model_nulls_in_field_sources():
    # The model is told to "use null for any value you cannot infer" and applies that
    # inside field_sources too. This is the exact payload class that crashed extract on
    # the device. Drives OpenRouterClient.parse -> _to_model -> ExtractedBrief for real.
    raw = json.dumps({
        "category": "nonprofit_charity", "headline": "Bake Sale",
        "subheadline": None, "cta_text": None,
        "field_sources": {"headline": "stated", "category": "inferred",
                          "address": None, "price": None, "destination": None},
    })
    client = OpenRouterClient(api_key="test")
    client.messages._oai = _fake_oai(raw)   # parse() uses messages._oai, captured at construction
    brief = extract_brief("bake sale flyer", client=client)
    assert brief.headline == "Bake Sale"
    assert brief.field_sources == {"headline": "stated", "category": "inferred"}  # nulls dropped


def test_build_design_brief_survives_model_nulls():
    # Same failure class one turn later: DesignBrief's fields are non-optional; the model
    # may null them. The real parse path must coerce to defaults, not raise.
    raw = json.dumps({"notes": None, "checklist": None, "recommendations": ["Add a donation QR"]})
    client = OpenRouterClient(api_key="test")
    client.messages._oai = _fake_oai(raw)   # parse() uses messages._oai, captured at construction
    brief = ExtractedBrief(category="nonprofit_charity", headline="Bake Sale")
    design = build_design_brief(brief, rubric_for(brief.category), answers={}, client=client)
    assert design.notes == ""
    assert design.checklist == []
    assert design.recommendations == ["Add a donation QR"]


# --- streamed event shapes match the iOS DTO contract (guards future regressions) ---

def _frames(body: str):
    """Parse raw SSE text into [(event, json)] the way the iOS client must."""
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


def test_describe_event_shapes_match_ios_dtos():
    fake = ExtractedBrief(category="nonprofit_charity", headline="Bake Sale")
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.extract.extract_brief", return_value=fake):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"message": "bake sale", "action": "describe"}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["parsed_fields", "questions"]
    questions = dict(fs)["questions"]["questions"]
    assert questions and all(isinstance(q["field"], str) and isinstance(q["text"], str) for q in questions)


def test_plan_and_review_event_shapes_match_ios_dtos():
    brief_dict = {"category": "nonprofit_charity", "headline": "Bake Sale", "date": "Sat 10-2",
                  "venue_name": "Grace Hall", "cta_text": "Come!", "field_sources": {}}
    design = DesignBrief(notes="Keep it warm.", checklist=["Big headline"],
                         recommendations=["Add a QR"])
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.plan.build_design_brief", return_value=design):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"action": "answers", "brief": brief_dict,
                                                  "answers": {"cta_text": "Come!"}}) as r:
            fs = _frames("".join(r.iter_text()))
    # `note` is a conversational assistant line; ignore it for the structural check.
    assert [k for k, _ in fs if k != "note"] == ["parsed_fields", "design_brief", "review"]
    d = dict(fs)["design_brief"]
    assert isinstance(d["notes"], str) and isinstance(d["checklist"], list) and isinstance(d["recommendations"], list)
    rev = dict(fs)["review"]
    assert all({"key", "value", "source"} <= f.keys() for f in rev["fields"])
    assert all({"key", "label", "value", "options", "reason"} <= x.keys() for x in rev["decisions"])
    assert rev["plan"] is None or "notes" in rev["plan"]


def test_approve_concepts_event_shape_matches_ios_dto():
    brief_dict = {"category": "nonprofit_charity", "headline": "Bake Sale", "field_sources": {}}
    fake_concepts = [Concept("v1", "QUJD"), Concept("v2", "QUJD"), Concept("v3", None, "boom")]
    with patch("engine.app.get_client", return_value=MagicMock()), \
         patch("engine.app.get_generator", return_value=MagicMock()), \
         patch("engine.tools.generate_concepts", return_value=fake_concepts):
        client = TestClient(app)
        with client.stream("POST", "/chat", json={"action": "approve", "brief": brief_dict,
                                                  "answers": {"destination": "instagram"}}) as r:
            fs = _frames("".join(r.iter_text()))
    assert [k for k, _ in fs] == ["concepts"]
    cs = dict(fs)["concepts"]
    assert len(cs) == 3 and all(isinstance(c["version_id"], str) and "image_base64" in c and "error" in c for c in cs)
