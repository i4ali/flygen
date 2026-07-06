# Multi-language flyer generation - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let users generate flyers in 13 languages by threading a `language` choice from a new profile default + review-card row through the wire into the engine's already-existing (currently dead) translation machinery, so Nano Banana Pro translates the copy at render time while keeping addresses/phone/email/URLs/dates/times verbatim.

**Architecture:** iOS sends an optional `language` code on every `/chat` request. The engine sets it on the `FlyerProject`, which the existing `FlyerPromptBuilder` already consumes to inject a per-language "translate + preserve" instruction into the image prompt. No new translation step; no new image model. Backward compatible - missing/unknown language defaults to English.

**Tech Stack:** iOS Swift/SwiftUI + SwiftData; Python engine (FastAPI on Cloud Run) calling OpenRouter's `google/gemini-3-pro-image-preview` ("nano-banana-pro").

**Design doc:** `docs/plans/2026-07-05-multi-language-flyer-design.md`

## Conventions for this plan (FlyGen-specific)

- **No TDD ceremony.** Verify each task by **building** (`xcodebuild`) and/or **curling the local engine** (`curl localhost:8000`), then hand interactive/visual checks to the owner. Do **not** write XCTest/pytest suites unless a task says so.
- **Work on `main`.** No branches, no worktrees.
- **Commits are checkpoints.** Commit points below are suggested groupings; the owner commits when ready. Never add an agent co-author.
- **The two enums MUST stay byte-for-byte mirrored** (raw values + instructions) between `FlyGen/FlyGen/Models/Language.swift` and `models.py`, or the wire `language` string won't map.
- **Engine changes require redeploy** to Cloud Run before any Release/TestFlight build (Release hits the deployed engine; Debug hits `localhost:8000`). See Task 14.
- Engine ground truth: run `./run-engine.sh` (auto-reclaims port 8000) and `curl localhost:8000` - a stale uvicorn can mask changes.

## The 13 languages (raw values)

`en` English, `es` Spanish, `ur` Urdu, `ar` Arabic, `zh` Chinese (Simplified) *(existing)*; `hi` Hindi, `fr` French, `bn` Bengali, `pt` Portuguese, `ru` Russian, `id` Indonesian, `de` German, `ja` Japanese *(new)*. RTL = Arabic + Urdu only.

Enum order: keep the existing 5 in place, append the 8 new (stable diff; order is display-only and trivially re-sortable later).

---

# Phase 1 - Engine (Python): the translation capability

Backward-compatible and independent of iOS; do this first and verify by curl.

### Task 1: Expand the `FlyerLanguage` enum + add dates/times to the preserve-list

**Files:**
- Modify: `models.py:152-180`

**Step 1:** Add the 8 new cases after `CHINESE` (line 158):

```python
    ENGLISH = "en"
    SPANISH = "es"
    URDU = "ur"
    ARABIC = "ar"
    CHINESE = "zh"
    HINDI = "hi"
    FRENCH = "fr"
    BENGALI = "bn"
    PORTUGUESE = "pt"
    RUSSIAN = "ru"
    INDONESIAN = "id"
    GERMAN = "de"
    JAPANESE = "ja"
```

**Step 2:** Extend the `display_name` dict (line 162-168) with:

```python
            "hi": "हिन्दी (Hindi)",
            "fr": "Français (French)",
            "bn": "বাংলা (Bengali)",
            "pt": "Português (Portuguese)",
            "ru": "Русский (Russian)",
            "id": "Bahasa Indonesia (Indonesian)",
            "de": "Deutsch (German)",
            "ja": "日本語 (Japanese)",
```

**Step 3:** In the `prompt_instruction` dict (line 173-179): (a) add `URLs, dates, or times` to the existing do-not-translate clause in `es`/`ur`/`ar`/`zh`, and (b) add the 8 new entries. Every non-English entry's preserve clause reads: `DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided` (RTL entries keep the trailing `in left-to-right order`). New entries (script hint where non-Latin):

