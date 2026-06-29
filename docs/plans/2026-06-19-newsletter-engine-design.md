# Newsletter Engine Path — Design

> Status: **validated design**, ready for an implementation plan. Date: 2026-06-19.
> Companion to the flyer engine (`docs/plans/2026-06-18-design-expert-engine-design.md`) and the
> "no silent defaults" review gate (`docs/plans/2026-06-19-no-silent-defaults.md`).

## Goal

Add a **newsletter** content type to the engine as a *second pillar* alongside flyers — a thin but
real end-to-end path that mirrors the flyer milestone: a free-text brain-dump becomes a designed,
multi-section **one-page Letter newsletter**, with the engine's complete interpretation surfaced for
one human approval (the `review` gate) before anything is rendered.

## Decisions (from brainstorming)

1. **Scope — mirror the flyer milestone.** Thin end-to-end: `describe → outline + design defaults
   (gate) → draft sections → render ONE Letter page → refine`. Reuse the engine spine. **Defer**
   multi-page issues, "make it monthly" recurrence, and export — these are client/later concerns
   (consistent with the flyer export boundary).
2. **Render — reuse the image pipeline.** Compile the approved document into one prompt and render a
   single Letter page via `nano-banana-pro` (`FlyerImageGenerator`), exactly like the flyer. The
   schema stays **renderer-agnostic** so a structured (HTML/PDF) renderer can be swapped in later if
   text fidelity disappoints — without touching the spine.
