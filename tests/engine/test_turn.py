from engine.turn import TurnResult, TurnDecision, CreativeElement, validate_decisions

def test_turnresult_parses_minimal():
    t = TurnResult.model_validate({"status": "ready", "category": "event", "headline": "Gala"})
    assert t.status == "ready" and t.headline == "Gala"

def test_additional_info_dedups_case_insensitively():
    t = TurnResult.model_validate({"additional_info": ["Right after Dhuhr prayer",
                                                       "right after dhuhr prayer ",
                                                       "Right after Dhuhr prayer"]})
    assert t.additional_info == ["Right after Dhuhr prayer"]

def test_additional_info_dedups_whitespace_variants():
    # The LLM sometimes repeats a qualifier with invisible whitespace differences
    # (non-breaking space, double space); dedup must treat them as one.
    t = TurnResult.model_validate({"additional_info":
        ["Ladies only", "Ladies only", "Ladies  only"]})
    assert t.additional_info == ["Ladies only"]

def test_additional_info_coerces_bare_string():
    t = TurnResult.model_validate({"additional_info": "Ladies only"})
    assert t.additional_info == ["Ladies only"]

def test_additional_info_dedups_punctuation_variants():
    # Across round-trips the model re-emits the same qualifier with drifting punctuation/case;
    # these must collapse (the recurring "x2/x3" rows).
    t = TurnResult.model_validate({"additional_info":
        ["Right after Dhuhr prayer", "Right after Dhuhr prayer.", "right after dhuhr prayer"]})
    assert t.additional_info == ["Right after Dhuhr prayer"]

def test_additional_info_dedups_invisible_format_char_variants():
    # Zero-width/format chars (ZWSP, word joiner) render as nothing, so these three all show
    # as an identical "Ladies only" row - they must collapse to one extra, not three.
    t = TurnResult.model_validate({"additional_info":
        ["Ladies only", "Ladies\u200b only", "\u2060Ladies only"]})
    assert t.additional_info == ["Ladies only"]

def test_additional_info_drops_facts_already_in_a_field():
    # A fact captured both as a dedicated field AND as an extra must not double up: the extra
    # that echoes the field is dropped; genuinely-standalone extras stay.
    t = TurnResult.model_validate({
        "time": "1:30 PM",
        "additional_info": ["1:30 PM", "Right after Dhuhr prayer", "Ladies only"],
    })
    assert t.additional_info == ["Right after Dhuhr prayer", "Ladies only"]

def test_validate_decisions_flags_offvocab_format():
    t = TurnResult(decisions=[
        TurnDecision(key="format", value="letter"),       # real AspectRatio value
        TurnDecision(key="format", value="billboard"),    # not supported
        TurnDecision(key="visual_style", value="Modern Minimal"),  # display name ok
    ])
    validate_decisions(t)
    by = {(d.key, d.value): d.supported for d in t.decisions}
    assert by[("format", "letter")] is True
    assert by[("format", "billboard")] is False
    assert by[("visual_style", "Modern Minimal")] is True

def test_category_defaults_when_null():
    assert TurnResult.model_validate({"category": None}).category == "announcement"