```python
            "hi": "Generate all text content in Hindi (हिन्दी). Use Devanagari script. Translate headlines, descriptions, and calls-to-action to Hindi. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Hindi while preserving the intended meaning and tone.",
            "fr": "Generate all text content in French (Français). Translate headlines, descriptions, and calls-to-action to French. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to French while preserving the intended meaning and tone.",
            "bn": "Generate all text content in Bengali (বাংলা). Use Bengali script. Translate headlines, descriptions, and calls-to-action to Bengali. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Bengali while preserving the intended meaning and tone.",
            "pt": "Generate all text content in Portuguese (Português). Translate headlines, descriptions, and calls-to-action to Portuguese. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Portuguese while preserving the intended meaning and tone.",
            "ru": "Generate all text content in Russian (Русский). Use Cyrillic script. Translate headlines, descriptions, and calls-to-action to Russian. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Russian while preserving the intended meaning and tone.",
            "id": "Generate all text content in Indonesian (Bahasa Indonesia). Translate headlines, descriptions, and calls-to-action to Indonesian. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Indonesian while preserving the intended meaning and tone.",
            "de": "Generate all text content in German (Deutsch). Translate headlines, descriptions, and calls-to-action to German. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to German while preserving the intended meaning and tone.",
            "ja": "Generate all text content in Japanese (日本語). Translate headlines, descriptions, and calls-to-action to Japanese. DO NOT translate addresses, phone numbers, emails, URLs, dates, or times - keep them exactly as provided. If the user provides text in another language, translate it to Japanese while preserving the intended meaning and tone.",
```

**Verify:** `python -c "from models import FlyerLanguage as L; print(L('ja').display_name, L('hi').prompt_instruction[:40])"` -> prints the Japanese name + start of the Hindi instruction, no KeyError.

### Task 2: Soften the "ALL text" wrappers + add a language-gated RTL rendering instruction

**Files:**
- Modify: `prompt_builder.py:270-276`, `prompt_builder.py:511-517`, and add near `prompt_builder.py:386-393`

**Why:** (1) The wrapper text says "ALL text content appears in the target language," which fights the new dates/times (and existing address) exceptions - soften it. (2) The existing Arabic/Urdu calligraphy block is gated on `_has_arabic_content()` (detects Arabic **codepoints in the copy**), but in our flow the copy is still **English** at build time (translation happens at render), so it never fires for a target-language flyer - and it even says "do NOT translate the English text into Arabic," which is wrong for us. Add a **language-gated** rendering-quality instruction instead.

**Step 1:** Replace the wrapper at lines 272-275:

```python
        if self.project.language != FlyerLanguage.ENGLISH:
            sections.append(
                f"CRITICAL LANGUAGE REQUIREMENT: {self.project.language.prompt_instruction} "
                "All text content MUST appear in the target language, EXCEPT addresses, phone "
                "numbers, emails, URLs, dates, and times, which stay exactly as provided. "
                "Translate all other English or non-target-language text; do not leave "
                "translatable text in English."
            )
```

**Step 2:** Replace the reminder at lines 513-516:

```python
            parts.append(
                f"IMPORTANT: All text below MUST appear in {self.project.language.display_name}, "
                "EXCEPT addresses, phone numbers, emails, URLs, dates, and times (keep those exactly "
                "as provided). Translate any other English or non-target-language text; if text is "
                "already in the target language, use it as-is."
            )
```

**Step 3:** Add a new section immediately after the existing Arabic/Urdu block (after line 393):

```python
        # 14.6 RTL rendering quality when the TARGET language is Arabic/Urdu. The copy is still
        # English at build time (translated at render), so _has_arabic_content() above won't fire;
        # gate on the target language and give calligraphy-quality guidance WITHOUT a "don't
        # translate English" clause (here we DO want translation).
        if self.project.language in (FlyerLanguage.ARABIC, FlyerLanguage.URDU):
            sections.append(
                f"RIGHT-TO-LEFT RENDERING: Render all translated text as correctly-spelled, "
                f"connected {self.project.language.display_name} calligraphy laid out right-to-left. "
                "Each phrase must appear EXACTLY ONCE, cleanly placed so nothing overlaps, "
                "duplicates, or collides. Keep addresses, phone numbers, emails, URLs, dates, and "
                "times in their original left-to-right form."
            )
```

