from unittest.mock import MagicMock
from engine.schema import ExtractedBrief
from engine.orchestrator import Engine, Event


def _engine_with(brief, questions, deps=None):
    deps = deps or {}
    deps.setdefault("extract", lambda text, client=None: brief)
    deps.setdefault("build_questions", lambda b, **k: questions)
    return Engine(client=MagicMock(), **deps)


def test_vague_brief_emits_questions_and_does_not_generate():
    from engine.gaps import QuestionSet, Question
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale"),
        QuestionSet([Question("date", "When is it?")]),
    )
    events = list(eng.handle_user_message("bake sale flyer"))
    kinds = [e.kind for e in events]
    assert "parsed_fields" in kinds
    assert "questions" in kinds
    assert "concepts" not in kinds   # gated: must answer / approve first


def test_describe_always_asks_size_with_labeled_options():
    # Even a complete brief gates to ask the size up-front, as a labeled choice question.
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Gala", date="Sat", venue_name="Hall", cta_text="Come"),
        QuestionSet([]),                       # no content gaps
    )
    events = list(eng.handle_user_message("..."))
    kinds = [e.kind for e in events]
    assert "questions" in kinds and "review" not in kinds   # gates to ask size
    qs = next(e.payload for e in events if e.kind == "questions")
    fmt = [q for q in qs.questions if q.field == "format"]
    assert fmt and fmt[0].options                            # size asked, with options
    assert fmt[0].options[0]["value"] == "4:5"               # default first


def test_complete_brief_reaches_design_brief_then_review():
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale", date="Sat", venue_name="Hall", cta_text="Come"),
        QuestionSet([]),
    )
    assert "questions" in [e.kind for e in eng.handle_user_message("...")]   # gates to ask size
    kinds = [e.kind for e in eng.handle_answers({"format": "4:5"})]          # then plans
    assert "design_brief" in kinds   # "plans like a pro" turn
    assert "review" in kinds          # consolidated review gate (replaces awaiting_approval)
    assert "awaiting_approval" not in kinds
    assert "concepts" not in kinds   # no blind jump to generate


def test_review_payload_has_fields_decisions_and_plan():
    from engine.gaps import QuestionSet
    from engine.schema import ReviewProposal
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Bake Sale", date="Sat",
                       venue_name="Hall", cta_text="Come",
                       field_sources={"headline": "stated", "category": "inferred"}),
        QuestionSet([]),
    )
    list(eng.handle_user_message("..."))                          # gates to ask size
    events = list(eng.handle_answers({"format": "4:5"}))          # then plans -> review
    kinds = [e.kind for e in events]
    assert "design_brief" in kinds
    assert "review" in kinds and "awaiting_approval" not in kinds
    assert "concepts" not in kinds
    review = next(e.payload for e in events if e.kind == "review")
    assert isinstance(review, ReviewProposal)
    assert any(f.key == "headline" for f in review.fields)
    assert any(d.key == "format" for d in review.decisions)   # format always surfaced
    assert review.plan is not None


