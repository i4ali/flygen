# Onboarding rebuild: feature-showcase demo (design)

Date: 2026-07-19
Status: Approved (design). Implementation deferred until owner says go.
Supersedes: the "edit-demo" beat added earlier today (`2026-07-19-onboarding-edit-demo*.md`) - its
single text-edit beat becomes the visual markup beat here, and its `onboarding_demo_edit` asset is
replaced.

## Why

The current chat-first onboarding demos exactly two things - a sentence becomes three flyers, then
a typed edit ("make it Sunday") updates one. It undersells the app and, worse, it *lies about the
QR feature*:

1. `onboarding_demo_1.png` (revealed right after the user "just types a sentence") has a scannable
   QR + "Scan to RSVP" **baked into the image**, and
2. `OnboardingScript.swift:54` ticks *"Adding a QR code for RSVPs"* in the first-generation
   worklog.

Together they make a real, deliberate feature (add a QR) look like an automatic byproduct of
typing. The owner flagged this directly: "user is typing a prompt and it already scanned the QR
code for some reason. That's wrong."

The onboarding also sits directly in front of the paywall: `ContentView.swift:53-57` fires
`showPostOnboardingPaywall` the instant onboarding completes. **This flow is the conversion pitch.**
Every beat should be a reason to subscribe.

## Goals

- Show four real features on one evolving flyer: **generate**, **add a QR**, **circle-to-edit
  (markup)**, **resize for any platform**, and **save the prompt** (5 feature beats total including
  generation).
- Teach the *real* gestures, so nothing surprises the user in-app.
- Kill the "QR was already there" problem: demo flyers start QR-free; QR appears only when the
  assistant offers it.
- End by getting the user to type their own event (investment), then hand off to the paywall.
- Keep the demo tight enough to convert (target ~45s of auto-play before the hands-on beat), with a
  skip.

## Non-goals

- No live engine calls during onboarding (it stays fully scripted/canned: free, fast,
  deterministic). Real generation is what the paywall unlocks.
- Not collecting profile data up front beyond the one language preference (unchanged from today).
- The classic wizard Creation flow and its `QRCodeStepView` are untouched (dead relative to chat).

## Decisions (all confirmed with owner)

| Question | Decision |
|---|---|
| Demo style | **Hybrid**: fast auto-play story, then one hands-on beat before the paywall. |
| Which "save" | **Save the prompt** (bookmark -> saves brief text to the Prompts tab), as named. |
| Extra beat | **Add "Resize for anywhere"** (one flyer -> Instagram post / Story / print). |
| Ending | **Type your event -> paywall** ("invest, then ask"). Keep the quick language pick. |
| Opener | **Keep the 3-concept reveal**, then narrow to one hero. |
| Assets | **Generate a clean, QR-free set through the real engine** (see Assets). |

## Real in-app UX the demo must mirror (from code)

- **QR**: no button. The assistant *proactively offers* a QR via `QROfferBubble`
  (`FlyerChatView.swift:317-352`) with **Yes, add it / No thanks**; on Yes the QR is composited into
  the **next** render, bottom-right (`orchestrator.py:78-92`, `qr_service.py:125-145`). Demo shows:
  offer card -> "Yes" -> hero re-renders *with* the QR.
