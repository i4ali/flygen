#!/usr/bin/env python3
"""
Build a finished TikTok carousel: embed a business's images into a Concept-A slide HTML and
render each slide to a true 1080x1920 PNG (via headless Google Chrome).

Usage:
    .venv/bin/python marketing/tiktok-carousel/scripts/build_and_render.py \
        --html   marketing/tiktok-carousel/examples/rosa-bakery/slides.html \
        --assets marketing/tiktok-carousel/examples/rosa-bakery/assets \
        --out    marketing/tiktok-carousel/examples/rosa-bakery/out

--html defaults to the shared template.html. Copy that to <business>/slides.html and edit the
7 caption blocks first (see PLAYBOOK.md) - the captions are the only per-business text.

The assets dir must contain (from generate_assets.py):
    bad_flyer.png  good_0.png good_1.png good_2.png  scene_1.png scene_3.png scene_4.png scene_7.png
Requires Pillow (repo .venv has it) and Google Chrome.
"""
import argparse, base64, io, os, pathlib, signal, subprocess, sys
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_TEMPLATE = HERE.parent / "template.html"
SCREENSHOT = HERE.parent / "app-screenshot.png"   # constant slide-5 app screen (same every business)
CHROME = os.environ.get("CHROME_BIN",
                        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

# token -> (asset filename, embed width px).  Full-bleed art = 1080; the small trio flyers = 820.
TOKENS = {
    "__BADFLYER__": ("bad_flyer.png", 1080),
    "__SCENE1__":   ("scene_1.png",   1080),
    "__SCENE3__":   ("scene_3.png",   1080),
    "__SCENE4__":   ("scene_4.png",   1080),
    "__SCENE7__":   ("scene_7.png",   1080),
    "__GOOD0__":    ("good_0.png",    820),
    "__GOOD1__":    ("good_1.png",    820),
    "__GOOD2__":    ("good_2.png",    820),
}
SLIDE_NAMES = ["1_hook", "2_sting", "3_struggle", "4_cost", "5_the-turn", "6_reveal", "7_payoff"]


def data_uri(path, width):
    im = Image.open(path).convert("RGB")
    if im.width != width:
        im = im.resize((width, round(im.height * width / im.width)))
    buf = io.BytesIO(); im.save(buf, format="JPEG", quality=88)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def build(html_path, assets, out):
    import re
    html = pathlib.Path(html_path).read_text()
    # constant app screenshot (slide 5) - identical for every business, lives beside the template
    if "__SCREENSHOT__" in html:
        if not SCREENSHOT.exists():
            sys.exit(f"ERROR: missing constant screenshot {SCREENSHOT}")
        html = html.replace("__SCREENSHOT__", data_uri(SCREENSHOT, 1080))
    # per-business images from the assets dir
    for token, (fname, w) in TOKENS.items():
        if token not in html:
            print(f"  note: {token} not in html (skipped)"); continue
        f = pathlib.Path(assets) / fname
        if not f.exists():
            sys.exit(f"ERROR: missing asset {f}")
        html = html.replace(token, data_uri(f, w))
    left = sorted(set(re.findall(r'__[A-Z0-9]+__', html)))
    if left:
        sys.exit(f"ERROR: unresolved tokens still present: {left}")
    built = pathlib.Path(out) / "built.html"
    built.write_text(html)
    print(f"  built -> {built} ({round(len(html)/1024/1024,2)} MB)")
    return built


def render(built, out):
    file_url = "file://" + str(pathlib.Path(built).resolve())
    made = []
    for i in range(1, 8):
        png = pathlib.Path(out) / f"slide_{i}.png"
        if png.exists(): png.unlink()
        cmd = [CHROME, "--headless=new", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
               "--no-first-run", "--no-default-browser-check",
               f"--user-data-dir={out}/.chrome-prof-{i}",
               "--force-device-scale-factor=1", "--window-size=1080,1920",
               f"--screenshot={png}", f"{file_url}#export={i}"]
        p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        try:
            p.wait(timeout=45)
        except subprocess.TimeoutExpired:
            try: os.killpg(os.getpgid(p.pid), signal.SIGKILL)
            except Exception: pass
        ok = png.exists() and png.stat().st_size > 0
        print(f"  slide {i}: {'OK' if ok else 'FAIL'}")
        if ok:
            final = pathlib.Path(out) / f"{i}_{SLIDE_NAMES[i-1].split('_',1)[1]}.png"
            png.replace(final); made.append(final)
    # tidy chrome profiles
    for d in pathlib.Path(out).glob(".chrome-prof-*"):
        subprocess.run(["rm", "-rf", str(d)])
    return made


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", default=str(DEFAULT_TEMPLATE))
    ap.add_argument("--assets", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    out = pathlib.Path(a.out).resolve(); out.mkdir(parents=True, exist_ok=True)
    if not pathlib.Path(CHROME).exists():
        sys.exit(f"ERROR: Chrome not found at {CHROME} (set CHROME_BIN).")
    print("Embedding assets...")
    built = build(a.html, a.assets, out)
    print("Rendering 1080x1920 PNGs...")
    made = render(built, out)
    print(f"\nDone: {len(made)}/7 slides -> {out}")
    for m in made: print("  ", m.name)


if __name__ == "__main__":
    main()
