# Chat-First Onboarding - Design

**Date:** 2026-07-02
**Status:** Design approved, ready for implementation plan
**Topic:** Replace the wizard-era onboarding with a single scrollable chat thread that demos the real product, then collects minimal personalization.

---

## Problem

The current onboarding is a 9-screen paged wizard (`Views/Onboarding/InteractiveOnboardingView` + `OnboardingViewModel`, ~2,500 lines total). Its centerpiece, `WorkflowDemoScreen` (614 lines), auto-plays a demo of the **retired** step-by-step creation wizard (Category -> Style -> Text -> Logo -> QR -> Colors -> AI Analysis). That feature no longer ships (`FeatureFlags.classicCreationEnabled = false`), so onboarding advertises a product we don't have. Two of its Lottie assets (`celebration`, `onboarding-loading`) are also missing from the bundle and silently fail to render.

The app is now chat-first. Onboarding should teach the chat, in the chat's own language.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Scope | Tight chat-centric rebuild - delete the 9-screen wizard flow |
| Structure | **One continuous scrollable chat thread** that *is* the onboarding |
| Demo playback | **Auto-plays** hands-free (self-typing, auto-scroll), then hands the user the controls |
| Personalization | Two questions only: **categories** (what you make) + **language** |
| Demo example | Neutral **summer BBQ fundraiser** (no faith/cultural specificity) |
| Reveal images | **3 real flyers generated via the live engine**, bundled as onboarding assets |
| Motion | Pure SwiftUI (no Lottie) |

Dropped from the old flow: user role, visual style, mood, color scheme (the chat now decides style/mood/color per-flyer; role only ever pre-sorted categories, which the user now picks directly).

---

## The experience - beat by beat

A single `ScrollView` chat thread. Beats append top-to-bottom and auto-scroll, exactly like the real chat's stream. Timing annotations matter because pacing *is* the design.

**① Greeting** `~0-2s, auto`
Dark purple-tinted hero gradient (`FGGradients.heroBackground`). Small FlyGen wordmark at top. Assistant's first line fades + rises in (plain gray text, identical to the real chat):
> "Hi - I'm your designer. Give me a sentence, I'll give you a flyer. Watch."

**② The sentence types itself** `~2-5s, auto`
A violet user bubble appears on the right and types itself out character-by-character (invisible-hand typewriter), then "sends" with a settle:
> "Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome."

**③ It thinks** `~5-8s, auto`
The real chat's typing indicator (cyan spinner + contextual text) cycles:
> "Reading your idea..." -> "Designing 3 concepts..."

A brief chip-row slides in to prove comprehension:
> `BBQ Fundraiser · Sat 12pm · Lincoln Park · $10`

**④ The reveal - the money shot** `~8-11s, auto`
Three real flyer cards bloom in, staggered ~0.15s apart: each scales 0.9 -> 1 while the signature radial glow (violet -> cyan) blooms behind them and a soft shimmer sweeps across. Assistant line above:
> "Three ways to go - and that was one sentence."

**⑤ The turn** `~11s, auto -> interactive`
Breaks the fourth wall to the real user. Gentle haptic; auto-scroll stops; everything below responds to touch:
> "Your turn. Two quick things so I can tailor everything to you."

**⑥ "What do you make?"** `interactive`
Category chips animate in (wrapping capsule flow, all `FlyerCategory` values, multi-select). Tapping fills a chip violet with a haptic. **Continue** collapses the selected chips into a sent user bubble (`matchedGeometryEffect`) - the taps literally become the chat reply. Continue is always enabled (selecting nothing is allowed; Explore just stays generic).

**⑦ "What language(s)?"** `interactive`
Same interaction with the 5 `FlyerLanguage` chips (English / Espanol / اردو / العربية / 中文), device language pre-selected. Select -> Continue -> collapses into a bubble.

**⑧ Wrap + handoff** `auto`
Assistant reflects the answers back, then a gradient CTA button with the accent glow:
> "Perfect - your flyers, your language. Let's make the first one."
>
> **[ Make your first flyer ]**

Tap -> persist prefs, flip the onboarding flag, drop into the app (Home tab). Tiny sparkle + haptic on tap.

**Skip:** a quiet "Skip" top-right throughout. It fast-forwards the movie (①-⑤) straight to ⑥. The two questions are only ~4 taps, so they are not skippable as a group; each is individually skippable via Continue-with-nothing-selected (applies sensible defaults: no category filter, device language).

---

## Technical architecture