- **Markup**: a **"Mark up to edit"** button under each flyer (`FlyerChatView.swift:834-842`) opens a
  full-screen editor; the user drags a **magenta (#FF0096) circle**, types a note ("What should
  change here?"), taps **Apply** -> "Updated concept" (`FlyerAnnotationView.swift`). Demo animates a
  circle + note drawing themselves, then Apply.
- **Resize**: a **Resize** menu of aspect ratios under the flyer -> `vm.resize` produces a resized
  concept (`FlyerChatView.swift:876-893`). Demo shows format chips and the hero morphing to 9:16.
- **Save the prompt**: the **bookmark** toolbar button (`FlyerChatView.swift:70-74`) saves the first
  user brief as a `SavedPrompt` into the **Prompts** tab for reuse (`PromptsTab.swift`). Demo shows
  the bookmark tapping and a "Saved to your Prompts" confirmation. (Distinct from "save the flyer
  image" -> My Flyers, which we are *not* showing.)

## The script, beat by beat

Copy is final/build-ready. `🤖` = assistant line, `💬` = self-typing user bubble.

### ① Hook - one sentence becomes three flyers
- 🤖 "Hi, I'm your designer. One sentence, and I'll design you a flyer. Watch."
- 💬 "Summer BBQ fundraiser this Saturday, 12pm at Lincoln Park - $10 a plate, all welcome."
- Brief chips (comprehension): `BBQ Fundraiser` · `Sat 12pm` · `Lincoln Park` · `$10`
- Worklog ticks **design decisions only** - **no QR line**:
  - "Reading a warm, community tone"
  - "Choosing a warm, high-contrast palette"
  - "Balancing the headline hierarchy"
  - "Keeping the address & time exact"
- ✨ Reveal: three concepts fan in, **none with a QR**.
- 🤖 "Three ways to go, from one sentence."
- 🤖 "Let's build on this one." -> middle hero slides forward; others recede. The story now follows
  this single flyer.

### ② Add a QR (the feature, done honestly)
- 🤖 "Want people to RSVP? I can add a scannable QR."
- QR offer card (mirrors `QROfferBubble`): *"Add a QR code that opens your RSVP link?"*
  `[Yes, add it] [No thanks]`
- After a beat, **Yes, add it** highlights and taps itself.
- 🤖 "Done - it bakes right onto your flyer."
- Hero re-blooms **with the QR** bottom-right + "Scan to RSVP".

### ③ Circle-to-edit (markup)
- 🤖 "Need a change? Don't retype it - just circle it."
- **Mark up to edit** appears under the hero and taps itself. A magenta circle draws itself around
  **"Saturday"**; a note types *"make it Sunday."* A second circle near the footer types *"add Live
  music."* Then **Apply** taps.
- Edit worklog ticks: "Keeping your layout & colors" -> "Switching Saturday to Sunday" -> "Adding
  'Live music'".
- Hero re-blooms: now **Sunday + Live music**, QR intact.
- 🤖 "Updated in seconds - nothing redone from scratch."

### ④ Resize for anywhere
- 🤖 "Same flyer, everywhere you post."
- **Resize** control shows; format chips animate `Poster` · `Story` · `Square`; the hero morphs into
  a tall 9:16 Story.
- 🤖 "One design, sized for Instagram, Stories, and print."

### ⑤ Save the prompt
- 🤖 "Love this brief? Save it and reuse it anytime."
- The **bookmark** (top-right) pulses and taps -> **"Saved to your Prompts ✓"** slides in.
- 🤖 "It's in your Prompts tab now - tweak the details, fresh flyer in one tap."

### ⑥ Your turn -> paywall
- 🤖 "Your turn. What are you promoting?"
- Text input, placeholder *"e.g., Saturday yoga class in the park."* The user types their **real**
  event. Nothing is stored (same privacy stance as today's open question); the value is the
  investment, not the data.
- On send: 🤖 "Perfect - let's make yours."
- 🤖 "One more - what language should your flyers be in?" -> the existing language chip question
  (sets `defaultFlyerLanguage`).
- 🤖 "Great. Your flyers, your language."
- CTA **"Make my flyer"** -> `finish()` -> onboarding completes -> paywall fires.

A subtle **"Skip ▸"** in the top bar jumps straight to ⑥ for impatient users.

## Architecture

Keep the good bones. Today's onboarding is data-driven: `OnboardingScript.beats` (an
`[OnboardingBeat]`) is walked by `ChatOnboardingViewModel.runLoop()`, and `ChatOnboardingView`
renders each `RenderedBeat`. We **keep the runner and the view shell and rewrite the script**, adding
a handful of new auto-play beat types and their views.

### New `OnboardingBeat` / `RenderedBeat.Kind` cases
- `.narrowToHero(String)` - transition from the 3-concept fan to a single centered hero.
- `.qrOffer(QROfferDemo)` - the offer card; auto-resolves to "Yes" after a pause, then the runner
  reveals the QR hero.
- `.markup(MarkupDemo)` - the hero with an animated magenta circle + typed note(s), then "Apply";
  the runner then reveals the edited hero.
- `.resize(ResizeDemo)` - format chips + hero morph to a target aspect ratio.
- `.savePrompt` - bookmark pulse + "Saved to your Prompts" toast.

Reused unchanged: `.assistant`, `.userTypes`, `.brief`, `.worklog`, `.reveal` (handles both the
3-card fan and the solo hero re-reveals), `.textQuestion`, `.chipQuestion`, `.cta`.

### New SwiftUI components (all pure SwiftUI motion, no Lottie)
- `OnboardingQROfferView` - visually matches the real `QROfferBubble` (accent card, `qrcode` glyph,
  Yes/No), with a scripted auto-tap highlight on "Yes".
- `OnboardingMarkupView` - draws the magenta circle(s) and types the note(s) over the hero image,
  mirroring `FlyerAnnotationView`'s look (magenta #FF0096, numbered badge), then an "Apply" pulse.
- `OnboardingResizeView` - the format chips + an aspect-ratio morph of the hero.
- `OnboardingSavePromptView` - the bookmark tap + confirmation toast.

The circle/note/QR are drawn or composited in SwiftUI at runtime, so the only *art* needed is the
flyer stills below.

### Runner changes
Add `runLoop()` cases for the new auto beats: play the visual, `pause()` for its duration, then
continue. The two interactive beats (`.textQuestion`, `.chipQuestion`) already stop the runner and
resume on submit - the ⑥ ending reuses them as-is. Timing constants live in `OnboardingTiming`.

## Assets (generate through the real engine)

One clean set of the **same** BBQ flyer, portrait 3:4, produced via the engine's real Nano Banana
wrappers (Higgsfield MCP) so they look production-real. Generating *through the real pipeline*
guarantees fidelity:

| Imageset | Content | How |
|---|---|---|
| `onboarding_concept_1/2/3` | Three distinct BBQ concepts, **no QR** | Real 3-concept generation on the BBQ brief |
| `onboarding_hero_qr` | Concept 2 + composited QR bottom-right + "Scan to RSVP" | `qr_service.composite_qr_onto_bytes` on concept 2 |
| `onboarding_hero_edited` | Concept 2 + QR + "Sunday" + "Live music" | Real markup/refine edit path on `onboarding_hero_qr` |
| `onboarding_hero_story` | The edited hero reframed to 9:16 Story | Reframe/outpaint of `onboarding_hero_edited` |

The chosen "hero" is concept 2 (the middle card that slides forward). Replaces the current
`onboarding_demo_1/2/3` and `onboarding_demo_edit` imagesets (all of which carry a baked-in QR).
Placeholders render until the real art lands (existing `DemoFlyerCard` fallback pattern).

## Pacing

Rough auto-play budget before the hands-on beat: ① ~14s, ② ~7s, ③ ~10s, ④ ~7s, ⑤ ~6s ≈ **~44s**,
then interactive. `Skip ▸` jumps to ⑥. Reduce-motion collapses pauses (existing behavior).

## Risks / open items

- **Length vs. conversion**: five beats is more than today. Mitigations: fast per-beat pacing, the
  Skip control, and one continuous flyer so it reads as a single story, not five demos.
- **Markup auto-play fidelity**: reusing the real `FlyerAnnotationView` in an auto-driven mode is
  complex; a lightweight look-alike (`OnboardingMarkupView`) is the pragmatic call. It must match the
  real editor's look closely enough that the gesture feels familiar.
- **Asset regeneration** is a prerequisite; the flow can be built against placeholders in parallel.
- **CloudKit**: no schema change (onboarding still only persists `defaultFlyerLanguage`).

## What ships

1. New demo asset set (engine-generated), QR-free until beat ②.
2. Rewritten `OnboardingScript.beats` + new beat types.
3. New onboarding demo components (QR offer, markup, resize, save-prompt) + a `narrowToHero`
   transition.
4. Runner cases + timing for the new beats; `Skip ▸` control.
5. Removal of the "Adding a QR code" worklog line and the baked-QR demo assets.
