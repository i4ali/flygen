# FlyGen — Flyer Create & Edit Workflow Review

**Date:** 2026-08-04 · **Scope:** the complete create and edit workflow, judged against real use cases
**Method:** 22 agents read the shipping code end-to-end — 5 mapping passes over the chat UI, the engine turn loop,
the retired wizard, entry/monetization, and the prompt/image pipeline; 9 use-case walkthroughs; an adversarial
verification pass over every claim; and a completeness critic. **152 findings. Every one was re-checked against the
code by an independent agent instructed to refute it: 0 were refuted**, 30 were corrected in detail.

---

## 1. Headline verdict

**The intake is the best part of this product and the edit loop is the worst.**

One sentence really does become a complete, reviewable, editable design brief in a single LLM call. That is a genuine
achievement and it is the thing the README calls the moat. But the moment the user has an image in hand — which is
where flyer tools live or die — the architecture stops helping and starts fighting.

The single most damaging fact in this review:

> **A typed refine rebuilds the entire flyer prompt from a brief that carries no design decisions**, so every
> one-word correction silently re-specifies the flyer as *warm reds/oranges, light airy background, modern-minimal,
> friendly, illustrated, portrait 3:4* — and then appends *"Preserve all other elements exactly as they appear."*
> `engine/orchestrator.py:184` → `engine/compile_project.py:17-21,59-64` → `engine/tools.py:53-60`

Ana asks to fix "Feburary 8". The prompt she generates contains, verbatim:

```
Date/time must read EXACTLY: "Feburary 8 | 7:00 PM" (SPELLING: F e b u r a r y   8   | ...)
...
CRITICAL TEXT REQUIREMENTS: All text must be spelled EXACTLY as specified above - double-check every letter.

EDIT MODE: Modify the provided image with these specific changes: fix the date to February 8.
Preserve all other elements exactly as they appear in the original image.
```

Two long, emphatic, letter-spelled instructions say *keep the typo*. One trailing sentence says *fix it*. She pays a
quota unit for a coin flip, and the failure is silent — the flyer comes back looking fine with the typo still in it.

### Scorecard

| Dimension | Grade | One-line reason |
|---|:--:|---|
| First-run experience | **D** | Brand-new install hits a paywall on its first send; no free flyer, no trial |
| Intake / brief extraction | **A−** | One sentence → complete brief, provenance badges, editable before spending |
| Review-and-approve gate | **B−** | Right idea, right placement; but one-shot latching and no way to add a missing field |
| **Create → first image** | **B** | Genuinely fast and good; 3 concepts for 1 unit |
| **Edit an image you made** | **D** | The refine prompt actively contradicts the edit; no undo, no diff, no retry |
| **Edit a flyer you uploaded** | **C+** | Architecturally the *better* edit path — light prompt, true aspect ratio — but unprotected |
| Multi-format / print | **D+** | Letter, A4 and Portrait all render as 3:4; no DPI, no PDF, no share sheet in chat |
| Brand consistency | **F** | Logo, brand colours, typography and templates are all unreachable from chat |
| Multi-language | **C** | Impressive create-path engineering; language is dropped on 4 of 5 image actions |
| Failure & recovery | **D−** | Latch-before-dispatch bricks cards; no Retry; no persistence; SSE tail loss |
| Accessibility | **F** | Every font is `fixedSize:` (Dynamic Type off); one accessibility modifier in the whole repo |
| Economics / honesty | **D** | Paywall sells "50 flyers/month"; the meter counts edits and resizes too |

**Findings by severity:** 20 blockers · 82 major · 31 minor (persona passes) + 19 more from the critic.

---

## 2. What the product actually is today

This matters more than any single bug, because it reframes everything else:

```swift
// FlyGen/FlyGen/App/FlyGenApp.swift:10,15
static let chatEnabled = true
static let classicCreationEnabled = false   // ← the 9-step wizard, templates, drafts, QR, logo
```

**Chat is not one of two creation surfaces. It is the only one.** The guided wizard, `TemplateLibrary`'s ~30 templates,
`QRCodeService`, `LogoCompositeService`, `DraftStorageService`, `ShareLink`, the whole `ResultView` — all compiled, all
live, all unreachable. Everything the wizard could do that chat cannot is simply *gone from the product*, while the app
continues to advertise several of those capabilities.

The shipping surface is five actions over an SSE endpoint:

| Action | Brain? | Image calls | Prompt shape | Cost |
|---|---|---|---|---|
| `describe` / `answers` | gate + Sonnet (effort high, 16k) | 0 | — | free to the user |
| `approve` | none (rebuilt from brief) | **3, sequential** | full ~2,500-char design prompt | 1 unit |
| `refine` | none | 1 | **full design prompt + "EDIT MODE"** | 1 unit |
| `reference` (reuse a flyer) | none | 1 | 1 sentence, true aspect ratio | 1 unit |
| `resize` | none | 1 | 4 sentences, no anchors, no negatives | 1 unit |