3. **Imagery — model renders in-page.** Any photos/graphics are AI-rendered from the prompt (the
   whole page is one generation). User-supplied photo slots are deferred (the pipeline already
   accepts `input_images`, so it's an easy follow-up).

## Non-goals (this milestone)

- Multi-page issues, page dots, "add page 2".
- Recurrence / scheduling ("make it monthly") — persistence concern, out of engine.
- Export (PDF / print / email / images) — client/OS concern, out of engine.
- User-uploaded photos / brand store.
- Changes to `models.py` / `prompt_builder.py` / `image_generator.py` (the newsletter prompt builder
  is engine-side).

## Architecture

A new `engine/newsletter/` subpackage — a *parallel* path, not a rewrite — that reuses the spine and
the image pipeline.

| New (`engine/newsletter/`) | Reused as-is |
|---|---|
| `schema.py` — newsletter types | `engine.decide.DecisionProposal` (design defaults) |
| `extract.py` — parse the brain-dump | `engine.schema.DesignBrief` (editorial rationale) |
| `outline.py` — the "editor's eye" (structure + draft copy) | `image_generator.FlyerImageGenerator` (the renderer) |
| `rubric.py` — what a good newsletter needs | `engine.app._to_jsonable` / SSE serialization |
| `decide.py` — format/columns/palette/style/quality/model | the gate philosophy (`review` before generate) |
| `prompt.py` — compile project → page prompt | `engine.orchestrator._resolved_image` (base64↔temp for refine) |
| `tools.py` — render one Letter page | `engine.tools.Concept` (the image result type) |
| `orchestrator.py` — `NewsletterEngine` | |

`/chat` gains a `kind: "flyer" | "newsletter"` switch (default `flyer`) routing to the right engine.
Same endpoint, same SSE shape.

## Conversational flow & events

Maps 1:1 onto the flyer turns — same spine, newsletter rhythm:

| Flyer turn | Newsletter turn | Event |
|---|---|---|
| describe → extract fields | describe → parse the **brain-dump** into items | `parsed_items` |
| gap questions (critical field missing) | gap questions (only if masthead identity missing) | `questions` *(gate)* |
| `design_brief` (plans like a pro) | **outline** — propose ordered sections + draft copy + add the missing footer | (folded into review) |
| **`review`** (fields + decisions + plan) | **`review`** — sections (tagged *stated* / *suggested*) + design defaults + editorial plan | `review` *(gate)* |
| approve(field/decision overrides) → generate | approve(**section** + decision overrides) → render | `page` |
| refine (whole image) | **refine (section-scoped)** | `refined` |

The only genuinely new turn is the outline (multi-section structure instead of flat fields). The
`review` gate is the heart and keeps the **"no silent defaults"** contract: nothing renders until the
*structure* (sections, order, what was suggested) **and** every design default are approved.

## Schema (`engine/newsletter/schema.py`, pydantic)

```
NewsletterItem(topic, note?, source="stated")
NewsletterBrief                                   # extraction output
  org_name?, title?, issue_label?, audience?, purpose?, destination?
  items: [NewsletterItem]
  field_sources: {field -> stated|inferred}

Masthead(title, org_name?, issue_label?)
Section(key, heading, body="", kind="brief", origin="stated", order)
  kind   = lead | brief | events | footer         # drives layout emphasis
  origin = stated | suggested                      # from your notes vs engine-added
NewsletterOutline(masthead, sections[])            # proposed structure + drafted copy
NewsletterProject(masthead, sections[], format="letter", columns=2,
                  palette, visual_style, quality="hd", model="nano-banana-pro")  # renderer-agnostic
```

Reused from the flyer (DRY): `DecisionProposal`, `DesignBrief`, and the same loose-typing lessons —
`decisions: list` and `plan: Optional[Any]` with `arbitrary_types_allowed` so a mocked plan never
trips validation.

## The `review` payload — `NewsletterReviewProposal(sections, decisions, plan)`

The newsletter twin of `ReviewProposal`, with **sections** where the flyer had **fields**. Example
(church brain-dump):

```
sections:                                          ← structure, tagged + ordered
  1 lead    "Welcome Pastor Dale"          stated
  2 brief   "Summer Camp — sign-ups open"  stated
  3 brief   "Garden volunteers needed"     stated
  4 events  "Parish Picnic · Jun 28"       stated
  5 footer  "Give & contact"               suggested   ← the footer you forgot

decisions:                                         ← every default, with a reason
  format   Letter         [letter · a4]        print + pin friendly
  columns  2              [1 · 2]               two columns scan well on Letter
  palette  Warm & hopeful [3 dirs]             from the newsletter rubric
  style    Clean editorial[10]                 readable, uncluttered default
  quality  HD             [low·med·high·hd]    print-ready
  model    nano-banana-pro[2]                  highest-fidelity

plan (DesignBrief): notes, checklist[...], recommendations[...]   ← editorial rationale
```

Builders mirror the flyer: `build_section_proposals(outline)` ↔ `build_field_proposals`,
`propose_newsletter_decisions(rubric)` ↔ `propose_decisions`,
`to_newsletter_project(brief, outline, decisions)` ↔ `to_flyer_project`. At `approve`,
`section_overrides` (reorder / drop / edit headings) and `decision_overrides` (e.g. `columns: 1`,
`format: a4`) apply before render — mirroring `apply_proposed`.

## Generation (reuse the image pipeline)

`engine/newsletter/prompt.py` compiles `NewsletterProject` → one rich prompt (masthead, ordered
sections with headings + drafted body, layout hints "2-column US Letter, lead spanning the top,
footer with contact at the bottom", palette/style), returning a package like the flyer's
`{main_prompt, negative_prompt, model, aspect_ratio, quality}`.

```
generate_newsletter(project, generator, n=1)   # engine/newsletter/tools.py
  → FlyerImageGenerator.generate(prompt=…, model="nano-banana-pro",
        aspect_ratio="letter", quality="hd", n=1, save_images=False)
  → Concept(version_id="page", image_base64)        # event: page
```

Same generator, same `Concept`, base64 only (no disk). `n=1` — a newsletter is one document, not three
directions to pick among.

**Text-density caveat.** Image generation is far better at a headline + a few fields than at
paragraphs across sections. Mitigations: keep section bodies short/structured; instruct the model for
legible text. The renderer-agnostic schema is the real insurance — a structured renderer can replace
the render step later without changing extract/outline/gate/draft.

## Section-scoped refine

`refine_section(project, prior_image, section_key, instruction, generator)` reuses the flyer
edit-mode (`input_images=[prior_page]`, "modify only X, preserve everything else"); the scoping ("in
the *Summer Camp* section…") rides in the prompt. Best-effort under image-gen, surgical once a
structured renderer exists. Reuses `_resolved_image` for base64↔temp handling. Event: `refined`.

## `/chat` wiring

`ChatIn` gains `kind: "flyer" | "newsletter"` (default flyer) + `section_overrides`; `run_turn` routes
`newsletter` to `NewsletterEngine`. `_to_jsonable` / `_sse` already serialize pydantic + dataclasses,
so `review` and `page` stream as real JSON unchanged.

## Orchestrator — `NewsletterEngine`

- `handle_user_message(text)` → `extract_newsletter` → `parsed_items`; gaps → `questions` (gate) OR
  `build_outline` → `review` (gate).
- `handle_answers(answers)` → merge → re-gate → `review`.
- `handle_approval(section_overrides, decision_overrides, answers)` → apply overrides to outline +
  project → render → `page`. **Render only here.**
- `handle_refine(section_key, instruction, prior_image)` → `refined`.

## Testing (mirror the flyer suite; mock LLM + generator — never hit real APIs)

| Test file | Asserts |
|---|---|
| `test_newsletter_schema.py` | brief round-trips; `build_section_proposals` tags origin + order; `to_newsletter_project` → Letter/columns |
| `test_newsletter_decide.py` | `propose_newsletter_decisions` always surfaces format + columns + palette w/ options; overrides apply |
| `test_newsletter_outline.py` | `build_outline` (mock LLM) orders sections + adds the missing footer |
| `test_newsletter_orchestrator.py` | describe → `review` (sections+decisions+plan, no render); approve applies overrides then renders; render **gated** until approve; section refine edit-mode |
| `test_newsletter_app.py` | `kind=newsletter` routes correctly; `review` serializes sections+decisions; approve routes overrides |
| `test_newsletter_tools.py` | `generate_newsletter` compiles a prompt + calls generator with `aspect_ratio="letter"`, returns base64 |

## Success criteria (done when)

- `pytest tests/engine` green (flyer 46 + new newsletter tests).
- Engine emits `review` (sections + Letter/columns/palette/style/quality/model decisions + editorial
  plan — **never silent**); render only on `approve`; returns a base64 Letter page.
- Gate holds: no path from describe/answers straight to `page`.
- Export / recurrence stay out (client/later); **no changes** to `models.py` / `prompt_builder.py` /
  `image_generator.py`.
- *(Optional live smoke:* `kind=newsletter` describe → review → approve → one rendered Letter page.*)*

## Future (explicitly out of this milestone)

- Structured (HTML/template → image/PDF) renderer for crisp text + surgical section edits.
- User-supplied photos in section slots (reuse `input_images`).
- Multi-page issues; section-scoped *region* re-rendering.
- Recurrence ("make it monthly") + export (PDF/print/email/images) — client/persistence layer.
