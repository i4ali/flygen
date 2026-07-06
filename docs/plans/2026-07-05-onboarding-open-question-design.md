# Onboarding: Open Personal Question - Design

- **Date:** 2026-07-05
- **Status:** Design approved, implementation pending
- **Surfaces:** `FlyGen/FlyGen/Views/Onboarding/` (script, view model, view, chip-question file) + `FlyGen/FlyGen/App/ContentView.swift`

## Goal

Replace the onboarding's 15-chip category question with one warm, open, free-text question. Ticking
15 category boxes reads as a cold taxonomy survey and is a poor gauge of what someone actually does.
A single "What do you do?" in the user's own words is more personal and a truer signal - even though
we deliberately store nothing from it.

## The change

**Before:** demo -> "What do you make?" (15 category chips, multi-select) -> "What language?" (5 chips) -> CTA

**After:** demo -> **"What do you do?"** (one open text line) -> warm reply -> "What language?" (5 chips, unchanged) -> CTA

The demo, the language question, and the CTA are untouched. Only the category beat changes, plus the
lead-in/closing copy around it.

## Behavior

New thread sequence (replacing the `.category` chip beat):

1. Assistant: *"Your turn. First - what do you do?"*
2. **Text-input beat:** an inline text field in the Aurora chat style. Placeholder *"e.g., I run a
   home bakery"*, a send arrow (disabled while the field is empty), and a quiet **Skip**.
   - On **send**, the typed words become a normal user bubble, then the *answered* warm reply.
   - On **skip**, no user bubble is added, then the *skipped* warm reply.
3. Assistant warm reply (skip-aware, so it never reads wrong after a skip):
   - answered: *"Nice. Let's make you something that gets noticed."*
   - skipped: *"All good - let's get you noticed."*
4. Language chip question (unchanged), then the existing closing line and CTA.

### What we store: nothing

The text answer is **not** persisted, classified, or synced. No category inference, no profile, no
CloudKit write. It is a rapport beat: the user articulates their thing, is heard, and moves on. The
copy is intentionally honest and does not promise "I'll remember this," because we won't.

### Scaffolding

Placeholder hint + Skip only. **No example chips** - they would quietly reintroduce the "menu of
options" feel we are removing. The placeholder steers enough; Skip means no one is trapped by a blank
field.

## Consequence: Explore personalization

New users now finish onboarding with `preferredCategories == []`. `ExploreTab.isPreferredSample`
already returns `false` for everything in that case, so Explore degrades gracefully to showing all
samples equally with no "For You" boost. Nothing breaks. Personalization comes later from what the
user actually creates.

## iOS implementation

- **`OnboardingScript.swift`**
  - Add beat `case textQuestion(placeholder: String)` to `OnboardingBeat`. The **prompt is a normal
    preceding `.assistant("Your turn. First - what do you do?")` beat** (not carried inside the text
    beat) so the question stays visible above the answer - the text beat renders only the field.
  - Remove `OnboardingQuestionKind.category` (language becomes the only chip-question kind).
  - Replace the `.chipQuestion(.category ...)` beat with `.assistant(...)` + `.textQuestion(...)`.
  - Add the two reply strings as constants (`textReplyAnswered`, `textReplySkipped`) so the copy still
    lives in the script. The warm reply is **not** a static beat in the array (it branches on skip);
    the view model appends the right one - the beat after `.textQuestion` is the language question.
- **`ChatOnboardingViewModel.swift`**
  - Drop `selectedCategories`, `orderedCategories()`, and the category branch of `collapsedReply`.
  - Add `@Published var textDraft: String = ""` bound by the input view, plus a `RenderedBeat.Kind`
    case for the active text question.
  - Add `submitTextQuestion(skipped: Bool)`: on send, collapse `textDraft` into a `.user` bubble;
    on skip, add no bubble. Then append an `.assistant` bubble with `textReplyAnswered` /
    `textReplySkipped` accordingly, clear the draft, set `isInteracting = false`, and `resume()`.
    Handle the new beat in `runLoop` the same way `.chipQuestion` pauses the runner.
  - Change `onComplete` to `(([FlyerLanguage]) -> Void)?` and `finish()` to pass only languages.
- **`ChatOnboardingView.swift`**
  - Change `onComplete` to `([FlyerLanguage]) -> Void`.
  - Add a `beatView` case rendering the new **`OnboardingTextQuestionView`** (inline field + send +
    Skip), reusing the assistant-bubble + button styling from the chip-question view. Ensure the
    field scrolls into view when focused (keyboard avoidance).
- **`OnboardingChipQuestionView.swift`**
  - Remove the `.category` branch and the now-unused `FlyerCategory.onboardingLabel` extension.
  - Add `OnboardingTextQuestionView` here (same file, both are "interactive onboarding question"
    views) to avoid a classic-pbxproj file addition. If a separate file is preferred, register it
    in the `.xcodeproj` via the `xcodeproj` gem.
- **`ContentView.swift`**
  - Update the `ChatOnboardingView` closure to `{ languages in ... }`: keep `setPreferredLanguages`
    + save; **remove** `setPreferredCategories` and the `savePreferredCategories` CloudKit call. The
    post-onboarding paywall logic is unchanged.

No engine change, no CloudKit schema change, no data migration - `preferredCategories` simply stays
at its default `[]`.

## Out of scope (possible follow-on)

Auto-populate `preferredCategories` from the categories of flyers the user actually creates (the
engine already classifies each flyer), so Explore's "For You" earns its personalization from behavior
rather than an upfront survey. Not part of this change.

## Verification

Build + run in the simulator (owner handles the visual/interactive check): confirm the open question
renders, send and Skip both advance the thread, the language question and CTA still work, and Explore
shows all samples with no crash for a fresh (empty-preferences) profile.
