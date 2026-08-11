#!/usr/bin/env python3
"""
Integration Tests for Aspect Ratio Verification

Generates images with different aspect ratios and verifies
the output image dimensions match the requested format.

Usage:
    python test_aspect_ratios.py 1:1        # Test square format
    python test_aspect_ratios.py 9:16       # Test story format
    python test_aspect_ratios.py all        # Test all formats
    python test_aspect_ratios.py --list     # List supported formats
"""
import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: pillow package required. Run: pip install pillow")
    exit(1)

from models import (
    FlyerProject, FlyerCategory, TextContent, ColorSettings,
    VisualSettings, OutputSettings, AspectRatio
)
from prompt_builder import FlyerPromptBuilder
from image_generator import create_generator


# =============================================================================
# EXPECTED RATIOS
# =============================================================================

# Expected aspect ratios (width/height) with tolerance.
# 4:5 is generated natively; letter/a4 are deterministically padded to the true paper
# ratio after generation, so all six must land within a tight tolerance - loose
# tolerances here previously made the letter/a4/4:5 collapse to 3:4 unfalsifiable.
EXPECTED_RATIOS = {
    "1:1": (1.0, 0.02),          # Square
    "4:5": (0.8, 0.02),          # Portrait - native on nano-banana-pro
    "9:16": (0.5625, 0.02),      # Story/Vertical
    "16:9": (1.777, 0.02),       # Landscape/Banner
    "letter": (8.5 / 11, 0.01),  # US Letter - exact via post-generation padding
    "a4": (210 / 297, 0.01),     # A4 - exact via post-generation padding
}

# Map string to AspectRatio enum
RATIO_MAP = {
    "1:1": AspectRatio.SQUARE_1_1,
    "4:5": AspectRatio.PORTRAIT_4_5,
    "9:16": AspectRatio.STORY_9_16,
    "16:9": AspectRatio.LANDSCAPE_16_9,
    "letter": AspectRatio.LETTER,
    "a4": AspectRatio.A4,
}


# =============================================================================
# TEST HELPERS
# =============================================================================

def create_test_project(aspect_ratio: AspectRatio) -> FlyerProject:
    """Create minimal project for format testing"""
    return FlyerProject(
        category=FlyerCategory.EVENT,
        text_content=TextContent(
            headline="FORMAT TEST",
            subheadline=f"Testing {aspect_ratio.value} aspect ratio"
        ),
        colors=ColorSettings(),
        visuals=VisualSettings(),
        output=OutputSettings(aspect_ratio=aspect_ratio)
    )


def verify_dimensions(image_path: str, expected_ratio: str) -> tuple:
    """
    Check if image dimensions match expected aspect ratio.

    Returns:
        (passed: bool, message: str, actual_ratio: float)
    """
    img = Image.open(image_path)
    width, height = img.size
    actual_ratio = width / height

    expected, tolerance = EXPECTED_RATIOS[expected_ratio]
    passed = abs(actual_ratio - expected) <= tolerance

    msg = f"{width}x{height} (ratio={actual_ratio:.3f}, expected~{expected:.3f}, tol={tolerance})"
    return passed, msg, actual_ratio


# =============================================================================
# TEST RUNNER
# =============================================================================

def list_formats():
    """Print all supported aspect ratios"""
    print("\n📐 Supported Aspect Ratios:\n")
    for ratio, (expected, tolerance) in EXPECTED_RATIOS.items():
        enum_val = RATIO_MAP[ratio]
        print(f"  {ratio:8s} - {enum_val.display_name}")
        print(f"           Expected ratio: {expected:.3f} (±{tolerance})\n")


def run_test(aspect_ratio: str, use_openrouter: bool = True) -> bool:
    """
    Test a single aspect ratio.

    Returns:
        True if test passed, False otherwise
    """
    if aspect_ratio not in RATIO_MAP:
        print(f"❌ Unknown aspect ratio: {aspect_ratio}")
        print(f"   Valid options: {', '.join(RATIO_MAP.keys())}")
        return False

    ar_enum = RATIO_MAP[aspect_ratio]

    print(f"\n{'='*60}")
    print(f"🧪 TESTING: {aspect_ratio} ({ar_enum.display_name})")
    print(f"{'='*60}")

    # Create test project
    project = create_test_project(ar_enum)

    # Build prompt
    builder = FlyerPromptBuilder(project)
    package = builder.build()

    print(f"\n📐 Requested aspect ratio: {aspect_ratio}")
    print(f"🤖 Model: {package['model']}")

    # Create output directory
    output_dir = Path("test_output")
    output_dir.mkdir(exist_ok=True)

    # Generate image
    print(f"\n⏳ Generating image (using {'OpenRouter' if use_openrouter else 'OpenAI'})...")

    generator = create_generator(mock=False, use_openrouter=use_openrouter)

    results = generator.generate(
        prompt=package["main_prompt"],
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"]
    )

    for result in results:
        if result.success and result.image_path:
            # Move to test_output with descriptive name
            src = Path(result.image_path)
            dest = output_dir / f"aspect_test_{aspect_ratio.replace(':', 'x')}{src.suffix}"
            src.rename(dest)

            # Verify dimensions
            passed, msg, actual = verify_dimensions(str(dest), aspect_ratio)

            if passed:
                print(f"\n✅ PASS: {msg}")
                print(f"   Image saved to: {dest}")
                return True
            else:
                print(f"\n❌ FAIL: {msg}")
                print(f"   Image saved to: {dest}")
                return False
        else:
            print(f"\n❌ Generation failed: {result.error_message}")
            return False

    return False


def main():
    parser = argparse.ArgumentParser(
        description="Test aspect ratio generation and verification",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python test_aspect_ratios.py 1:1        # Test square format
    python test_aspect_ratios.py 9:16       # Test story format
    python test_aspect_ratios.py 16:9       # Test landscape format
    python test_aspect_ratios.py all        # Test all formats
    python test_aspect_ratios.py --list     # List supported formats
        """
    )
    parser.add_argument("ratio", nargs="?", help="Aspect ratio to test (e.g., '1:1', '9:16') or 'all'")
    parser.add_argument("--list", action="store_true", help="List all supported aspect ratios")
    parser.add_argument("--openai", action="store_true",
                        help="Use OpenAI directly instead of OpenRouter")

    args = parser.parse_args()

    if args.list:
        list_formats()
        return

    if not args.ratio:
        parser.print_help()
        return

    use_openrouter = not args.openai

    if args.ratio.lower() == "all":
        print("\n🚀 Running ALL aspect ratio tests...\n")
        results = {}

        for ratio in RATIO_MAP.keys():
            success = run_test(ratio, use_openrouter=use_openrouter)
            results[ratio] = success

        # Summary
        print("\n" + "=" * 60)
        print("📊 RESULTS SUMMARY")
        print("=" * 60)

        passed = sum(1 for v in results.values() if v)
        total = len(results)

        for ratio, success in results.items():
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"  {ratio:8s}: {status}")

        print(f"\n  Total: {passed}/{total} passed")
        print()
    else:
        run_test(args.ratio, use_openrouter=use_openrouter)


if __name__ == "__main__":
    main()
