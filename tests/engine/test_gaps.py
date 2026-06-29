import types
from unittest.mock import MagicMock

from engine.schema import ExtractedBrief
from engine.gaps import missing_critical_fields, build_questions, QUESTION_TEXT


def _fake_client(generated: dict):
    """A client whose messages.parse returns LLM-written question text per field,
    mirroring OpenRouterClient: resp.parsed_output.questions -> [{field, text}]."""
    qs = [types.SimpleNamespace(field=f, text=t) for f, t in generated.items()]
    resp = types.SimpleNamespace(parsed_output=types.SimpleNamespace(questions=qs))
    client = MagicMock()
    client.messages.parse.return_value = resp
    return client


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


def test_build_questions_uses_llm_generated_text_when_client_present():
    # With a client, the question WORDING comes from the model (human, brief-specific),
    # while the field keys stay machine-readable so answers still map back.
    brief = ExtractedBrief(category="event", headline="Bake Sale")  # missing date, venue_name, cta_text
    gen = {"date": "What day is your bake sale?",
           "venue_name": "Where's the bake sale being held?",
           "cta_text": "How can folks support — donate at the door, or is there a link?"}
    client = _fake_client(gen)
    qs = build_questions(brief, client=client)
    by = {q.field: q.text for q in qs.questions}
    assert by["date"] == "What day is your bake sale?"
    assert by["cta_text"].startswith("How can folks support")
    assert set(by) == set(missing_critical_fields(brief))   # same gaps, just human wording
    # the question turn deliberates too: adaptive thinking + high effort flow through
    kwargs = client.messages.parse.call_args.kwargs
    assert kwargs["thinking"] == {"type": "adaptive"}
    assert kwargs["output_config"] == {"effort": "high"}


def test_build_questions_falls_back_to_static_for_fields_the_model_omits():
    # If the model returns text for only some fields, the rest use the static copy —
    # every gap still gets a question.
    brief = ExtractedBrief(category="event", headline="Bake Sale")
    qs = build_questions(brief, client=_fake_client({"date": "What day is your bake sale?"}))
    by = {q.field: q.text for q in qs.questions}
    assert by["date"] == "What day is your bake sale?"           # generated
    assert by["venue_name"] == QUESTION_TEXT["venue_name"]       # static fallback
    assert by["cta_text"] == QUESTION_TEXT["cta_text"]           # static fallback


def test_build_questions_falls_back_to_static_when_model_call_raises():
    # A model hiccup must degrade to the old wording, never bubble an error.
    brief = ExtractedBrief(category="event", headline="Bake Sale")
    client = MagicMock()
    client.messages.parse.side_effect = RuntimeError("model down")
    qs = build_questions(brief, client=client)
    by = {q.field: q.text for q in qs.questions}
    assert by == {f: QUESTION_TEXT[f] for f in missing_critical_fields(brief)}


def test_build_questions_without_client_stays_static_and_makes_no_call():
    # Backward-compatible: no client -> deterministic static copy, no model call.
    brief = ExtractedBrief(category="event", headline="Bake Sale")
    qs = build_questions(brief)
    by = {q.field: q.text for q in qs.questions}
    assert by == {f: QUESTION_TEXT[f] for f in missing_critical_fields(brief)}


def test_build_questions_adds_designer_clarification_beyond_the_floor():
    # A complete-enough brief (no required gaps) can still earn a sharp, model-chosen
    # clarification — the Bloom Dale case: nothing required, but "when does the sale end?"
    brief = ExtractedBrief(category="sale_promo", headline="Summer Clearance",
                           discount_text="20% off", cta_text="Don't miss out")
    assert missing_critical_fields(brief) == []                 # no required gaps
    gen = {"sale_end_date": "When does the sale end, so I can add a deadline like 'ends Sunday'?"}
    qs = build_questions(brief, client=_fake_client(gen))
    by = {q.field: q.text for q in qs.questions}
    assert "sale_end_date" in by
    assert by["sale_end_date"].startswith("When does the sale end")


def test_question_system_prompt_guides_proper_question_punctuation():
    # #9: questions sometimes ended a statement with "?"; the persona must phrase real
    # questions with a single question mark.
    from engine.gaps import QUESTION_SYSTEM
    assert "question mark" in QUESTION_SYSTEM.lower()


def test_question_prompt_tells_model_to_reuse_canonical_field_keys():
    # Root-cause guard for the answer-drop bug: added clarifications should reuse real
    # ExtractedBrief slots (so "pay rate" -> price) rather than always inventing keys.
    from engine.gaps import _question_prompt
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    prompt = _question_prompt(brief, floor=[], max_questions=3, clarify=True)
    assert "price" in prompt and "address" in prompt    # the canonical slots are offered
    assert "reuse" in prompt.lower()                      # and the model is told to reuse them


def test_question_prompt_asks_for_values_not_yes_no():
    # Root cause of the "price = No" bug: optional details were asked as yes/no ("Do you want
    # to include a wage?"), inviting a bare "No"/"Yes" with no value. Ask for the value itself.
    from engine.gaps import _question_prompt
    brief = ExtractedBrief(category="job_posting", headline="Now Hiring")
    prompt = _question_prompt(brief, floor=[], max_questions=3, clarify=True)
    assert "yes/no" in prompt.lower()


def test_build_questions_caps_total_at_three_and_prioritizes_the_floor():
    brief = ExtractedBrief(category="event", headline="Gala")   # floor: date, venue_name, cta_text
    gen = {"date": "What day is the gala?", "venue_name": "Where's the gala?",
           "cta_text": "How should guests RSVP?", "dress_code": "Is there a dress code?"}
    qs = build_questions(brief, client=_fake_client(gen))
    fields = [q.field for q in qs.questions]
    assert len(fields) == 3                                     # capped at max_questions
    assert set(fields) == set(missing_critical_fields(brief))   # floor kept, addition dropped
    assert "dress_code" not in fields


def test_build_questions_clarify_false_skips_call_when_brief_complete():
    # The follow-up (answers) turn must not pile on new clarifications -> no question loop.
    brief = ExtractedBrief(category="sale_promo", headline="Clearance",
                           discount_text="20% off", cta_text="Shop now")
    client = _fake_client({"sale_end_date": "When does it end?"})
    qs = build_questions(brief, client=client, clarify=False)
    assert qs.questions == []
    assert not client.messages.parse.called                    # no model call when nothing required


def test_build_questions_clarify_false_still_insists_on_missing_must_have_only():
    brief = ExtractedBrief(category="event", headline="Gala", date="Sat", venue_name="Hall")  # cta missing
    client = _fake_client({"cta_text": "How should guests RSVP?", "dress_code": "Dress code?"})
    qs = build_questions(brief, client=client, clarify=False)
    fields = [q.field for q in qs.questions]
    assert fields == ["cta_text"]                              # the must-have, and ONLY it
