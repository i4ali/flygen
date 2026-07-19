# Onboarding Feature-Showcase Implementation Plan

> **For Claude:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Rebuild the chat-first onboarding into a hybrid auto-play demo that honestly showcases
five features on one evolving flyer (generate -> add QR -> circle-to-edit -> resize -> save the
prompt), then hands off to the paywall - fixing the "QR was already there" bug.

**Architecture:** Keep the existing data-driven engine - `OnboardingScript.beats` walked by
`ChatOnboardingViewModel.runLoop()`, rendered by `ChatOnboardingView`. Rewrite the script, add four
auto-play beat types (`qrOffer`, `markup`, `resize`, `savePrompt`) with matching SwiftUI demo views,
add a Skip control, and regenerate the demo flyer assets (QR-free until the QR beat) through the real
engine pipeline.

**Tech Stack:** SwiftUI (iOS), SwiftData/CloudKit (unchanged), Python engine + `qr_service.py` +
Higgsfield MCP for asset generation. Classic `.xcodeproj` (objectVersion 63) - new `.swift` files
need pbxproj edits via the `xcodeproj` ruby gem.

**Design doc:** `docs/plans/2026-07-19-onboarding-feature-showcase-design.md` (read it first - it has
the final copy and rationale).

**Verification convention (this repo):** No Swift test target. Each code task ends with a
**build-gate**: `xcodebuild ... build` must succeed. Visual/interactive correctness is handed to the
owner in the simulator (do not drive the simulator - see the `owner-handles-simulator-verification`
convention). Commit only when the owner asks.

**Build-gate command (reuse throughout):**
```bash
cd /Users/muhammadimranali/Documents/development/flygen/FlyGen && \
xcodebuild -project FlyGen.xcodeproj -scheme FlyGen \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug build 2>&1 | tail -25
```
Expected: `** BUILD SUCCEEDED **`.

---

## Phase A: Regenerate demo assets (QR-free until the QR beat)

Can run in parallel with Phases B-E: the flow builds against placeholders (existing `DemoFlyerCard`
fallback), so wiring does not block on final art.

### Task A1: Generate three QR-free BBQ concepts

**Goal:** Produce three distinct, production-real BBQ fundraiser concept flyers with **no QR code**,
portrait 3:4.

**Brief (same as the demo script):** "Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park -
$10 a plate, all welcome."

**Steps:**
1. Generate three concepts through the engine's real Nano Banana wrappers (Higgsfield MCP
   `generate_image`, or the engine's `engine/` generation path used for real concepts). Use
   `prompt_builder.py`'s concept prompt shape so the look matches production. **Explicitly exclude
   any QR / "Scan to RSVP" element** from every concept.
2. Pick concept 2 as the hero (the middle card that the story follows).
3. Save the three PNGs to the scratchpad, review them (Read the images) for: no QR, legible
   headline, correct facts (Sat 12pm, Lincoln Park, $10), 3:4 aspect.

**Verify:** Read all three images back; confirm no QR is present on any.

### Task A2: Composite the QR onto the hero -> `hero_qr`

**Goal:** The hero (concept 2) with a real scannable QR composited bottom-right + "Scan to RSVP",
using the *actual* production compositor so it looks identical to what users get.

**Steps:**
1. Run concept 2's bytes through `qr_service.composite_qr_onto_bytes` (`qr_service.py:125-145`) with
   a demo RSVP URL (e.g. `https://flygen.app/rsvp`), corner = bottom-right, the production styling
   constants (`qr_service.py:17-22`).
2. Save as the `hero_qr` PNG. Read it back; confirm the QR is present, bottom-right, with padding.

### Task A3: Produce the edited hero -> `hero_edited`

**Goal:** `hero_qr` with **"Saturday" -> "Sunday"** and **"Live music" added**, layout/colors/QR
otherwise preserved - i.e. the real markup-edit result.

**Steps:**
1. Run `hero_qr` through the real annotated/refine edit path (`orchestrator.py:206` annotated
   branch, or the reference edit path) with the instruction: "1. Change Saturday to Sunday. 2. Add
   'Live music'. Keep the layout, colors, and QR exactly."
2. Save as `hero_edited`. Read it back; confirm Sunday + Live music, QR intact, layout preserved.

### Task A4: Reframe the edited hero to a 9:16 Story -> `hero_story`

