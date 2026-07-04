# Reuse a Flyer - Reference-Driven Edit (Design Spec)

- Date: 2026-07-03
- Status: Approved design. Implementation timing TBD (bank + schedule separately).
- Related: [[chat-expert-rewrite-decided]] (one-brain interpreter), [[no-silent-defaults]], [[flyer-generation-economics]], [[non-flyer-chat-gate]]

## Summary

Let a user upload an existing flyer and get a new one that keeps that flyer's exact
design but swaps in their own details. This is an **in-place raster edit** via
Nano Banana Pro (Gemini 3 Pro Image), not a from-scratch generation.

> **IMPLEMENTED DESIGN (simplified 2026-07-03) - supersedes the brain-driven flow described
> below.** The user uploads the flyer and types what to change in their own words; the engine
> hands the image plus that text **straight to Nano Banana Pro** and returns the edited flyer.
> **No brain reads the flyer, no field extraction, no questions, no review card, no diffing.**
> The image model is trusted to read the flyer and make exactly the requested change; anything
> the user wants controlled (e.g. "keep the existing photo") is just words in the instruction,
> not code. Each further tweak is another image+words turn on the latest image. Engine surface:
> a `reference` action + `reference_image_b64` on the request -> `handle_reference` ->
> `edit_reference` (light prompt, n=1, auto-detects the reference's aspect ratio). The verbose
> brain-reads-and-asks design in the sections below was built, tested, then removed as
> over-engineering (see build notes); it's kept only as rationale/history.

## Why

Common real user need: "I have a flyer I like (last year's, a community/mosque template,
one I saw) - just make it mine." Today the only path is describing everything from scratch.
This is a low-friction, differentiated shortcut that leans on the model's single biggest
strength (reference + edit).

## Non-goals (v1)

- **Style-mimic as a primary mode.** "Make mine *look like* this but with my content, fresh
  generation" is a different feature. Here it appears **only as a failure fallback** (see
  Fallback below).
- **Swapping a photo *inside* the reference** (e.g. the user's face where the sample had a
  different one). Compositing into an existing raster is a harder, separate problem. Deferred to v2.
- **Non-flyer detection / redirect.** If the upload isn't really a flyer, we just try the edit
  anyway and let the model do its best. No validation branch.
- **Multiple references / collage.** One reference per flyer.
- **Persistent attach button or upfront entry.** The single nudge is the only entry point.

## Decisions locked

| Question | Decision |
|---|---|
| What we do with the upload | Edit the exact flyer (swap details, preserve design) |
| How much the reference drives the flow | Reference drives it: brain reads it, asks only for swaps, skips design questions |
| Output count | 1 faithful edit (not 3 concepts); refine/resize available as today |
| Output size | Inherits the reference's dimensions; different size = resize afterward |
| Photo-into-reference swap | Not in v1 |
| Quota / paywall | Same as a normal create: 1 unit, same gating. Refine/resize free as today |
| Non-flyer upload | Just try to edit it anyway; no detection/redirect |
| Entry points | Just the nudge after the first message (one per flyer) |
| Copyright gate | None (soft one-time notice possible later; not a blocker) |
| Misread protection | "Here's what I read off your flyer" confirmation is shown before generating |

## User experience / flow

1. User types an initial description as normal (e.g. *"Muharram majlis on the 15th at the Islamic Center"*).
2. **Reference nudge** appears - a twin of the existing `photo_suggestion` nudge:
   *"Got a flyer you'd like me to reuse the design of? I'll keep the look and just swap in your
   details."* with an **Upload** button and a **"No, design from scratch"** decline. Fires once per flyer.
3. **Decline** -> today's flow is untouched (the normal photo nudge may still fire afterward).
4. **Upload** (single image) -> the reference takes over:
   - The brain (Claude Sonnet 4.6, vision) **reads the flyer**: its text content and field
     structure (headline, date, time, venue, contact, etc.) plus a read of its design.
   - It **echoes back what it read** (*"Here's what's on this flyer..."*) so a misread is caught,
     not baked in (applies the no-silent-defaults rule to the reference).
   - It asks **only for the details to swap**, reconciling against whatever the user already typed
     (*"This one says 'Annual Gala, Aug 3' - what's your event name and date?"*).
   - **Design-stage questions are skipped.** Palette/style/mood/format are inherited from the reference.
   - **Structural-mismatch flag:** if the reference doesn't fit the event type (e.g. a two-name
     wedding flyer for a birthday), the brain says so and adapts rather than silently producing
     something broken (*"I can adapt this, but the layout may shift..."*).