**Verify:** covered by Task 5's curl (the `es` and `ar` prompt packages show the softened wrapper / RTL line).

### Task 3: Thread `language` from the wire into the `FlyerProject`

**Files:**
- Modify: `engine/app.py:14-29` (add field), `engine/app.py:52-61` (pass to handlers)
- Modify: `engine/orchestrator.py:144-145` + `:154-155` (approval), `:165-166` + `:183` (refine)
- Modify: `engine/compile_project.py:50-51` + `:71-73` (build_project)

**Step 1:** `engine/app.py` - add to `ChatIn` (after line 29):

```python
    language: Optional[str] = None      # target flyer language code (en, es, ...); None -> English
```

**Step 2:** `engine/app.py` `run_turn` - pass `body.language` into the two handlers that build a project:

```python
    if action == "approve":
        return eng.handle_approval(field_overrides=body.field_overrides,
                                   decision_overrides=body.decision_overrides,
                                   answers=body.answers or {},
                                   user_photos_b64=body.user_photos_b64,
                                   selected_elements=body.selected_elements,
                                   language=body.language)
    if action == "refine":
        return eng.handle_refine(body.prior_image_path, body.instruction or "",
                                 prior_image_b64=body.prior_image_b64,
                                 annotated=bool(body.annotated),
                                 language=body.language)
```

(Leave `reference` and `resize` untouched - see Task 4.)

**Step 3:** `engine/orchestrator.py` - accept + forward `language`:

- `handle_approval(...)` signature (line 144-145): add `language=None`. Then line 154-155:
  ```python
  project = self._build_project(turn, field_overrides or {}, decision_overrides or {},
                                selected_elements=selected_elements, language=language)
  ```
- `handle_refine(...)` signature (line 165-166): add `language=None`. Then line 183:
  ```python
  project = self._build_project(turn, {}, {}, None, language=language)
  ```

**Step 4:** `engine/compile_project.py` `build_project` - accept `language` and set it on the project:

```python
def build_project(turn, field_overrides: dict, decision_overrides: dict,
                  selected_elements: Optional[list] = None,
                  language: Optional[str] = None) -> FlyerProject:
    ...
    try:
        lang = FlyerLanguage(language) if language else FlyerLanguage.ENGLISH
    except ValueError:
        lang = FlyerLanguage.ENGLISH          # unknown code -> safe English default
    return FlyerProject(category=_category(turn.category), language=lang, text_content=tc,
                        output=output, visuals=visuals, colors=colors,
                        imagery_description=imagery, special_instructions=instructions)
```

Ensure `FlyerLanguage` is imported in `compile_project.py` (it imports from `models`; add to the import if not already present).

**Verify:** covered by Task 5.

### Task 4: Confirm refine honors `project.language`; leave reference/resize brain-free

**Files:** Read `engine/tools.py` `refine_concept` (the `self._refine` target) + `_generate_concepts`.

**Reasoning (already decided):**
- `approve` -> `_generate_concepts(project)` -> `FlyerPromptBuilder(project).build()` - language flows automatically once Task 3 sets `project.language`. **Primary path, done.**
- `refine` (non-annotated) -> `_build_project(...)` rebuild (now carries language) -> `self._refine(project, ...)`. **Verify** `refine_concept` surfaces `project.language` in its prompt (via `FlyerPromptBuilder` or an explicit `project.language.prompt_instruction`). If it builds a light prompt that ignores the project, append `project.language.prompt_instruction` when `project.language != ENGLISH`.
- `refine` (annotated), `reference`, `resize`: **no language** - annotated/reference edits are brain-free light prompts on an existing/uploaded image (translating an uploaded flyer would be wrong), and `resize` says "preserve ALL text exactly as shown," so a resized flyer keeps its already-translated text. This matches "language sticks to the flyer" without extra plumbing.

