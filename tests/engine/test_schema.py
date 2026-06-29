from engine.schema import (
    ExtractedBrief, DesignBrief, to_flyer_project, field_source, FieldProposal,
    build_field_proposals, reconcile_field_sources,
)
from models import FlyerProject, FlyerCategory, AspectRatio


def test_extracted_brief_converts_to_flyer_project():
    brief = ExtractedBrief(
        category="nonprofit_charity",
        headline="Bake Sale",
        date="Sat Jun 14 · 10–2",
        venue_name="Grace Hall",
        cta_text="Donate online",
    )
    project = to_flyer_project(brief)
    assert isinstance(project, FlyerProject)
    assert project.category == FlyerCategory.NONPROFIT_CHARITY
    assert project.text_content.headline == "Bake Sale"
    assert project.text_content.venue_name == "Grace Hall"
    # sane default format when the engine hasn't decided yet
    assert project.output.aspect_ratio == AspectRatio.PORTRAIT_4_5


def test_additional_info_coerces_a_bare_string_to_a_list():
    # Real crash from the "Spring craft fair" run: the extraction model returned
    # additional_info as a bare string ("Featuring lots of local vendors") instead of a list,
    # and ExtractedBrief raised a pydantic list_type error that surfaced in the chat. The
    # schema must coerce it (mirroring the other tolerant before-validators), never reject.
    import json
    brief = ExtractedBrief.model_validate_json(json.dumps({
        "category": "event", "headline": "Spring Craft Fair",
        "additional_info": "Featuring lots of local vendors"}))
    assert brief.additional_info == ["Featuring lots of local vendors"]


def test_additional_info_tolerates_list_nulls_and_empties():
    assert ExtractedBrief(additional_info=["a", None, "  ", "b"]).additional_info == ["a", "b"]
    assert ExtractedBrief(additional_info=None).additional_info is None
    assert ExtractedBrief(additional_info="   ").additional_info is None     # empty string -> nothing to add


def test_additional_info_survives_brief_round_trip_to_project():
    # The captured extras must survive the stateless client round-trip (model_dump ->
    # reconstruct on the next turn) and reach the generated project.
    brief = ExtractedBrief(category="job_posting", headline="Hi",
                           additional_info=["experience required: No experience needed"])
    restored = ExtractedBrief(**brief.model_dump())
    assert restored.additional_info == ["experience required: No experience needed"]
    tc = to_flyer_project(restored).text_content
    assert tc.additional_info == ["experience required: No experience needed"]


def test_is_non_value_matches_meta_answers_but_keeps_real_values():
    from engine.schema import is_non_value
    for v in ["No", "none", "N/A", "nope", "Yes", "sure", "idk", "not sure",
              "you decide", "whatever", "doesn't matter", "-"]:
        assert is_non_value(v), v
    for v in ["Free", "Unpaid", "TBD", "TBA", "$18/hr", "88 Front Street",
              "No experience needed", "Saturday"]:
        assert not is_non_value(v), v


def test_to_flyer_project_drops_non_value_field_values():
    # Last-mile guard: a meta/non-answer that reached the brief by ANY path must not render.
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring",
                           price="No", phone="n/a", cta_text="Apply In Store")
    tc = to_flyer_project(brief).text_content
    assert tc.price is None and tc.phone is None       # dropped — no "No"/"n/a" on the flyer
    assert tc.cta_text == "Apply In Store"             # real value kept


def test_sanitize_brief_nulls_non_value_fields_but_keeps_category_and_real_values():
    from engine.schema import sanitize_brief
    brief = ExtractedBrief(category="event", headline="Gala", price="No",
                           venue_name="you decide", date="Saturday")
    sanitize_brief(brief)
    assert brief.price is None and brief.venue_name is None   # meta-answers dropped
    assert brief.date == "Saturday"                           # real value kept
    assert brief.category == "event"                          # category never touched


def test_is_valid_website_accepts_wellformed_and_rejects_junk():
    # owner rule: accept any well-formed web address at face value (a 3rd-party domain like
    # ticketmaster.com is fine — the user may really use it); reject non-URL prose.
    from engine.schema import is_valid_website
    for v in ["ticketmaster.com", "Ticketmaster.com", "https://shop.example.com/sale",
              "www.foo.org", "store.co.uk", "instagram.com/mystore", "http://a.io"]:
        assert is_valid_website(v), v
    for v in ["idk", "my store", "call us", "facebook", "123", "", "ask in store", "foo@bar.com"]:
        assert not is_valid_website(v), v