5. **Confirm card** - reuses the existing review gate, minus the design proposals:
   *"I'll keep this exact design and change: headline -> ..., date -> ..., venue -> .... Generate?"*
6. **Edit** via Nano Banana Pro: the reference is fed in as the base image with a
   "preserve this design, replace only this text" instruction. Returns **1** edited flyer.
7. **Refine / resize** work exactly as they do today (existing `prior_image_b64` paths).

### Fallback (quality safety net)

If the edit comes back poor (ghosted old text, mangled script, obviously broken), the brain
offers: *"I couldn't cleanly edit this one - want me to rebuild it fresh in the same style
instead?"* That routes into a style-match generation (the mode not chosen as primary), used
only here as insurance. This is the escape hatch for the text-fidelity risk below, especially
Arabic/Urdu.

## Architecture / data flow

State stays **stateless per request** (consistent with today): the reference image round-trips
in the request body, just like `brief` and `prior_image_b64` do now.

### Request / wire changes

- New field `reference_image_b64: Optional[str]` on `ChatIn` (engine `app.py`) and
  `ChatRequest` (iOS `ChatModels.swift`). Single base64 JPEG, normalized client-side like the
  existing `user_photos_b64` (HEIC -> JPEG).
- New flag on the brief (`ExtractedBrief` / `ExtractedBriefDTO`):
  - `reference_suggestion` - triggers the nudge (mirrors `photo_suggestion`).
  - a mode marker (e.g. `reference_mode: true`) so later turns know we are in reference-edit mode.
- The client **persists the reference** in the view model and **re-sends `reference_image_b64`**
  on the turns that need it: the initial read turn and the final approve/edit turn (mirrors how
  `prior_image_b64` is re-sent for refine/resize).

### Turn routing

- **Read turn:** when a reference arrives and has not yet been read, the brain's job is
  read + reconcile + emit the reduced question set (gaps only, tailored to the swaps) + the
  "what I read" note + any structural-mismatch flag. The design stage is suppressed.
- **Gaps stage** runs (collecting the swap details). **Design stage is skipped** in reference mode.
- **Approve turn:** the engine checks `reference_mode` + presence of `reference_image_b64`. If set,
  it routes to the **edit path (n=1)** instead of `generate_concepts` (n=3).

### Image generation

- Add a small edit path in `engine/tools.py` (parallel to `refine_concept(mode="edit")`), e.g.
  `edit_reference(reference_path, text_content, aspect_ratio, ...)`:
  - Materializes the reference to a temp file (reuse the `orchestrator._materialized_images` /
    `_resolved_image` pattern).
  - Calls the generator with the reference as the input image and an **edit-mode prompt**.
  - `n=1`, `save_images=False`, returns a single `Concept`.
- Prompt (in `prompt_builder.py`): reuse `_build_text_section` (its per-letter "SPELLING:"
  emphasis is exactly what we want for fidelity) wrapped in an edit framing:
  *"EDIT MODE: Preserve this flyer's exact design, layout, colors, fonts, and graphics. Replace
  ONLY the following text..."*. **Skip** the palette/style/mood/category-style sections (inherited).
- **Aspect ratio:** set to the reference's ratio. Detect from the uploaded image's dimensions
  (client-side is simplest; pass through `aspect_ratio`). This also skips the format question.

### Brain / prompt changes

- The brain must receive the reference image in-context on the read turn (Sonnet 4.6 is
  vision-capable). Add a reference-mode branch to the turn logic and system prompt: read the
  flyer, extract fields + design read, produce the reduced question set, skip design, flag
  structural mismatch.

### iOS changes

- `ReferenceSuggestionBubble` (twin of `PhotoSuggestionBubble` in `FlyerChatView.swift`): single-image
  `PhotosPicker`, normalize to JPEG, plus a decline action.
- `ChatRequest.reference_image_b64`; persist the reference in `FlyerChatViewModel` and re-send on
  read + approve turns.
