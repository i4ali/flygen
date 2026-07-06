# Multi-language flyer generation - design

- Date: 2026-07-05
- Status: Approved, pending implementation
- Related: `docs/plans/2026-07-05-onboarding-open-question-design.md` (the onboarding this modifies)

## Problem / current state

FlyGen generates flyers in **English only**, even though a full multilingual
machinery already exists in the codebase - it's just dead code.

The chat flow is the only live way to make a flyer, and language never enters it:

- iOS `ChatRequest` and the engine's `ChatIn` have **no language field**.
- `engine/compile_project.build_project()` constructs the `FlyerProject`
  **without setting `language`**, so it defaults to `FlyerLanguage.ENGLISH`
  (`models.py:252`).
- The prompt builder's language block is gated behind
  `if project.language != FlyerLanguage.ENGLISH` (`prompt_builder.py:270-276`,
  `511-516`) - a branch that is **never true**, so Nano Banana always receives an
  English-only prompt.
- Onboarding collects `UserProfile.preferredLanguages` (`UserProfile.swift:29`)
  but it is **written once and never read**.

The retired 9-screen wizard (gated off via `FeatureFlags.classicCreationEnabled = false`)
had a working language path, but it's unreachable.

## Goals

- Generate flyers in **13 languages**.
- **Reuse the existing translation machinery** - no new translation engine, no
  separate translation step. Nano Banana Pro translates as it renders.
- Preserve fixed details (addresses, phone, email, URLs, **dates/times**) verbatim.
- Language is chosen **per-flyer on the review card**, pre-selected from a profile
  default.
- Language **persists across every edit** within a flyer (refine/resize/reference/annotate).
- Backward compatible: an old client that sends no language still works (defaults English).

## Non-goals (YAGNI)

- No auto-detecting the language from the user's typed text.
- No mixing multiple languages within a single flyer.
- No regional variants (no Traditional Chinese, no Brazilian vs European Portuguese).
- No reviving the retired wizard's on-device `PromptBuilder.swift` path - engine-side only.
- No verification/back-translation UI (user approves English copy, ships target-language copy).

## Key decisions (with rationale)

| # | Decision | Why |
|---|----------|-----|
| 1 | Engine-side `language` field feeds the existing `FlyerPromptBuilder` | One source of truth for translation rules; minimal new code. Rejected: on-device prompt building (duplicates logic, diverges from engine) and a separate translation LLM step (extra call, a place for date/address corruption). |
| 2 | 13 big-population languages; Japanese included | Big languages are high-resource and render best. Skipped a formal per-language render spike but will **eyeball Hindi + Bengali** (the two new complex scripts) during build. Dropped the smaller tail (Italian, Vietnamese, Korean, Turkish, Farsi, Thai, Tagalog, Hebrew). |
| 3 | Dates/times kept **literal English**, verbatim | Owner's call. Added to the existing do-not-translate list (addresses/phone/email/URLs). |
| 4 | Language = a **pre-selected, changeable row on the review card**; no separate step, no timer | Lowest friction: pre-selected default means zero extra taps for the common case; the existing "Approve & generate" is the "continue". Explicit approval preserved - we never auto-spend a generation. |
| 5 | New **profile "Default flyer language"** setting; onboarding single-select **dropdown** seeds it | Onboarding simplified from multi-select chips to one preferred language; dropdown suits a single pick out of 13. |
| 6 | Language **persists** across all edits + stored on the saved flyer | Otherwise edits drift back to English / mix languages. |

## Languages (13)

Mirror **exactly** on both sides - iOS `FlyerLanguage` (`Language.swift`) and Python
`FlyerLanguage` (`models.py`) - raw values and instructions must match or the wire
`language` string won't map.

| Language | Raw value | Status | Script / notes |
|----------|-----------|--------|----------------|
| English | `en` | existing | Latin |
| Spanish | `es` | existing | Latin |
| Chinese (Simplified) | `zh` | existing | Han |
| Arabic | `ar` | existing | Arabic, **RTL** (handled) |
| Urdu | `ur` | existing | Nastaliq, **RTL** (handled) |
| Hindi | `hi` | new | Devanagari - **eyeball render quality** |
| French | `fr` | new | Latin |
| Bengali | `bn` | new | Bengali - **eyeball render quality** |
| Portuguese | `pt` | new | Latin |
| Russian | `ru` | new | Cyrillic |
| Indonesian | `id` | new | Latin |
| German | `de` | new | Latin |
| Japanese | `ja` | new | Kanji/Kana |

No new RTL languages (RTL stays Arabic + Urdu, both already handled by the existing
script-integrity instruction at `prompt_builder.py:387-393`).

Declare the enum in a sensible display order (common first) so any list/menu reads well.

## Translation & preservation rules

Each language's `promptInstruction` / `prompt_instruction` follows the existing template.
Two text changes, applied to **both** iOS and Python:

1. **Extend the do-not-translate list** to include dates and times:

   > "Translate headlines, descriptions, and calls-to-action to {language}.
   > DO NOT translate addresses, phone numbers, emails, URLs, **dates, or times** -
   > keep them exactly as provided. If the user provides text in another language,
   > translate it to {language} while preserving the intended meaning and tone."

2. **Soften the "ALL text" wrapper** so it respects the exceptions instead of
   over-translating. Currently (`prompt_builder.py:271-276`, `511-516`):

   > "You MUST ensure ALL text content appears in the target language..."

   becomes roughly:

   > "All text content **except the preserved items (addresses, phone numbers, emails,
   > URLs, dates, times)** must appear in the target language..."

RTL languages keep the existing "...in left-to-right order" clause for the preserved
items (now including dates).

