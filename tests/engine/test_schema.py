from engine.schema import ExtractedBrief, FieldProposal, DesignBrief, ReviewProposal, CreativeProposal


def test_extracted_brief_round_trips_through_dict():
    brief = ExtractedBrief(category="event", headline="Gala", field_sources={"headline": "stated"})
    restored = ExtractedBrief(**brief.model_dump())
    assert restored.category == "event" and restored.headline == "Gala"
    assert restored.field_sources == {"headline": "stated"}


def test_extracted_brief_coerces_null_category_to_default():
    assert ExtractedBrief.model_validate({"category": None}).category == "announcement"


def test_extracted_brief_dedups_additional_info():
    b = ExtractedBrief.model_validate({"additional_info": ["Ladies only", "ladies only ", "Bring a friend"]})
    assert b.additional_info == ["Ladies only", "Bring a friend"]


def test_extracted_brief_coerces_additional_info_string_to_list():
    b = ExtractedBrief.model_validate({"category": "event", "additional_info": "Lots of vendors"})
    assert b.additional_info == ["Lots of vendors"]


def test_extracted_brief_drops_null_field_sources_values():
    b = ExtractedBrief.model_validate({"category": "event",
                                       "field_sources": {"headline": "stated", "date": None}})
    assert b.field_sources == {"headline": "stated"}


def test_review_proposal_holds_fields_decisions_creative_elements():
    r = ReviewProposal(fields=[FieldProposal(key="headline", value="Gala", source="stated")],
                       decisions=[{"key": "format", "value": "4:5"}],
                       creative_elements=[CreativeProposal(what="Gold accents")],
                       plan=DesignBrief(notes="n", checklist=["c"], recommendations=["r"]))
    assert r.fields[0].key == "headline"
    assert r.creative_elements[0].selected is True
    assert r.plan.notes == "n"