def test_contact_detectors_are_disjoint():
    # Routing a contact answer relies on phone / email / website being mutually exclusive, so a
    # value matches at most one channel. (This is why a phone given to a "website" question can be
    # re-routed safely without ever stealing a real URL.)
    from engine.schema import looks_like_phone, looks_like_email, is_valid_website
    phones = ["555-0123", "(555) 012-3456", "+1 555 012 3456", "5550123"]
    emails = ["rsvp@riverside.org", "Maria.Lopez@shelter.co.uk"]
    sites = ["ticketmaster.com", "greenhouse.com/tickets", "https://a.io"]
    neither = ["Ticketmaster", "Call us", "$18", "idk", "", "123"]
    for v in phones:
        assert looks_like_phone(v) and not looks_like_email(v) and not is_valid_website(v), v
    for v in emails:
        assert looks_like_email(v) and not looks_like_phone(v) and not is_valid_website(v), v
    for v in sites:
        assert is_valid_website(v) and not looks_like_phone(v) and not looks_like_email(v), v
    for v in neither:
        assert not looks_like_phone(v) and not looks_like_email(v), v


def test_sanitize_brief_keeps_malformed_website_for_review_flagging():
    # owner decision: never silently drop a website the user entered — keep it so the review can
    # show + flag it. (A bare non-answer like "idk" is still dropped by the non-value rule.)
    from engine.schema import sanitize_brief
    kept = sanitize_brief(ExtractedBrief(category="sale_promo", headline="Sale", website="Ticketmaster"))
    assert kept.website == "Ticketmaster"            # malformed but real -> kept for flagging
    good = sanitize_brief(ExtractedBrief(category="sale_promo", headline="Sale", website="ticketmaster.com"))
    assert good.website == "ticketmaster.com"
    dropped = sanitize_brief(ExtractedBrief(category="sale_promo", headline="Sale", website="idk"))
    assert dropped.website is None                    # a non-answer is still dropped


def test_to_flyer_project_keeps_user_website_even_if_malformed():
    # the user saw it flagged in review and approved -> render what they entered (don't silently
    # strip it at the last mile). A bare decline ("no") is still dropped.
    tc = to_flyer_project(ExtractedBrief(category="sale_promo", headline="Sale",
                                         website="Ticketmaster")).text_content
    assert tc.website == "Ticketmaster"
    tc2 = to_flyer_project(ExtractedBrief(category="sale_promo", headline="Sale",
                                          website="no")).text_content
    assert tc2.website is None


def test_build_field_proposals_flags_malformed_website_only():
    # the review marks a malformed website so the UI can highlight it; valid ones carry no flag,
    # and no other field is ever flagged.
    flagged = {p.key: p for p in build_field_proposals(
        ExtractedBrief(category="sale_promo", headline="Sale", website="Ticketmaster"))}
    assert flagged["website"].warning and "web address" in flagged["website"].warning.lower()
    ok = {p.key: p for p in build_field_proposals(
        ExtractedBrief(category="sale_promo", headline="Sale", website="ticketmaster.com"))}
    assert ok["website"].warning is None
    assert ok["headline"].warning is None            # non-website fields never flagged


def test_unknown_category_falls_back_to_announcement():
    project = to_flyer_project(ExtractedBrief(category="not_a_real_category", headline="Hi"))
    assert project.category == FlyerCategory.ANNOUNCEMENT


def test_brief_aspect_ratio_drives_project_output():
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala", aspect_ratio="9:16"))
    assert project.output.aspect_ratio == AspectRatio.STORY_9_16


def test_brief_without_aspect_ratio_defaults_to_portrait():
    project = to_flyer_project(ExtractedBrief(category="event", headline="Gala"))
    assert project.output.aspect_ratio == AspectRatio.PORTRAIT_4_5


def test_to_flyer_project_accepts_category_display_name():
    # #5: the review surfaces the category as a display name; sending it back must resolve.
    project = to_flyer_project(ExtractedBrief(category="Job Posting", headline="Hi"))
    assert project.category == FlyerCategory.JOB_POSTING


def test_build_field_proposals_shows_category_display_name():
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring",
                           field_sources={"category": "inferred"})
    by = {p.key: p for p in build_field_proposals(brief)}
    assert by["category"].value == "Job Posting"        # not the raw "job_posting"


def test_null_category_coerces_to_announcement():
    # the model may emit category: null for ultra-vague briefs
    brief = ExtractedBrief(category=None, headline="Hi")
    assert brief.category == "announcement"
    assert to_flyer_project(brief).category == FlyerCategory.ANNOUNCEMENT


def test_field_sources_round_trip_and_helper_defaults_to_inferred():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", destination="instagram",
        field_sources={"headline": "stated", "category": "inferred"},
    )
    assert brief.destination == "instagram"
    assert field_source(brief, "headline") == "stated"
    assert field_source(brief, "category") == "inferred"
    assert field_source(brief, "venue_name") == "inferred"   # unknown -> conservative


def test_build_field_proposals_includes_populated_fields_with_source():
    brief = ExtractedBrief(
        category="event", headline="Bake Sale", venue_name="Grace Hall",
        field_sources={"headline": "stated", "venue_name": "stated", "category": "inferred"},
    )
    props = build_field_proposals(brief)
    by_key = {p.key: p for p in props}
    assert isinstance(props[0], FieldProposal)
    assert by_key["headline"].value == "Bake Sale" and by_key["headline"].source == "stated"
    assert by_key["category"].source == "inferred"
    assert "subheadline" not in by_key          # empty fields are omitted


