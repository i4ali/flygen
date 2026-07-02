from engine.turn import TurnResult, TurnDecision, CreativeElement
from engine.review import assemble_review, to_brief_dict, to_question_set


def test_assemble_review_fields_decisions_elements():
    turn = TurnResult(status="ready", category="event", headline="Gala",
                      field_sources={"headline": "stated", "category": "inferred"},
                      decisions=[TurnDecision(key="format", value="4:5", options=["4:5", "letter"], reason="feeds")],
                      creative_elements=[CreativeElement(what="Shrine silhouette", sensitivity="sensitive"),
                                         CreativeElement(what="Crimson palette", sensitivity="safe")])
    r = assemble_review(turn)
    assert any(f.key == "headline" and f.source == "stated" for f in r.fields)
    assert r.decisions[0]["key"] == "format" and r.decisions[0]["label"] == "Size / format"
    sel = {e.what: e.selected for e in r.creative_elements}
    assert sel["Crimson palette"] is True and sel["Shrine silhouette"] is False


def test_to_brief_dict_drops_nulls_keeps_sources():
    turn = TurnResult(category="event", headline="Gala", field_sources={"headline": "stated"})
    d = to_brief_dict(turn)
    assert d["headline"] == "Gala" and "subheadline" not in d and d["field_sources"]["headline"] == "stated"


def test_assemble_review_shows_category_display_name_and_option_labels():
    from engine.turn import TurnResult, TurnDecision
    turn = TurnResult(status="ready", category="beauty_salon", headline="Glow",
                      field_sources={"headline": "stated"}, warnings={"website": "looks off"},
                      website="glow",
                      decisions=[TurnDecision(key="format", value="4:5", options=["4:5", "letter"])])
    r = assemble_review(turn)
    cat = next(f for f in r.fields if f.key == "category")
    assert cat.value == "Beauty & Salon"                          # display name, not raw token
    web = next(f for f in r.fields if f.key == "website")
    assert web.warning == "looks off"                             # warning carried through
    dec = r.decisions[0]
    assert dec["supported"] is True                               # supported flag carried
    # option_labels is a {value: label} dict - matches the iOS DecisionProposalDTO [String: String]
    assert dec["option_labels"]["4:5"].startswith("Portrait")     # "4:5" -> "Portrait (4:5) - Instagram"
    assert "Letter" in dec["option_labels"]["letter"]             # "letter" -> "Letter (8.5x11) - Print"


def test_to_brief_dict_keeps_social_handle():
    from engine.turn import TurnResult
    d = to_brief_dict(TurnResult(category="beauty_salon", headline="Glow", social_handle="@glowbar"))
    assert d["social_handle"] == "@glowbar"


def test_to_brief_dict_carries_photo_suggestion_when_set():
    turn = TurnResult(category="music_concert", headline="Live",
                      photo_suggestion="Featuring Ali Zafar? Add a photo and I'll feature it.")
    assert to_brief_dict(turn)["photo_suggestion"].startswith("Featuring Ali Zafar")
    # omitted from the wire when the brain leaves it null
    assert "photo_suggestion" not in to_brief_dict(TurnResult(category="announcement", headline="Closed"))
