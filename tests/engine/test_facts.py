from facts import normalize_fact, dedup_facts, without_represented


def test_normalize_folds_case_whitespace_and_edge_punctuation():
    # nbsp, double space, trailing period, and case all fold to the same key.
    keys = {normalize_fact("Ladies only"), normalize_fact("Ladies only"),
            normalize_fact("Ladies  only"), normalize_fact("Ladies only."),
            normalize_fact("LADIES ONLY"), normalize_fact("  • Ladies only!  ")}
    assert keys == {"ladies only"}


def test_normalize_keeps_interior_content_distinct():
    assert normalize_fact("7:30 PM") != normalize_fact("7 PM")
    assert normalize_fact("Free parking") != normalize_fact("Free")
    assert normalize_fact(123) == "" and normalize_fact(None) == ""


def test_normalize_ignores_invisible_format_chars():
    # Unicode format chars (ZWSP, word joiner, BOM, directional marks) render as nothing, so
    # variants that LOOK identical on screen must produce the same key - otherwise they all
    # survive dedup and show as duplicate "extra" rows. Escapes, not literals, so the
    # difference stays visible to readers of this file.
    variants = ["Ladies only", "Ladies\u200b only", "Ladies only\u200e",
                "\u2060Ladies only", "Ladies\ufeff only"]
    assert {normalize_fact(v) for v in variants} == {"ladies only"}
    # But an invisible char REPLACING the space renders as "Ladiesonly" - visibly different,
    # so it must stay a distinct key. Conservative, never fuzzy.
    assert normalize_fact("Ladies\u200bonly") != normalize_fact("Ladies only")


def test_dedup_facts_collapses_invisible_char_variants():
    assert dedup_facts(["Ladies only", "Ladies\u200b only", "\u2060Ladies only"]) == ["Ladies only"]


def test_dedup_facts_keeps_first_display_form_and_collapses_variants():
    assert dedup_facts(["Ladies only", "ladies only.", "Ladies only"]) == ["Ladies only"]


def test_dedup_facts_coerces_and_guards():
    assert dedup_facts("Solo act") == ["Solo act"]
    assert dedup_facts(None) is None
    assert dedup_facts(123) is None                 # non-list -> None, no pydantic crash
    assert dedup_facts(["", "   ", "Real"]) == ["Real"]


def test_without_represented_drops_field_echoes_only():
    # "Free" echoes the price field -> dropped; the standalone qualifier stays.
    assert without_represented(["Free", "Doors 7 PM"], ["Free", "Cypress"]) == ["Doors 7 PM"]
    # normalized match (case/space) still counts; everything represented -> None.
    assert without_represented(["7 PM "], ["7 pm"]) is None
    # a superstring is NOT a match - conservative, never fuzzy.
    assert without_represented(["Free parking"], ["Free"]) == ["Free parking"]