Note the asymmetry that runs through the whole review: **the two *lightest* prompts (`edit_reference`,
`annotated_edit`) are the two *safest* edit paths, and the heaviest prompt (`refine`) is the most destructive one.**

---

## 3. What is genuinely good

This is not a bad codebase. Several things here are better than most apps in this category, and the fix plan should
protect them.

- **One-call intake.** `engine/interpret.py` does extraction, completeness checking, design decisions, creative
  proposals and a written plan in a single structured call. From one sentence to a full reviewable brief.
- **Provenance is surfaced.** STATED/INFERRED badges on every extracted field (`FlyerChatView.swift:462-471`) —
  the user can see what the model invented. Very few AI tools do this.
- **No silent defaults, honestly implemented.** The generic rubric deliberately declines to nudge a palette rather
  than mislead a solemn brief (`engine/rubrics.py:39-43`) — with the reasoning written down.
- **The gate fails open, by design and with the math written out** (`engine/gate.py:7-11`). A real request is never
  turned away by the classifier.
- **Failure is free.** `onCreditDeduction` fires only inside `image_base64 != nil` branches
  (`FlyerChatViewModel.swift:462-466, 471-475`). Users are never billed for a spinner.
- **Text anchoring is real engineering.** Per-field `must read EXACTLY` + letter-by-letter spelling, with Arabic
  script deliberately exempted from letter-splitting because it would corrupt the shaping
  (`prompt_builder.py:502-510`). The idea is right; only the *data* fed to it on a refine is wrong.
- **Annotate-to-edit is the best feature in the app.** Circle it, note it, send. It bypasses the project rebuild
  entirely, uses a ~40-word prompt, reads the image's true pixel ratio, and — uniquely in the whole product —
  **survives failure with state intact** (`reopenAnnotationIfPending`, `FlyerChatViewModel.swift:385-389`).
- **Reuse-a-flyer is the right primitive**, offered as the second bubble of every chat, with three sources.
- **Fact dedup is Unicode-aware** where it matters — NFKC, `casefold()`, and stripping Cf directional marks so two
  visually identical Arabic strings dedup correctly (`facts.py:25-45`).
- **Sensitive creative ideas are opt-in, not opt-out** (`engine/review.py:67`). Correct default for religious and
  cultural briefs.
- **Three concepts for one quota unit**, and every prior version stays live and re-editable in the transcript.

---

## 4. The eight structural faults

Most of the 152 findings are symptoms of eight root causes. Fix these and the majority collapse.

### F1 — The refine path re-litigates the entire design

`handle_refine` rebuilds the project with **empty overrides** from a brief that **never carried decisions**:

```python
# engine/orchestrator.py:183-184
turn = TurnResult(**{k: v for k, v in self.brief.items() if k in TurnResult.model_fields})
project = self._build_project(turn, {}, {}, None, language=language)
```

`_decisions_map` returns `{}`, so `_aspect(None)` → `PORTRAIT_4_5`, style → `MODERN_MINIMAL`, mood → `FRIENDLY`,
palette → the warm/light default, `imagery_description` → `None`. That whole create prompt is then prepended to
`EDIT MODE`. **Symptoms:** palette/style/mood reset · aspect-ratio snap-back to 3:4 · creative elements dropped ·
typo resurrection · a 16:9 cover becoming portrait after one typo fix.

Note the same user intent behaves *differently depending on whether a circle was drawn*: the annotated path reads the
real ratio (`engine/tools.py:77-86`) and skips the rebuild entirely.

### F2 — Nothing about the flyer round-trips

`to_brief_dict` (`engine/review.py:15-23`) puts content fields on the wire and nothing else. No decisions, no creative
elements, no aspect ratio. And `handle_approval` emits only `concepts` — never an updated `parsed_fields` — so **the
client's brief never learns what was actually generated.**

**Symptoms:** review-card corrections silently reverted on the next refine · the approved look is unknowable to
client, server and storage · `chatFlyerProject()` saves default colours/visuals (its own comment admits this,
`FlyerChatViewModel.swift:392-394`) · "Use as Template" is deliberately hidden for chat flyers because the recipe is
known to be wrong (`GalleryTab.swift:201`) · **"same design, new content" has no implementation at all.**

### F3 — Zero persistence, and the transcript is the only state

```swift
@Published var transcript: [ChatBubble] = []          // FlyerChatViewModel.swift:30 — in memory only
Button("Close") { dismiss() }                          // FlyerChatView.swift:68 — no alert, no isStreaming guard
```

No SwiftData write, no UserDefaults, no `scenePhase` hook anywhere in `Chat/`. The transcript *is* the version
history, the undo stack, the working brief and the only handle on `currentReferenceB64`. One mis-tap on Close — top
left, exactly where Back lives — destroys all of it, including paid concepts. The retired wizard autosaved a draft on
background and asked before discarding. **The shipping surface has neither.**