def test_handle_approval_generates_concepts():
    from engine.tools import Concept
    gen_mock = MagicMock(return_value=[Concept("v1", "b64"), Concept("v2", "b64"), Concept("v3", "b64")])
    eng = Engine(client=MagicMock(), generate_concepts=gen_mock, generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Bake Sale", date="Sat", venue_name="Hall", cta_text="Come")
    events = list(eng.handle_approval(decision_overrides={}))
    assert "concepts" in [e.kind for e in events]
    assert gen_mock.called
    # a compiled FlyerProject + the generator were passed to the tool
    args, kwargs = gen_mock.call_args
    assert kwargs.get("generator") is not None


def test_handle_approval_applies_field_and_decision_overrides():
    from engine.tools import Concept
    captured = {}
    def fake_generate(project, generator=None, n=3):
        captured["headline"] = project.text_content.headline
        captured["aspect"] = project.output.aspect_ratio
        return [Concept("v1", "b64")]
    eng = Engine(client=MagicMock(), generate_concepts=fake_generate, generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Bake Sale", cta_text="Come")
    events = list(eng.handle_approval(
        field_overrides={"headline": "Spring Bake Sale"},
        decision_overrides={"format": "letter"},
    ))
    from models import AspectRatio
    assert "concepts" in [e.kind for e in events]
    assert captured["headline"] == "Spring Bake Sale"       # field override applied
    assert captured["aspect"] == AspectRatio.LETTER          # decision override applied


def test_handle_approval_materializes_user_photos_and_cleans_up():
    import base64, os
    from engine.tools import Concept
    seen = {}

    def fake_generate(project, generator=None, n=3, user_photo_paths=None):
        seen["paths"] = list(user_photo_paths or [])
        seen["exist_during"] = [os.path.exists(p) for p in (user_photo_paths or [])]
        seen["user_photo_path"] = project.user_photo_path     # set so the prompt features them
        return [Concept("v1", "b64")]

    eng = Engine(client=MagicMock(), generate_concepts=fake_generate, generator=MagicMock())
    eng.brief = ExtractedBrief(category="music_concert", headline="Show")
    b64 = base64.b64encode(b"\x89PNG fake-photo-bytes").decode()

    events = list(eng.handle_approval(decision_overrides={}, user_photos_b64=[b64, b64]))

    assert "concepts" in [e.kind for e in events]
    assert len(seen["paths"]) == 2
    assert all(seen["exist_during"])                              # files readable during generation
    assert seen["user_photo_path"] == seen["paths"][0]           # first photo drives the prompt instruction
    assert not any(os.path.exists(p) for p in seen["paths"])     # temp files cleaned up afterwards


def test_handle_refine_calls_refine_tool_with_prior_image():
    from engine.tools import Concept
    refine_mock = MagicMock(return_value=Concept("refined", "b64"))
    eng = Engine(client=MagicMock(), refine_concept=refine_mock, generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Bake Sale")
    events = list(eng.handle_refine("/tmp/prev.png", "make the title bigger"))
    assert any(e.kind == "refined" for e in events)
    assert refine_mock.called
    assert "/tmp/prev.png" in refine_mock.call_args.args


def test_handle_resize_calls_resize_tool():
    from engine.tools import Concept
    resize_mock = MagicMock(return_value=Concept("resized", "b64"))
    eng = Engine(client=MagicMock(), resize_concept=resize_mock, generator=MagicMock())
    events = list(eng.handle_resize("/tmp/prev.png", "letter"))
    assert any(e.kind == "resized" for e in events)
    assert resize_mock.called


def test_handle_refine_materializes_base64_to_a_real_path_then_cleans_up():
    import base64, os
    from engine.tools import Concept
    seen = {}

    def fake_refine(project, path, instruction, generator=None, mode="edit"):
        seen["path"] = path
        seen["existed_during_call"] = os.path.exists(path)  # tool needs a real file
        return Concept("refined", "b64")

    eng = Engine(client=MagicMock(), refine_concept=fake_refine, generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="X")
    b64 = base64.b64encode(b"\x89PNG\r\n\x1a\n not-a-real-png-but-bytes").decode()

    events = list(eng.handle_refine(prior_image_b64=b64, instruction="bigger title"))

    assert any(e.kind == "refined" for e in events)
    assert seen["existed_during_call"] is True            # generator saw a readable file
    assert not os.path.exists(seen["path"])               # temp cleaned up afterwards


def test_handle_refine_without_any_prior_image_errors():
    eng = Engine(client=MagicMock(), refine_concept=MagicMock(), generator=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="X")
    kinds = [e.kind for e in eng.handle_refine()]
    assert "error" in kinds


def test_design_brief_questions_gate_before_review():
    from engine.schema import DesignBrief, DesignQuestion
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Gala", date="next weekend",
                       venue_name="Hall", cta_text="Come"),
        QuestionSet([]),                                  # no up-front gaps
        deps={"build_design_brief": lambda *a, **k: DesignBrief(
            notes="n", questions=[DesignQuestion(field="date", text="What's the exact date?")])},
    )
    list(eng.handle_user_message("..."))                   # gates to ask size first
    events = list(eng.handle_answers({"format": "4:5"}))   # then plans -> design must-fix gate
    kinds = [e.kind for e in events]
    assert kinds.count("design_brief") == 1
    assert "questions" in kinds and "review" not in kinds          # gated on the must-fixes
    qs = next(e.payload for e in events if e.kind == "questions")
    assert qs.stage == "design"
    assert [q.field for q in qs.questions] == ["date"]
    assert "note" in kinds                                         # conversational lead-in


def test_design_questions_gate_even_when_model_omits_text():
    # the model often names the must-fix field but nulls the text; still gate, with a fallback.
    from engine.schema import DesignBrief, DesignQuestion
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Gala", date="next weekend",
                       venue_name="Hall", cta_text="Come"),
        QuestionSet([]),
        deps={"build_design_brief": lambda *a, **k: DesignBrief(
            notes="n", questions=[DesignQuestion(field="date", text=None)])},
    )
    list(eng.handle_user_message("..."))                   # gates to ask size first
    events = list(eng.handle_answers({"format": "4:5"}))   # then plans -> design must-fix gate
    kinds = [e.kind for e in events]
    assert "questions" in kinds and "review" not in kinds
    qs = next(e.payload for e in events if e.kind == "questions")
    assert qs.questions[0].field == "date"
    assert qs.questions[0].text and qs.questions[0].text.strip()   # non-empty fallback phrasing