**Goal:** The edited hero as a tall Instagram-Story crop, to demo Resize.

**Steps:**
1. Reframe/outpaint `hero_edited` to 9:16 (Higgsfield `reframe`/`outpaint_image`, or the engine's
   `resize` path).
2. Save as `hero_story`. Read it back; confirm 9:16 and the same design.

### Task A5: Install the imagesets into the asset catalog

**Files:**
- Create: `FlyGen/FlyGen/Resources/Assets.xcassets/onboarding_concept_1.imageset/` (+ `_2`, `_3`)
- Create: `FlyGen/FlyGen/Resources/Assets.xcassets/onboarding_hero_qr.imageset/`
- Create: `FlyGen/FlyGen/Resources/Assets.xcassets/onboarding_hero_edited.imageset/`
- Create: `FlyGen/FlyGen/Resources/Assets.xcassets/onboarding_hero_story.imageset/`
- Delete (later, Task F1): `onboarding_demo_1/2/3.imageset`, `onboarding_demo_edit.imageset`

**Steps:**
1. For each imageset, create the folder + a `Contents.json` (copy the schema from an existing
   `onboarding_demo_1.imageset/Contents.json` - single universal PNG, no scale variants) and drop the
   PNG in.
2. Asset catalogs are folder references, so **no pbxproj edit is needed** for imagesets (unlike
   `.swift` files).

**Build-gate:** run the build command. Expected `BUILD SUCCEEDED` (assets compile).

---

## Phase B: Data model - new beat types + the rewritten script

### Task B1: Add the demo payload structs + new `OnboardingBeat` cases

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/OnboardingScript.swift`

**Step 1:** Add the payload structs near the top (after the imports):

```swift
import CoreGraphics

/// Payload for the auto-play QR-offer beat: mirrors the real `QROfferBubble`, auto-accepts, then
/// the runner reveals `revealImage` (the hero with the QR composited on).
struct QROfferDemo: Equatable {
    let prompt: String          // "Add a QR code that opens your RSVP link?"
    let acceptLabel: String     // "Yes, add it"
    let declineLabel: String    // "No thanks"
    let revealImage: String     // "onboarding_hero_qr"
}

/// One markup circle + its note, positioned in normalized (0...1) flyer space.
struct MarkupMark: Equatable {
    let center: CGPoint         // normalized over the flyer image
    let note: String            // "make it Sunday"
}

/// Payload for the auto-play markup beat: draws circles + types notes over `baseImage`, then the
/// runner ticks `worklog` and reveals `resultImage`.
struct MarkupDemo: Equatable {
    let baseImage: String       // "onboarding_hero_qr"
    let marks: [MarkupMark]
    let worklog: [String]
    let resultImage: String     // "onboarding_hero_edited"
}

/// Payload for the auto-play resize beat: shows format chips, selects one, morphs to `resultImage`.
struct ResizeDemo: Equatable {
    let formats: [String]       // ["Poster", "Story", "Square"]
    let selected: String        // "Story"
    let resultImage: String     // "onboarding_hero_story"
}
```

**Step 2:** Add the new cases to `enum OnboardingBeat`:

```swift
    /// Auto-play: the QR offer card that accepts itself, then reveals the QR'd hero.
    case qrOffer(QROfferDemo)
    /// Auto-play: circle(s) + note(s) draw onto the hero, then the edited hero is revealed.
    case markup(MarkupDemo)
    /// Auto-play: format chips + a morph of the hero into a new aspect ratio.
    case resize(ResizeDemo)
    /// Auto-play: the bookmark taps and a "Saved to your Prompts" confirmation appears.
    case savePrompt
```

**Build-gate:** build (the enum compiles even before the runner handles them - Swift will warn on
non-exhaustive switches; those are fixed in Phase C/D, so expect build to FAIL until then only if
switches are exhaustive without `default`. The current `runLoop`/`beatView` switches are exhaustive,
so complete Tasks B1-B3, C1, D6 before the next green build. Do not build-gate mid-phase here.)

### Task B2: Rewrite `OnboardingScript.beats` and the static content

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/OnboardingScript.swift`

**Step 1:** Replace `demoFlyerImages`, `worklogItems`, `editDemoImage`, `editWorklogItems` and the
`beats` array with the new script. Keep `textReplyAnswered`/`textReplySkipped`.