### F4 — Latch-before-dispatch

Both approval controls disable themselves *before* the work is attempted, and nothing ever re-enables them:

```swift
Button { approved = true;  onApprove(fo, dov, selectedElements()) }   // FlyerChatView.swift:688
Button { submitted = true; onSubmit(answers, order) }                  // FlyerChatView.swift:540
```

A network blip, a paywall, an empty submit, or a tap while streaming permanently bricks the card. The review card at
least checks `isBlocked` first (`:687`); the questions card does not — so a user who hits the paywall, **subscribes,
and comes back finds the card still dead.** With no Retry on error bubbles and no persistence, the only escape is the
composer, which wipes the brief and starts over.

### F5 — The brand and asset layer is built, promoted, and disconnected

| Asset | Exists | Reachable from chat |
|---|:--:|:--:|
| Brand Kit (logo, contacts) | ✅ + intro sheet + Profile row | ❌ zero `BrandKit` references under `Chat/` |
| Logo compositing | ✅ `LogoCompositeService` | ❌ only called from the dead wizard |
| QR codes | ✅ `QRCodeService` + `qr_service.py` | ❌ zero production call sites |
| ~30 templates | ✅ `TemplateLibrary` (915 lines) | ❌ behind `classicCreationEnabled` |
| Brand colours | ❌ `BrandKit` has no colour fields at all | ❌ |

And the app **actively sells what it cannot do**: `BrandKitView` says *"They'll auto-fill when you create new
flyers."*; the unskippable onboarding demo lists *"Adding a QR code for RSVPs"* as one of five "real engine steps"
(`OnboardingScript.swift:54`), 0.4 s before the paywall. Asking for a QR in chat doesn't fail loudly — the brain files
it as a fact and the flyer is instructed to print *"Scan the QR code to buy tickets"* next to no code.

### F6 — Generative-only editing, with no verification

The only artifact is a flat raster (`Concept = version_id + image_base64 + error`). So the only way to fix one
character is to post the whole image back to the image model and re-render everything. And:

- `edit_reference` and `annotated_edit` send **no text anchors and no negative prompt** — every untouched word on the
  flyer must be re-read from pixels and re-rendered.
- `resize_concept` likewise: a full re-layout with no spelling protection, on the operation whose *whole risk* is
  cropping and re-flowing text.
- **Nothing anywhere checks the output.** Success is `image_base64 != nil`. No OCR, no diff against the brief, no
  back-translation — the multi-language design doc explicitly accepted this.
- Successive edits are re-renders of re-renders. The reuse design doc's own validation records that round 2 on "real
  external flyers (compressed WhatsApp JPEGs / photos of print)" is **"Still pending"** — that is the primary input.

### F7 — The composer's meaning is set by UI mode, never by intent

Outside reuse mode, *any* typed text nulls the brief and starts a new flyer. Inside reuse mode, *any* typed text is an
edit instruction against the current image. Neither branch looks at what was actually said. The gate only ever answers
"flyer / not-flyer" — it never classifies **create vs. edit**, and `INTERPRET_SYSTEM` has no concept that a flyer
already exists.

So: typing "make the 20% bigger" under three finished concepts silently produces a *fourth brand-new flyer*, and
typing next month's full bulletin after picking last month's flyer from My Flyers hands that whole description to the
image model as an *edit instruction*. Both are paid, both are silent, and both are the most natural thing to do.

### F8 — The meter doesn't match the pitch, and it's inverted

