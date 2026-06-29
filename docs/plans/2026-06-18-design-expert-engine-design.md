# FlyGen Design‑Expert Engine — Design Doc / PRD

- **Date:** 2026-06-18
- **Status:** Draft for review (engine-first scope). No implementation started.
- **Scope:** The conversation + reasoning layer only ("the engine"). The chat UI, subscription/paywall, and thread persistence are explicitly out of scope and will be specced separately.
- **Design reference:** `mockups/chat-v2/` (flyer flow, the "plans it like a pro" step, the seven expert behaviours). This doc turns those validated behaviours into a buildable backend component.

---

## 1. What this is

The **design‑expert engine** is the brain that turns a user's plain‑language request into a finished flyer by behaving like a senior designer rather than a form: it extracts what it can, asks **only what it genuinely can't infer**, runs a professional **design checklist out loud**, proposes what the user missed, then drives FlyGen's existing image pipeline. It is a platform‑agnostic backend component — the same engine sits under the iOS chat today and any other surface later.

It is the **biggest unknown** in the chat‑first pivot and the piece reusable regardless of which UI or pricing model ships, which is why it is being specced first.

---

## 2. Goals / Non‑goals

**Goals**

- Replace the 9‑step wizard's *data collection* with a conversation that produces a valid `FlyerProject`.
- Embody the "trained eye" from the mockups: extraction → adaptive questioning (0→N) → design‑brief/checklist reasoning → proactive recommendations → format & colour guidance.
- **Reuse, not replace, the deterministic prompt compiler and image pipeline.** The engine produces *design intent* (a `FlyerProject` + rationale); `FlyerPromptBuilder` still compiles the image prompt, and `FlyerImageGenerator` still calls Gemini.
- Expose a **streamed, tool‑aware conversational interface** the UI can render (typing, "planning…", three concepts, refine).
- Take **flyers end‑to‑end**; design the rubric/tooling so newsletters and menus can be added later as new content types (not built here).

**Non‑goals (separate specs / deferred)**

- The iOS chat UI.
- Subscription, paywall, free‑tier limits, credit→subscription migration.
- Thread persistence / identity (on‑device + CloudKit vs. a real backend) — treated as an *interface* the engine plugs into, not designed here.
- Newsletter & menu rubrics and multi‑section flows.
- Any change to the image model — Gemini‑3‑Pro‑image stays.

---

## 3. Where it sits — current reality (grounded in the code)

| Component | Today | File / symbol |
|---|---|---|
| Backend shape | **Python CLI, stateless, no HTTP API, no DB, no auth/credit checks** | `main.py` |
| Generation entry | `generate(prompt, negative_prompt, model, aspect_ratio, quality, n, save_images, input_images) -> List[GenerationResult]` | `image_generator.py` → `FlyerImageGenerator` |
| Prompt compiler | `FlyerPromptBuilder(project).build() -> {main_prompt, negative_prompt, aspect_ratio, model, quality}` | `prompt_builder.py` |
| Image model | `nano-banana-pro` = `google/gemini-3-pro-image-preview` via **OpenRouter** (OpenAI SDK `chat.completions` + `image_config`). Supports **image‑in** (logo, refine‑edit). No Cloudflare layer in code. | `image_generator.py` |
| Refine | "Edit mode": prior image as `input_images` + `EDIT MODE: …` instruction → same `generate()` | `main.py`, `RefinementPromptBuilder` |
| Resize | `reformat_image()` regenerates from scratch with new `aspect_ratio` + source image | `main.py` |
| Data model | `FlyerProject` (+ `TextContent`, `ColorSettings`, `VisualSettings`, `OutputSettings`, `QRCodeSettings`) and the enums below; `CATEGORY_TEXT_FIELDS` maps each of 15 categories → its relevant text fields | `models.py` |
| 5‑language + RTL + spelling rules | Encoded deterministically in `FlyerPromptBuilder` (Spanish/Urdu/Arabic/Chinese, RTL handling, character‑level spelling emphasis, flat‑design directive) | `prompt_builder.py` |

**Engine data flow (proposed):**

```
User NL ──▶ ENGINE (Claude Opus 4.8, tool-use agent)
              │  • extract → FlyerProject fields
              │  • gap analysis → ask 0..N questions
              │  • design rubric → brief + notes + recommendations  ← "plans like a pro"
              │  • map decisions → enums (style/mood/colour/format)
              ▼
         generate_flyer(project)  ──▶ FlyerPromptBuilder.build()
                                   ──▶ FlyerImageGenerator.generate(n=3)
                                   ──▶ OpenRouter ──▶ Gemini-3-Pro-image
              ◀── image(s) ────────────┘
         narrate · refine (talk/tap) · resize · export
```

**Key architectural stance:** *Claude reasons and converses; Gemini generates images, exposed to Claude as a tool.* The hard‑won spelling/RTL/flat‑design logic in `FlyerPromptBuilder` is kept as the deterministic compiler — the engine's job is to produce a **correct `FlyerProject` plus the design rationale**, not to author raw image prompts. (The engine may still author free‑text `special_instructions` / `imagery_description` fields the compiler already supports.)

