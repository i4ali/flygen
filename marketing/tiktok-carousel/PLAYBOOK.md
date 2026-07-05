# TikTok Carousel Playbook - "Concept A: 10/10 product, 3/10 flyer"

A repeatable recipe for indirect FlyGen promo on TikTok. First-person small-business storytime:
someone's **product is great but their flyer is amateur**, they spiral, then the app slips in almost
by accident on the "turn." The app is never pitched - it's named only in the bio.

Built once for **Rosa's Home Bakery** (see `examples/rosa-bakery/`). Repeat for any business type by
swapping the copy and regenerating the images.

---

## The 7-beat structure

Each slide is `1080 x 1920`. Captions use TikTok's native white-text-in-translucent-pill style and
sit inside the safe zone. Placeholders below: `{product}`, `{role}` (baker/nail tech/…),
`{business}`, `{event}` (the sale/drop), `{enemy}` (Canva), `{price}` ($80), `{outcome}` (sold out by
noon).

| # | Beat | On-screen copy (skeleton) | Visual |
|---|------|---------------------------|--------|
| 1 | **Hook** | `my {product}: 10/10 🧁` / `the flyer I posted to sell them 👉` | `scene_1` - a genuinely 10/10 product photo |
| 2 | **Sting** | `...yeah.` / `I posted this. to actual paying customers 💀` | `bad_flyer` - the tacky DIY flyer |
| 3 | **Struggle** | `I'm a {role}, not a graphic designer.` / `{enemy} has 4,000 templates and somehow I hated all of them.` | `scene_3` - defeated at a laptop |
| 4 | **Cost** | `spent my whole day off on THAT ☝️` / `a designer quoted me ${price}. for ONE flyer 😵` / `(I need a new one every week)` | `scene_4` - late-night / time+money |
| 5 | **Turn** | `then a girl in my small-biz group goes:` / `"just describe it. one sentence."` / `...describe it to WHAT 😭` | **app screenshot (constant, baked into template)** |
| 6 | **Reveal** | `so I described my {event}. one sentence.` / `it gave me THESE. in 20 seconds 😳` | `good_0/1/2` - 3 pro concepts (Minimal/Elegant/Playful) |
| 7 | **Payoff** | `posted it. {outcome}.` / `never opening {enemy} again 🫶` / `(what I used is in my bio - for my fellow Not-A-Designers)` | `scene_7` - the win (sold-out / happy client) |

**Voice rules (non-negotiable - this is what makes it read as organic, not an ad):**
- lowercase, dry, self-deprecating. Roast yourself, not the competitor.
- Never say "download," never name the app on-slide. Bio only.
- The slide-7 CTA stays *small in size, safe in position* - a whisper in the corner-ish, above the caption zone.
- Real phone photos beat generated stand-ins. Generated art is a great draft; swap for the owner's own shots when possible.

---

## Title + caption

**Title / caption first line** (the scroll-stopper). Pick one, keep it lowercase:
- `nobody warned me the hardest part of running a {business-type} would be... the flyer 😭`  ← default
- `POV: your product is a 10 but your flyer is a 3`
- `the real reason my {product} weren't selling... and it wasn't the {product} 👀`
- `I almost paid ${price} for a flyer I ended up making in 20 seconds`

**Caption body + close:** one self-deprecating line, then a soft `link in bio 🤝` (never the app name).
**Hashtags:** 1 broad (`#smallbusiness #smallbusinesscheck`), 2-3 niche (`#homebakery #bakersoftiktok`),
1-2 pain (`#canvastruggles`), `#foryou`. Post 2-3 hook variants as separate posts; let the algorithm pick.

---

## Design spec (already baked into `template.html`)

- Canvas `1080 x 1920`. **Safe zone:** keep text inside `x: 80-930`, `y: 250-1420`. Danger: top ~250px
  (UI), right ~150px (like/comment/share rail), bottom ~500px (caption, @handle, sound, swipe-dots).
- Type: hero ~74px / support ~56px / micro ~39px, heavy rounded (SF Pro Rounded system stack).
- Slide 1's hook is centered so it survives the profile-grid thumbnail crop.
- Toggle "Show safe zones" in the gallery to check any custom copy.

---