**Verify:** `refine` on a non-English concept in the local integration test (Task 12/13 handoff) keeps the language; note in the commit what `refine_concept` needed (nothing vs. an injected line).

### Task 5: Local curl verification of the engine

**Step 1:** Start the engine: `./run-engine.sh` (serves `localhost:8000`).

**Step 2:** Approve a brief with `language: "es"` and confirm the generated concept renders Spanish. Minimal smoke (adapt an existing smoke script or curl `/chat` with `action:"approve"`, a small `brief`, and `language:"es"`). Since `/chat` streams SSE and calls the image model, prefer a direct unit check of the prompt package:

```bash
python -c "
from models import FlyerProject, FlyerCategory, FlyerLanguage, TextContent
from prompt_builder import FlyerPromptBuilder
p = FlyerProject(category=FlyerCategory.EVENT, language=FlyerLanguage.SPANISH,
                 text_content=TextContent(headline='Summer Sale', date='Saturday, July 12'))
pkg = FlyerPromptBuilder(p).build()
assert 'target language' in pkg['main_prompt'] and 'dates' in pkg['main_prompt']
print('OK: Spanish instruction + preserve-dates present')
p.language = FlyerLanguage.ARABIC
assert 'RIGHT-TO-LEFT RENDERING' in FlyerPromptBuilder(p).build()['main_prompt']
print('OK: Arabic RTL rendering line present')
"
```

Expected: both `OK:` lines print. (Confirms Tasks 1-3 end-to-end in the prompt.)

**Commit checkpoint (engine):** `feat(engine): multi-language flyer generation (13 languages, translate-at-render)`

---

# Phase 2 - iOS: mirror the enum + carry `language` on the wire

### Task 6: Mirror `FlyerLanguage` on iOS (13 cases) + `shortName`

**Files:**
- Modify: `FlyGen/FlyGen/Models/Language.swift:3-34`
- Modify: `FlyGen/FlyGen/Views/Onboarding/OnboardingChipQuestionView.swift:117-128` (`shortName`)

**Step 1:** Add the 8 new cases (append after `.chinese`, line 8) - raw values MUST match Python exactly:

```swift
    case english = "en"
    case spanish = "es"
    case urdu = "ur"
    case arabic = "ar"
    case chinese = "zh"
    case hindi = "hi"
    case french = "fr"
    case bengali = "bn"
    case portuguese = "pt"
    case russian = "ru"
    case indonesian = "id"
    case german = "de"
    case japanese = "ja"
```

**Step 2:** Extend `displayName` (line 10-18), `promptInstruction` (line 20-33), and `shortName` (OnboardingChipQuestionView.swift:119-127) - all three are exhaustive `switch`es with no `default`, so the compiler will flag any missing case. Use the exact same strings as Python Task 1 (displayName + promptInstruction), and for `shortName`: `हिन्दी`, `Français`, `বাংলা`, `Português`, `Русский`, `Indonesia`, `Deutsch`, `日本語`. Also add `URLs, dates, or times` to the existing 5 non-English `promptInstruction` strings so iOS matches Python (iOS `promptInstruction` is only used by the retired wizard today, but keep them mirrored).

**Verify:** `xcodebuild -scheme FlyGen -destination 'platform=iOS Simulator,name=iPhone 16' build` compiles (exhaustive switches force all cases handled). See Task 14 for the exact build command.

### Task 7: Add `language` to `ChatRequest` and stamp it centrally

**Files:**
- Modify: `FlyGen/FlyGen/Chat/ChatModels.swift:5-19`
- Modify: `FlyGen/FlyGen/Chat/FlyerChatViewModel.swift` (add state + stamp in the central `run(...)`)

**Step 1:** Add one optional field to `ChatRequest` (implicit memberwise init absorbs it; all call sites keep compiling):

```swift
    var annotated: Bool?
    var language: String?               // target flyer language code; stamped centrally in run(...)
```

