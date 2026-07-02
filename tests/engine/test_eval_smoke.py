from unittest.mock import MagicMock
from engine.eval.run_eval import run_eval, load_briefs
from engine.turn import TurnResult, TurnQuestion, TurnDecision, CreativeElement


def test_corpus_loads_with_expected_ids():
    briefs = load_briefs()
    ids = {b["id"] for b in briefs}
    assert {"complete_event", "thin", "floor_event_no_date",
            "offvocab_format", "contact_routing", "sensitive_muharram"} <= ids
    assert all("text" in b and "expect" in b for b in briefs)


def test_eval_harness_runs_over_corpus_with_mocked_interpret():
    briefs = [{"id": "complete_event", "text": "bake sale at Grace Hall", "expect": "ready"},
              {"id": "thin", "text": "make me a flyer", "expect": "need_input"},
              {"id": "sensitive_muharram", "text": "Muharram majlis", "expect": "ready, sensitive element"}]

    def fake_interpret(prior, text, answers, client=None):
        if "make me a flyer" in text:
            return TurnResult(status="need_input",
                              questions=[TurnQuestion(field="purpose", text="What is it for?")])
        if "Muharram" in text:
            return TurnResult(status="ready", category="church_religious",
                              decisions=[TurnDecision(key="format", value="4:5")],
                              creative_elements=[CreativeElement(what="Shrine silhouette", sensitivity="sensitive")])
        return TurnResult(status="ready", category="nonprofit_charity",
                          decisions=[TurnDecision(key="format", value="4:5")])

    summary = run_eval(briefs, client=MagicMock(), interpret=fake_interpret)
    assert summary["n"] == 3
    by = {r["id"]: r for r in summary["results"]}
    assert by["thin"]["status"] == "need_input" and by["thin"]["questions"] == ["purpose"]
    assert by["complete_event"]["status"] == "ready" and "format" in by["complete_event"]["decisions"]
    assert ("Shrine silhouette", "sensitive") in by["sensitive_muharram"]["creative_elements"]