```swift
    /// The three QR-free concepts fanned in beat ①. Hero (concept 2) is what the story follows.
    static let demoConcepts = ["onboarding_concept_1", "onboarding_concept_2", "onboarding_concept_3"]
    static let heroBase = "onboarding_concept_2"

    /// Generation worklog - DESIGN DECISIONS ONLY. The QR line is deliberately gone; QR is now a
    /// deliberate feature shown in beat ②, not an automatic step.
    static let worklogItems = [
        "Reading a warm, community tone",
        "Choosing a warm, high-contrast palette",
        "Balancing the headline hierarchy",
        "Keeping the address & time exact",
    ]

    static let qrOffer = QROfferDemo(
        prompt: "Add a QR code that opens your RSVP link?",
        acceptLabel: "Yes, add it",
        declineLabel: "No thanks",
        revealImage: "onboarding_hero_qr")

    static let markupDemo = MarkupDemo(
        baseImage: "onboarding_hero_qr",
        marks: [
            MarkupMark(center: CGPoint(x: 0.5, y: 0.42), note: "make it Sunday"),
            MarkupMark(center: CGPoint(x: 0.5, y: 0.60), note: "add Live music"),
        ],
        worklog: ["Keeping your layout & colors", "Switching Saturday to Sunday", "Adding 'Live music'"],
        resultImage: "onboarding_hero_edited")

    static let resizeDemo = ResizeDemo(
        formats: ["Poster", "Story", "Square"],
        selected: "Story",
        resultImage: "onboarding_hero_story")

    static let beats: [OnboardingBeat] = [
        // ① Hook
        .assistant("Hi, I'm your designer. One sentence, and I'll design you a flyer. Watch."),
        .userTypes("Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome."),
        .brief(["BBQ Fundraiser", "Sat 12pm", "Lincoln Park", "$10"]),
        .worklog(worklogItems),
        .reveal(demoConcepts),
        .assistant("Three ways to go, from one sentence."),
        .assistant("Let's build on this one."),
        .reveal([heroBase]),
        // ② Add a QR
        .assistant("Want people to RSVP? I can add a scannable QR."),
        .qrOffer(qrOffer),                       // auto-accepts, then reveals the QR'd hero
        .assistant("Done - it bakes right onto your flyer."),
        // ③ Circle-to-edit
        .assistant("Need a change? Don't retype it - just circle it."),
        .markup(markupDemo),                     // draws circles + notes, then reveals the edited hero
        .assistant("Updated in seconds - nothing redone from scratch."),
        // ④ Resize
        .assistant("Same flyer, everywhere you post."),
        .resize(resizeDemo),
        .assistant("One design, sized for Instagram, Stories, and print."),
        // ⑤ Save the prompt
        .assistant("Love this brief? Save it and reuse it anytime."),
        .savePrompt,
        .assistant("It's in your Prompts tab now - tweak the details, fresh flyer in one tap."),
        // ⑥ Your turn -> paywall
        .assistant("Your turn. What are you promoting?"),
        .textQuestion(placeholder: "e.g., Saturday yoga class in the park"),
        .chipQuestion(OnboardingQuestion(kind: .language, prompt: "What language should your flyers be in?")),
        .assistant("Great. Your flyers, your language."),
        .cta("Make my flyer"),
    ]
```

Note: the `qrOffer`/`markup`/`resize` beats each internally reveal their result image (handled by
the runner in Task C1), so no separate `.reveal(...)` follows them.

### Task B3: Mirror the new kinds in `RenderedBeat`

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingViewModel.swift:9-19`

Add to `RenderedBeat.Kind`:

```swift
        case qrOffer(QROfferDemo, accepted: Bool)   // accepted flips true to animate the auto-tap
        case markup(MarkupDemo)
        case resize(ResizeDemo)
        case savePrompt(saved: Bool)                // saved flips true to show the confirmation
```

---

## Phase C: Runner

### Task C1: Handle the new auto beats in `runLoop()`

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingViewModel.swift:103-147`

Add cases inside the `switch beats[index]` loop:

```swift
            case .qrOffer(let demo):
                await pause(OnboardingTiming.beatGap)
                let id = append(.qrOffer(demo, accepted: false))
                await pause(OnboardingTiming.qrOfferDwell)           // let the card read
                if Task.isCancelled { return }
                withAnimation(FGAnimations.spring) { update(id, .qrOffer(demo, accepted: true)) }
                await pause(OnboardingTiming.qrAcceptHold)           // the "Yes" tap lands
                append(.reveal([demo.revealImage]))                 // hero re-blooms WITH the QR
                await pause(OnboardingTiming.revealHold)
            case .markup(let demo):
                await pause(OnboardingTiming.beatGap)
                append(.markup(demo))
                await pause(OnboardingMarkupView.duration(for: demo))  // draw circles + type notes + Apply
                if Task.isCancelled { return }
                append(.worklog(demo.worklog))
                await pause(WorklogView.duration(for: demo.worklog))
                append(.reveal([demo.resultImage]))                 // edited hero
                await pause(OnboardingTiming.revealHold)
            case .resize(let demo):
                await pause(OnboardingTiming.beatGap)
                append(.resize(demo))
                await pause(OnboardingResizeView.duration)          // chips + morph
                await pause(OnboardingTiming.revealHold)
            case .savePrompt:
                await pause(OnboardingTiming.beatGap)
                let id = append(.savePrompt(saved: false))
                await pause(OnboardingTiming.saveTapDelay)
                if Task.isCancelled { return }
                withAnimation(FGAnimations.spring) { update(id, .savePrompt(saved: true)) }
                await pause(OnboardingTiming.saveConfirmHold)
```

### Task C2: Add timing constants

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/OnboardingScript.swift` (the `OnboardingTiming` enum)

```swift
    /// How long the QR offer card sits before it auto-accepts.
    static let qrOfferDwell: Double = 1.4
    /// Hold after the "Yes" tap before the QR'd hero reveals.
    static let qrAcceptHold: Double = 0.5
    /// Delay before the bookmark auto-taps in the save-prompt beat.
    static let saveTapDelay: Double = 1.0
    /// How long the "Saved to your Prompts" confirmation holds.
    static let saveConfirmHold: Double = 1.4
```

(`OnboardingMarkupView.duration(for:)` and `OnboardingResizeView.duration` are defined with their
views in Phase D.)

---

## Phase D: Demo views

These are creative SwiftUI views: the plan gives the structure, data contract, and animation
approach; **final visual polish is iterated live in the simulator with the owner.** Match the real
components' look (colors from `FGColors`, radii from `FGSpacing`).

### Task D2 (first, it's the hard one): `OnboardingMarkupView`

**Files:**
- Create: `FlyGen/FlyGen/Views/Onboarding/Components/OnboardingMarkupView.swift`

**Contract:** given a `MarkupDemo`, render `baseImage` in a flyer card, then sequentially: for each
mark, animate a **magenta (#FF0096) numbered circle** stroking on at `mark.center` and a small note
capsule typing out `mark.note`; finally flash an **"Apply"** pill. Expose:

```swift
static func duration(for demo: MarkupDemo) -> Double   // sum of per-mark draw+type + apply flash
```

**Approach:** normalized `center` * card size for placement; stroke the circle with
`.trim(from:0,to:animated ? 1 : 0)`; type the note with a timer like `typeUser`. Mirror
`FlyerAnnotationView` styling (magenta `UIColor(red:1,green:0,blue:0.588)`, numbered badge on the
circle's top-left, `pencil.and.outline` glyph on the note). No real gestures - it plays itself.

### Task D1: `OnboardingQROfferView`

**Files:**
- Create: `FlyGen/FlyGen/Views/Onboarding/Components/OnboardingQROfferView.swift`

**Contract:** given `(QROfferDemo, accepted: Bool)`, render a card that visually matches the real
`QROfferBubble` (`FlyerChatView.swift:317-352`): `accentSecondary` 10% fill, 35% border, `cardRadius`,
a `qrcode` glyph, the prompt text, and two buttons - **Yes, add it** (`checkmark`, solid
`accentPrimary`) and **No thanks** (dismiss style). When `accepted` flips true, animate a press/glow
on the Yes button and dim/disable both. No engine call.

### Task D3: `OnboardingResizeView`

**Files:**
- Create: `FlyGen/FlyGen/Views/Onboarding/Components/OnboardingResizeView.swift`

**Contract:** given a `ResizeDemo`, show the hero (`resultImage`) inside an animated frame that
starts at 3:4 and morphs to 9:16 while format chips (`formats`) slide in and `selected` highlights.
Expose `static let duration: Double`. Convey "one design, many sizes" - a `Resize`/`aspectratio`
affordance plus the aspect morph.

### Task D4: `OnboardingSavePromptView`

**Files:**
- Create: `FlyGen/FlyGen/Views/Onboarding/Components/OnboardingSavePromptView.swift`

**Contract:** given `saved: Bool`, show a small row with a **bookmark** glyph (matching the chat
toolbar's `bookmark`); when `saved` flips true, animate the bookmark filling + a **"Saved to your
Prompts ✓"** capsule sliding in (green `checkmark`).

### Task D5: `OnboardingMarkupView.duration` / `OnboardingResizeView.duration` sanity

Confirm the `duration` values the runner awaits (Task C1) match each view's internal animation
length, so beats don't cut off or hang. Tune in-sim with the owner.

### Task D6: Render the new kinds in `ChatOnboardingView.beatView`

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingView.swift:45-57`