**Step 2:** Add session language state to `FlyerChatViewModel` (near the other `@Published`s):

```swift
    /// The flyer's target language for this session. Seeded from the profile default
    /// (see FlyerChatView.onAppear), changeable on the review card, sticky across edits.
    @Published var selectedLanguage: FlyerLanguage = .english
```

**Step 3:** Stamp it in the single `run(_:thinking:)` dispatch so **every** request carries it (DRY - one edit instead of 6+ call sites). Find `func run(` in `FlyerChatViewModel.swift` and set `language` on the request before it's encoded/sent, e.g.:

```swift
    private func run(_ request: ChatRequest, thinking: String) {
        var request = request
        request.language = selectedLanguage.rawValue
        // ...existing body unchanged...
    }
```

The engine ignores `language` on non-generating turns and on `reference`/`resize`, so stamping universally is harmless and future-proof.

**Verify:** builds (Task 14). Runtime confirmation in Task 13.

### Task 8: Persist the language on chat-origin saved flyers

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatViewModel.swift:386` (`chatFlyerProject()`)

**Why:** `SavedFlyer.projectData` is an encoded `FlyerProject`, which already has a `language` field - but `chatFlyerProject()` builds `FlyerProject(category:)` without it, so chat flyers save as English. Setting it makes the saved flyer's language correct (and queryable later) for free.

**Step 1:** Set the language when constructing the project:

```swift
        FlyerProject(category: ..., language: selectedLanguage, ...)   // was: no language arg
```

(Match the actual initializer args at line 386; just add `language: selectedLanguage`.)

**Verify:** builds. No new persisted field on `SavedFlyer` (no schema migration).

**Commit checkpoint (iOS wire):** `feat(iOS): send flyer language on chat requests + persist on saved flyers`

---

# Phase 3 - iOS UI: the profile default, onboarding dropdown, review-card row

### Task 9: Add `defaultFlyerLanguage` to `UserProfile`

**Files:**
- Modify: `FlyGen/FlyGen/Models/UserProfile.swift` (declaration ~line 29, init ~line 43, accessors ~line 84)

**Step 1:** Add the stored property (CloudKit needs a default value) near `preferredLanguages` (line 29):

```swift
    /// The user's default flyer language (raw value). Seeded at onboarding, editable in Settings,
    /// and used to pre-select the review-card language row. Replaces the retired preferredLanguages
    /// multi-select as the single source for a default.
    var defaultFlyerLanguage: String = "en"
```

**Step 2:** Initialize it in `init()` (after line 43): `self.defaultFlyerLanguage = "en"`.

**Step 3:** Add an enum accessor + setter (mirroring the `userRole` triad, near line 84):

```swift
    var defaultFlyerLanguageEnum: FlyerLanguage {
        FlyerLanguage(rawValue: defaultFlyerLanguage) ?? .english
    }
    func setDefaultFlyerLanguage(_ language: FlyerLanguage) {
        defaultFlyerLanguage = language.rawValue
    }