### New files
```
Views/Onboarding/
  ChatOnboardingView.swift        // scrollable thread + coordinator (ScrollViewReader, auto-scroll)
  ChatOnboardingViewModel.swift   // script state-machine + timing, @Published transcript
  OnboardingScript.swift          // the storyboard AS DATA (ordered [Beat])
  Components/ChipQuestion.swift   // interactive multi-select chip question (categories/language)
  Components/DemoFlyerReveal.swift// the 3-card staggered radial-glow reveal
```

### The state machine
The storyboard is a declarative ordered list of beats:
```
enum Beat {
  case assistantText(String)
  case userTypes(String)          // typewriter
  case thinking([String])         // cycling status lines
  case briefRow([String])         // comprehension chips
  case flyerReveal([ImageName])   // the 3-card bloom
  case chipQuestion(ChipQuestionSpec)  // STOPS, waits for user
  case cta(title: String)
}
```
`ChatOnboardingViewModel` walks the auto beats with `async` / `await Task.sleep` (cancellable - replaces the old `Timer` + `DispatchQueue.asyncAfter` soup), appending each to a `@Published var transcript: [RenderedBeat]` the view renders and auto-scrolls. At a `.chipQuestion` beat it suspends and awaits the user's Continue, then resumes. All durations live in one `Timing` constants block.

### Honest bubbles (one source of truth)
The real chat's `AssistantBubble`, `UserBubble`, and `TypingBubble` are currently `private` inside `Chat/FlyerChatView.swift`. Extract them into a shared `Chat/ChatBubbleViews.swift` so both the real chat and the onboarding demo render from the identical components. The demo cannot drift from reality, and it is less code overall. Small, contained refactor of the chat file.

### Completion contract (preserved)
`ContentView` continues to gate on `@AppStorage("hasCompletedOnboarding")` and pass a completion callback. Change only the payload:
- **Old:** grab-bag of categories + role + visualStyle + mood + colorScheme + languages.
- **New:** `{ categories: [FlyerCategory], languages: [FlyerLanguage] }`.

Trim the closure at `ContentView.swift:40-65` to persist only those two onto `UserProfile`, keep the existing CloudKit category sync, then set `hasCompletedOnboarding = true`. Everything downstream of onboarding is unchanged. (Verify exact `UserProfile` field names + the CloudKit sync call against the real code during implementation.)