def test_design_questions_skip_fields_the_user_already_answered():
    # #7: don't re-ask for a detail the user already provided this session. An address
    # given in the gap round (under any alias) must not be re-asked by the design pass.
    from engine.schema import DesignBrief, DesignQuestion
    eng = Engine(
        client=MagicMock(),
        build_design_brief=lambda *a, **k: DesignBrief(
            notes="n", questions=[DesignQuestion(field="full_address", text="What's the full address?")]),
    )
    eng.brief = ExtractedBrief(category="event", headline="Gala", date="Sat",
                               venue_name="Hall", cta_text="Come")
    eng.answers = {"venue_address": "88 Front Street"}     # canonical 'address' already answered
    kinds = [e.kind for e in eng._plan_and_await()]
    assert "questions" not in kinds      # redundant address re-ask dropped
    assert "review" in kinds             # proceeds straight to review


def test_design_brief_with_no_questions_goes_straight_to_review_with_a_note():
    from engine.schema import DesignBrief
    from engine.gaps import QuestionSet
    eng = _engine_with(
        ExtractedBrief(category="event", headline="Gala", date="Sat Jun 28",
                       venue_name="Hall", cta_text="RSVP at x.org"),
        QuestionSet([]),
        deps={"build_design_brief": lambda *a, **k: DesignBrief(notes="n", questions=[])},
    )
    list(eng.handle_user_message("..."))                          # gates to ask size
    kinds = [e.kind for e in eng.handle_answers({"format": "4:5"})]
    assert "design_brief" in kinds and "review" in kinds
    assert "note" in kinds                                         # message between brief and review


