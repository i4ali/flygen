#!/usr/bin/env python3
"""
Test Script for Flyer Generation

Generates flyers for manual verification of spelling accuracy and text handling.

Usage:
    python test_flyer.py 1        # Run test case 1
    python test_flyer.py 2        # Run test case 2
    python test_flyer.py all      # Run all test cases
    python test_flyer.py --list   # List all test cases
"""
import argparse
import sys
from pathlib import Path

from models import (
    FlyerProject, FlyerCategory, TextContent, ColorSettings,
    VisualSettings, OutputSettings,
    VisualStyle, Mood, ColorSchemePreset, BackgroundType,
    TextProminence, AspectRatio
)
from prompt_builder import FlyerPromptBuilder
from image_generator import create_generator


# =============================================================================
# TEST CASES
# =============================================================================

TEST_CASES = {
    1: {
        "name": "Long Address",
        "description": "Tests address rendering - the original 'Uniates' problem",
        "project": FlyerProject(
            category=FlyerCategory.REAL_ESTATE,
            text_content=TextContent(
                headline="OPEN HOUSE",
                subheadline="Your Dream Home Awaits",
                address="17710 S Cypress Villas Dr, Spring, TX 77379, United States",
                date="Saturday, December 21st",
                time="10 AM - 4 PM",
                price="$450,000",
                cta_text="Schedule a Tour Today!"
            ),
            colors=ColorSettings(preset=ColorSchemePreset.EARTH_TONES),
            visuals=VisualSettings(
                style=VisualStyle.CORPORATE_PROFESSIONAL,
                mood=Mood.PROFESSIONAL
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },

    2: {
        "name": "Complex Contact Info",
        "description": "Tests phone, email, website spelling accuracy",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            text_content=TextContent(
                headline="COMMUNITY MEETUP",
                subheadline="Join Us for an Evening of Connection",
                venue_name="Cypress Community Center",
                date="January 15, 2025",
                time="6:30 PM - 9:00 PM",
                phone="(713) 555-0199",
                email="events@cypressvillas.com",
                website="www.cypressvillas.com/openhouse",
                cta_text="RSVP Now!"
            ),
            colors=ColorSettings(preset=ColorSchemePreset.COOL),
            visuals=VisualSettings(
                style=VisualStyle.MODERN_MINIMAL,
                mood=Mood.FRIENDLY
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },

    3: {
        "name": "Long Headline with Numbers",
        "description": "Tests headline spelling emphasis with numbers and dates",
        "project": FlyerProject(
            category=FlyerCategory.GRAND_OPENING,
            text_content=TextContent(
                headline="GRAND OPENING DECEMBER 21ST 2024",
                subheadline="Celebrate With Us - 50% Off Everything!",
                venue_name="MegaStore Plaza",
                address="4521 Commerce Blvd, Houston, TX",
                time="9 AM - 9 PM",
                discount_text="50% OFF ALL ITEMS",
                cta_text="Don't Miss Out!"
            ),
            colors=ColorSettings(preset=ColorSchemePreset.WARM),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.EXCITING
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },

    4: {
        "name": "All Fields Stress Test",
        "description": "All text fields populated - maximum text content",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="MEGA WEEKEND SALE",
                subheadline="The Biggest Sale of the Year",
                date="December 14-15, 2024",
                time="10:00 AM - 8:00 PM",
                venue_name="Fashion District Mall",
                address="8899 Retail Row, Suite 200, Dallas, TX 75201",
                price="Starting at $9.99",
                discount_text="UP TO 70% OFF",
                cta_text="Shop Now - Limited Time!",
                phone="1-800-555-SALE",
                email="deals@fashiondistrict.com",
                website="www.fashiondistrict.com/mega-sale",
                fine_print="While supplies last. Some exclusions apply."
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.NEON,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.NEON_GLOW,
                mood=Mood.URGENT,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },

    5: {
        "name": "Very Long Subheadline",
        "description": "Tests text wrapping with 100+ character subheadline",
        "project": FlyerProject(
            category=FlyerCategory.CLASS_WORKSHOP,
            text_content=TextContent(
                headline="PHOTOGRAPHY MASTERCLASS",
                subheadline="Learn professional photography techniques from award-winning photographers in this comprehensive hands-on workshop series",
                date="Every Saturday in January",
                time="2:00 PM - 5:00 PM",
                venue_name="Creative Arts Studio",
                price="$299 for full series",
                cta_text="Register Now - Limited Spots!"
            ),
            colors=ColorSettings(preset=ColorSchemePreset.MONOCHROME),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.INSPIRATIONAL
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },

    6: {
        "name": "Special Characters",
        "description": "Tests ampersands, apostrophes, dashes, and other special chars",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            text_content=TextContent(
                headline="SMITH & JONES' BBQ",
                subheadline="Award-Winning Texas-Style Barbecue",
                venue_name="O'Malley's Kitchen & Bar",
                address="123 Main St - Downtown District",
                phone="(555) 123-4567",
                price="$15-$35 per plate",
                cta_text="Book Your Table - It's Worth It!",
                website="www.smith-jones-bbq.com"
            ),
            colors=ColorSettings(preset=ColorSchemePreset.WARM),
            visuals=VisualSettings(
                style=VisualStyle.RETRO_VINTAGE,
                mood=Mood.FRIENDLY
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5)
        )
    },
}


# =============================================================================
# RUNNER
# =============================================================================

def list_tests():
    """Print all available test cases."""
    print("\n📋 Available Test Cases:\n")
    for num, test in TEST_CASES.items():
        print(f"  {num}. {test['name']}")
        print(f"     {test['description']}\n")


def run_test(test_num: int, use_openrouter: bool = True):
    """Run a single test case."""
    if test_num not in TEST_CASES:
        print(f"❌ Test case {test_num} not found. Use --list to see available tests.")
        return False

    test = TEST_CASES[test_num]
    project = test["project"]

    print(f"\n{'='*60}")
    print(f"🧪 TEST {test_num}: {test['name']}")
    print(f"   {test['description']}")
    print(f"{'='*60}")

    # Build prompt
    builder = FlyerPromptBuilder(project)
    package = builder.build()

    print(f"\n📋 GENERATED PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    print("-" * 50)

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
        if result.success:
            # Move/rename to test_output with descriptive name
            if result.image_path:
                src = Path(result.image_path)
                dest = output_dir / f"test_{test_num}_{test['name'].lower().replace(' ', '_')}{src.suffix}"
                src.rename(dest)
                print(f"\n✅ Image saved to: {dest}")
            return True
        else:
            print(f"\n❌ Generation failed: {result.error_message}")
            return False

    return False


def main():
    parser = argparse.ArgumentParser(
        description="Test flyer generation for spelling and text handling",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python test_flyer.py 1        # Run test case 1
    python test_flyer.py 3        # Run test case 3
    python test_flyer.py all      # Run all test cases
    python test_flyer.py --list   # List all test cases
        """
    )
    parser.add_argument("test", nargs="?", help="Test case number or 'all'")
    parser.add_argument("--list", action="store_true", help="List all test cases")
    parser.add_argument("--openai", action="store_true",
                        help="Use OpenAI directly instead of OpenRouter")

    args = parser.parse_args()

    if args.list:
        list_tests()
        return

    if not args.test:
        parser.print_help()
        return

    use_openrouter = not args.openai

    if args.test.lower() == "all":
        print("\n🚀 Running ALL test cases...\n")
        results = {}
        for num in TEST_CASES:
            success = run_test(num, use_openrouter=use_openrouter)
            results[num] = success

        print("\n" + "=" * 60)
        print("📊 RESULTS SUMMARY")
        print("=" * 60)
        for num, success in results.items():
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"  Test {num}: {status} - {TEST_CASES[num]['name']}")
        print()
    else:
        try:
            test_num = int(args.test)
            run_test(test_num, use_openrouter=use_openrouter)
        except ValueError:
            print(f"❌ Invalid test number: {args.test}")
            print("   Use a number (1-6) or 'all'")


if __name__ == "__main__":
    main()