def test_field_sources_drops_null_values_from_model_output():
    # GLM is told to "use null for any value you cannot infer" and applies that inside
    # field_sources too, emitting e.g. {"headline":"stated","address":null,...}. A strict
    # Dict[str, str] rejects those nulls (the real extract crash); the schema must drop
    # them, not raise. This mirrors extract's _to_model -> model_validate_json path.
    import json
    raw = json.dumps({
        "category": "event", "headline": "Bake Sale",
        "field_sources": {"headline": "stated", "address": None, "price": None},
    })
    brief = ExtractedBrief.model_validate_json(raw)
    assert brief.field_sources == {"headline": "stated"}
    assert field_source(brief, "headline") == "stated"
    assert field_source(brief, "address") == "inferred"   # dropped null -> conservative default


def test_field_sources_null_whole_value_coerces_to_empty():
    # the model may also emit field_sources: null entirely
    brief = ExtractedBrief(category="event", headline="Hi", field_sources=None)
    assert brief.field_sources == {}


def test_reconcile_field_sources_upgrades_verbatim_values_to_stated():
    # A value that appears verbatim in the user's text IS stated, regardless of what the
    # extraction model guessed — this kills the "Now Hiring Baristas tagged INFERRED" flip.
    brief = ExtractedBrief(
        category="job_posting", headline="Now Hiring Baristas", venue_name="Daybreak Coffee",
        body_text="We're looking for friendly, energetic baristas to join our crew",
        field_sources={"headline": "inferred", "venue_name": "inferred", "body_text": "inferred"},
    )
    reconcile_field_sources(brief, "Now hiring baristas at Daybreak Coffee, part-time, apply in store")
    assert field_source(brief, "headline") == "stated"      # verbatim -> upgraded
    assert field_source(brief, "venue_name") == "stated"    # verbatim -> upgraded
    assert field_source(brief, "body_text") == "inferred"   # invented copy -> left as-is


def test_reconcile_field_sources_never_downgrades_or_marks_category():
    brief = ExtractedBrief(
        category="event", headline="Spring Gala",
        field_sources={"headline": "stated", "category": "inferred"},
    )
    reconcile_field_sources(brief, "make me a flyer")        # nothing appears verbatim
    assert field_source(brief, "headline") == "stated"      # never downgraded
    assert field_source(brief, "category") == "inferred"    # category stays inferred (deduced)


def test_design_brief_coerces_null_fields_to_defaults():
    # build_design_brief parses DesignBrief via the same adapter that tells the model to
    # "use null for any value you cannot infer". notes/checklist/recommendations are
    # non-Optional, so a null must coerce to the empty default, not raise. Mirrors the
    # real _to_model -> model_validate_json path.
    import json
    raw = json.dumps({"notes": None, "checklist": None, "recommendations": None})
    db = DesignBrief.model_validate_json(raw)
    assert db.notes == ""
    assert db.checklist == []
    assert db.recommendations == []


def test_design_brief_drops_null_items_inside_lists():
    # defensively tolerate a null element inside an otherwise-populated list
    db = DesignBrief(notes="ok", checklist=["a", None, "b"], recommendations=[None])
    assert db.checklist == ["a", "b"]
    assert db.recommendations == []


def test_design_brief_carries_structured_recommendations_and_tolerates_nulls():
    # #2/#3: the design pass now pre-selects palette/style/mood so the review proposals match
    # its reasoning instead of blind category/hard-coded defaults. Nulls coerce to None.
    import json
    db = DesignBrief.model_validate_json(json.dumps({
        "notes": "n", "recommended_palette": "Premium black & gold",
        "recommended_style": "Elegant Luxury", "recommended_mood": "Festive"}))
    assert db.recommended_palette == "Premium black & gold"
    assert db.recommended_style == "Elegant Luxury"
    assert db.recommended_mood == "Festive"
    nulled = DesignBrief.model_validate_json(json.dumps({
        "notes": "n", "recommended_palette": None, "recommended_style": None, "recommended_mood": None}))
    assert nulled.recommended_palette is None
    assert nulled.recommended_style is None and nulled.recommended_mood is None


def test_design_brief_parses_must_fix_questions_and_tolerates_nulls():
    # the plan turn now surfaces generation-blocking gaps as structured questions; tolerate
    # the model nulling the list, or emitting a null item.
    import json
    raw = json.dumps({"notes": "n", "checklist": [], "recommendations": [],
                      "questions": [{"field": "date", "text": "What's the exact date?"}, None]})
    db = DesignBrief.model_validate_json(raw)
    assert [(q.field, q.text) for q in db.questions] == [("date", "What's the exact date?")]
    assert DesignBrief(notes="n", questions=None).questions == []   # whole-null tolerated