def test_handle_design_answers_applies_recomputes_plan_and_reviews_without_re_asking():
    eng = Engine(client=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Gala", venue_name="Hall", cta_text="Come")
    events = list(eng.handle_design_answers({"date": "Sat June 28, 10am"}))
    kinds = [e.kind for e in events]
    assert "review" in kinds
    assert "questions" not in kinds                  # no re-ask loop
    assert "design_brief" in kinds                   # #2: plan re-run against the updated brief
    assert eng.brief.date == "Sat June 28, 10am"     # answer applied
    assert "note" in kinds


def test_design_answers_recompute_plan_so_review_is_not_stale():
    # #2: the plan shown at review must reflect the must-fix answer, not the pre-answer brief.
    # First pass flags a vague date and recommends a rote palette; after the date is given the
    # recomputed pass drops the "too broad" note and recommends a fitting palette.
    from engine.schema import DesignBrief, DesignQuestion
    briefs = iter([
        DesignBrief(notes="'August' is too broad for a deadline", recommended_palette="High-energy red/yellow",
                    questions=[DesignQuestion(field="date", text="What's the exact end date?")]),
        DesignBrief(notes="Locked to Aug 1 — deadline copy ready", recommended_palette="Winter frost", questions=[]),
    ])
    eng = Engine(client=MagicMock(), build_design_brief=lambda *a, **k: next(briefs))
    eng.brief = ExtractedBrief(category="sale_promo", headline="Big Winter Sale",
                               discount_text="60% off", cta_text="Shop")
    list(eng._plan_and_await())                                       # call 1 -> must-fix date gate
    events = list(eng.handle_design_answers({"date": "August 1"}))    # answer -> recompute (call 2)
    review = next(e.payload for e in events if e.kind == "review")
    assert review.plan.notes == "Locked to Aug 1 — deadline copy ready"           # fresh notes
    assert {d.key: d for d in review.decisions}["palette"].value == "Winter frost"  # fresh palette
    assert "design_brief" in [e.kind for e in events]                # refreshed plan re-surfaced


def test_floor_reask_is_capped_then_proceeds_to_plan():
    # #3: a still-missing critical field is re-asked at most once, then the flow proceeds to the
    # plan/review instead of looping forever (a user who can't supply it isn't trapped).
    from engine.gaps import QuestionSet, Question
    from engine.schema import DesignBrief
    floor_q = QuestionSet([Question("discount_text", "What's the offer?")])   # never satisfied
    eng = Engine(client=MagicMock(),
                 build_questions=lambda b, **k: floor_q,
                 build_design_brief=lambda *a, **k: DesignBrief(notes="n", questions=[]))
    eng.brief = ExtractedBrief(category="sale_promo", headline="Sale", cta_text="Shop")   # no discount_text
    first = [e.kind for e in eng.handle_answers({"x": "1"})]
    assert "questions" in first and "review" not in first        # re-asks the floor once
    second = [e.kind for e in eng.handle_answers({"x": "2"})]
    assert "review" in second and "questions" not in second      # then proceeds — no infinite loop


def test_proceeding_with_missing_critical_field_does_not_overclaim():
    # #3: when proceeding despite a still-blank critical field, the pre-review note stays honest.
    from engine.gaps import QuestionSet, Question
    from engine.schema import DesignBrief
    eng = Engine(client=MagicMock(),
                 build_questions=lambda b, **k: QuestionSet([Question("discount_text", "Offer?")]),
                 build_design_brief=lambda *a, **k: DesignBrief(notes="n", questions=[]))
    eng.brief = ExtractedBrief(category="sale_promo", headline="Sale", cta_text="Shop")
    eng.floor_reasked = True                                      # already re-asked -> next proceeds
    events = list(eng.handle_answers({"x": "1"}))
    note = next(e.payload for e in events if e.kind == "note")
    assert "everything" not in note.lower()                      # honest — discount_text still blank
    assert "review" in [e.kind for e in events]


def test_clarification_answers_reach_generation_and_are_not_dropped():
    # Regression for the headline audit bug: model-invented answer keys (pay_rate,
    # venue_address, experience_required) were silently dropped before generation because
    # they weren't ExtractedBrief attributes. They must now reach the FlyerProject.
    from engine.gaps import QuestionSet
    from engine.schema import DesignBrief
    from engine.tools import Concept
    captured = {}

    def fake_generate(project, generator=None, n=3):
        captured["project"] = project
        return [Concept("v1", "b64")]

    eng = Engine(
        client=MagicMock(),
        build_questions=lambda b, **k: QuestionSet([]),
        build_design_brief=lambda *a, **k: DesignBrief(notes="n"),
        generate_concepts=fake_generate, generator=MagicMock(),
    )
    eng.brief = ExtractedBrief(category="job_posting", headline="Now Hiring Baristas",
                               body_text="Join the team")
    list(eng.handle_answers({
        "pay_rate": "$18/hr",
        "venue_address": "88 Front Street",
        "experience_required": "No experience needed",
    }))
    list(eng.handle_approval(decision_overrides={}))

    tc = captured["project"].text_content
    assert tc.price == "$18/hr"                      # alias mapped to the price slot
    assert tc.address == "88 Front Street"           # alias mapped to the address slot
    assert any("experience" in i.lower() for i in (tc.additional_info or []))   # captured, not lost


def test_design_answers_do_not_over_claim_when_brief_still_incomplete():
    # #4: if a required field is still blank after the design must-fix turn, proceed to
    # review (no loop) but DON'T falsely say "that's everything I needed".
    eng = Engine(client=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Gala")   # needs date, venue, cta
    events = list(eng.handle_design_answers({"date": "Sat", "venue_name": "Hall"}))  # cta still missing
    kinds = [e.kind for e in events]
    note = next(e.payload for e in events if e.kind == "note")
    assert "everything" not in note.lower()              # no false completeness claim
    assert "review" in kinds and "questions" not in kinds  # still proceeds, no re-ask loop


def test_design_answers_confirm_completeness_when_nothing_is_missing():
    eng = Engine(client=MagicMock())
    eng.brief = ExtractedBrief(category="event", headline="Gala", date="Sat",
                               venue_name="Hall", cta_text="RSVP")
    events = list(eng.handle_design_answers({"time": "6pm"}))
    note = next(e.payload for e in events if e.kind == "note")
    assert "everything" in note.lower()                  # confident only when truly complete


def test_review_decisions_prefer_the_design_plans_recommendations():
    # #2/#3: the design pass's palette/style/mood reach the review proposals (the bug was the
    # design brief being built but never passed to propose_decisions).
    from engine.gaps import QuestionSet
    from engine.schema import DesignBrief
    eng = _engine_with(
        ExtractedBrief(category="sale_promo", headline="Big Winter Sale",
                       discount_text="Up to 60% off", cta_text="Shop now"),
        QuestionSet([]),
        deps={"build_design_brief": lambda *a, **k: DesignBrief(
            notes="winter", recommended_palette="Premium black & gold",
            recommended_style="Elegant Luxury", recommended_mood="Festive", questions=[])},
    )
    list(eng.handle_user_message("..."))
    events = list(eng.handle_answers({"format": "letter"}))
    review = next(e.payload for e in events if e.kind == "review")
    decs = {d.key: d for d in review.decisions}
    assert decs["palette"].value == "Premium black & gold"     # plan's choice, surfaced for approval
    assert decs["visual_style"].value == "Elegant Luxury"
    assert decs["mood"].value == "Festive"


def test_design_recommendations_survive_the_mustfix_detour_to_review():
    # the recommendation is cached so the must-fix answer round (which re-emits review with
    # design=None) still surfaces the plan's choice rather than reverting to defaults.
    from engine.schema import DesignBrief
    eng = Engine(client=MagicMock(),
                 build_design_brief=lambda *a, **k: DesignBrief(
                     notes="n", recommended_style="Bold Vibrant", questions=[]))
    eng.brief = ExtractedBrief(category="event", headline="Gala", venue_name="Hall", cta_text="Come")
    list(eng._plan_and_await())                                       # builds + caches the design
    events = list(eng.handle_design_answers({"date": "Sat Jun 28"}))  # _emit_review(None) path
    review = next(e.payload for e in events if e.kind == "review")
    assert {d.key: d for d in review.decisions}["visual_style"].value == "Bold Vibrant"


def test_generation_prompt_carries_the_plans_emphasis():
    # #4: the rubric hierarchy + the design pass's recommendations must reach the IMAGE prompt
    # (via special_instructions) so the discount/urgency aren't rendered as afterthoughts.
    from engine.gaps import QuestionSet
    from engine.schema import DesignBrief
    from engine.tools import Concept
    captured = {}

    def fake_generate(project, generator=None, n=3):
        captured["si"] = project.special_instructions or ""
        return [Concept("v1", "b64")]

    eng = Engine(
        client=MagicMock(),
        build_questions=lambda b, **k: QuestionSet([]),
        build_design_brief=lambda *a, **k: DesignBrief(
            notes="n", recommendations=["Make the discount the single biggest element."], questions=[]),
        generate_concepts=fake_generate, generator=MagicMock(),
    )
    eng.brief = ExtractedBrief(category="sale_promo", headline="Big Winter Sale",
                               discount_text="Up to 60% off", cta_text="Shop now")
    list(eng._plan_and_await())                                   # caches design (recommendations)
    list(eng.handle_approval(decision_overrides={}))
    assert "discount" in captured["si"].lower()                  # rubric hierarchy emphasis present
    assert "biggest element" in captured["si"].lower()           # plan's recommendation carried through


def test_concepts_gated_until_approval():
    from engine.gaps import QuestionSet
    gen = MagicMock()
    eng = _engine_with(
        ExtractedBrief(category="event", headline="X", date="Sat", venue_name="H", cta_text="Go"),
        QuestionSet([]),
        deps={"generate_concepts": gen},
    )
    list(eng.handle_user_message("..."))   # describe flow only
    assert not gen.called                   # generation tool never fires pre-approval
