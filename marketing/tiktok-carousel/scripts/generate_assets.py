#!/usr/bin/env python3
"""
Generate all 8 business-specific images for a "Concept A" TikTok carousel, using FlyGen's
own Nano Banana Pro pipeline (image_generator.py).

Per business: edit the CONFIG block below, then run:

    cd <repo root>            # so `import image_generator` and .env resolve
    PYTHONPATH=. .venv/bin/python marketing/tiktok-carousel/scripts/generate_assets.py

Outputs (into CONFIG['out_dir']):
    bad_flyer.png            slide 2  (deliberately tacky DIY flyer)
    good_0/1/2.png           slide 6  (Minimal / Elegant / Playful pro concepts)
    scene_1/3/4/7.png        slides 1/3/4/7 (photographic story beats)

The constant app screenshot (slide 5) is NOT generated - it lives baked into template.html.
"""
import os, pathlib, base64, sys

# ---------------------------------------------------------------------------
# CONFIG  - the only thing you edit per business
# ---------------------------------------------------------------------------
CONFIG = {
    "slug": "rosa-bakery",
    "out_dir": "marketing/tiktok-carousel/examples/rosa-bakery/assets",

    # --- used to build the flyer copy (slides 2 & 6) ---
    "offer_headline": "CUPCAKE SALE",          # the big line on the flyer
    "business_name":  "Rosa's Home Bakery",
    "details": [                                # 3-5 short lines, spelled exactly
        "This Saturday - 10 AM",
        "A dozen for $18",
        "Pre-order by Friday",
        "DM to reserve",
    ],
    # what the GOOD flyers should depict as their hero imagery
    "good_subject": "beautifully frosted gourmet cupcakes",
    "category_line": ("Professional sale-and-promotion flyer for a home bakery's weekend cupcake "
                      "sale, with appetizing, mouth-watering food appeal."),

    # --- the 4 photographic story beats (free-text; tailor to the trade) ---
    # Keep them photographic, candid, "authentic phone photo", and match the character across beats.
    "scene_1_hook": (
        "A gorgeous, mouth-watering close-up photograph of a fresh batch of beautifully frosted "
        "gourmet cupcakes arranged on a rustic wooden board, soft natural window light, shallow "
        "depth of field, vibrant pastel buttercream with berries and sprinkles. Authentic "
        "high-quality phone photo taken by a home baker for social media. Appetizing, warm."),
    "scene_3_struggle": (
        "A candid documentary-style photograph of a stressed young woman, a home baker and small "
        "business owner, at her kitchen table in front of a laptop, one hand on her forehead, "
        "frustrated and overwhelmed. Mixing bowls and a tray of plain cupcakes nearby. Warm cozy "
        "home lighting, relatable, real, not staged."),
    "scene_4_cost": (
        "A moody, authentic photograph of the same young woman late at night at her kitchen table, "
        "cool laptop-screen glow on her tired face, a coffee mug and a small analog clock nearby, "
        "dim warm ambient light. A feeling of long hours and stress. Realistic phone-photo style."),
    "scene_7_payoff": (
        "A bright, cheerful, authentic photograph of a cozy home-bakery counter in warm morning "
        "light: an almost-empty cupcake tray with just crumbs and one or two cupcakes left, next "
        "to a small handwritten card. Celebratory, warm, realistic phone-photo style."),
}

# ---------------------------------------------------------------------------
# Prompt assembly (templated - normally no need to touch)
# ---------------------------------------------------------------------------
def detail_list(cfg):
    return "; ".join(f"'{d}'" for d in cfg["details"])

BAD_FLYER = (
    "A deliberately amateurish, tacky homemade flyer, the kind an untrained person would slap "
    "together in old Microsoft Word or PowerPoint 2007. Vertical portrait flyer, full-bleed, "
    "screenshotted as a printed flyer pinned to a corkboard. UGLY clashing colors (harsh lime-green "
    "background with red, blue and purple text), several mismatched fonts including Comic Sans and a "
    "cheesy rainbow-gradient WordArt title, cheap pixelated clip-art and clip-art balloons with "
    "visible white edges, everything centered and cramped with uneven spacing, a stretched pixelated "
    "clip-art border, ugly drop shadows, lens-flare sparkles, overuse of exclamation marks. "
    "Legible text reading: '{business}', '{headline}!!!', {details}. "
    "It must look genuinely low-effort and unprofessional. NOT stylish, NOT ironic, just amateur."
)
BAD_FLYER_NEG = ("professional, elegant, modern, clean, minimalist, sleek, tasteful, cohesive, "
                 "harmonious colors, good typography, designer-made")

