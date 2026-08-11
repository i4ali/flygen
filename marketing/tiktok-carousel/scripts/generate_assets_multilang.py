#!/usr/bin/env python3
"""
Generate the 6 business images for a "Concept B: one flyer, every language" TikTok carousel,
using FlyGen's own Nano Banana Pro pipeline (image_generator.py).

Concept B is feature-forward but still indirect: a family-run shop's sale flyer is shown in
English, then re-rendered - IDENTICAL layout - in each of the neighborhood's languages, one
swipe per language. The app appears only on the turn slide (constant screenshot).

Per business: edit the CONFIG block below, then run:

    cd <repo root>            # so `import image_generator` and .env resolve
    PYTHONPATH=. .venv/bin/python marketing/tiktok-carousel/scripts/generate_assets_multilang.py

Outputs (into CONFIG['out_dir']):
    scene_1.png              slide 1  (candid hook photo of the shop/owner)
    flyer_en.png             slide 2  (the pro sale flyer, English)
    flyer_<lang>.png         slides 3..N (reference-edits of flyer_en - same design, translated)
    scene_7.png              slide 7  (the payoff scene, same character as scene_1)

The constant app screenshot (turn slide) is NOT generated - build_and_render embeds it.

Key trick: each language flyer is generated with input_images=[flyer_en.png], so Nano Banana
reproduces the exact layout and only swaps the text. Give it the EXACT translated strings -
never ask the model to translate on its own.
"""
import os, pathlib, base64, sys

# ---------------------------------------------------------------------------
# CONFIG  - the only thing you edit per business
# ---------------------------------------------------------------------------
CONFIG = {
    "slug": "madina-grocery",
    "out_dir": "marketing/tiktok-carousel/examples/madina-grocery/assets",

    # --- flyer copy (slide 2, English base) ---
    "business_name":  "Madina Halal Market",
    "offer_headline": "BIG WEEKEND SALE",
    "details": [                               # 3-5 short lines, spelled exactly
        "This Saturday & Sunday",
        "20% off all spices & rice",
        "Fresh halal meat daily",
        "Free delivery over $50",
    ],
    "flyer_style": (
        "Professional grocery-market sale flyer, warm and appetizing: rich emerald green and "
        "cream palette with gold accents, clean modern layout, a beautiful hero arrangement of "
        "colorful whole spices in bowls, basmati rice and fresh produce, subtle geometric border "
        "motif. Confident type hierarchy, generous spacing, premium neighborhood-market feel. "
        "Keep ALL text and key content in the middle 70% of the frame (safe from top/bottom "
        "crops), balanced composition."
    ),

    # --- the translations (exact strings; order matches: business, headline, then details) ---
    "languages": [
        {
            "code": "ur", "name": "Urdu", "rtl": True,
            "lines": [
                "مدینہ حلال مارکیٹ",
                "بڑی ویک اینڈ سیل",
                "ہفتہ اور اتوار",
                "تمام مصالحوں اور چاول پر %20 رعایت",
                "روزانہ تازہ حلال گوشت",
                "50 ڈالر سے زیادہ پر مفت ڈیلیوری",
            ],
            "script_note": "Urdu in Nastaliq-style Perso-Arabic script, written right-to-left",
        },
        {
            "code": "bn", "name": "Bengali", "rtl": False,
            "lines": [
                "মদিনা হালাল মার্কেট",
                "বিশাল উইকেন্ড সেল",
                "শনিবার ও রবিবার",
                "সব মসলা ও চালে ২০% ছাড়",
                "প্রতিদিন তাজা হালাল মাংস",
                "৫০ ডলারের বেশি কেনাকাটায় ফ্রি ডেলিভারি",
            ],
            "script_note": "Bengali (Bangla) script, written left-to-right",
        },
        {
            "code": "ar", "name": "Arabic", "rtl": True,
            "lines": [
                "سوق المدينة الحلال",
                "تخفيضات نهاية الأسبوع الكبرى",
                "السبت والأحد",
                "خصم %20 على جميع البهارات والأرز",
                "لحم حلال طازج يومياً",
                "توصيل مجاني للطلبات فوق 50 دولاراً",
            ],
            "script_note": "Modern Standard Arabic script, written right-to-left",
        },
    ],

    # --- the 2 photographic story beats (same character in both) ---
    "character": (
        "a warm middle-aged South Asian shopkeeper in his 50s with a neatly trimmed "
        "grey-flecked beard, wearing a simple light-blue button-up shirt"
    ),
    "scene_1_hook": (
        "A candid, authentic phone photograph inside a small family-run halal grocery store: "
        "{character} smiling behind the counter, surrounded by shelves of colorful spice boxes, "
        "sacks of basmati rice and fresh produce. Warm inviting light, slightly imperfect "
        "framing, realistic small-business social-media photo, not staged or corporate."
    ),
    "scene_7_payoff": (
        "A candid, authentic phone photograph of the same small family-run halal grocery store "
        "on a busy Saturday: {character} at the counter serving a short line of happy customers "
        "of different ages and backgrounds, including two elderly South Asian women in colorful "
        "dupattas with full shopping baskets. Bustling, warm, celebratory neighborhood feel, "
        "realistic phone-photo style."
    ),
}