### Motion (pure SwiftUI, reuses `FGAnimations`)
- **Typewriter** - a growing substring driven by an async loop (~30-40ms/char).
- **Bubble entrance** - existing pattern: opacity 0->1 + offset y 20->0 + `FGAnimations.spring`.
- **Typing indicator** - reuse the real chat's `TypingBubble` (honesty). Optional later upgrade: bouncing 3-dot indicator applied to *both* real chat and onboarding.
- **Flyer reveal** - staggered (0.15s) scale + opacity, blurred radial-glow `Circle` bloom (the app's recurring motif), optional `.fgShimmer()` sweep.
- **Chips -> bubble collapse** - `matchedGeometryEffect` (new to the codebase; the clean way to do this transition).
- **Auto-scroll** - `ScrollViewReader` scrolling to the last beat on `transcript` change, like the real chat.

---

## What gets deleted vs. preserved

**Deleted (~2,500 lines):** `InteractiveOnboardingView`, `OnboardingContainerView`, `OnboardingViewModel`, `WorkflowDemoScreen`, and the per-screen files (`WelcomeScreen`, `UserRoleScreen`, `CategoryPreferencesScreen`, `LanguagePreferencesScreen`, `BrandKitScreen`'s onboarding page, `BuildingExperienceScreen`, `SampleShowcaseScreen`, `ReadyToCreateScreen`), the orphaned `AIGenerationScreen` + `SampleLoadingScreen`, and the mock components (`MockSelectionChip`, onboarding `OnboardingProgressIndicator`).

**Preserved:**
- `BrandKitIntroSheet` - shown separately to *existing* users via `hasSeenBrandKitIntro`; a different flow. Relocate it out of `BrandKitScreen.swift` into its own file so deleting the onboarding screen is clean.
- `SampleFlyers` asset catalog.

**Follow-up (not this change):** Lottie (`lottie-ios`) is used only by the old onboarding. Once this ships, the dependency and `LottieAnimationView` wrapper can be removed. Tracked as a separate cleanup.

---

## Assets - the 3 reveal flyers

Generate three real flyers from the BBQ sentence via the live FlyGen engine, pick the three strongest, and bundle them in a new `OnboardingDemo` asset set (portrait). The reveal then shows genuine product output. This is a one-round dependency (owner generates + selects) that blocks final visual verification of beat ④, but not the build of everything else.

## Personalization data

- **Categories** (multi-select, optional) -> `UserProfile`, synced to CloudKit; drives Explore "For You" badges.
- **Languages** (multi-select, device language pre-selected) -> `UserProfile`; drives localization.
- Nothing else is collected.

## Accessibility & edge cases

- **Reduce Motion** - content appears instantly (no typewriter, no stagger) but still sequences beat-to-beat; no glow bloom / shimmer.
- **VoiceOver** - auto-play switches to **tap-to-advance** so nothing races the screen reader; chips carry proper labels + selected traits.
- **Skip** - top-right; fast-forwards ①-⑤ to ⑥.
- **Backgrounding mid-animation** - the walking `Task` cancels on disappear and the thread restores its last completed beat on reappear (no half-typed state).
- **Small screens (SE)** - thread scrolls; no fixed-height assumptions.
- **Re-onboarding** - still gated solely by `hasCompletedOnboarding`.

## Verification

Per project norms (skip formal TDD, favor momentum): verify by build + simulator walkthrough. Manual checklist - the thread auto-plays and auto-scrolls; typewriter + reveal read well; Skip fast-forwards correctly; both chip questions select/collapse; CTA persists categories + languages to `UserProfile` and flips the flag; Reduce Motion + VoiceOver paths behave.

## Copy (draft)

| Beat | Text |
|---|---|
| Greeting | "Hi - I'm your designer. Give me a sentence, I'll give you a flyer. Watch." |
| User types | "Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome." |
| Thinking | "Reading your idea..." -> "Designing 3 concepts..." |
| Brief row | `BBQ Fundraiser · Sat 12pm · Lincoln Park · $10` |
| Reveal | "Three ways to go - and that was one sentence." |
| Turn | "Your turn. Two quick things so I can tailor everything to you." |
| Q1 | "What do you make?" |
| Q2 | "What language do you design in?" |
| Wrap | "Perfect - your flyers, your language. Let's make the first one." |
| CTA | "Make your first flyer" |

## Open items

1. **Where the CTA lands** - default is the Home tab (matches current behavior). Possible enhancement: deep-link straight into a fresh chat to strike while the iron's hot. Deferred; lean toward Home for now.
2. **Demo sentence rotation** - single fixed sentence for v1. Rotating among 2-3 (to show range) is a later nice-to-have and multiplies the required bundled images.
3. ~~**Reveal images** - the one blocking asset dependency~~ - DONE (2026-07-03): 3 real `nano-banana-pro` flyers generated via OpenRouter (`image_generator.py`) and bundled in `onboarding_demo_1/2/3`.

---

## Premium pass (2026-07-03)

The first build read as "correct but average." Direction chosen: **rich stage, honest chat** - keep the chat honest, make the surrounding stage feel expensive. Implemented:

- **Living aurora background** (`AuroraBackground.swift`) - drifting violet/cyan/pink blobs (screen-blended) over near-black, a generated grain tile, and a vignette. Replaces the flat `heroBackground`.
- **Animated brand mark** - a slowly rotating conic-gradient glyph beside the wordmark (`OnboardingBrandMark` in `ChatOnboardingView.swift`), not a plain text label.
- **"Show its work" beat** (`WorklogView.swift` + `.worklog` beat) - between the facts chips and the reveal, a checklist of expert design decisions ticks from cyan spinner to green check ("Reading a warm, community tone" → "Choosing a warm, high-contrast palette" → …). Conveys engine quality by demonstration, not claims. Each line maps to a real engine step.
- **Cinematic reveal** - `DemoFlyerReveal` now fans the 3 cards with `rotation3DEffect` + perspective, a raised/larger center card, the glow bloom, and a light-sweep gloss across each.
- **Crafted micro-motion** - a blinking caret while the sentence self-types (`UserBubble(caret:)`), a breathing glow behind the CTA, and the user pill upgraded to a subtle violet gradient + soft glow (shared bubble, so the real chat gets the same subtle polish - onboarding stays identical to chat).
- **Value line** near the CTA (designer-anchored, no price, truthful): *"The polish you'd hire a designer for - ready whenever you need one."*
- **Human category chips** - onboarding chips now use warm `FlyerCategory.onboardingLabel` ("Events & gatherings", "Announcements & newsletters", "Fundraisers & causes") instead of taxonomy jargon ("Grand Opening"). Maps 1:1 to the category; Explore personalization unchanged.

All reduce-motion aware; pure SwiftUI (no Lottie). Reference mockup of the direction was approved before building.

## Paywall social proof (separate surface)

`SubscriptionPaywallView` gains a **social-proof section** between the feature list and the plan selector: a 5-star "Loved on the App Store" header + real review card(s). Content lives in `PaywallReview.reviews` and must stay **real** (App Store Guideline 2.3.1). Seeded with one real review ("Game-changer" - wisementor274); add more real ones there.