---

## 4. The design‑expert behaviour model (the heart)

Four capabilities, each mapped to a moment the mockups already show:

| # | Capability | What it does | Mockup moment |
|---|---|---|---|
| a | **Extraction** | NL → `FlyerProject` fields: infer `FlyerCategory`, fill `TextContent` (headline, date, venue, CTA…). Structured output, validated. | "It parses, then…" (step 2) |
| b | **Adaptive questioning** | Compare extracted fields against `CATEGORY_TEXT_FIELDS[category]` ∩ the rubric's *design‑critical* must‑haves. Ask **only the design‑relevant unknowns** — 0 for a complete brief, a few for a vague one. Never a fixed script. | "Asks only what it can't infer" (2 questions) |
| c | **Design reasoning ("the checklist")** | Run the per‑category **rubric** to produce: (i) internal **design notes** (reasoning), (ii) a user‑facing **design brief** ("what a great X needs", applied to this brief), (iii) **proactive recommendations** (things the user didn't ask for but should have). Gates generation. | "It plans like a pro — out loud" (step 3) |
| d | **Decision mapping** | Choose enums (`VisualStyle`, `Mood`, `ColorSchemePreset` / specific hexes, `AspectRatio`, `BackgroundType`, `TextProminence`, `ImageryType`) **with rationale**, surfaced as a few **named directions** (tappable chips/swatches in the UI). | "Suggests a size + colour directions" (step 4) |

Then it orchestrates **generate → refine (talk or tap) → resize**, and can surface **past work + samples** on request.

**Worked example — "Flyer for our church bake sale Saturday 10–2 at Grace Hall, proceeds to youth camp":**

1. *Extract* → `category = NONPROFIT_CHARITY` (or `EVENT`), `headline="Bake Sale"`, `date="Sat Jun 14 · 10–2"`, `venue_name="Grace Hall"`, purpose="youth summer camp".
2. *Gap analysis* → category needs a destination/format decision and a clear `cta_text`; rubric flags "fundraisers need an easy give path." → **two** questions: *where's it headed (Instagram/print)?* and *add a donation QR?*
3. *Design reasoning* → notes ("fundraisers convert on emotion + ease; lead with the cause, not the cupcakes; a QR removes the cash‑only barrier") + brief checklist (cause up top · date/time/place scannable · one warm photo · one‑tap donate QR · high contrast) + recommendation ("add a 'one day only' urgency line").
4. *Decision mapping* → `aspect_ratio=PORTRAIT_4_5` (Instagram + prints), `style/mood` = warm/homemade direction, `qr_settings.enabled=true`.
5. *Generate* → `generate_flyer(project, n=3)` → 3 concepts.

---

## 5. Architecture

**The engine is a Claude tool‑use agent** built on the Messages API.

- **Model:** `claude-opus-4-8` — the "senior designer" persona and the reasoning quality *are* the product. Adaptive thinking (`thinking: {type: "adaptive"}`); `effort` tuned per turn (`high` for the planning/brief turn, `medium`/`low` for trivial acknowledgements). Official **`anthropic` Python SDK** (matches the backend language). *Cost lever:* Sonnet 4.6 can be A/B‑tested for high‑volume turns if quality holds, but Opus is the default given the persona.
- **Two‑model split:** Claude reasons/converses; **Gemini‑3‑Pro‑image generates**, exposed to Claude as a tool. (The team already runs OpenRouter; keep Gemini on that path and add the Anthropic SDK for the reasoning engine.)
- **Loop:** a **manual agentic loop** (not the auto tool‑runner) so we can implement the human‑in‑the‑loop gate (approve the plan before generating) and surface tool lifecycle events to the UI.
- **Structured outputs** (`output_config.format` / `messages.parse()`) where the UI needs to render structured payloads: the parsed `FlyerProject`, the question set (chips), the design brief (checklist), the colour/format directions (swatches).
- **Prompt caching:** the system prompt is large and stable — persona + enum catalogs + **per‑category rubrics** + the `CATEGORY_TEXT_FIELDS` map. Mark it `cache_control: ephemeral` so every design conversation reuses the cached prefix (~0.1× read cost).
- **Streaming (SSE):** emit token deltas (assistant text), optional summarized thinking, and **tool lifecycle events** (`planning…`, `generating 3 concepts…`, concept thumbnails ready) so the UI can render the mockup states.

**Tool surface (the engine's tools):**

| Tool | Wraps | Returns |
|---|---|---|
| `generate_flyer(project)` | `FlyerPromptBuilder.build()` → `FlyerImageGenerator.generate(n=3)` | 3 concept images (base64) + `version_id`s |
| `refine_flyer(version_id, instruction, mode=edit\|new)` | existing edit‑mode (prior image + `EDIT MODE`) / regenerate path | new image + `version_id` |
| `resize_flyer(version_id, aspect_ratio)` | `reformat_image()` | resized image |
| `get_past_work(query)` / `get_samples(category)` | library/sample store **(interface — depends on storage, flagged)** | image refs |

Design reasoning (extraction, questioning, the checklist) lives in the **model + system prompt**, not in tools — tools are only the side‑effecting image operations, per the "promote to a tool only what needs gating/rendering" principle.

---

## 6. The design knowledge (rubrics)

The "PhD in design" is **curated, reviewable design knowledge**, not vibes. Define a per‑`FlyerCategory` **rubric** data structure capturing:

- must‑have content beats (e.g. fundraiser → cause, give‑path),
- hierarchy priority (what should be loudest),
- default format + the reason,
- common proactive recommendations,
- candidate palette/mood directions.

Authored as **structured data** loaded into the cached system prompt (so it's tunable and testable, not hard‑coded prose). v1 authors rubrics for the **highest‑traffic categories** with a sane generic fallback; the rest inherit the fallback until authored.

---

## 7. Conversation state & interface

- The engine is **logically stateless per request**: input = (conversation history, accumulated `FlyerProject`, version list); output = (assistant events, updated state). **Thread persistence is the surrounding layer's job** (out of scope; open question: on‑device + CloudKit like today, or a real backend).
- **Proposed surface** — a thin **FastAPI** service (this also resolves the "no HTTP API" gap the codebase has today):
  - `POST /chat` (SSE) — body `{thread_state, user_message | chip_action}`; streams assistant + tool events.
  - Internally runs the agentic loop and calls the generation tools **in‑process** (the pipeline is Python — no second HTTP hop needed; just refactor `generate()`/`reformat_image()` to return base64 without writing to disk).

---

## 8. Cost (illustrative — must be validated)

- System (persona + rubrics + enums) ≈ 4–6k tokens, **cached** after the first turn (≈0.1× reads).
- A full flyer conversation (≈5–15 turns) → rough order **$0.15–0.35** for the reasoning layer, **plus image‑generation cost** (Gemini, unchanged and the dominant variable cost).
- This is the number to model against the **subscription unit economics** (the "is a heavy user profitable?" open question from the mockups). Levers: `effort` per turn, Sonnet 4.6 for cheap turns, caps on concepts/refines.

---

## 9. Risks / open questions

1. **Extraction fidelity** — does one sentence reliably become correct fields? *The #1 product risk.* Mitigation: structured outputs + confirmation chips + the design‑brief gate (the user sees parsed fields before anything is generated).
2. **Rubric authoring & evaluation** — who curates the design knowledge and how is it scored.
3. **Unit economics of "unlimited"** conversations under subscription (cross‑ref the mockups' open question).
4. **Thread persistence & identity** — interface, deferred.
5. **Image‑model alignment** — Gemini must honour the engine's intent; keep `FlyerPromptBuilder`'s spelling/RTL/flat‑design encoding rather than re‑authoring prompts in Claude.
6. **Latency** — planning turn + 3‑concept generation; the streamed "planning…/generating…" UX (already assumed by the mockups) is required, not optional.
7. **Past‑work / samples retrieval** depends on a library store (flagged).
8. **Newsletter / menu** need different rubrics and multi‑section tooling — designed‑for, not built here.

---

## 10. Acceptance criteria (engine scope)

Given a corpus of representative briefs of varying completeness, the engine:

- extracts correct `FlyerProject` fields at/above a target accuracy;
- asks the **right number** of questions (0 for complete briefs, a few for vague ones) — never a fixed count;
- emits, on the planning turn, a **structured design brief + ≥1 category‑appropriate proactive recommendation**;
- produces a `FlyerProject` that **compiles cleanly** through `FlyerPromptBuilder` and generates a flyer reflecting the brief;
- supports **refine** (talk/tap) and **resize** through the existing pipeline.

**Cheapest validation (from the mockups):** wire a pure‑chat flyer thread to the existing pipeline, ship to TestFlight, and measure (a) "do people prefer talking to the wizard?", (b) extraction accuracy, (c) cost per conversation — *before* building the canvas, newsletter, or subscription layers.

---

## 11. Suggested build order (for the later implementation plan)

1. **Pipeline‑as‑tools** — in‑process `generate/refine/resize` wrappers returning base64 (no disk), behind a `POST /chat` SSE skeleton. Resolves the no‑API gap.
2. **Extraction → `FlyerProject` (structured output) → generate.** Prove the pipe end‑to‑end, no questions yet.
3. **Adaptive questioning** — gap analysis vs. `CATEGORY_TEXT_FIELDS` + rubric must‑haves.
4. **Design rubric + brief/notes/recommendation** (the "plans like a pro" turn) for the top 2–3 categories.
5. **Decision mapping** to enums + named colour/format directions.
6. **Refine / resize loop**; past‑work/samples stubs.
7. **Eval harness** over the representative‑brief corpus.

The chat‑UI spec and the subscription spec then consume this engine.

---

*Posters/flows referenced live in `mockups/chat-v2/`. All cost figures are illustrative placeholders for modelling, not commitments.*
