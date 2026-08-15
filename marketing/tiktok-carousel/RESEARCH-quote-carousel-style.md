# Research: does the "aesthetic quote carousel" style fit FlyGen's niche?

*(August 2026. Prompted by a Thaqalayn promo carousel — dark, serene quote cards with a "keep
swiping" hook and a soft-sell final slide showing the app's lock-screen widget.)*

## TL;DR

- The **soft-sell, value-first, app-is-incidental principle** behind that carousel is exactly right,
  and carousels are currently the highest-engagement organic format on TikTok (~81% more engagement
  than video in a ~700k-post analysis; swipeable formats see ~2.5x higher interaction than
  auto-play).
- But the **aesthetic quote-card format itself is niche-bound**. It works for faith / motivational /
  self-improvement audiences because the quotes ARE the app's content — the carousel delivers the
  product's value directly, and people save/share it for its own sake.
- FlyGen's audience (small-business owners, side-hustlers, #smallbusinesstok) engages with different
  intrinsic value: **relatable storytime, before/after transformation, behind-the-scenes**. Relatable
  "ordinary person" storytelling also converts measurably better (~30% lift; 66% of people prefer
  brand stories about ordinary people).
- **Recommendation:** keep Concept A (the storytime carousel in `PLAYBOOK.md`) as the primary format
  — it is the niche-correct translation of the Thaqalayn idea. Add the adapted showcase variant
  below ("Concept C") as a secondary test that borrows the quote-carousel *structure* legitimately.

## Why the Thaqalayn carousel works (and why it won't transfer 1:1)

1. **Content–product identity.** Each slide is literally what the app delivers daily. Viewers get
   the full value before ever learning an app exists. A flyer app has no equivalent "quote" — a
   slide of design tips or motivational lines about entrepreneurship would be generic filler,
   competing in the most oversaturated carousel category (motivational quotes).
2. **Save/share economics.** Spiritual quote cards get saved and reshared as wallpapers and stories;
   the carousel doubles as a product sample. Small-business owners save *how-tos, transformations,
   and tools*, not aesthetic cards about flyers.
3. **Emotional register.** The serene, reverent tone matches its niche. #smallbusinesstok's viral
   register is the opposite: lowercase, self-deprecating, chaotic-relatable ("I posted this to
   actual paying customers 💀").

## What the niche research says

- Carousels/slideshows are the format to be in: highest engagement of any organic post type in
  2025–2026 analyses; "keep swiping" curiosity hooks ("slide 3 changed everything") are a proven
  driver; 5–15 slides is the completion-rate sweet spot; AI-generated image carousels are
  themselves a top-performing 2026 format.
- For small-business audiences specifically, the consistently top formats are: **storytime**
  (personal stakes, a mistake → breakthrough arc), **before/after transformation** (works wherever
  visible change is the point — exactly a bad flyer → pro flyer), and **behind-the-scenes**.
- Educational/list carousels work in business niches too, but convert as "tips" content — weaker
  fit for an indirect promo where the app must feel discovered, not taught.

Concept A already combines all three winners (storytime arc + flyer before/after + BTS of running a
small business) in carousel form. The research validates it as the preferred format for this niche.

## Concept C (proposed): "the gallery" — Thaqalayn structure, FlyGen content

A secondary, lower-effort format to A/B against Concept A. It ports the quote-carousel structure by
substituting the one thing FlyGen has that is genuinely beautiful and save-worthy: **the flyers
themselves**, each paired with the one throwaway sentence that created it (the "quote").

- **Slide 1 (hook, Thaqalayn-style typographic card):** `4 flyers` / *made by people who can't
  design, from one sentence each* / `KEEP SWIPING`.
- **Slides 2–5:** one gorgeous flyer per slide, full-bleed. Above it, quote-card style, the exact
  sentence the owner typed — e.g. *"chocolate cake sale this saturday, warm and homemade"* — with a
  small attribution line (`ROSA'S HOME BAKERY — typed in 8 seconds`). The sentence-vs-result gap is
  the payoff of every swipe (same mechanism as Concept B's language swipes).
- **Slide 6 (soft sell, mirrors the lock-screen slide):** the constant app screenshot with one
  quiet line — *"they all used the same thing. it's in my bio."* No app name on-slide, no
  "download," per the Concept A voice rules.
- Production: reuses `good_*`-style generation from `scripts/generate_assets.py` (4 businesses × 1
  flyer) + the constant `app-screenshot.png`; captions via a `template.html` copy. No new tooling
  required, though a serif/elegant caption variant of the template would match the register better
  than the white-pill style.

Test order: post Concept A variants first (validated format), then Concept C as a stylistic
counter-test; let the algorithm decide.

## Sources

- https://instacarousel.com/blog/tiktok-carousel-photo-mode-2026/ (carousel vs video engagement)
- https://www.krumzi.com/blog/how-to-make-tiktok-carousel-posts-a-complete-guide-2026 (formats: how-to, before/after, comparison)
- https://alici.ai/blog/tiktok-carousel-2026-make-money (swipeable interaction rates, AI carousels)
- https://affinco.com/tiktok-slideshow/ (slideshow engagement benchmarks, curiosity hooks)
- https://fourthwall.com/blog/15-viral-tiktok-video-ideas-to-help-boost-your-business (storytime/BTS/before-after for small biz)
- https://tikadsuite.com/blog/tiktok-content-types/ (high-performing content types 2026)
- https://marketingltb.com/blog/statistics/storytelling-statistics/ (storytelling conversion lift, ordinary-people preference)
- https://www.postwaffle.com/blog/tiktok-carousel-ideas (educational-niche carousel fit)
