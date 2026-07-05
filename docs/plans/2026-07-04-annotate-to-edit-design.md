# Annotate-to-Edit - Visual Edit Instructions (Design Spec)

- Date: 2026-07-04
- Status: Approved design (owner sign-off 2026-07-04). **Phase 0 spike PASSED 2026-07-04 -
  single-image approach confirmed. Building.**
- Related: [[trust-the-model-over-scaffolding]], reuse-a-flyer spec
  (`docs/plans/2026-07-03-reuse-a-flyer-reference-edit-design.md`),
  [[flyer-generation-economics]], [[xcode-project-file-management]].

## Summary

Let a user **circle areas of a flyer and pin a numbered note to each**, instead of typing every
change into the composer. The circles + numbered notes compile into the exact same thing we send
today - an image plus an edit instruction - so this is a **visual authoring surface for an edit
turn**, not a new engine capability.

The user opens the flyer **full-screen**, drags circles onto the spots to change, types a short
note on each (shown as a sticky note right there on the image), optionally adds one whole-flyer
note, and taps **Apply**. We then send the flyer **with the numbered circles burned in** plus a
numbered message (`1. ... 2. ...`) so the model matches circle ① to instruction 1, and removes the
circles from its output.

This works on **both** editable surfaces: a reuse-a-flyer flyer (uploaded / picked from My Flyers
or Explore) and a **freshly generated result** (as an alternative to the typed refine box).

## Why

