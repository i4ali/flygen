# Design — No Silent Defaults: the "Review Everything" gate

**Status:** Approved (brainstorm 2026-06-19). Implementation plan to follow.

## Principle

The design-expert engine must not silently apply any default or assumption. Every default the engine fills in (format, palette, style, quality, model, QR) and every value it infers must be surfaced for human approval — confirm or override — before it generates. See memory `no-silent-defaults`.

This reconciles with the engine's existing "ask only what it can't infer" principle as follows:
- **Missing critical fields** → still asked as questions (unchanged `gaps.py`) before planning.
- **Inferred values + design defaults** → never asked and never applied blind; surfaced together in **one** consolidated review.

## Decisions (settled in brainstorm)

1. **Approval model:** a single *consolidated review* — all assumptions shown at once, approve-all-or-override-any. Not per-question.
2. **Scope:** *everything* — the full interpretation: every extracted field **plus** every design choice **plus** the plan's recommendations.
3. **Placement:** *after planning, before generating* — `extract → [questions] → design brief → REVIEW → approve/override → generate`. The design brief is cheap reasoning; only image generation is gated.
4. **Field source detection:** *model self-report, folded into the existing extraction call* — each field reports `stated` vs `inferred`; no extra LLM round-trip.

## Flow

```
Before:  extract → [questions] → design_brief → awaiting_approval → (approve) → concepts
After:   extract → [questions] → design_brief → review → (approve + overrides) → concepts
```

The bare `awaiting_approval` event is replaced by a structured **`review`** event. The generation gate is preserved: concepts are produced only after `approve`.

## The ReviewProposal payload

The `review` event carries a structured proposal the client renders as the consolidated review:

1. **fields** — list of `FieldProposal { key, value, source }` for every populated content field (headline, subheadline, body, date, time, venue, address, price, discount, cta, phone, email, website, category). `source ∈ {stated, inferred}`. Inferred items are the "double-check me" highlights.
2. **decisions** — list of `DecisionProposal { key, label, value, options, reason }` for every design choice the engine would otherwise apply silently:
   - `format` (aspect ratio) — **always present** (the bug fix): inferred from the brief when clear ("for printing" → letter), else the 4:5 default. Options = the supported aspect ratios.
   - `palette` — recommended named direction from the rubric, with its alternatives (named swatches).
   - `visual_style`, `mood` — recommended + alternatives.
   - `quality`, `model` — recommended + alternatives.
   - `qr` — enabled? + url.
3. **plan** — the existing `DesignBrief` (notes + applied checklist + recommendations), advisory.

## Component changes

**`schema.py`**
- Extraction output carries per-field source, folded into the single extract call. Add a `field_sources: dict[str, str]` to the extracted result (`stated` | `inferred`), populated by the model. `to_flyer_project` ignores it. `EXTRACT_SYSTEM` gains a short instruction defining the stated/inferred distinction so the model self-reports reliably.
- New models: `FieldProposal`, `DecisionProposal`, `ReviewProposal`.

**`decide.py`**
- New `propose_decisions(brief, rubric) → list[DecisionProposal]` — returns each design axis as `{value, options, reason}` **without applying**. `format` is always included (inferred-or-default). `propose_palette_directions` feeds the palette options.
- `apply_decisions(project, overrides, rubric)` — unchanged role, now driven by the user's confirmed/overridden values at approval time.

**`orchestrator.py`**
- After `design_brief`, build the `ReviewProposal` (fields + sources + `propose_decisions` + plan) and `yield Event("review", proposal)` instead of bare `awaiting_approval`.
- `handle_approval(overrides)` — apply field overrides to the brief and decision overrides via `apply_decisions`, then generate. Overrides default to the proposed values when the user changes nothing.

**`app.py`**
- Serialize the `review` event over SSE.
- The `approve` action accepts `overrides` (fields + decisions); `run_turn` routes it to `handle_approval(overrides)`.

**No changes** to `models.py` / `prompt_builder.py` / `image_generator.py`.

## Testing

- `propose_decisions` returns recommended + alternatives for every design axis; `format` is always present (inferred vs default cases).
- Extraction self-report: `field_sources` parsed and surfaced; review tags fields `stated`/`inferred`.
- Orchestrator emits `review` (not bare `awaiting_approval`) carrying fields + decisions + plan; no `concepts` before `approve`.
- `handle_approval` applies overrides (e.g., format override `letter` → `project.output.aspect_ratio == LETTER`) before generating.
- App routes `approve` with `overrides`; `review` event streams over SSE.
- Mock the LLM client and the generator throughout (no real API in unit tests).

## Non-goals

- Persistence across HTTP requests (state still passed in/out per request).
- Changes to the image pipeline modules.
- Per-question approval or an inline-confirmation flow (explicitly rejected in favor of the single consolidated review).
