---
name: tiktok-carousel
description: "Use when the user wants to create, generate, or produce a TikTok or Instagram promo carousel for FlyGen - especially an indirect, problem-first storytime that makes the app look incidental - or wants to repeat the carousel formula for a new business type (baker, nail tech, cleaner, reseller, etc.)."
---

# FlyGen TikTok Promo Carousel

## Overview

Produces a 7-slide, 1080x1920 TikTok carousel that promotes FlyGen **indirectly**: a first-person
small-business storytime where the owner's product is great but their flyer is amateur, they spiral,
and the app slips in on the "turn" (never pitched, named only in the bio). Called "Concept A".

The full recipe, copy skeleton, prompt templates, design/safe-zone spec, and niche-swap table live in
**`marketing/tiktok-carousel/PLAYBOOK.md`** - read it before building. This skill is the entry point;
the playbook is the source of truth.

## When to use

- "Make a TikTok/Reels carousel to promote the app", "another one for a nail salon / cleaner / reseller".
- Any indirect, relatable, problem-first promo where the app should feel incidental.

Not for: direct feature ads, app-store screenshots (use `aso-appstore-screenshots`), or in-app flyers.

## Workflow

**First, read `marketing/tiktok-carousel/PLAYBOOK.md` in full** - it has the 7-beat copy skeleton and the
prompt templates you'll adapt. Then gather **and confirm with the user** the business specifics (trade,
product, offer + detail lines, the win) - image generation costs API calls, so don't guess - and run
these 3 steps **from the repo root**:

1. **Generate the 8 images.** Edit the `CONFIG` block in
   `marketing/tiktok-carousel/scripts/generate_assets.py` (slug, out_dir, business, offer, details,
   `good_subject`, `category_line`, and the 4 photographic `scene_*` prompts - keep the same character
   across scenes 3/4/7), then:
   ```
   PYTHONPATH=. .venv/bin/python marketing/tiktok-carousel/scripts/generate_assets.py
   ```
   View the outputs; regenerate any that miss (tacky bad flyer, clean pro good flyers, candid scenes).
   This makes 8 business images; with the 1 constant app screenshot they fill 7 rendered slides.

2. **Write the captions.** Copy `template.html` to `examples/<slug>/slides.html` and edit the 7 `.cap`
   caption blocks per the playbook's skeleton (the template is small and normally editable - the app
   screenshot is a token, not baked in). Leave the app-screenshot slide (5) as-is.

3. **Build + render.**
   ```
   .venv/bin/python marketing/tiktok-carousel/scripts/build_and_render.py \
     --html marketing/tiktok-carousel/examples/<slug>/slides.html \
     --assets marketing/tiktok-carousel/examples/<slug>/assets \
     --out marketing/tiktok-carousel/examples/<slug>/out
   ```
   Produces `1_hook.png ... 7_payoff.png` at true 1080x1920, ready to upload in order. It also writes
   `out/built.html` - the self-contained finished deck.

To let the user preview/approve, publish **`out/built.html`** as an Artifact (that has every image
embedded; `slides.html` still has unresolved tokens and shows broken images). Copy the final PNGs to
`~/Downloads/` so they can grab them. Also give a title + caption + hashtags using the playbook's formulas.

## Key facts

- Images come from **FlyGen's own Nano Banana Pro pipeline** (`image_generator.py`, key in `.env`) - the
  same model the app ships. No engine deploy is needed; it's all local generation.
- The **app screenshot (slide 5) is constant** across every business - it lives as
  `marketing/tiktok-carousel/app-screenshot.png` and the build script embeds it automatically. Never
  regenerate it; refresh that one file only if the app UI changes.
- Voice is lowercase, self-deprecating; never say "download" or name the app on-slide.
- Requires the repo `.venv` (has `openai` + Pillow) and Google Chrome (headless export; set `CHROME_BIN`
  to override its path).
- Worked reference: `marketing/tiktok-carousel/examples/rosa-bakery/`.