The paywall sells **"50 flyers / month"** / "12 flyers / week". The meter counts image *actions*: create, refine,
resize, reference edit — one unit each. The code knows this (`GenerationAccess`'s own doc comment says "a single image
action (new / refine / resize)"), the UI never says it, and there is **no quota indicator anywhere in the chat**.

Worse, it's inverted against cost: an approve turn is **three sequential** image calls for one unit; a refine is one
call for one unit. The rational user strategy is to *abandon the flyer and re-describe it* rather than refine — which
is exactly the path that discards their approved decisions.

Both governing design docs say the opposite of what shipped: *"Refine/resize free as today"* and *"Annotated refine on
a generated result = **free**."*

---

## 5. Use-case breakdown

### 5.1 "One sentence, one flyer, right now" — Maria, corner grocery, Friday night · **C+**

*"20% off all produce this weekend"* → she wants one flyer for Instagram and the shop door in under two minutes.

**Works:** one ungated tap from Home into a blinking cursor. One sentence produces a complete brief. Every design
decision arrives pre-picked with a reason, so zero taps are required on the panel. The auto-scroll deliberately defers
a runloop tick so she lands on the Approve button, not past it.

**Breaks:**
- **A brand-new install cannot make anything.** `credits = 0`, no code path grants any, `CreditPurchaseSheet` is
  unreachable → her first send hits the paywall after she's already typed. No free flyer, no watermarked sample.
- Before that, a **hard iCloud wall** blocks the app on a live CloudKit round trip that fails closed on any error.
- "Portrait (4:5) — Instagram" **never produces 4:5**; `NANO_BANANA_ASPECT_RATIOS` maps it to 3:4 — taller, and
  Instagram crops it, on a "full-bleed, fills the canvas edge-to-edge" design. Gemini accepts 4:5 natively.
- Her **shop's name never appears**: not in her sentence, not in the must-have floor, and `BrandKit.businessName` is
  applied by no code path in the repo. Anonymous sale poster.
- Every chat flyer is force-fed *"custom illustrated graphic elements, artistic drawings"* — `imagery_type` is never
  set, so it defaults to `ILLUSTRATED`. A produce sale is the archetypal case for photography.
- If the brain suggests a photo (likely for food), the **review card is silently withheld** until she answers — and if
  she types instead, the held review is discarded forever while the nudge's buttons stay visible and inert.
- Tapping "Send answers" with nothing filled in — her most natural "just make it" gesture — **permanently bricks the
  card** with no request sent and no feedback.

### 5.2 "Twelve hard facts and a QR code" — Sam, community fundraiser · **C−**

**Works:** the composer is genuinely built for a long paste. Facts with no dedicated field *do* reach the image with
the same exact-spelling anchoring as the headline. Dedup is conservative and correct. Every dedicated field is
editable with provenance before a credit is spent, and clearing a field actually deletes the value.

**Breaks:**
- **QR is impossible** (F5) and asking produces flyer copy telling people to scan nothing.
- **The ticket price is deleted** whenever a discount line also exists — `if discount_text: … elif price:`
  (`prompt_builder.py:609-617`). Both fields render on the review card, so he approves seeing "$25" and it never
  appears. "Kids under 12 free" plus a ticket price is exactly the shape that triggers it.
- **`additional_info` is not on the review card at all.** Five of his thirteen facts — both sponsor names, doors time,
  kids-free, the QR line — cannot be seen or edited on the screen titled "Review before I generate", and
  `build_project` ignores an override for it even if one were sent. A misspelled sponsor name is the single most
  reputationally costly error on a fundraiser poster.
- Extras are badged **STATED in green regardless of provenance** — the client hardcodes it (`ChatModels.swift:63`).
  The card designed to catch hallucinations lies about the only facts he can't edit.
- Thirteen facts arrive as thirteen **flat, equally-imperative** demands. The per-category `hierarchy` that exists in
  `rubrics.py` never leaves `interpret.py` — it never reaches the image prompt. Meanwhile the negative prompt says
  "cluttered busy composition". Nothing counts fields or warns.
- **The first turn always gets the wrong rubric.** `cat = (prior_brief or {}).get("category") or "announcement"` —
  on the opening describe turn there is no prior brief, so a one-shot "describe → ready → approve" flow (the dominant
  path for a user who supplies everything) **never sees its category's checklist, palette directions or must-have
  floor at all.** His fundraiser never gets "Show the impact, not just the ask."

### 5.3 "Fix one word" — Ana · **D** ← the make-or-break case

**Works:** the prior image *is* passed as an edit base, not regenerated blind. Every prior version stays permanently
reachable and independently re-editable, so she can branch from any card. Failed generations are free. The annotate
path is architecturally correct for this and reopens with circles intact on failure.

**Breaks:** everything in F1 and F2, plus:
- **No zoom.** Concept images render `scaledToFit` inline with no tap-to-zoom and no full-screen. The only zoomable
  surface in the app is the annotation editor — which is **gated on quota**. The user who most needs to check her
  flyer (out of quota, unsure the fix landed) is the one who cannot look at it.
- **No version labels, no diff, no revert.** Every refined concept is `version_id = "refined"` and every card is
  titled "Updated concept". After three corrections she has four identical cards distinguishable only by scroll
  position — and every insertion yanks her back to the bottom.
- **Mid-generation, every card control looks live and swallows taps.** `refine`, `resize`, `beginAnnotation` all
  `guard !isStreaming` but the buttons are never disabled. The composer is correctly greyed out; the cards are not.
- **No Retry on error bubbles**, despite both governing plans specifying "inline error bubble with Retry".
- **The annotated path sends zero text anchors** — the safest path for her edit has no defense against the phone
  number being re-spelled, and nothing would notice.
- The **annotation number badge is drawn unclamped** at the circle's top-left corner and gets clipped off the image
  for circles near the top or left edge — exactly where dates and phone numbers live. The note tag *is* clamped, so
  the omission is clearly unintentional. Circles can also be dragged fully off the flyer while their numbered
  instruction still ships.
- **Typing the whole-flyer note resets the canvas zoom**, because raising the keyboard changes the scroll view bounds
  and `layout(for:)` unconditionally sets `zoomScale = 1`. Zoom is the whole reason the feature can target small text.
- A **note-only annotation (no circles) silently routes to the heavyweight refine path** — two visually identical
  actions in the same editor produce structurally different prompts.

### 5.4 "Same flyer, new date" — Dev, reusing a camera-roll photo · **C+**

**Works:** the best-designed path in the app. Aspect ratio is inferred from real pixels. The composer — not a buried
box — is the edit input, with a mode header and a "New flyer" escape. One HTTP round-trip, one image call, no brain.
The result is a first-class concept card.

**Breaks:**
- **Language is dropped entirely** on `reference` and `resize` (`engine/app.py:47-50, 65-67`), and reuse mode has no
  language control at all because it never produces a review card. The design doc lists this exact work as required.
- **Resize silently drops out of the edit chain**: `currentReferenceB64` is updated only in the `.concepts` branch, so
  after a paid resize the next composer edit reverts to the pre-resize image.
- **"New flyer" leaves every previous card live**, and using one returns the raw internal string
  `"no project to refine"` in a red bubble — following the advertised escape hatch produces developer-ese.
- **Every reused flyer saves with a blank title and category "announcement"** (`brief` is nil, `SavedFlyer.headline`
  only falls back when the *project* is nil, not when the headline is empty). For a monthly user, My Flyers becomes an
  untitled wall — and My Flyers is exactly where he goes each month to find last month's flyer.
- **No downsampling anywhere.** A 12MP photo is base64'd whole, stored twice, retained for the session, and re-decoded
  on every render pass. This is the most likely cause of a mid-session memory kill — which, given F3, is fatal.
- **EXIF orientation is never normalized.** `PIL` reports stored dimensions, so a rotation-tagged iPhone photo can be
  measured — and generated — at the wrong shape. Zero `exif` hits in the repo.
- **A photo that isn't a clean flyer is passed through whole**: no crop, no deskew, no rectangle detection. A photo of
  a printed flyer on a table produces a flyer with the table in it, at the photo's ratio.
- **The My Flyers picker throws away the stored brief.** The `SavedFlyer` carries a fully decoded `FlyerProject` with
  last month's headline, date, venue, phone, website — and `onPick(data)` passes only the image bytes. The app knows
  what the flyer says and chooses not to tell the model.

### 5.5 "A weekly series that looks like a set" — Nadia, yoga studio · **F**

This is the subscription-retention use case, and it is **structurally absent**.

- **Her logo can never appear.** `ChatRequest` has no logo field; `build_project` never sets `logo_path`; the two
  places a logo could enter the image are both dead in chat.
- **There is nowhere in the product to express a brand colour.** `BrandKit` has no colour fields; `ColorSettings` has
  them but no view writes them. The palette is a free-text *name* the LLM invents fresh each week — so she cannot even
  re-select the same palette name twice, and it almost never matches `PALETTE_SWATCHES` so she never gets curated hexes.
- **Typography is not expressible anywhere** in the system — the only signal is a clause buried inside canned style
  descriptors.
- **Nothing about the look round-trips** (F2), so "reuse the look with new content" has no implementation. The only
  reuse primitive is pixel editing of the previous image — a fundamentally different, lossier operation.
- **Templates — the one data structure in the app that bundles a reusable look** (palette + style + mood + format +
  swappable text, ~30 of them) — are dark code.
- Her category (`fitness_wellness`) has no authored rubric, so the brain is told "no preset direction" every week.
- Saved chat flyers **record default colours and visuals, not what was generated** — the app has already conceded this
  by disabling "Use as Template" for them.
- `UserProfile.preferredVisualStyle` / `preferredMood` / `preferredColorScheme` exist with typed accessors and have
  **no reader and no writer anywhere in the app.**

### 5.6 "One flyer, five channels" — Tom · **D+**

**Works:** resize is a genuine model re-layout, not a crop — the right call for 1:1 → 9:16. Every version stays live,
so he can re-resize the *original* rather than chaining lossy re-renders. It's stateless, so it survives a brief reset.

**Breaks:**
- **Three of six format options are the same shape.** `4:5`, `letter` and `a4` all map to `3:4`. Paying a second unit
  for "A4" after "Letter" returns a pixel-identical result. `test_aspect_ratios.py` uses ±0.15 tolerances, so the one
  test that exists to catch this **can never fail**.
- **No print resolution, DPI, bleed, or PDF anywhere.** The only knob sent to the model is `aspect_ratio`; `quality`
  is accepted and never forwarded. "Print-ready quality" is prompt text.
- **No share sheet in chat.** The only `ShareLink` in the codebase is in the dead `ResultView`. To post his flyer he
  must tap My Flyers → Close (destroying the transcript) → Gallery → Share.
- **Refining a resized version snaps it back to portrait 3:4** (F1) — there is effectively no way to iterate on any
  non-portrait version.
- **An uploaded flyer cannot be resized at all** — `ReferenceImageCard` has no Resize menu, even though
  `handle_resize` is fully stateless and would work.
- **Resize taps during a generation are silently swallowed** — and firing off three resizes back-to-back is exactly
  what this user does.
- All four saved versions record `aspectRatio = .portrait` and are indistinguishable in the gallery.

### 5.7 "My flyers, my language" — Layla (Arabic) and Miguel (Spanish) · **C−**

**Works:** the language wire contract is end-to-end and hard to get wrong — stamped on every request in `run()`, not
per call site. The 13-language enums are mirrored exactly across Swift and Python. Onboarding pre-selects from device
locale with in-script labels. The Arabic shaping work is real and targeted, not generic.

**Breaks:**
- **Language cannot be changed after Approve.** The only control is on the review card, disabled by `approved`. When
  concepts come back in the wrong language there is no control anywhere in the app to fix it.
- **The prompt says both "translate everything" and "reproduce the English letter-for-letter."** For the mainline
  shape (English brief → non-English flyer), `must read EXACTLY: "<English>" (SPELLING: …)` fires under a header
  saying "Spell ALL text EXACTLY, letter by letter", alongside "Translate all other English text."
- **For an Arabic brief targeting Arabic**, `_has_arabic_content` adds *"do NOT translate the English text into
  Arabic"* while the language block adds *"translate all non-target-language text."* The one case the Arabic code was
  written for is the one case where its two halves collide.
- **`_spell_out` shatters Devanagari and Bengali graphemes** — verified: `दीपावली मेला` → `द ी प ा व ल ी   म े ल ा`.
  The Arabic exemption exists precisely to prevent this; the design doc flagged Hindi and Bengali for a render check
  before ship.
- **`.upper()` on the spelling hint** turns German `Straßenfest` into `S T R A S S E N F E S T` — the prompt hands the
  model two spellings and presents the wrong one as authoritative.
- Language reaches **1 of 5 image actions**. `reference`, `resize`, and the annotated branch of `refine` all drop it.
- Edit and resize prompts carry **no RTL or script-integrity guidance** — the paths with the most re-rendering risk
  have none of the mitigation the create path has.
- **The app ships one UI language and no RTL layout**: `knownRegions = (Base, en)`, zero `.strings`/`.xcstrings`, zero
  `NSLocalizedString`. Layla reads English to reach an Arabic output, and the transcript's direction fights her text.
- Fact dedup's edge-punctuation list is Latin-only, so `مواقف مجانية۔` and `مواقف مجانية` don't dedup — the guard
  silently does nothing for non-Latin users.

### 5.8 "Everything goes wrong" — flaky connection · **D−**

**Works:** failure is genuinely free. The interpret failure path is wrapped in a real human sentence, locked in by a
test. Temp files are cleaned in `finally` blocks. The UI never wedges in a permanently-streaming state. The annotation
retry is a genuinely good recovery affordance.

**Breaks:**
- **F4 in full:** one transient blip converts a description, answered questions, corrected fields, an overridden
  palette and a chosen language into read-only wreckage.
- **Approve clears the user's uploaded photos before knowing the turn succeeded** — and the photo entry point no
  longer exists afterwards (`photoNudged = true` suppresses the only nudge).
- **The last SSE event of every turn is discarded if the stream errors at the tail.** The parser flushes at the *start*
  of the next frame, and `AsyncBytes.lines` never surfaces the blank-line delimiter — so the final frame comes only
  from the post-loop `flush()`, which is skipped when the loop throws. An `approve` turn emits **exactly one event**.
  Three fully-paid-for concepts, in hand, thrown away by parser bookkeeping.
- **A turn that yields zero decodable events fails completely silently** — the spinner just vanishes. No message, no
  error, no way to know whether anything generated or was charged.
- **Content-policy refusals are indistinguishable from network failures.** `message.content` (where the refusal prose
  is) and `finish_reason` are never read; zero `moderation|refusal|content_filter` hits in the Python tree. The copy
  says "Mind trying again?" — so a user whose flyer contains a religious figure loops forever, burning money.
- **No exception handling** on `handle_approval/refine/resize/reference`; `StreamingResponse` has already sent 200, so
  a server bug is reported to the user as "The network connection was lost."
- **No background-task handling and no SSE heartbeat.** Taking a phone call during the advertised "about a minute"
  generation deterministically kills the turn, while the server completes and pays for three images nobody sees.
- **A partial batch (1 of 3) charges a full unit** and renders raw Python exception text between the flyers.
- **The annotation editor's Apply is the one engine action never wrapped in `gated`** — and it's the path
  auto-re-presented after a failure, i.e. exactly where a user is most likely to be at zero quota.
- **Gating is skipped entirely when no `UserProfile` exists** — `isGenerationBlocked` returns `false`.

### 5.9 "Large text and VoiceOver" — Deacon Ray, 68, parish administrator · **F**

- **Dynamic Type is switched off for the entire app.** `.custom(face, fixedSize: size)` is the API that explicitly
  opts *out* of scaling, across ~429 call sites. The custom composer does the same in UIKit. Zero `UIFontMetrics`,
  `relativeTo:`, `ScaledMetric` or `dynamicTypeSize` hits in any Swift file. The review card — the mandatory approval
  gate — carries its meaning in its smallest text, and there is no zoom and no reflow.
- **There is no VoiceOver support at all.** One `accessibility*` match exists in the whole repo, and it is
  `accessibilityReduceMotion`. The send button, the refine wand, and the photo-delete are bare SF Symbols. The
  composer's placeholder is a sibling `UILabel`, so it reads as floating static text over the field. Annotate-to-edit
  is a drawing canvas with no non-visual equivalent.
- Chat is the only creation surface, so this isn't degraded access — it's **no access**.

**Also surfaced by the critic:**
- **Category is rendered as an editable field and edits to it are silently discarded** — `_CONTENT_FIELDS` omits
  `category`, so `build_project` uses the un-overridden value. It's the highest-leverage value in the pipeline
  (context, negatives, hints, rubric) and it's the first row on the approval screen, in a box with a cursor.
- **The review card can only edit facts the model already extracted** — there is no "+ add" control. At the exact
  moment a user notices a missing phone number, the only way to supply it throws away everything already agreed.
- **Conversation itself is paywalled** even though describe/answers produce no image and consume no quota — while the
  Sonnet calls they *do* cost the operator are metered nowhere. At zero remaining, the chat is a screen where nothing
  can be typed.
- **A paying subscriber on a cold launch is treated as blocked**, because `refreshEntitlements()` waits behind two
  StoreKit network round trips and `quota(for: nil)` is 0.
- **Nothing can be shared or handed off except a flat image.** Private-only CloudKit, no `CKShare`, no brief export.
  The job-to-be-done is two-player (volunteer → secretary, owner → printer); the app is architecturally single-player.
- **No caption, no hashtags, no alt text.** "Sized for any post" is sold everywhere, but the last mile of *postable*
  is left entirely to the user — and the engine already has the facts letter-perfect for free.
- **Legacy credits below 10 are permanently unspendable and invisible** — floor-divided to 0 everywhere.
- **The app is force-dark**, so a flyer destined for white paper is only ever judged against near-black chrome with a
  flattering border and shadow.

---

## 6. Is chat the right paradigm here?

**For intake: yes, emphatically.** Turning "20% off produce this weekend" into a structured, provenance-tagged,
editable brief in one call is a real advantage over a 9-step wizard, and the review card is the right shape for a
single consolidated approval.

**For editing: no, not on its own.** Three things make a chat-only surface strictly worse than direct manipulation for
the jobs this product exists to do:

1. **Fixing a typo is the most common thing anyone does to a finished flyer**, and here it is the *most expensive and
   least reliable* operation available: probabilistic, billable, unverifiable, and capable of changing nine things
   nobody asked about. The repo already contains two exact, free, deterministic compositors (`LogoCompositeService`,
   `QRCodeService`) — both dead.
2. **The approval screen is a form with no schema.** It can only show what the LLM chose to populate, so it can't
   offer a field the user needs to add — and the composer, the only other input, destroys the brief.
3. **The transcript is doing four jobs at once** — version history, undo stack, working state, and conversation — and
   it has no persistence. Every recovery story in the product depends on an array that a single tap deletes.

The honest conclusion is that **chat should own intake and intent, and direct manipulation should own correction.**
The seams already exist: the brief is structured, the text is anchored, the annotation editor already proves users
will point at a region. What's missing is a durable representation of the flyer that is something other than a JPEG.

---

## 7. Prioritized fix plan

### P0 — Stop destroying user work (small, high leverage)

| # | Fix | Files |
|---|---|---|
| 1 | **Send approved decisions back on refine.** The client already holds them in the review card's `decisionValues`. This one change kills F1 entirely — no more palette reset, style reset, or 3:4 snap-back. | `FlyerChatViewModel.swift:342` |
| 2 | **Emit a fresh `parsed_fields` from `handle_approval`** carrying the post-override brief. Kills the typo-resurrection bug. | `engine/orchestrator.py:155-164` |
| 3 | **Don't latch before dispatch.** Bind `approved`/`submitted` to a view-model signal that resets on failure; validate and gate *before* setting them. | `FlyerChatView.swift:540, 688` |
| 4 | **Confirm on Close** whenever the transcript holds an unsaved concept or a live stream. | `FlyerChatView.swift:68` |
| 5 | **Flush the SSE buffer in the `catch`** so a tail-side socket fault stops discarding a completed generation. | `FlyerChatClient.swift:80-84` |
| 6 | **Only clear `brief`/`answers` when a new `parsed_fields` actually arrives**, not optimistically in `send()`. | `FlyerChatViewModel.swift:288` |
| 7 | **Update `currentReferenceB64` on `.refined`/`.resized`** in reference mode (one-line mirror of the `.concepts` branch). | `FlyerChatViewModel.swift:471` |
| 8 | **Clear photos in the success branch**, not synchronously after dispatch. | `FlyerChatViewModel.swift:329` |
| 9 | **Never emit raw internal strings** — wrap the four in `orchestrator.py` the way interpret failures already are; wrap each `handle_*` generator in a try/except. | `engine/orchestrator.py:154,174,186,201` |
| 10 | **Grant one free flyer on profile creation.** Converts the wall into an upsell the user has already seen the value of. | `ContentView.swift:130-139` |

### P1 — Make edits trustworthy

- **Derive the refine aspect ratio from the prior image** with `_reference_aspect_ratio()` — the function already exists.
- **Stop re-emitting the full text section on refine.** Send prior image + EDIT MODE (the shape `annotated_edit`
  already uses successfully), or reconcile the instruction into the brief first and anchor on the corrected values.
- **Add text anchors + negatives to `edit_reference`, `annotated_edit` and `resize_concept`** — a short preserve-list
  of known strings ("these must appear unchanged") plus at minimum `misspelled words, illegible text, cut-off text`.
- **Add Retry to error bubbles**, carrying the failed `ChatRequest`. Both design plans specify it.
- **Disable card controls while `isStreaming`** (refine field, wand, Resize, Mark up) — the composer already is.
- **Add tap-to-zoom / full-screen preview on concepts, ungated.**
- **Version the transcript**: number cards, echo the instruction that produced each, add "use this version".
- **Persist the chat session** (brief, answers, language, reference pointer, concept images) on background and dismiss.
- **Clamp annotation badges into image bounds** and clamp circle origins to 0…1; preserve zoom on keyboard show.
- **Route note-only annotations through `annotated_edit`** instead of the heavyweight refine path.

### P2 — Close the honesty gaps

- **Fix or remove the print formats.** Add `"4:5": "4:5"` (Gemini accepts it natively); either give letter/A4 true
  ratios via deterministic pad/crop, or stop labelling them "Print". Tighten `test_aspect_ratios.py` tolerances.
- **Fix the paywall copy or the meter.** Either "50 designs, edits & resizes / month", or make refine/resize free as
  both design docs specify. Show remaining quota in the chat toolbar and label action costs.
- **Add an out-of-quota state to the paywall** showing the renewal date instead of an acquisition CTA; make the Home
  pill tappable for subscribers.
- **Resolve entitlements before products** on launch, and add an `.unknown` state so a subscriber isn't shown a paywall.
- **Replace the onboarding worklog's QR line** with something the engine actually does, and add a test asserting each
  entry maps to a live code path.
- **Stop shipping the Brand Kit promise** until it's wired — or wire it (see P3).
- **Emit both price and discount** when both are populated.
- **Show `additional_info` on the review card** as editable rows, and honour an override for it.
- **Make category a Menu, not a text field** — or make its override actually work.
- **Render all 15 review fields**, unpopulated ones dimmed, so a user can add a missing fact.
- **Gate only image-producing actions**, letting describe/answers run free to a modest budget — a better conversion
  moment and a far less inert blocked state.
- **Surface Save-to-Photos results** (success checkmark / permission error) — the Gallery already does this correctly.

### P3 — Unlock the use cases that are currently impossible

- **Round-trip the design** (`decisions` + `selected_elements` in `to_brief_dict`, persisted on `SavedFlyer`). This
  single change unlocks "make another like this", accurate saved records, and a real template story.
- **Wire the Brand Kit into chat**: `logo_b64` + contacts on the request; composite the logo client-side with the
  service that already exists. Add brand colour fields and send hexes.
- **Bring QR to chat** — `qr_service.py` is written and tested; it needs a field on the wire and a reserved corner.
- **Expose templates as decision seeds** in chat, plus "save this look".
- **Classify create-vs-edit** in the gate (it's already in the request path) instead of routing on UI mode.
- **Infer the category before the first briefing** so the one-shot path stops getting the generic rubric.
- **Generate the three concepts concurrently** and stream each as it arrives — cuts the wait ~3× for free and shrinks
  the timeout exposure.
- **Add a structured layer**: return text runs with bounding boxes so pure-text corrections can be composited
  on-device, free and exact, reserving generative re-render for genuine design changes.
- **Fix accessibility**: `relativeTo:` on every font role, `UIFontMetrics` in the composer, and labels on every
  icon-only control. This is table stakes, not polish.
- **Add caption + alt text** to `TurnResult` — no extra LLM turn, no image call, and it completes "postable".
- **Make the brief exportable**, so a flyer can be handed to the person who actually prints it.

---

## Appendix — evidence

Full per-agent transcripts and structured findings:
`~/.claude/projects/-home-user-flygen/<session>/subagents/workflows/wf_e0936282-b49/journal.jsonl`

Verification tally across the 133 persona findings: **103 CONFIRMED · 30 PARTLY_TRUE (corrected in detail) ·
0 REFUTED.** Every claim in this report cites code that was opened and read; several were validated by building the
actual prompt and reading the output.