- A bubble to show the uploaded reference (twin of `UserPhotosBubble`, labeled "Reference").
- Decode the new brief flags; nudge logic: **once per flyer, mutually exclusive with the photo
  nudge** - if the user takes the reference path, suppress the photo nudge; if they decline, the
  photo nudge may still fire.
- Review card in reference mode: show the field swaps; the decisions section is empty or reads
  "Design: matched to your reference."
- Detect the reference's aspect ratio and pass it through (or let the engine detect it).

## Quota / paywall

An edit-create burns **1 quota unit** and hits the paywall exactly like a from-scratch create,
even though it produces a single image. Refine/resize remain free, as today. No new counter logic.
(See [[flyer-generation-economics]].) Pricing can be revisited later; this is the least-surprising
default.

## Risks and mitigations

1. **Text fidelity on a raster edit (the make-or-break), especially Arabic/Urdu.** Swapping text on
   an existing flyer can leave ghosting or font mismatches; non-Latin scripts are hardest.
   *Mitigation:* **prototype first** (Phase 0 below) on 2-3 real flyers including one Urdu, before
   any UI is built. If it is shaky on non-Latin scripts, the style-rebuild fallback becomes the
   primary path for those, and we know that up front.
2. **Brain misreads the reference.** *Mitigation:* the "here's what I read" confirmation.
3. **Structural mismatch** (reference doesn't fit the event). *Mitigation:* brain flags and adapts.
4. **Larger payloads** (reference re-sent each relevant turn). Acceptable; already done for
   `prior_image_b64`.
5. **Non-flyer input.** No special handling by decision; the model does its best.

## Prototype-first plan (de-risk before building)

**Phase 0 - text-fidelity spike (throwaway).** A small script that calls the existing
`image_generator` edit path with a real flyer image + a "preserve design, swap this text"
instruction. Evaluate fidelity across Latin and Urdu. **Decision gate:** if fidelity is good,
build the full flow; if not, the fallback becomes primary for non-Latin and we adjust the UX
copy accordingly.

**Phase 0 result (2026-07-03, round 1 - app-generated flyers): PASS.** Ran the edit on three
`test_output/` flyers via `nano-banana-pro`:
- Ornate English (Jashn -> Milad-un-Nabi): design preserved ~pixel-perfect (filigree, lanterns,
  arch), all text swapped cleanly, no ghosting.
- **Urdu niaz (the critical case): clean, legible Urdu re-rendered** (title, date line, "from"
  line), background calligraphy/gradient preserved. Native-speaker spot-check still advisable.
- Text-dense menu (Huqqa -> Zaituun): name/day/phone/price-badge swapped, all menu items + food
  photos preserved.
- **Caveat - speed: ~50-111s per edit.** Fidelity is not the risk; latency is. The UX needs an
  explicit "this takes a minute" progress state.
- **Still pending: round 2 on real external flyers** (compressed WhatsApp JPEGs / photos of print),
  which is the honest stress test. Round 1 flyers were the app's own clean AI output.

**Build note (2026-07-03) - the edit is driven by an explicit change-list, not a field re-list or a
field-diff.** Two approaches were tried and rejected end-to-end on the real Muharram flyer:
1. *Re-list every field* ("make the text read this") -> over-edited: the model **replaced the
   speaker's photo** to match the new (African) name and **re-laid-out the headline band** (the brain
   had embellished it during extraction).