```

**CloudKit note:** this is an additive, defaulted field. If `UserProfile` is CloudKit-synced, deploy the schema Dev -> Production before release (per global CLAUDE.md).

**Verify:** builds.

### Task 10: Settings - "Default flyer language" row

**Files:**
- Modify: `FlyGen/FlyGen/Views/Settings/SettingsView.swift` (add `@Query`/`modelContext`; add a row to `generationSettingsSection`, lines 78-119)
- Reuse: `FlyGen/FlyGen/Views/Components/SelectionCard.swift:293` (`LanguagePicker`)

**Step 1:** Give `SettingsView` profile access (it has none today):

```swift
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
```

**Step 2:** Add a "Default flyer language" row as a third row in `generationSettingsSection` (after the Provider row, before the card's `.background`), using a `Menu` bound to the profile. Mirror the existing row layout (`HStack { Text(label); Spacer(); Menu {...} label {...} }`), listing `FlyerLanguage.allCases` with `displayName` + a checkmark on the current, writing through `profile.setDefaultFlyerLanguage(_:)` + `try? modelContext.save()`. (You may reuse `LanguagePicker` if its "Output Language" framing fits; otherwise mirror the row style for visual consistency with Model/Provider.)

**Verify:** builds; owner confirms the row appears and persists (Task 14 handoff).

### Task 11: Onboarding - single-select language dropdown (replaces multi-select chips)

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingViewModel.swift` (`selectedLanguages` Set -> single; `collapsedReply`; `finish`; `onComplete` type; seed at line 50)
- Modify: `FlyGen/FlyGen/Views/Onboarding/OnboardingChipQuestionView.swift` (render a dropdown for the language question)
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingView.swift:9` (`onComplete` type)
- Modify: `FlyGen/FlyGen/App/ContentView.swift:42-59` (persist the single default)

**Step 1:** In `ChatOnboardingViewModel`, change to single selection:

```swift
    @Published var selectedLanguage: FlyerLanguage = .english   // was: selectedLanguages: Set<FlyerLanguage>
```
Seed it at `start(reduceMotion:)` (line 50): `selectedLanguage = Self.deviceLanguage()`. Update `collapsedReply(for:)` (204-210) to `return selectedLanguage.shortName`. Delete `orderedLanguages()` (213-215). Change `onComplete` type (37-38) to `((FlyerLanguage) -> Void)?` and `finish()` (91-94) to `onComplete?(selectedLanguage)`.

**Step 2:** In `OnboardingChipQuestionView` (already language-only after the earlier category removal), replace the multi-select chips body with the reusable dropdown. Bind `LanguagePicker(selection: $vm.selectedLanguage)` (from `SelectionCard.swift:293`), keep the existing Continue button that calls `vm.submitCurrentQuestion()`. Keep the struct/file name to avoid pbxproj edits; update the doc comment to say "language dropdown."

**Step 3:** In `ChatOnboardingView.swift:9`, change `let onComplete: ([FlyerLanguage]) -> Void` to `let onComplete: (FlyerLanguage) -> Void`.

**Step 4:** In `ContentView.swift:42-59`, change the closure to persist the single default:

```swift
                ChatOnboardingView { language in
                    if let profile = userProfiles.first {
                        profile.setDefaultFlyerLanguage(language)
                        try? modelContext.save()
                    }
                    hasCompletedOnboarding = true
                    // ...unchanged paywall block...
                }
```

**Verify:** builds; owner confirms onboarding shows a language dropdown and the choice lands in Settings (Task 14).

### Task 12: Review card - pre-selected "Language" row

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatView.swift` (`ReviewCard`, lines 589-664; dispatch at 146-148)

**Step 1:** Give `ReviewCard` a binding to the session language so the row reflects and updates `vm.selectedLanguage`:

```swift
private struct ReviewCard: View {
    let review: ReviewProposalDTO
    @Binding var language: FlyerLanguage        // add
    // ...existing...
```

**Step 2:** In the dispatch (line 146-148), pass the binding:

```swift
case .review(let r):  ReviewCard(review: r, language: $vm.selectedLanguage,
                          isBlocked: isGenerationBlocked,
                          onBlocked: { showingPaywall = true },
                          onApprove: { vm.approve(fieldOverrides: $0, decisionOverrides: $1, selectedElements: $2) })
```

`vm.selectedLanguage` is already stamped onto the approve request by `run(...)` (Task 7), so no change to the approve callback signature.

**Step 3:** Add a "Language" row inside `AssistantCard { ... }`, right after the `ForEach(review.decisions)` block (~line 648), mirroring the decision-row Menu markup (label in `FGTypography.caption`/`textTertiary`; `Menu` styled `FGColors.backgroundTertiary` / `FGSpacing.inputRadius` / `chevron.up.chevron.down`):