```swift
        case .qrOffer(let demo, let accepted): OnboardingQROfferView(demo: demo, accepted: accepted)
        case .markup(let demo):                OnboardingMarkupView(demo: demo, reduceMotion: reduceMotion)
        case .resize(let demo):                OnboardingResizeView(demo: demo, reduceMotion: reduceMotion)
        case .savePrompt(let saved):           OnboardingSavePromptView(saved: saved)
```

### Task D7: Register the four new `.swift` files in the Xcode project

**Files:**
- Modify: `FlyGen/FlyGen.xcodeproj/project.pbxproj`

Use the `xcodeproj` ruby gem (classic pbxproj, objectVersion 63 - no synchronized groups) to add the
four new component files to the `FlyGen` target, then build. Follow the
`xcode-project-file-management` convention.

**Build-gate:** run the build command. Expected `** BUILD SUCCEEDED **`. This is the first fully
green build (Phases B, C, D complete the exhaustive switches).

**Owner checkpoint:** hand off to the owner to run the simulator and eyeball beats ①-⑤ end to end
(pacing, the QR add, the markup draw, the resize morph, the save toast).

---

## Phase E: Skip control

### Task E1: Add "Skip ▸" that jumps to beat ⑥

**Files:**
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingView.swift` (top bar)
- Modify: `FlyGen/FlyGen/Views/Onboarding/ChatOnboardingViewModel.swift` (a `skipToEnding()`)

**Contract:** a subtle "Skip ▸" trailing in `topBar`. `skipToEnding()` cancels `runTask`, sets
`index` to the first `.textQuestion` beat, clears any in-flight transient beats, and `resume()`s so
the ⑥ input appears immediately. Guard against double-taps.

**Build-gate:** build. **Owner checkpoint:** verify Skip lands on the "what are you promoting?" input.

---

## Phase F: Cleanup + final verification

### Task F1: Remove the old baked-QR assets and any dead references

**Files:**
- Delete: `onboarding_demo_1/2/3.imageset`, `onboarding_demo_edit.imageset`
- Grep: ensure no code references `onboarding_demo_*` or the removed `editDemoImage`/`demoFlyerImages`
  symbols.

**Build-gate:** build. Expected `BUILD SUCCEEDED`.

### Task F2: Full read-through vs. the design doc

Re-read `2026-07-19-onboarding-feature-showcase-design.md` and confirm every beat's copy and behavior
matches. Confirm the generation worklog no longer mentions QR (the original bug).

### Task F3: Owner acceptance in the simulator

Hand off: full run from a fresh install (reset `hasCompletedOnboarding`), through all beats, the
hands-on ⑥ input, the language pick, the CTA, and confirm the paywall fires right after. This is the
conversion moment - watch the whole thing feels like a pitch, not a chore.

### Task F4 (owner-gated): commit

Only when the owner asks. Suggested message:
`feat: rebuild onboarding as an honest feature-showcase demo (QR, markup, resize, save)`

---

## Task summary / ordering

- **Parallel track:** Phase A (assets) can run alongside B-E; the flow builds on placeholders.
- **Critical path for a green build:** B1 -> B2 -> B3 -> C1 -> C2 -> D2 -> D1 -> D3 -> D4 -> D6 ->
  D7 (first green build) -> E1 -> A5 (drop real art) -> F1.
- **Owner checkpoints:** after D7 (beats ①-⑤), after E1 (skip), and F3 (full acceptance).