GOOD_TEXT = (
    " Include this text, spelled EXACTLY, with a clear visual hierarchy: large headline '{headline}'; "
    "brand name '{business}'; {details}. CRITICAL TEXT REQUIREMENTS: all text crisp, clear and "
    "perfectly legible, spelled exactly, professional print-ready quality, visually striking, "
    "balanced composition with clear visual hierarchy."
)
GOOD_NEG = ("amateur, clip art, WordArt, Comic Sans, clashing colors, cluttered, busy, low-resolution, "
            "pixelated, tacky, childish, misspelled text, garbled letters, watermark, corkboard")
GOOD_STYLES = [
    ("good_0", "Modern minimalist design with clean lines, generous white space, contemporary "
               "sans-serif typography, uncluttered composition, sophisticated simplicity. Soft neutral "
               "palette (warm cream, muted blush, charcoal text), one elegant hero photo of {subject}. "
               "Bright, airy, premium boutique brand feel."),
    ("good_1", "Elegant luxury design with a sophisticated muted palette, refined serif typography, "
               "premium high-end feel, subtle gold accents, tasteful restraint. Deep warm tones with "
               "delicate gold, a rich close-up hero of {subject}. Upscale boutique aesthetic."),
    ("good_2", "Playful but tasteful, professionally-designed modern flyer: cheerful pastel colors, "
               "rounded friendly shapes, clean bouncy typography, subtle tidy illustrations, joyful yet "
               "polished. Pastel palette with confident hierarchy, hero of {subject}. Cute, NOT amateur."),
]
NO_TEXT = "text, words, letters, captions, watermark, logo, brand name, typography, poster, sign"


def main():
    root = pathlib.Path(__file__).resolve().parents[3]  # repo root
    os.chdir(root)
    for line in pathlib.Path(".env").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1); os.environ.setdefault(k, v.strip())
    from image_generator import create_generator

    cfg = CONFIG
    out = pathlib.Path(cfg["out_dir"]); out.mkdir(parents=True, exist_ok=True)
    gen = create_generator(mock=False, use_openrouter=True)

    jobs = []  # (filename, prompt, negative, aspect)
    jobs.append(("bad_flyer", BAD_FLYER.format(business=cfg["business_name"],
                 headline=cfg["offer_headline"], details=detail_list(cfg)), BAD_FLYER_NEG, "9:16"))
    gtext = GOOD_TEXT.format(headline=cfg["offer_headline"], business=cfg["business_name"],
                             details=detail_list(cfg))
    for name, style in GOOD_STYLES:
        jobs.append((name, cfg["category_line"] + " Vertical portrait flyer. " +
                     style.format(subject=cfg["good_subject"]) + gtext, GOOD_NEG, "4:5"))
    jobs += [("scene_1", cfg["scene_1_hook"], NO_TEXT, "9:16"),
             ("scene_3", cfg["scene_3_struggle"], NO_TEXT + ", readable screen", "9:16"),
             ("scene_4", cfg["scene_4_cost"], NO_TEXT + ", readable clock numbers", "9:16"),
             ("scene_7", cfg["scene_7_payoff"], "watermark, logo, ugly, cluttered, dark", "9:16")]

    ok = 0
    for name, prompt, neg, ar in jobs:
        res = gen.generate(prompt=prompt, negative_prompt=neg, model="nano-banana-pro",
                           aspect_ratio=ar, n=1, save_images=False)
        r = res[0]
        if r.success and r.image_base64:
            (out / f"{name}.png").write_bytes(base64.b64decode(r.image_base64))
            print(f"OK  {name}.png"); ok += 1
        else:
            print(f"FAIL {name}: {r.error_message}")
    print(f"\n{ok}/{len(jobs)} generated into {out}")
    sys.exit(0 if ok == len(jobs) else 1)


if __name__ == "__main__":
    main()