Describing spatial edits in words is awkward ("the logo in the top-right, and the price banner at
the bottom, and the third menu item"). Pointing is natural. Showing the model *where* each change
applies - by drawing on the image - is also how the model reads intent most reliably: the picture
carries the location, the numbered text carries the instruction. It leans on the model's
reference-and-edit strength (same bet as reuse-a-flyer) and keeps the code a light wrapper.

## The key idea: two renderings of one annotation

Each annotation exists in two forms. Keeping them separate is the core of the design.

| Rendering | Contains | Who sees it |
|---|---|---|
| **Editor view** | flyer + numbered circles + each note as a sticky note beside its circle + an optional whole-flyer note box | the user, while annotating |
| **Model image** | flyer + numbered circles **only** (all note text stripped) | Nano Banana Pro |

The note text never gets burned into the image sent to the model; it travels as the numbered
message instead (plus a trailing whole-flyer line, if any). This keeps the image clean - just
pointers - and puts the verbose instructions where text belongs.

## Decisions locked

| Question | Decision |
|---|---|
| What goes on the model image | Numbered circles only - **no** note text baked in |
| Circle color | Fixed **high-contrast magenta** (`~#FF0096`) - proven visible on dark/gold, black, and lime in the spike; user sees it live while drawing, so blend-in self-corrects. Adaptive/user-pick deferred |
| What carries the instructions | A numbered message `1. <note>\n2. <note>\n...`, plus an optional trailing whole-flyer line |
| Whole-flyer / global changes | Optional **general-note box** in the editor, appended as a trailing unnumbered instruction - so regional + global changes go in one turn |
| One image or two | **One** image (marked-up). Two-image (map + clean) is the spike fallback only |
| Where it works | Reuse-a-flyer flyers **and** freshly generated results |
| Annotation shape (v1) | Circles / ellipses only (drag to draw) |
| Relationship to the typed box | **Complements** it - typing still works; annotation is an optional second path |
| After Apply | Sends immediately (the editor was the authoring step); no separate review-text screen |
| Failed edit (no image) | Annotations **retained** - reopen the editor with all circles/notes intact to reword and resend |
| Presentation | **Full-screen** editor with pinch-to-zoom + pan for precise placement |
| Server-side coordinates | None - the image is the spatial channel; no region parsing |
| Quota | Inherits the path: reuse-mode annotated edit = 1 unit (as today); annotated refine on a generated result = free (as today) |

## User experience / flow

1. Any editable image card shows a **"Mark up" button** - the reuse-mode "Your flyer" card, an
   edited-result card, and a generated concept card.
2. Tapping it opens the **full-screen annotation editor** on that exact image.
3. **Drag to draw a circle** (bold high-contrast outline). It auto-numbers (①②③...) and its
   **sticky-note text field opens immediately** - the user types the change for that spot ("make
   this the new date", "remove this logo"). Dismissing with an **empty** note removes the circle,
   so every circle always has a note and there are never orphan pointers.
4. Repeat per spot. **Tap** a note to edit its text; **delete** removes the circle and **renumbers**
   the rest so they stay contiguous 1..N; **drag** a circle to reposition it. **Pinch-to-zoom / pan**
   to work precisely on small or dense areas.
5. Optionally type a **whole-flyer note** in the editor's general box for changes not tied to one
   spot ("make it more festive", "warmer colors") - it rides along as a trailing instruction.
6. **Apply edits** → we generate the *circles-only* flattened image and the compiled instruction
   (numbered list + any trailing whole-flyer line) **together** (so the numbers always agree), then
   send it as one edit turn. Apply is enabled once there's anything to send (≥1 circle, or a
   whole-flyer note). With **no circles** it's just a plain edit (clean image + the note).
7. The result returns **clean** (marks removed, changes applied). The user's turn appears in the
   transcript as the compiled message (with a thumbnail of the marked-up image we actually sent).
   Iterate again on the new result - a fresh, mark-free image each round. **If the edit fails** (no
   image), the circles + notes are kept so the user can reopen, reword, and resend without redrawing.

### The full-screen editor

- Presented via `.fullScreenCover` (not a sheet) so the flyer uses the entire screen.
- The flyer is **fit-to-screen** (aspect-preserved, letterboxed on the off-axis).
- **Pinch-to-zoom and two-finger pan**, clamped so the flyer can't be lost off-screen; drawing and
  dragging circles work at any zoom.
- **Circle color** is a fixed high-contrast **magenta** (`~#FF0096`) - proven visible on
  dark-green/gold, black/gold, and lime backgrounds in the Phase 0 spike. Because the user sees the
  circle as they draw, any rare blend-in is self-correcting; adaptive color and user-pick are deferred.
- The **number badge** sits on the circle's edge (not its center) so it never occludes the content
  being circled - the model must still read what's inside.
- A **whole-flyer note** field (bottom of the editor), empty by default, for global changes.
- Chrome: a top bar with **Cancel** / title / **Apply**, and a minimal bottom hint ("Drag to circle
  an area"). No shape picker in v1 (circles only).
- Sticky notes auto-position beside their circle and nudge to stay on-screen; tapping one opens its
  text field with the keyboard.

## Architecture / data flow

Stateless per request, exactly like every other turn: the marked-up image round-trips in the
request body just as `reference_image_b64` / `prior_image_b64` do today.

### What we send

- **Reuse mode**: `action:"reference"`, `reference_image_b64` = flattened marked image,
  `message` = the compiled instruction, **`annotated:true`**.
- **Generated result**: `action:"refine"`, `prior_image_b64` = flattened marked image,
  `instruction` = the compiled instruction, **`annotated:true`**.
- The compiled instruction is the numbered list plus, if present, a trailing whole-flyer line
  ("Also, across the whole flyer: ..."). **`annotated` is set only when ≥1 circle was drawn**; a
  general-note-only Apply sends the clean image with `annotated` omitted (an ordinary edit).

### The one engine change: an annotated-edit prompt

Today's reuse prompt is *"Edit this flyer to make this change, keeping the rest of the flyer the
same: {instruction}"*. Sent as-is with a marked-up image, "keep the rest the same" would
**preserve the circles** - the exact failure we must avoid.

So when `annotated` is set, the engine swaps in an annotated-edit prompt (still a light wrapper,
just the essential framing):

> *"This flyer has numbered circles marking areas to change. Apply the numbered instructions below
> to the matching circled areas, then remove every circle and number so none remain in the final
> flyer:\n\n{compiled instruction}"*

- The `{compiled instruction}` is passed through verbatim, so a trailing whole-flyer line just
  becomes another instruction the model applies - the engine needs no special handling for it.
- Threaded through **both** `handle_reference` and `handle_refine` via the `annotated` flag; when
  false/absent, behaviour is byte-for-byte unchanged.
- Implemented as a small branch in `engine/tools.py` (`edit_reference` and the refine path) - or a
  single shared `_annotated_edit_prompt(instruction)` builder they both call. No brain, no
  extraction, no coordinate math, no color hardcoded in the prompt.
- Aspect ratio is auto-detected from the image as today; the marked image has the original's
  dimensions, so it is preserved.

### iOS

- **New `FlyerAnnotationView`** (full-screen), self-contained: inputs a `UIImage` **and an optional
  initial annotation set** (for reopen-after-failure); outputs `(flattenedJPEG: Data,
  compiledText: String, annotated: Bool, annotations: [Annotation], generalNote: String)` via a
  completion closure. Internal model: `Annotation { id, normalizedRect, number, comment }`
  (normalized 0..1 so it survives scaling/zoom) plus a `generalNote` string. Flattens
  **circles-only** via `ImageRenderer` at the image's native resolution; the outline color is the
  high-contrast pick above.
  - New `.swift` file → one `xcodeproj` pbxproj edit (see [[xcode-project-file-management]]), then
    `xcodebuild` to verify.
- **Entry points** wired in `FlyerChatView.swift`: a "Mark up" button on `ReferenceImageCard`, the
  edited-result card, and the generated concept card. Each presents `FlyerAnnotationView` on the
  card's image; on Apply the closure calls into `FlyerChatViewModel`.
- **`FlyerChatViewModel`**: a method that takes the editor output and dispatches the right request -
  `reference` (reuse mode) or `refine` (generated result), with `annotated` set only when circles
  were drawn. Reuses existing gating, streaming, error, and `currentReferenceB64` paths; the marked
  image is only what we *send*, while the *displayed* current image stays the clean latest result.
  It **retains the pending annotation set** until the edit succeeds, so a no-image failure can
  reopen the editor with everything intact.
- **`ChatRequest`** gains `var annotated: Bool?` (omitted when nil, like the other optionals).
- The typed composer / refine box are untouched - annotation is additive.

## Phase 0 spike (the gate, chosen by owner - run before building UI)

Same de-risking discipline as reuse-a-flyer's Phase 0. **Throwaway**, no app code.

- On 2-3 real flyers (include **one edited generated result**, one **text-dense** flyer, and one
  **red/dark** flyer to check the high-contrast color), hand-draw numbered circles in any image
  editor, then call the existing image generator with the annotated-edit prompt.
- **Check:** (a) the model maps ①→instruction 1 correctly, and (b) it **removes the circles/numbers**
  so none remain in the output.
- **Decision gate:**
  - Clean removal + correct mapping → build the single-image design as specified.
  - Circles leak into the output → switch to the **two-image fallback**: send the marked image as a
    *map* plus the clean original as the *base to edit* ("use image 1 to locate each numbered change;
    produce an edited image 2; do not draw the marks"). This changes only *what we send*, not the
    editor UI, so the build is unaffected.

### Phase 0 result (2026-07-04): PASS

Ran the spike on three real flyers via `nano-banana-pro` - magenta circles with edge number badges,
single marked image + a numbered instruction list:

- **Islamic event (dark green/gold, ornate):** date and phone swapped correctly by circle number;
  **all marks removed**; ornate arch / lanterns / geometric pattern preserved.
- **Huqqa menu (black/gold, text-dense, 3 circles):** price badge, one menu line (Cheese Pizza →
  Garlic Naan + price 10 → 8), and phone all swapped; circle ② slightly overlapped "Baba Ganoush"
  yet it was left untouched - **the numbered text disambiguated**; all marks removed.
- **Rosa's bakery (a "photo of a printed poster" generated result, lime bg):** two regional swaps
  (date, price) **plus the whole-flyer note** (green → pastel pink) applied together in one turn;
  all marks removed; cork board / pins / fold creases / flower border preserved.

Mapping was correct in every case (including the dense and the overlapping circle), circle/number
removal was **100% clean** on all three, fixed magenta was highly visible on every background, and
the trailing whole-flyer note worked alongside the regional edits. **Decision: build the
single-image design as specified; the two-image fallback is not needed.** Latency 18-119s (the
slowest confirms the existing "this takes a minute" progress state is warranted).

## Quota / paywall

No new counter logic. An annotated edit is just an edit on whichever path it rides:
- Reuse-mode annotated edit = **1 quota unit** and gated, exactly like a typed reuse edit today.
- Annotated refine on a generated result = **free**, exactly like a typed refine today.

(See [[flyer-generation-economics]]. Pricing revisit is deferred, as with reuse-a-flyer.)

## Risks and mitigations

1. **Marks bleed into the output** (a circle or stray number left in the final flyer). *The
   make-or-break.* *Mitigation:* the "remove every circle and number" instruction; **Phase 0 spike**
   proves it before any UI; two-image fallback if it fails.
2. **Wrong circle→instruction mapping** on a busy flyer. *Mitigation:* numbers drawn large and
   high-contrast with the badge on the circle edge; the spike checks mapping on a dense flyer; notes
   are 1..N contiguous.
3. **Precise placement on small elements / invisible circles on busy flyers.** *Mitigation:*
   pinch-to-zoom + pan; the high-contrast color pick; normalized coordinates so a circle stays put
   across zoom.
4. **No-image result** (model declines). *Mitigation:* existing friendly `.error` bubble path; no
   quota consumed, current image unchanged, **and the annotation set is retained** so the user
   reopens with circles intact and rewords - a clean retry.
5. **Latency** (~50-111s per edit, per reuse-a-flyer Phase 0). *Mitigation:* the existing
   "this takes a minute" progress state applies unchanged.

## Non-goals (v1)

- **Other annotation shapes** - freeform ink, arrows, rectangles, tap-to-pin. Circles only.
- **User-selectable circle color.** v1 auto-picks a high-contrast color; a manual toggle is deferred.
- **Server-side coordinate parsing / region masks.** The image is the spatial channel.
- **Review-the-compiled-text screen** before send. The editor is the authoring step; to reword,
  re-open Mark up. (Easy to add later if it's missed.)
- **Annotating gallery images outside a chat.** Only inside the chat's editable cards for now.
- **Replacing the typed box.** Annotation is a second path, not a replacement.

## Rough implementation phases

1. **Phase 0 (do first, gate):** annotated-edit spike (above).
2. **Engine:** `annotated` flag on `ChatIn`; annotated-edit prompt branch in `edit_reference` +
   the refine path; deploy to Cloud Run (Release hits the deployed engine).
3. **iOS - editor:** `FlyerAnnotationView` (full-screen, zoom/pan, draw/edit/delete/renumber,
   high-contrast color, edge number badge, whole-flyer note field, accepts an initial annotation
   set, circles-only flatten), pbxproj add, build.
4. **iOS - wiring:** "Mark up" buttons on the three card types; VM dispatch to `reference`/`refine`
   with `annotated` (only when circles drawn); `ChatRequest.annotated`; retain-on-failure reopen;
   transcript thumbnail of the marked image.
5. **Verify** on device (owner): reuse-mode edit, generated-result edit, multi-circle, delete/
   renumber, zoom placement, whole-flyer note, failed-edit retry, mark-free output.

## Build notes (2026-07-04)

- **Engine (done, verified).** New `annotated: Optional[bool]` on `ChatIn`; a shared
  `annotated_edit(image, generator, instruction)` in `engine/tools.py` using the spike-validated
  prompt ("... remove every circle and number ..."); branched into from both `handle_reference`
  and `handle_refine` when `annotated` is set. `annotated` false/absent = byte-for-byte unchanged.
  A fake-generator harness confirmed: annotated -> annotated prompt + single image + n=1 on both
  paths; reference `annotated=false` still uses the plain prompt (regression guard); no-image case
  errors cleanly with no generate call.
- **iOS editor (done, builds).** New `FlyerAnnotationView.swift` (added to the `Chat` group /
  `FlyGen` target). A `UIScrollView` gives native pinch-zoom + **two-finger** pan; a one-finger pan
  on an overlay draws a new circle (empty space) or repositions an existing one; a tap edits a
  circle's note. Finger-count separates draw from pan, so no mode toggle. Circles are stored
  normalized (0..1) so they survive zoom. Two renderings: the on-screen overlay shows circles +
  number badges + small note tags; `renderMarkedImage` flattens **circles + numbers only** at native
  resolution for the model (the exact spike artifact). Notes are edited via an alert (auto-opens on
  a new circle; empty = discard); whole-flyer note sits in the bottom bar.
- **iOS wiring (done, builds).** `ChatRequest.annotated`; `FlyerChatViewModel.beginAnnotation` +
  `applyAnnotatedEdit` (routes `reference` in reuse mode, `refine` on a generated result; `annotated`
  set only when circles exist) + `reopenAnnotationIfPending` (retain-on-failure). "Mark up to edit"
  buttons on `ReferenceImageCard` and every generated `ConceptsCard`; a `fullScreenCover(item:)`
  presents the editor. Gating is at editor-open (a paid generation follows), reusing `gated { }`;
  quota consumes on success via the existing `onCreditDeduction`. The transcript shows the marked
  image thumbnail + the numbered message we sent.
- **Whole app builds** (`xcodebuild ... iphonesimulator` → BUILD SUCCEEDED).
- **Deploy:** engine redeployed to Cloud Run without `--set-env-vars` so the existing
  `OPENROUTER_API_KEY` + `ENGINE_SHARED_SECRET` are preserved (avoids the wipe pitfall). Backward
  compatible - no released client sends `annotated`, so current users are unaffected.

## Deferred / open

- Additional shapes (arrows / freeform / pin) - later, if circles prove limiting.
- User-selectable circle color - later, if the auto-pick misses.
- Review-the-text-before-send step - later, if users want to tweak wording.
- Annotating arbitrary gallery images - later.