```swift
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                Text("Language").font(FGTypography.caption).foregroundColor(FGColors.textTertiary)
                Menu {
                    ForEach(FlyerLanguage.allCases, id: \.self) { lang in
                        Button { language = lang } label: {
                            HStack { Text(lang.displayName); if language == lang { Image(systemName: "checkmark") } }
                        }
                    }
                } label: {
                    HStack {
                        Text(language.displayName).font(FGTypography.bodySmall).foregroundColor(FGColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundColor(FGColors.textTertiary)
                    }
                    .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                    .background(FGColors.backgroundTertiary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
                }.disabled(approved)
            }
```

The card's copy stays English (unchanged); only this row declares the render language.

**Verify:** builds; owner confirms the row shows the default and changing it sticks.

### Task 13: Seed `vm.selectedLanguage` from the profile default

**Files:**
- Modify: `FlyGen/FlyGen/Chat/FlyerChatView.swift` (wherever the view has profile access / `.onAppear`)

**Step 1:** When the chat view appears, seed the session language from the profile (falling back to English). If `FlyerChatView` lacks a `@Query userProfiles`, add one (mirroring `ContentView`), then:

```swift
        .onAppear { vm.selectedLanguage = userProfiles.first?.defaultFlyerLanguageEnum ?? .english }
```

Because `selectedLanguage` is sticky for the session, seeding on appear is enough; the review-card row lets the user override per flyer.

**Verify:** builds. Runtime: with a profile default of, say, Spanish, a fresh flyer's review row shows Spanish.

**Commit checkpoint (iOS UI):** `feat(iOS): flyer language - profile default, onboarding dropdown, review-card row`

---

# Phase 4 - Build, integration test, deploy

### Task 14: Build iOS + integration test + owner handoff

**Step 1:** Build:
```bash
xcodebuild -project FlyGen/FlyGen.xcodeproj -scheme FlyGen \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```
Expected: `BUILD SUCCEEDED`. (Confirm the exact scheme/project path; adjust simulator name to one installed.)

**Step 2:** Local integration (Debug hits `localhost:8000`): with `./run-engine.sh` running, the owner drives the simulator - onboarding dropdown -> a flyer with the review-card language set to Spanish -> Approve -> confirm the 3 concepts render Spanish with the **date left in English** and address/phone unchanged. Then a **refine** ("make the headline bigger") stays Spanish.

**Step 3 (owner, per owner-handles-simulator-verification):** eyeball rendering for the risky new scripts specifically - **Hindi (Devanagari)** and **Bengali** - plus **Arabic/Urdu** RTL. Flag any that render garbled; if a script is consistently broken, drop that case from both enums rather than ship unreadable text.

### Task 15: Deploy the engine to Cloud Run (before any Release/TestFlight build)

**Files:** none (deploy only). Per `CLAUDE.md`:

```bash
gcloud run deploy flygen-engine --source . --region us-central1 \
  --allow-unauthenticated --memory 1Gi --timeout 600 \
  --set-env-vars OPENROUTER_API_KEY=<key>,ENGINE_SHARED_SECRET=<secret> --quiet
```

(Pass BOTH env vars per the Cloud Run deploy memory.) Release builds hit this deployed engine; without redeploy, multi-language silently fails in production.

**Step 2:** If `UserProfile` is CloudKit-synced, deploy the CloudKit schema Dev -> Production (the additive `defaultFlyerLanguage` field) before releasing.

**Commit checkpoint:** bump build number (`Info.plist`) when cutting the release, per the owner's normal flow.

---

## Risk / rollback

- **Fully backward compatible.** `language` is optional everywhere; an old client or an unknown code -> English. Engine can deploy ahead of iOS safely.
- **Enum drift is the main footgun.** If iOS and Python raw values/instructions diverge, a language silently falls back to English (unknown code) - keep them mirrored (Tasks 1 & 6 use identical strings).
- **Garbled scripts.** Mitigation is the Task 14 eyeball pass on Hindi/Bengali/Arabic/Urdu; dropping a case is a one-line revert in both enums.
- **Rollback:** revert the engine deploy (previous Cloud Run revision) and/or the iOS commits; no data migration to unwind (additive field only).