## UX

### Profile setting (new)

Add a **"Default flyer language"** control to the profile/settings screen - a menu
listing all 13. Backed by a new `UserProfile.defaultFlyerLanguage` field.

### Onboarding (changed)

The language beat becomes a **single-select dropdown** (menu of 13), replacing the
multi-select chips. The chosen language is written directly to
`defaultFlyerLanguage`. The old multi-select `preferredLanguages` is retired from the
flow; the field stays on the model to avoid a needless SwiftData/CloudKit schema
migration, but is no longer populated.

New onboarding flow: demo -> open "what do you do?" (stores nothing) ->
"what language do you design in?" (dropdown) -> CTA.

### Review card (changed)

The review card gains a **`Language: English ▾`** row, pre-selected to
`defaultFlyerLanguage`. The copy shown on the card **stays English**; the row only
declares the render language. Tapping opens the 13-language menu; selecting updates
the session language. The copy does **not** regenerate on a language change (the
review is always English by design).

The existing **"Approve & generate"** button renders in whatever language is selected.
Generation still requires that explicit tap - no auto-generation.

## Persistence across edits

- `FlyerChatViewModel` holds `selectedLanguage: FlyerLanguage`, initialized from
  `defaultFlyerLanguage`.
- It is sent on **every** image-producing request - `approve` and all edit actions
  (`refine`, `resize`, `reference`, annotated edit). iOS sends language on each
  request, so the engine is stateless w.r.t. language (trusts the per-request value).
- The chosen language is stored on the **saved flyer** so later reuse/refine stays
  in-language.

## Architecture / data flow

```
Onboarding dropdown ─┐
Profile setting  ────┴─► UserProfile.defaultFlyerLanguage
                                   │ seeds
                                   ▼
                    FlyerChatViewModel.selectedLanguage ──► review-card row (changeable)
                                   │ included on approve + every edit
                                   ▼
        ChatRequest.language ──► POST /chat ──► ChatIn.language
                                                     │
                              build_project(language=…) ──► FlyerProject(language=…)
                                                     │
                          FlyerPromptBuilder(project).build()  ← existing, now fed a language
                                                     │ injects per-language translate+preserve instruction
                                                     ▼
                               Nano Banana Pro (google/gemini-3-pro-image-preview)
```

### iOS changes (file-level)

- `Models/Language.swift` - expand `FlyerLanguage` 5 -> 13 (raw values, `displayName`,
  `shortName`, `promptInstruction` with the dates/times exception). Consolidate
  `shortName` (currently an extension in `OnboardingChipQuestionView.swift`).
- `Models/UserProfile.swift` - add `defaultFlyerLanguage: String = "en"` + accessor.
- `App/ContentView.swift` - onboarding completion writes `defaultFlyerLanguage`
  (currently `setPreferredLanguages`, `ContentView.swift:46`).
- Onboarding view/script - swap the language chip beat for a dropdown beat.
- Profile/settings screen - add the "Default flyer language" menu.
- `Chat/ChatModels.swift` - add `language: String?` to `ChatRequest`.
- `Chat/FlyerChatViewModel.swift` - `selectedLanguage` state; include it in the payload
  builders for `approve` (`:303-319`), `refine`, `resize`, `reference`, annotated.
- The review card view - add the pre-selected `Language` row.
- Saved flyer model - store the language.

### Engine changes (file-level)

- `models.py` - expand `FlyerLanguage` 5 -> 13 (mirror iOS exactly); update
  `prompt_instruction` (dates/times).
- `prompt_builder.py` - soften the "ALL text" wrapper lines (`:271-276`, `:511-516`)
  to respect the preserved-items exceptions.
- `app.py` - add `language: Optional[str]` to `ChatIn` (`:14`).
- `compile_project.py` - `build_project(... language=…)` -> `FlyerProject(language=…)`
  (`:71-73`), defaulting to English on None/unknown.
- `tools.py` - inject the per-language instruction into the edit paths that currently
  hard-code English: `edit_reference` (`:96`), `annotated_edit` (`:108-113`),
  `resize_concept` (`:137-142`).
- Redeploy to Cloud Run (Release hits the deployed engine; pass both env vars).

## Edge cases & error handling

- **Missing/unknown language code** -> default English. Old clients and future unknown
  codes degrade gracefully.
- **Enum expansion is additive** -> existing stored `preferredLanguages` / flyer data
  still decodes.
- **RTL + English dates** -> dates stay left-to-right (existing pattern for the
  preserved items).
- **User types the brief in the target language** -> existing instruction translates to
  target; the review still shows English (brain normalizes to English), a small
  round-trip that's acceptable.
- **User approves English, ships copy they can't read** -> accepted for MVP; no
  back-translation/verification step.

## Testing / verification

- Build the iOS app (xcodebuild) after the enum + UI changes.
- Curl the local engine `/chat` with `language: "es"` and confirm the prompt package
  carries the translate instruction (ground truth per `curl localhost:8000`).
- Generate one sample flyer in each new language in the simulator; **eyeball Hindi and
  Bengali** rendering specifically. Flag any script that renders garbled rather than
  shipping it.
- Verify an edit (refine/resize) on a non-English flyer stays in-language.
- Owner handles the interactive simulator/device pass.

## Rollout

1. Land iOS + engine changes together (they must stay enum-mirrored).
2. **Redeploy the engine to Cloud Run** before any TestFlight/Release build.
3. `UserProfile` schema note: only an additive field (`defaultFlyerLanguage`); if
   `UserProfile` is CloudKit-synced, deploy the schema Dev -> Production before release.
