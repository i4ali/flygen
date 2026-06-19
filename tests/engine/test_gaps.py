from engine.schema import ExtractedBrief
from engine.gaps import missing_critical_fields, build_questions


def test_complete_brief_yields_no_questions():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", date="Sat", venue_name="Grace Hall",
        cta_text="Come by", website="x.org",
    )
    assert missing_critical_fields(brief) == []
    assert build_questions(brief).questions == []


def test_vague_brief_asks_for_critical_gaps_only():
    brief = ExtractedBrief(category="event", headline="Bake Sale")  # missing date, venue, cta
    missing = missing_critical_fields(brief)
    assert "date" in missing and "venue_name" in missing
    qs = build_questions(brief)
    assert 0 < len(qs.questions) <= 3            # adaptive: a few, never a fixed script
    assert any("date" in q.field for q in qs.questions)