2. *Field-diff* (brain records the flyer's literal text `reference_original`; edit only changed fields)
   -> **unreliable**: the read turn (sees the image) and later answer turns (work from the brief only)
   produce inconsistent extractions, so unchanged fields showed **false diffs** (venue, headline).

Final design, implemented: the brain emits `reference_changes` - a list of concrete, self-contained
edit instructions for ONLY what the user asked to change (e.g. "Change the speaker to ABDULLAH ABIDI
(AFRICA)"). `edit_reference` applies exactly those, with an explicit "do not change any photo/person/
face, even if a change names someone else," and mentions nothing else - so all other text, imagery,
and layout are left alone. `reference_changes` is sticky in the brief and accumulates across the
read -> answer -> approve turns. Field extraction still happens, but only to show the user what the
flyer says and to ask smart questions; it does NOT drive the edit.

**Build note (2026-07-03) - removed the brain layer entirely (owner feedback: still over-engineered).**
Even the change-list was too much machinery between the user and the model. Final shipped engine:
`handle_reference(image, instruction)` -> `edit_reference` passes the flyer + the user's own words
straight to Nano Banana Pro. No brain call, no `reference_mode`/`reference_changes`, no extraction,
no review card. Verified end-to-end with `client=None` (proves no brain dependency). Photo control is
just words: "keep the existing photo" noticeably preserved the subject's cap/pose/attire vs. a full
face-swap when unmentioned - though generative editing still re-renders a face somewhat (not
pixel-identical; inherent to the model, accepted for v1). Reverted: the multimodal shim, the reference
system prompt, and the `TurnResult`/brief reference fields. Kept: `nearest_aspect_ratio` (widened set),
the `reference` action, `edit_reference`.

**Build note (2026-07-03) - iOS wired (build succeeds).** A `.referenceNudge` bubble at chat start
offers three sources (owner's call): **Photos** (PhotosPicker), **My Flyers** (grid sheet over
`@Query SavedFlyer`, uses `imageData`), and **Explore** (grid sheet over `SampleLibrary.samples`,
renders `UIImage(named:)` to JPEG). All three feed `vm.useReference(imageData:)` -> `enterReferenceMode`
-> shows the flyer as the current concept (heading "Your flyer") and routes the concept card's refine
box to the `reference` action (mirrors the seed-from-sample pattern). Each edit is 1 quota unit via the
existing concepts/gated path; Save-to-Photos and Add-to-My-Flyers work (the latter now tolerates a nil
brief). All changes in existing Chat files - no new .swift files, so no pbxproj edits. **Left: Cloud Run
redeploy** so Release builds know the `reference` action (Debug hits localhost and works today).

**Bugfix (2026-07-03) - the composer must edit in reuse mode.** First device test: a typed edit ran
the full from-scratch design/review/3-concepts flow. Cause: reuse mode had TWO inputs - the concept
card's refine box (correctly `reference`) and the bottom composer (`describe`) - and the user typed in
the obvious bottom composer, so the brain parsed "change Friday Prayer to Sunday Prayer" as a NEW flyer.
Fix: in reuse mode the composer routes to `reference` on the current image too (placeholder ->
"Tell me what to change…"), the VM tracks `currentReferenceB64` (each edit builds on the last result),
and a small "Editing your flyer · New flyer" row lets the user drop back to describe. `inReferenceMode`
is now `@Published`. (The older seed-from-sample flow has the same two-input shape but was left as-is.)

**Polish (2026-07-03) - uploaded original is display-only.** Device feedback: the uploaded flyer showed
Save/My Flyers/Resize, which only make sense for GENERATED results. New `.referenceImage` bubble renders
the upload as a plain "Your flyer" image card (no actions, no refine box - editing is via the composer);
edited results keep the full toolset.

**Polish (2026-07-03) - graceful no-image failure.** The image model sometimes returns no image (e.g.
declined "change the speaker to Donald Trump"), which surfaced as a broken concept card with raw "No
image in response" + useless Refine/Save/Resize. Now a no-image result (any generation, all-concepts
case) shows a friendly `.error` bubble ("...mind trying again? Rewording the change can help.") instead.
Already-correct: no quota consumed and `currentReferenceB64` unchanged on failure, so retry is clean.

## Rough implementation phases

1. **Phase 0:** text-fidelity spike (above). Gate.
2. **Engine:** `reference_image_b64` field, brief flags, brain read-branch, edit path in
   `tools.py`, edit prompt in `prompt_builder.py`, skip-design routing, aspect-ratio passthrough.
3. **iOS:** reference nudge bubble, upload + persist + re-send, reference display bubble, brief-flag
   decoding, nudge mutual-exclusion with the photo nudge, review-card tweak.
4. **Fallback + structural-mismatch flag.**
5. **Deploy engine to Cloud Run** (Release hits the deployed engine) and verify on device.

## Deferred / open

- Copyright soft-notice: deferred, low stakes.
- Photo-into-reference compositing: v2.
- Upfront / persistent entry points: not now.
