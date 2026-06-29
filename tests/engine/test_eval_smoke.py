from unittest.mock import MagicMock
from engine.eval.run_eval import run_eval, load_briefs
from engine.schema import ExtractedBrief


def test_corpus_has_at_least_20_briefs():
    briefs = load_briefs()
    assert len(briefs) >= 20
    assert any(b["kind"] == "complete" for b in briefs)
    assert any(b["kind"] == "vague" for b in briefs)


def test_eval_harness_runs_over_two_briefs_with_mock_client():
    briefs = [
        {"text": "church bake sale Saturday 10-2 at Grace Hall, proceeds to youth camp, donate at the door",
         "kind": "complete", "expect_category": "nonprofit_charity",
         "expect_fields": ["venue_name", "cta_text"]},
        {"text": "make me a flyer", "kind": "vague", "expect_category": "event", "expect_fields": []},
    ]

    def fake_extract(text, client=None):
        if "bake sale" in text:
            return ExtractedBrief(category="nonprofit_charity", headline="Bake Sale",
                                  date="Sat 10-2", venue_name="Grace Hall", cta_text="Donate")
        return ExtractedBrief(category="event", headline="")  # vague -> missing critical fields

    summary = run_eval(briefs, client=MagicMock(), extract=fake_extract)

    assert isinstance(summary, dict)
    assert summary["n"] == 2
    assert summary["compiled"] == 2                 # both compile via the real FlyerPromptBuilder
    assert summary["question_count_ok"] == 2        # complete -> 0 qs, vague -> 1-3 qs
    assert len(summary["results"]) == 2
    assert summary["errors"] == []
