# Design - One-Brain Interpreter: collapse the validation pile into a single LLM read

- **Date:** 2026-06-30
- **Status:** Approved (brainstorm 2026-06-30). Implementation plan to follow.
- **Supersedes the validation/cleanup approach in:** `2026-06-18-design-expert-engine-design.md`, `2026-06-19-no-silent-defaults-design.md` (the *principles* there - reuse the pipeline, no silent defaults, ask only what you can't infer - are kept; the deterministic *implementation* of validation is what this replaces).

---

## 1. Problem

The chat engine has **two brains**. An LLM reads the user's words into structured fields (`engine/extract.py` -> `ExtractedBrief`), and then a growing pile of **deterministic Python** re-reads that output and the user's answers. Because human language is infinite, that cleanup layer can never be finished - there is always one more synonym, format phrasing, or contact shape, so every unexpected input becomes another special case.

Where the pile lives today (from the engine audit):

- **`engine/decide.py`** - three hand-kept lookup tables (`map_format` destination buckets, `_PALETTE_PRESETS` ~25 keyword->hex rows, `_FORMAT_OPTIONS`) plus `_resolve_enum` dual-label tolerance and default-vs-recommendation branching.
- **`engine/schema.py`** - four regex validators (`_WEBSITE_RE`, `_EMAIL_RE`, `_PHONE_CHARS_RE`) plus the `_NON_VALUE` word set, with `is_non_value` re-applied on 3+ paths (`sanitize_brief`, `to_flyer_project`, `apply_answers`).
- **`engine/answers.py`** - `_ALIASES` (16 synonym->canonical), `_route_contact` (regex re-classifies a phone that landed under `website`), `_normalize_price` (`"18$"` -> `"$18"`).
- **Split-brain** - the "take contact details at face value" rule is enforced *twice* and can disagree: a prompt instruction in `engine/plan.py` and a regex+warning in `engine/schema.py`.

The pile is the symptom; the split-brain design is the cause.

---

## 2. Principle

**One brain interprets. A thin typed edge validates. The human review gate is the safety net. Deterministic code never re-interprets natural language.**

A strong model is good at exactly what the regex pile does badly (disambiguating phone vs URL vs email, normalizing prices, recognizing "you decide", mapping "for printing" -> letter) - *and* it can do what a rule pile fundamentally cannot: bring world knowledge and design taste (propose a Muharram shrine silhouette, the right palette symbolism and tone) without an infinite occasion->motif table. So we host the brain and shrink the code.

---

## 3. Decisions (settled in brainstorm)

1. **Boundary: fat brain / thin code.** The interpretation call returns a finished, typed `TurnResult`. Deterministic code is four boring jobs: state machine, enum validator, review assembler, compiler mapper. Nothing interprets language except the brain.
2. **Review style: confident draft (opinionated).** The brain picks a best value for each design choice and presents it with a one-line rationale and alternatives a tap away; the user overrides what they don't like. Not neutral option-lists. It is a designer handing you a first draft, which is what lets a thin brief still produce something polished.
3. **Proactivity: hybrid.** The design-director proposes a small, curated set (2-3) of creative elements. The brain **self-tags each element's sensitivity**: `safe` (somber palette, reverent tone, abstract motifs) is **on by default** in the review and removable; `sensitive` (specific, representational, or religious imagery - e.g. the shrine silhouette, "Ya Hussain" calligraphy) is **off by default** and offered as an "add this?" suggestion. Nothing generates before approval, so the review is also the cultural-safety valve.
4. **Must-ask floor: a tiny declarative per-category list.** The rubric carries a short "must-have facts" list per category (EVENT -> date + location; SALE -> offer + dates; ...). Rule: **if a must-have is missing and not confidently inferable, ask rather than guess**; everything else is inferred and shown in review. This list grows when we add a *category*, never when users say new things - bounded and stable, which is what separates good data from a bad pile.
5. **Off-vocabulary handling.** When the brain returns a value we don't support (e.g. a "billboard" format not in our enums), the validator **surfaces it in the review flagged as unsupported and lets the user pick a valid one** - it never silently snaps to a nearest match. This is no-silent-defaults applied to our own gaps.
6. **Model & transport: stay on OpenRouter.** The reasoning brain continues through the existing OpenRouter shim (`engine/openrouter_client.py`), current model `claude-sonnet-4-6` (a one-line `config.py` swap if we later A/B Opus). We are **not** adopting the Anthropic SDK. (An earlier Anthropic-SDK rewrite was built, hit model-output bugs in sim-testing, and was reset/stashed; it is intentionally abandoned, not revived.)

---

## 4. Architecture

### 4.1 The `TurnResult` - the one object the brain returns each turn

The interpretation call reads the full conversation (user messages + prior answers) plus the cached system briefing (persona + enums + rubric + floor), and returns a single typed result:

```
TurnResult:
  status: "need_input" | "ready"

  # when status == need_input:
  questions: [ { key, prompt, why } ]        # only un-inferrable must-haves / blocking gaps

  # always (best current interpretation):
  brief:
    category: <enum token>
    fields: { key -> { value, source: "stated" | "inferred" } }
             # contacts already correctly slotted (phone in phone, URL in website),
             # price already normalized, a decline carried as an explicit
             # `deferred_to_us: true` flag rather than a magic "you decide" string

  # when status == ready (the confident draft):
  decisions: [ { key, value, options, reason } ]      # format/palette/style/mood/quality - chosen + alternatives
  creative_elements: [ { what, why, sensitivity: "safe" | "sensitive" } ]
  plan: { notes, checklist, recommendations }         # the user-facing design brief
```

Implementation note (not a product decision): this *interface* is one result per turn. Internally it may be served by one LLM call, or split into a cheap completeness/extraction pass and an expensive design-director pass tuned by `effort` - a cost optimization to settle at implementation time. Neither pass is ever followed by a deterministic re-interpretation layer.

### 4.2 Flow

```
interpret(full history + rubric)
      |
      v
  need_input? --yes--> ask questions --> collect answers --> (re-interpret)
      | no
      v
  ready: confident draft (decisions + creative_elements + plan)
      |
      v
  REVIEW  (human: confirm / override fields, decisions; toggle creative elements)
      |
      v
  approve + overrides
      |
      v
  validate enums  ->  assemble FlyerProject  ->  FlyerPromptBuilder  ->  Gemini (3 concepts)
```

The generation gate is preserved: concepts are produced only after `approve`. The questioning loop replaces *both* of today's separate ask phases (the `gaps.py` floor and the `plan.py` must-fix gate) with one loop driven by the brain plus the declarative floor.

### 4.3 The deterministic layer (four boring, testable jobs)

1. **State machine** - `need_input` loop -> review -> approve -> generate. (Reshaped `engine/orchestrator.py`.)
2. **Validator** - is each chosen value a real enum (`category`, `aspect_ratio`, `visual_style`, `mood`, `quality`)? Off-vocabulary -> surface flagged (Decision 5). The *only* gatekeeping. No `except: pass` swallowing.
3. **Assembler** - build the `ReviewProposal` from `TurnResult`: fields (with source; a malformed-looking website is flagged for review only if the *brain* reports it - no regex), decisions (value/options/reason), creative elements (what/why, pre-selected if `safe`), plan.
4. **Compiler mapper** - on approval, map confirmed/overridden values into `FlyerProject`; approved creative elements become free-text `imagery_description` / `special_instructions`; hand to the existing `FlyerPromptBuilder` -> `FlyerImageGenerator`.

### 4.4 The rubric becomes a design-director briefing

Today the rubric is per-category checklist/hierarchy/recommendation/palette data the cleanup code consults. It is upgraded to the brain's briefing material:

- **How to think** (for any brief): what is the occasion, what does it evoke, what motifs / symbolism / tone fit, what is appropriate and respectful. This is what produces clever, on-theme proposals without an occasion->motif table.
- **Must-have facts floor** (Decision 4) - bounded per-category data.
- **Palette directions + their swatches** - curated, reviewable color data (the brain picks a named direction; the swatches are carried by the rubric, so colors stay curated rather than hallucinated). This replaces the unbounded `_PALETTE_PRESETS` free-text keyword table with bounded, named directions.

---

## 5. What changes (migration map)

| File | Change |
|---|---|
| `engine/answers.py` | **Deleted.** Alias map, contact re-routing, price normalization all become re-interpretation by the brain. |
| `engine/decide.py` | **Gutted.** Delete `map_format`, `_PALETTE_PRESETS`, `_FORMAT_OPTIONS`, `_resolve_enum`, default-vs-rec branching. Decisions now come from `TurnResult`. Keep only the enum validator + palette-swatch lookup from rubric data. |
| `engine/schema.py` | Drop the regex validators and `_NON_VALUE`/`is_non_value`. Keep pydantic typing; reshape `ExtractedBrief`-style models into the `TurnResult` schema. The "keep + flag malformed website" behavior is preserved but is now **brain-reported** (it keeps the value and notes if it looks malformed), not regex-driven. |
| `engine/gaps.py` | Reshaped: the declarative floor moves into rubric data; LLM question-phrasing folds into the interpret call. Delete the deterministic floor-merge plumbing. |
| `engine/plan.py` | Folds into the design-director portion of the interpret prompt. The face-value *prompt rule* is no longer a separate enforcement point (the brain owns interpretation; the regex twin is gone), so the split-brain is removed. |
| `engine/orchestrator.py` | Simplified state machine around `TurnResult` (need_input loop, review, approve). |
| `engine/app.py` | Serialize `TurnResult` / review over SSE; route `approve` overrides (largely as today). |
| `engine/rubrics.py` | Expanded into the briefing: thinking framework + must-have floor + named palette directions with swatches. |
| `engine/openrouter_client.py` | **Kept.** The reasoning brain continues through this shim (no Anthropic SDK). The plan must use its robust JSON path for parsing `TurnResult`. |
| `engine/config.py` | **Kept.** Model stays `claude-sonnet-4-6` via OpenRouter (a one-line swap to A/B Opus later). |
| `models.py`, `prompt_builder.py`, `image_generator.py` | **Unchanged.** The deterministic compiler and image pipeline are reused as-is. |

---

## 6. Testability

- **Deterministic pieces** (validator, state machine, assembler, compiler mapper) are unit-tested with **fabricated `TurnResult` objects** - feed a fake brain-output, assert the review payload / `FlyerProject`. This is *more* testable than today's logic scattered across regex helpers.
- **The brain** is checked by the **`engine/eval/` harness** over a corpus of representative briefs (complete, thin, floor-triggering, and culturally-specific), not by unit tests.
- **No real API calls in unit tests** - mock the LLM client and `FlyerImageGenerator`.

---

## 7. Non-goals

- Changes to the image pipeline (`prompt_builder.py`, `image_generator.py`) or the image model (Gemini stays).
- Persistence / thread identity (still passed in/out per request).
- The iOS chat UI (separate; it consumes the review payload).
- Newsletter / menu rubrics and multi-section flows.

---

## 8. Risks / open questions (to finalize in the plan)

1. **Exact `TurnResult` field set** - the schema above is the shape; the precise field list (and how `deferred_to_us` / per-field source are represented) is finalized in the implementation plan.
2. **One LLM call vs. two-phase per turn** - an `effort`/cost optimization, decided at implementation time; does not change the interface.
3. **Prompt size & caching** - persona + enums + rubric + floor is large and stable; mark it `cache_control: ephemeral` so every turn reuses the cached prefix.
3b. **Reliable structured output over OpenRouter** - the `TurnResult` must parse every turn. OpenRouter's `json_schema` mode has been unreliable, so the plan uses the shim's robust strategy (prompt-driven JSON + tolerant parsing/repair), not a hard schema mode. This is the load-bearing risk of staying off the Anthropic SDK.
4. **Cultural-sensitivity accuracy** - mitigated structurally (`sensitive` elements are opt-in + the human review precedes all generation), but worth explicit eval coverage.
5. **Eval coverage** - the corpus must include thin briefs, each category's floor triggers, off-vocabulary values, and sensitive-imagery cases.

---

## 9. Suggested build order (high-level; detailed plan via writing-plans)

1. Define the `TurnResult` schema + the enum validator (the typed edge).
2. Author the system briefing: persona + enums + rubric-as-briefing + must-have floor + sensitivity tagging + confident-draft instruction.
3. Reshape `orchestrator.py` into the `TurnResult` state machine (interpret loop -> review -> approve).
4. Assembler: `ReviewProposal` from `TurnResult` (incl. creative elements + sensitivity pre-selection).
5. Compiler mapper: approved values + elements -> `FlyerProject` free-text -> `FlyerPromptBuilder`.
6. Delete `answers.py`; gut `decide.py` tables; drop `schema.py` validators; move the floor into rubric data; fold `plan.py` into the interpret prompt.
7. Update `app.py` serialization / routing.
8. Eval harness over the brief corpus (thin briefs, floor triggers, off-vocabulary, sensitive imagery).

The iOS chat spec and any later surface consume this engine unchanged.
