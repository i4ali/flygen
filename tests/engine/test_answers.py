from engine.schema import ExtractedBrief, build_field_proposals
from engine.answers import apply_answers, canonical_key


def test_apply_answers_sets_canonical_field_and_marks_it_stated():
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    unmapped = apply_answers(brief, {"price": "$18/hr"})
    assert brief.price == "$18/hr"
    assert brief.field_sources["price"] == "stated"   # the user just stated it
    assert unmapped == []


def test_apply_answers_maps_alias_keys_to_canonical_fields():
    # The question model invents snake_case keys (pay_rate, store_hours, venue_address);
    # they must still land in the right semantic slot instead of being dropped.
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    unmapped = apply_answers(brief, {
        "pay_rate": "$18/hr", "store_hours": "9am-5pm", "venue_address": "88 Front Street",
    })
    assert brief.price == "$18/hr"
    assert brief.time == "9am-5pm"
    assert brief.address == "88 Front Street"
    assert unmapped == []


def test_apply_answers_captures_unmapped_answer_into_additional_info():
    # An answer with no semantic home must NOT be dropped — it rides along as additional
    # info so the generator still renders it.
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    unmapped = apply_answers(brief, {"experience_required": "No experience needed"})
    assert unmapped == ["experience_required"]
    assert brief.additional_info == ["experience required: No experience needed"]


def test_apply_answers_skips_blank_values():
    brief = ExtractedBrief(category="event", headline="Gala", price="$10")
    unmapped = apply_answers(brief, {"price": "   ", "address": ""})
    assert brief.price == "$10"        # untouched by a blank answer
    assert brief.address is None
    assert unmapped == []


def test_apply_answers_normalizes_trailing_dollar_price():
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"price": "18$"})
    assert brief.price == "$18"


def test_apply_answers_appends_unmapped_without_clobbering_existing_info():
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring",
                           additional_info=["Free coffee"])
    apply_answers(brief, {"dress_code": "casual"})
    assert "Free coffee" in brief.additional_info
    assert "dress code: casual" in brief.additional_info


def test_apply_answers_treats_decline_as_skip_not_a_literal_value():
    # "No" to "do you want to include a wage?" means omit it — NOT price == "No".
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    unmapped = apply_answers(brief, {"pay_rate": "No"})
    assert brief.price is None                  # declined -> omitted
    assert "price" not in brief.field_sources   # not marked stated
    assert unmapped == []
    assert not brief.additional_info            # not captured as a stray note either


def test_apply_answers_skips_common_decline_phrasings():
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"price": "none", "discount_text": "N/A",
                          "website": "no thanks", "dress_code": "nope"})
    assert brief.price is None and brief.discount_text is None and brief.website is None
    assert not brief.additional_info            # the unmapped decline ('dress_code') is dropped too


def test_apply_answers_skips_bare_affirmation_too():
    # Symmetric to the decline bug: a bare "Yes" to "include a wage?" has no value to render,
    # so it must not become price == "Yes".
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    apply_answers(brief, {"pay_rate": "Yes"})
    assert brief.price is None
    assert not brief.additional_info


def test_apply_answers_skips_dont_know_and_defer_answers():
    # The bug class isn't just yes/no: "not sure" / "you decide" / "whatever" are non-answers.
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"date": "not sure", "venue_name": "you decide", "price": "whatever"})
    assert brief.date is None and brief.venue_name is None and brief.price is None
    assert not brief.additional_info


def test_apply_answers_keeps_meaningful_values_that_are_not_declines():
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"price": "Free", "body_text": "No experience needed"})
    assert brief.price == "Free"                          # 'Free' is a real value
    assert brief.body_text == "No experience needed"      # contains 'No' but isn't a decline


def test_apply_answers_routes_format_choice_to_aspect_ratio():
    # The early size picker sends {"format": "9:16"}; it must land on aspect_ratio, not as a note.
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"format": "9:16"})
    assert brief.aspect_ratio == "9:16"
    assert not brief.additional_info


def test_apply_answers_ignores_unknown_format_value():
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"format": "banana"})
    assert brief.aspect_ratio is None
    assert not brief.additional_info


def test_apply_answers_keeps_user_website_even_if_malformed():
    # owner decision: don't silently drop a website the user typed in answer to "what's the URL?" —
    # keep it (the review flags it). A valid one is taken at face value as before.
    brief = ExtractedBrief(category="sale_promo", headline="Sale")
    apply_answers(brief, {"website": "ticketmaster.com"})
    assert brief.website == "ticketmaster.com"
    brief2 = ExtractedBrief(category="sale_promo", headline="Sale")
    apply_answers(brief2, {"link": "Ticketmaster"})             # 'link' aliases to website
    assert brief2.website == "Ticketmaster"                      # malformed but real -> kept
    assert not brief2.additional_info                           # in its slot, not a stray note


def test_apply_answers_routes_a_phone_given_to_a_website_question_into_phone():
    # The bug: a single contact question offers "website, phone, or email" but binds to ONE
    # field key (website). A phone answer must land in `phone`, not `website` (where the review
    # would wrongly flag it as a malformed URL).
    brief = ExtractedBrief(category="event", headline="Open Mic Night")
    apply_answers(brief, {"website": "555-0123"})
    assert brief.phone == "555-0123"
    assert brief.website is None
    assert brief.field_sources["phone"] == "stated"
    # and the review no longer flags it as a bad web address
    flagged = [p for p in build_field_proposals(brief) if p.warning]
    assert flagged == []


def test_apply_answers_routes_an_email_given_to_a_website_question_into_email():
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"link": "rsvp@riverside.org"})   # 'link' aliases to website
    assert brief.email == "rsvp@riverside.org"
    assert brief.website is None


def test_apply_answers_keeps_a_real_url_in_website_not_misrouted():
    # A genuine URL given to a contact question stays in website (disjoint from phone/email).
    brief = ExtractedBrief(category="event", headline="Gala")
    apply_answers(brief, {"website": "greenhouse.com/tickets"})
    assert brief.website == "greenhouse.com/tickets"
    assert brief.phone is None and brief.email is None


def test_apply_answers_leaves_a_malformed_website_name_in_website_to_be_flagged():
    # Regression guard for the face-value rule: 'Ticketmaster' is neither phone nor email nor a
    # well-formed URL, so it stays under website and the review flags it (never re-routed away).
    brief = ExtractedBrief(category="sale_promo", headline="Sale")
    apply_answers(brief, {"link": "Ticketmaster"})
    assert brief.website == "Ticketmaster"
    assert brief.phone is None and brief.email is None
    assert any(p.key == "website" and p.warning for p in build_field_proposals(brief))


def test_canonical_key_maps_aliases_and_passes_through_unknown():
    assert canonical_key("pay_rate") == "price"
    assert canonical_key("wage") == "price"
    assert canonical_key("store_hours") == "time"
    assert canonical_key("venue_address") == "address"
    assert canonical_key("price") == "price"                       # already canonical
    assert canonical_key("experience_required") == "experience_required"   # no home
