# Explore "Use as Starting Point" -> seeded chat (refine an existing flyer)

Date: 2026-07-02
Status: Approved, implementing

## Goal

Two changes to finish retiring the old wizard from the user-facing flow:

1. **Redirect** the Explore tab's "Use as Starting Point" button away from the old wizard
   (`CreationFlowView`) and into the new chat.
2. When tapped, **open the chat seeded with that flyer** so the user can refine the exact
   design (change wording, colors, layout) rather than start from a blank chat.

After the redirect, nothing reachable sets `showingCreationFlow = true`, so the old wizard is
unreachable. Per decision, we **leave the wizard code dormant** behind `classicCreationEnabled = false`
(no deletion); `loadFromSample` becomes dead-but-kept.

## Decisions (from brainstorming)

- **Starting point = "tweak this exact design."** Seed the chat with the sample's *image* and let
  the engine edit it, preserving the look. (Not "regenerate a fresh flyer from the sample's recipe,"
  which would discard the visual design the user liked.)
- **Disable scope = "redirect only, leave dormant."** Don't delete the wizard; just make it
  unreachable and keep it behind the existing feature flag as a possible fallback.

## Key insight: no engine changes

The chat's existing `refine` action already does exactly what we need:

- `engine/orchestrator.py::handle_refine` rebuilds the project from the `brief` posted by the
  client, then edits whatever image is sent as `prior_image_b64`.
- The iOS `ConceptsCard` already renders an image with an inline **refine** box + **resize** + save
  (Photos / My Flyers). Its refine field calls `vm.refine(concept:instruction:)` ->
  `ChatRequest(action: "refine", brief:, instruction:, prior_image_b64:)`.

So seeding a sample as a synthetic "concept" (its image) plus a seeded `brief` (its facts) gives the
whole refine/resize/save interaction for free, with **zero backend changes**.

## Design

### Seeded transcript (on chat open, when a seed is present)

1. `assistant`: "Here's <name> as your starting point. Tell me what to change under the image ..."
2. `parsedFields(brief)`: a collapsed "here's what's in this flyer" card (existing component) so the
   user sees the loaded facts.
3. `concepts([seedConcept])`: the sample image as the current design, carrying the existing refine /
   resize / save controls. Card heading reads "Starting point" (see heading change below).

The user types a change in the image's refine box -> existing `refine` path edits that exact image ->
engine returns the updated design (rendered as a fresh single-concept card). Repeat, then save.

The bottom composer keeps its current meaning ("describe a brand-new flyer") as an escape hatch.

### SampleFlyer -> ExtractedBriefDTO mapping (new)

Inverse of the existing `chatFlyerProject()`. Map `sample.textContent` fields 1:1 to the brief
(`headline`, `subheadline`, `body_text`, `date`, `time`, `venue_name`, `address`, `price`,
`discount_text`, `cta_text`, `phone`, `email`, `website`, `social_handle`), `category` ->
`category.rawValue` (the same token the engine and `FlyerCategory(rawValue:)` use), `finePrint`
folded into `additional_info`, `specialInstructions` -> `purpose`. Every mapped field is marked
`field_sources = "stated"` (a sample's content is authored/known).

The sample's bundled image (`UIImage(named: sample.imageName)`) is JPEG-encoded and base64'd into a
synthetic `ConceptDTO(version_id: "seed-<id>", image_base64:, error: nil)`.

### Files touched

- `Chat/FlyerChatViewModel.swift`
  - `start()` -> `start(seed: SampleFlyer? = nil)`; guard on empty transcript.
  - new `seedFromSample(_:)` (builds the seeded transcript) and `static brief(from:)` mapper.
  - `ChatBubble.Kind.concepts` gains a `heading: String?` (presentation data); `apply()`'s two
    construction sites pass `heading: nil`.
- `Chat/FlyerChatView.swift`
  - add `let seed: SampleFlyer?` + `init(seed:) = nil`; `onAppear { vm.start(seed: seed) }`.
  - `ConceptsCard` gains `var heading: String? = nil`; single-concept heading falls back to
    "Updated concept" as today when `heading == nil`.
- `Views/Tabs/ExploreTab.swift`
  - present `FlyerChatView(seed:)` via a new `fullScreenCover(item: $chatSeed)` instead of calling
    `viewModel.loadFromSample`. Hand off from the detail sheet cleanly: the button sets `pendingSeed`;
    the detail cover's `onDismiss` promotes `pendingSeed -> chatSeed` (so the detail sheet fully
    closes before the chat presents). The now-unused `viewModel` param stays (avoids touching the
    tab wiring; consistent with "leave dormant").

## Out of scope (v1 boundaries)

- Adding the user's own photos stays with the fresh-flyer path (the seeded refine flow edits the
  design only).
- Saved refined flyers get `origin = .chat`; the saved image is the refined one. Structured
  colors/visuals keep defaults (a pre-existing chat-save limitation; does not affect the saved image).
- No wizard deletion; no backend changes.

## Verification

- Build the app (Debug) for the simulator; confirm it compiles.
- Manual: Explore -> tap a sample -> Use as Starting Point -> chat opens showing that flyer + facts;
  a refine ("change the date to ...") returns an edited image; save to My Flyers works.
- Confirm the old wizard no longer opens from Explore (or anywhere).