# ---------------------------------------------------------------------------
# Prompt assembly (templated - normally no need to touch)
# ---------------------------------------------------------------------------
FLYER_TEXT = (
    " Include this text, spelled EXACTLY, with a clear visual hierarchy: large headline "
    "'{headline}'; brand name '{business}'; {details}. CRITICAL TEXT REQUIREMENTS: all text "
    "crisp, clear and perfectly legible, spelled exactly, professional print-ready quality, "
    "visually striking, balanced composition with clear visual hierarchy."
)
FLYER_NEG = ("amateur, clip art, WordArt, Comic Sans, clashing colors, cluttered, busy, "
             "low-resolution, pixelated, tacky, childish, misspelled text, garbled letters, "
             "watermark, corkboard")

TRANSLATE_EDIT = (
    "Use the provided flyer image as the exact base. Reproduce the SAME flyer with an "
    "IDENTICAL layout: same background, same colors, same decorative elements, same photos of "
    "spices/rice/produce, same composition, same positions and relative sizes of every text "
    "block. Change ONLY the text: replace all wording with this {name} text, spelled EXACTLY "
    "({script_note}), mapped one-to-one onto the original text blocks in this order: "
    "{mapping}. POSITION RULES, do not deviate: the large gold headline (the topmost, biggest "
    "text) must read '{headline_tr}' - NOT the business name; the dark serif line directly "
    "below it must read '{business_tr}'. Every other line keeps its original slot. No English "
    "words or Latin letters may remain anywhere on the flyer. All {name} text must be crisp, "
    "correctly spelled, professionally typeset and perfectly legible."
)
TRANSLATE_NEG = ("English text, Latin letters, garbled letters, misspelled text, broken script, "
                 "disconnected letters, altered layout, different colors, different composition, "
                 "watermark, low-resolution")

NO_TEXT = "text, words, letters, captions, watermark, logo, brand name, typography, poster, sign"


def main():
    root = pathlib.Path(__file__).resolve().parents[3]  # repo root
    os.chdir(root)
    for line in pathlib.Path(".env").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1); os.environ.setdefault(k, v.strip())
    if not os.environ.get("OPENROUTER_API_KEY"):
        testing = os.environ.get("OPENROUTER_API_KEY_TESTING")
        if not testing:
            sys.exit("ERROR: no OPENROUTER_API_KEY or OPENROUTER_API_KEY_TESTING in .env")
        os.environ["OPENROUTER_API_KEY"] = testing
    from image_generator import create_generator

    cfg = CONFIG
    out = pathlib.Path(cfg["out_dir"]); out.mkdir(parents=True, exist_ok=True)
    gen = create_generator(mock=False, use_openrouter=True)

    only = set(sys.argv[1:])  # optionally regenerate a subset: e.g. flyer_ur scene_7

    def make(name, prompt, neg, ar, input_images=None):
        if only and name not in only:
            return True
        res = gen.generate(prompt=prompt, negative_prompt=neg, model="nano-banana-pro",
                           aspect_ratio=ar, n=1, save_images=False,
                           input_images=input_images)
        r = res[0]
        if r.success and r.image_base64:
            (out / f"{name}.png").write_bytes(base64.b64decode(r.image_base64))
            print(f"OK  {name}.png"); return True
        print(f"FAIL {name}: {r.error_message}"); return False

    ok = True
    ch = cfg["character"]
    ok &= make("scene_1", cfg["scene_1_hook"].format(character=ch), NO_TEXT, "9:16")

    details = "; ".join(f"'{d}'" for d in cfg["details"])
    en_prompt = (cfg["flyer_style"] + " Vertical portrait flyer, full-bleed." +
                 FLYER_TEXT.format(headline=cfg["offer_headline"],
                                   business=cfg["business_name"], details=details))
    ok &= make("flyer_en", en_prompt, FLYER_NEG, "9:16")

    base = out / "flyer_en.png"
    if not base.exists():
        sys.exit("ERROR: flyer_en.png missing - generate it before the language edits")
    en_lines = [cfg["business_name"], cfg["offer_headline"]] + cfg["details"]
    for lang in cfg["languages"]:
        mapping = "; ".join(f"'{en}' becomes '{tr}'" for en, tr in zip(en_lines, lang["lines"]))
        prompt = TRANSLATE_EDIT.format(name=lang["name"], script_note=lang["script_note"],
                                       mapping=mapping,
                                       business_tr=lang["lines"][0],
                                       headline_tr=lang["lines"][1])
        ok &= make(f"flyer_{lang['code']}", prompt, TRANSLATE_NEG, "9:16",
                   input_images=[str(base)])

    ok &= make("scene_7", cfg["scene_7_payoff"].format(character=ch),
               NO_TEXT + ", empty store, sad", "9:16")

    print(f"\ndone -> {out}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