## Repeat for a new business - 3 steps

Run everything from the **repo root** (so `.env` + `image_generator` resolve). Requires the repo
`.venv` (has `openai` + Pillow) and Google Chrome.

**1. Generate the 8 images.** Edit the `CONFIG` block in `scripts/generate_assets.py` (slug, business
name, offer headline, detail lines, `good_subject`, `category_line`, and the 4 photographic `scene_*`
prompts - tailor these to the trade), then:
```
PYTHONPATH=. .venv/bin/python marketing/tiktok-carousel/scripts/generate_assets.py
```
Outputs `bad_flyer / good_0..2 / scene_1,3,4,7 .png` into the config's `out_dir`. Eyeball them; re-run
if any miss (deliberately-tacky bad flyer, clean pro good flyers, authentic candid scenes).

**2. Write the captions.** Copy `template.html` to `examples/<slug>/slides.html` and edit the 7 caption
blocks using the skeleton above (search the `.cap` spans per slide). Keep the app-screenshot slide as-is.

**3. Build + render to PNGs.**
```
.venv/bin/python marketing/tiktok-carousel/scripts/build_and_render.py \
  --html   marketing/tiktok-carousel/examples/<slug>/slides.html \
  --assets marketing/tiktok-carousel/examples/<slug>/assets \
  --out    marketing/tiktok-carousel/examples/<slug>/out
```
Produces `1_hook.png ... 7_payoff.png` at true 1080x1920 in `out/`, plus `out/built.html` (the
self-contained finished deck).

> **Preview** the finished images via **`out/built.html`** (open in a browser, or publish it as an
> Artifact for approval) - it has every image embedded. Note: `slides.html`/`template.html` still contain
> unresolved `__SCENE1__`/`__GOOD0__`/... tokens, so they only preview captions, layout, and safe zones
> (broken images) until you build. The engine does **not** need deploying - it's all local generation.

---

## Niche-swap cheat sheet (same 7 beats)

| Trade | `{role}` | Hook product line | Struggle | Payoff |
|-------|----------|-------------------|----------|--------|
| Home baker | baker | `my cupcakes: 10/10 🧁` | "not a graphic designer" | sold out by noon |
| Nail tech | nail tech | `my nail sets: 10/10 💅` | "booked out but my promo pics look like 2012" | fully booked that week |
| Cleaning service | cleaner | `my before/afters: 10/10 🧽` | "my flyer looked like a scam, nobody called" | phone hasn't stopped |
| Reseller / thrift | reseller | `my inventory: 10/10 👖` | "great drops, my announcements looked like nothing" | sold out the drop |

For the scenes, keep the **same character** across slides 3, 4, 7 and match the workplace (salon chair,
cleaning van, clothing rack). The bad flyer + 3 good flyers are driven automatically by the CONFIG copy.

---

## Files

```
template.html                     Concept-A 7-slide template (~24KB, editable). All 9 images are tokens:
                                  __SCREENSHOT__ __BADFLYER__ __GOOD0..2__ __SCENE1/3/4/7__. Baker copy is
                                  the working example - edit the .cap caption blocks per business.
app-screenshot.png                The constant slide-5 app screen. build_and_render embeds it automatically;
                                  refresh only when the app UI changes.
scripts/generate_assets.py        Edit CONFIG -> generates the 8 business images via FlyGen's Nano Banana Pro.
scripts/build_and_render.py       Embeds screenshot + assets into the html + renders 7 x 1080x1920 PNGs
                                  (headless Chrome) into out/, plus out/built.html (the finished deck).
examples/rosa-bakery/             Worked baker example: slides.html (captions) + assets/ (8 source images).
```

## Gotchas
- **App screenshot is constant** across every business (it's the FlyGen home screen) - it lives as
  `app-screenshot.png` and the build script embeds it. Never regenerate it per business; refresh that one
  file only when the app UI changes.
- **Character continuity:** generate scenes 3/4/7 describing the *same* person; the model won't remember
  across calls, so bake the description into each prompt.
- **Slide-2 caption** overlaps the flyer's title a little - fine, but nudge it lower if you want the full
  flyer visible.
- Chrome path override: set `CHROME_BIN` if not at the default macOS location.
