# Experiment - Lean image prompt: strip the canned nudges from `prompt_builder.py`

- **Date:** 2026-07-01
- **Status:** Planned - deferred (not yet implemented). Capture-for-later; tackle down the road.
- **Motivation:** Part 2 of the "nudging audit" (2026-07-01). The audit found the *text brain* is
  already given good room, but the *image model* is heavily over-scripted for a renderer that has
  since been upgraded.

---

## Context

FlyGen drives two models, nudged oppositely:

- **Text brain** (`claude-sonnet-4-6` via OpenRouter) - the intake/design director. Given lots of
  room; light-touch direction. This is correct and stays.
- **Image model** (`nano-banana-pro` = Gemini 3 Pro Image) - the renderer, driven entirely by
  `prompt_builder.py`, which is near-total scripting.

`prompt_builder.py` was written for a weak renderer (`gpt-image-1`, still in the file's `__main__`
demo). We now ship `nano-banana-pro`, a much stronger renderer that likely does *better* with less
canned boilerplate. This experiment strips the three heaviest canned nudges and checks whether output
quality holds (text accuracy, palette fidelity) on a leaner prompt. It is fully revertable.

Two facts de-risk it (confirmed by codebase exploration):

- Nothing outside `prompt_builder.py` imports the descriptor dicts or the negative-prompt lists; only
  the classes `FlyerPromptBuilder` / `RefinementPromptBuilder` are imported (`engine/tools.py`,
  `main.py`, `demo.py`, tests). The module-level constants are effectively private.
- `negative_prompt` is **not** a structured API field. `image_generator.py:175-178` concatenates it as
  free-text `AVOID: {...}` onto the main prompt, so the "19+ negatives" were only ever soft text nudges;
  removing them just shortens or drops that block.

---

## File structure (revertable by design)

- **Backup (pristine):** copy the current `prompt_builder.py` -> **`prompt_builder_original.py`**. Untouched reference.
- **Experiment (active):** edit `prompt_builder.py` in place. Because `engine/tools.py` imports
  `from prompt_builder import FlyerPromptBuilder`, editing this file is what makes the experiment live,
  so we can actually generate concepts and judge them.
- **Revert:** `cp prompt_builder_original.py prompt_builder.py` (and revert the test file). Delete the
  backup once the experiment is validated or abandoned.

---

## The three removals (surgical - nothing else in the prompt changes)

### 1. Letter-by-letter spelling
- In `_build_text_section`: drop every `(SPELLING: {spelled})` annotation; keep the
  `... must read EXACTLY: "..."` anchor lines (that is the accuracy signal, not the spelling).
- Reword the header `... Spell ALL text EXACTLY as shown, letter by letter:` ->
  `... Render ALL text EXACTLY as shown, spelled correctly:`.
- Delete the now-unused `_spell_out` method. Keep `_chunk_text` (multi-line display hint) and
  `_contains_arabic` (used by `_has_arabic_content`).
- The separate `ARABIC/URDU SCRIPT: ...` block in `_build_main_prompt` **stays** - it is what actually
  protects Arabic rendering, and removing spelling only makes Arabic safer (no letter-splitting).

### 2. Canned negative prompts ("19 plus" = universal + per-category)
- In `_build_negative_prompt`: stop seeding from `UNIVERSAL_NEGATIVE_PROMPTS` and stop extending with
  `CATEGORY_NEGATIVE_PROMPTS`. **Keep** the user's own `visuals.avoid_elements` (user intent, not
  boilerplate). Result: `negative_prompt` is the user's avoidances or `""` (then no `AVOID:` block is
  appended - the `if negative_prompt:` guard in `image_generator` handles it).
- Delete the module-level `UNIVERSAL_NEGATIVE_PROMPTS` and `CATEGORY_NEGATIVE_PROMPTS` lists.
- `build()` still returns the same 5 keys (contract preserved).

### 3. Canned style / mood / color descriptor phrases
- **Style** (`_build_main_prompt`): replace `STYLE_DESCRIPTORS[...]` with the plain name via the
  transform already used elsewhere in this file - `visuals.style.display_name` (e.g. "Modern Minimal").
- **Mood**: same - `visuals.mood.display_name` (e.g. "Urgent").
- **Color** (`_build_color_section`): remove `COLOR_PALETTE_DESCRIPTORS` (preset phrase) and
  `BACKGROUND_DESCRIPTORS` (background-type phrase). **Keep** the free-text `description` (the brain's
  authoritative palette), explicit hex `primary/secondary/accent`, explicit `gradient_colors`, and
  explicit `background_color` (emitted without the canned type phrase). A bare `ColorSettings()` with no
  description now yields no color line - acceptable, since the real engine
  (`compile_project._colors_for`) always sets a `description`.
- Delete the module-level `STYLE_DESCRIPTORS`, `MOOD_DESCRIPTORS`, `COLOR_PALETTE_DESCRIPTORS`,
  `BACKGROUND_DESCRIPTORS` dicts.

---

## Explicitly untouched

Flat-design directive, aspect-ratio instruction, language/translation requirements, the
"CRITICAL TEXT REQUIREMENTS" accuracy block, logo + user-photo + imagery-description sections, category
hints, the Arabic/Urdu instruction block, and `RefinementPromptBuilder` (its `FEEDBACK_PATTERNS` is a
separate concern, out of scope).

---

## Test updates (`tests/engine/test_prompt_builder.py`)

Only this file asserts on built-prompt content. Two tests assert behavior we deliberately remove:

- `test_spell_out_skips_arabic` (calls `_spell_out`) -> **delete** (method is gone; the Arabic-split
  risk it guarded is moot once no text is spelled out).
- `test_color_section_without_description_keeps_legacy_defaults` (asserts the "warm color palette" canned
  phrase) -> **rework** into an inverse guard: with a bare `ColorSettings()`, assert the canned
  "warm color palette" / "bright and airy" phrases are now **absent**.

Still-passing, keep as-is: `test_color_section_uses_description_and_drops_warm_light`,
`test_arabic_instruction_present_when_content_has_arabic`, `test_no_arabic_instruction_for_plain_english`.

---

## Verification

1. `python -m pytest tests/engine/test_prompt_builder.py -q` -> green after the test edits.
2. `python -m pytest tests/engine -q` -> confirm nothing else regressed (no other test asserts on prompt text).
3. **A/B the built prompt (no API):** for one representative project, build via the new
   `prompt_builder.py` and via `prompt_builder_original.py` and diff `build()["main_prompt"]` +
   `["negative_prompt"]`. Confirm the only differences are: no `(SPELLING: ...)`, style/mood as plain
   names, a leaner color line, and an empty/short `AVOID:` block. (`python prompt_builder.py` runs the
   `__main__` demo for a quick one-shot print.)
4. **The real test (needs `OPENROUTER_API_KEY`):** generate concepts through the engine path
   (`engine/tools.generate_concepts`) for a couple of stress briefs - a Church/Majlis brief (palette +
   Arabic) and a text-heavy sale brief (spelling accuracy) - with the leaner prompt, and eyeball: text
   still spelled correctly, palette honored, layout intact. Compare against a generation from the backup
   to judge whether the removed nudges were load-bearing.

---

## Rollback

`cp prompt_builder_original.py prompt_builder.py` and `git checkout tests/engine/test_prompt_builder.py`.
Once the experiment is validated (or abandoned), delete `prompt_builder_original.py`.
