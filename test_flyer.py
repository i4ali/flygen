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
    VisualSettings, OutputSettings, QRCodeSettings,
    VisualStyle, Mood, ColorSchemePreset, BackgroundType,
    TextProminence, AspectRatio
)
from prompt_builder import FlyerPromptBuilder
from image_generator import create_generator
import qr_service


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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://example.com/property/17710-cypress-villas"
            )
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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://cypressvillas.com/rsvp"
            )
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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://megastoreplaza.com/grand-opening"
            )
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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            logo_path="logos/fashiondistrictmalllogo.png",
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.fashiondistrict.com/mega-sale"
            )
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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://creativeartstudio.com/photography"
            )
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
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            logo_path="logos/restaurantlogo.png",
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.smith-jones-bbq.com/menu"
            )
        )
    },

    # =========================================================================
    # SHOWCASE FLYERS - For Marketing FlyGen
    # =========================================================================

    7: {
        "name": "Winter Coding Camp",
        "description": "Showcase: Colorful kids coding camp flyer with multiple sessions",
        "project": FlyerProject(
            category=FlyerCategory.CLASS_WORKSHOP,
            text_content=TextContent(
                headline="WINTER CODING CAMP",
                subheadline="Learn to Code This Holiday Season!",
                date="December 26-30, 2024",
                time="9:00 AM - 3:00 PM",
                venue_name="TechKids Academy",
                address="2847 Innovation Drive, Austin, TX 78701",
                price="$299 per week",
                discount_text="EARLY BIRD: 20% OFF",
                cta_text="Register Now - Limited Spots!",
                website="www.techkidsaustin.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.techkidsaustin.com/register"
            )
        )
    },

    8: {
        "name": "Restaurant Grand Opening",
        "description": "Showcase: Elegant restaurant launch with upscale styling",
        "project": FlyerProject(
            category=FlyerCategory.GRAND_OPENING,
            text_content=TextContent(
                headline="GRAND OPENING",
                subheadline="Experience Modern Italian Cuisine",
                date="Friday, January 10th, 2025",
                time="5:00 PM - 11:00 PM",
                venue_name="Bella Vista Ristorante",
                address="445 Main Street, Downtown Seattle",
                discount_text="COMPLIMENTARY CHAMPAGNE",
                cta_text="Reserve Your Table",
                phone="(206) 555-8832",
                website="www.bellavistarestaurant.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.BLACK_GOLD,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.ELEGANT,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            logo_path="logos/restaurantlogo.png",
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.bellavistarestaurant.com/reserve"
            )
        )
    },

    9: {
        "name": "New Year Fitness Challenge",
        "description": "Showcase: Bold fitness promo with urgent/exciting energy",
        "project": FlyerProject(
            category=FlyerCategory.FITNESS_WELLNESS,
            text_content=TextContent(
                headline="30-DAY FITNESS CHALLENGE",
                subheadline="Transform Your Body in the New Year",
                date="Starting January 6th, 2025",
                time="Classes Daily: 6 AM, 12 PM, 6 PM",
                venue_name="Peak Performance Gym",
                address="1200 Fitness Blvd, Denver, CO 80202",
                price="$149 for 30 days",
                discount_text="FIRST 50 SIGN-UPS: 40% OFF",
                cta_text="Join the Challenge Today!",
                phone="(303) 555-7890",
                website="www.peakperformancegym.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.NEON,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.URGENT,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.peakperformancegym.com/challenge"
            )
        )
    },

    10: {
        "name": "Holiday Market Multi-Day",
        "description": "Showcase: Busy multi-date event using body_text for schedule",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            text_content=TextContent(
                headline="DOWNTOWN HOLIDAY MARKET",
                subheadline="Three Weekends of Holiday Magic!",
                body_text="DEC 14-15: Artisan Crafts & Live Music\nDEC 21-22: Santa Meet & Greet & Cookie Decorating\nDEC 28-29: New Year Countdown & Fireworks Show",
                time="Saturdays 10AM-9PM | Sundays 11AM-6PM",
                venue_name="Riverside Plaza",
                address="500 Commerce Street, Portland, OR 97204",
                price="FREE Admission | VIP $25",
                cta_text="Get Your VIP Pass!",
                website="www.portlandholidaymarket.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.portlandholidaymarket.com/vip"
            )
        )
    },

    11: {
        "name": "Text-Heavy Tech Conference",
        "description": "Showcase: Maximum text content to demonstrate text rendering capabilities",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            text_content=TextContent(
                headline="TECHSUMMIT 2025",
                subheadline="The Premier Technology Conference for Developers & Entrepreneurs",
                body_text="KEYNOTE SPEAKERS: Sarah Chen (Google AI) • Marcus Williams (Tesla) • Dr. Elena Rodriguez (MIT)\nWORKSHOPS: Machine Learning Fundamentals • Cloud Architecture • Mobile Development • Cybersecurity Best Practices\nNETWORKING: 500+ Industry Professionals • Startup Showcase • Career Fair",
                date="March 15-17, 2025",
                time="Registration 8:00 AM | Sessions 9:00 AM - 6:00 PM | Networking 6:00 PM - 9:00 PM",
                venue_name="Austin Convention Center",
                address="500 E Cesar Chavez Street, Austin, TX 78701",
                price="Early Bird $299 | Standard $449 | VIP $899",
                discount_text="STUDENTS: 50% OFF WITH VALID ID",
                cta_text="Register Now at TechSummit2025.com",
                phone="(512) 555-TECH",
                email="info@techsummit2025.com",
                website="www.techsummit2025.com",
                fine_print="Includes lunch, conference materials, and access to all sessions. Hotel accommodations not included."
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.MODERN_MINIMAL,
                mood=Mood.PROFESSIONAL,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    12: {
        "name": "Ultra Text-Dense Music Festival",
        "description": "Showcase: Extreme text density to stress-test text rendering limits",
        "project": FlyerProject(
            category=FlyerCategory.MUSIC_CONCERT,
            text_content=TextContent(
                headline="SOUNDWAVE MUSIC FESTIVAL 2025",
                subheadline="3 Days • 5 Stages • 50+ Artists • The Ultimate Music Experience",
                body_text="FRIDAY JUNE 13: The Midnight Echo • Neon Dreamers • Crystal Waves • DJ Phoenix Rising • The Velvet Underground Revival\nSATURDAY JUNE 14: Stellar Collision • The Black Keys Tribute • Aurora Borealis • Electric Symphony Orchestra • MC Thunder & The Storm Chasers\nSUNDAY JUNE 15: Cosmic Wanderers • The Jazz Fusion Collective • Acoustic Sunset Sessions • Grand Finale Fireworks Show featuring Symphony Orchestra",
                date="June 13-15, 2025",
                time="Gates 11AM | Music 12PM-12AM | Camping Available",
                venue_name="Riverside Amphitheater & Festival Grounds",
                address="12500 Festival Drive, Austin, TX 78701",
                price="Single Day $89 | Weekend Pass $199 | VIP Weekend $449 | Platinum All-Access $899",
                discount_text="EARLY BIRD ENDS MAY 1ST - SAVE 30%",
                cta_text="Get Tickets Now at SoundwaveFest.com - Don't Miss Out!",
                phone="1-888-SOUNDWV",
                email="tickets@soundwavefest.com",
                website="www.soundwavefest.com",
                fine_print="Rain or shine event. No refunds. Must be 18+ for general admission, 21+ for VIP areas. Bag policy enforced. Professional cameras prohibited. Food and beverages available on-site. Free parking with weekend pass."
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.NEON,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.NEON_GLOW,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.soundwavefest.com/tickets"
            )
        )
    },

    13: {
        "name": "Community Business Fair",
        "description": "Showcase: Maximum text density - multi-vendor community event with schedules, categories, and sponsors",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            text_content=TextContent(
                headline="SPRING VALLEY COMMUNITY BUSINESS FAIR 2025",
                subheadline="Shop Local • Support Local • 75+ Vendors • Live Entertainment • Free Parking",
                body_text="FOOD & DINING: Maria's Mexican Kitchen • Golden Dragon Chinese • Joe's BBQ Pit • Sweet Treats Bakery • Sunrise Coffee Roasters\nHOME SERVICES: AAA Plumbing & HVAC • Bright Future Solar • CleanPro Carpet Cleaning • GreenThumb Landscaping • SecureHome Alarms\nHEALTH & WELLNESS: Valley Family Dental • Peak Fitness Studio • Serenity Day Spa • Dr. Chen's Acupuncture • PetCare Veterinary Clinic\nPROFESSIONAL SERVICES: First National Bank • State Farm Insurance • Liberty Tax Prep • Anderson & Associates Law Firm • TechFix Computer Repair\nLIVE ENTERTAINMENT: 10AM DJ Mike's Morning Mix • 12PM Spring Valley High School Band • 2PM The Acoustic Duo • 4PM Mariachi Los Amigos • 6PM Headliner: The Blue Notes",
                date="Saturday & Sunday, April 12-13, 2025",
                time="Saturday 9AM-8PM | Sunday 10AM-6PM | Food Court Opens 11AM Daily",
                venue_name="Spring Valley Town Center & Civic Plaza",
                address="1250 Main Street, Spring Valley, TX 77386 (Corner of Main & Oak Avenue)",
                price="General Admission FREE | VIP Lounge $35 | Vendor Booth $150-$500",
                discount_text="EARLY BIRD VENDOR REGISTRATION: 25% OFF UNTIL MARCH 1ST",
                cta_text="Register Your Business Today at SpringValleyFair.com!",
                phone="(281) 555-FAIR | Vendor Hotline: (281) 555-0199",
                email="info@springvalleyfair.com | vendors@springvalleyfair.com",
                website="www.springvalleyfair.com",
                fine_print="Presented by Spring Valley Chamber of Commerce. Platinum Sponsors: First National Bank, Valley Medical Center, AutoNation Honda. Gold Sponsors: HEB, Kroger, Chick-fil-A. Rain date: April 19-20. Service animals only. ATM on-site. Children's activities in Family Fun Zone. Food vendors cash & card accepted."
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.springvalleyfair.com/register"
            )
        )
    },

    14: {
        "name": "Educational Newsletter",
        "description": "Showcase: School newsletter with health column, educational content, and Islamic perspective",
        "project": FlyerProject(
            category=FlyerCategory.ANNOUNCEMENT,
            text_content=TextContent(
                headline="Health Corner",
                subheadline="Northwest Saturday School Newsletter",
                body_text="""Why Screen Time Matters
By Dr. Pareesa Nathani, Pediatrician

Screens can be helpful for learning, but too much can affect:
• Sleep
• Mood and tantrums
• Behavior and attention
• Language skills and connection
• Social skills and real-life play

The goal isn't no screen time — it's healthy screen habits.

Recommended Daily Screen Time:
Ages 0-2: Avoid screens except for video calls with family
Ages 2-5: About 1 hour per day of high-quality content
Ages 6+: Set clear, consistent limits as a family

Islamic Perspective:
Islam teaches us to protect the heart and mind from harmful influences.
"A child is raised upon what he is exposed to." - Al-Kāfī""",
                website="www.nwsaturdayschool.org"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.WATERCOLOR_ARTISTIC,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
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


def run_test(
    test_num: int,
    use_openrouter: bool = True,
    logo_override: str = None,
    qr_override: str = None,
    disable_logo: bool = False,
    disable_qr: bool = False
):
    """Run a single test case."""
    if test_num not in TEST_CASES:
        print(f"❌ Test case {test_num} not found. Use --list to see available tests.")
        return False

    test = TEST_CASES[test_num]
    project = test["project"]

    # Handle logo override
    logo_path = None
    if not disable_logo:
        logo_path = logo_override or project.logo_path

    # Handle QR override
    qr_url = None
    if not disable_qr:
        if qr_override:
            qr_url = qr_override
        elif project.qr_settings and project.qr_settings.enabled:
            qr_url = project.qr_settings.url

    print(f"\n{'='*60}")
    print(f"🧪 TEST {test_num}: {test['name']}")
    print(f"   {test['description']}")
    if logo_path:
        print(f"   🖼️  Logo: {logo_path}")
    if qr_url:
        print(f"   📱 QR Code: {qr_url}")
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

    # Prepare input images (for logo)
    input_images = None
    if logo_path:
        if Path(logo_path).exists():
            input_images = [logo_path]
            print(f"   📎 Logo will be sent to AI for integration")
        else:
            print(f"   ⚠️  Logo file not found: {logo_path}")

    results = generator.generate(
        prompt=package["main_prompt"],
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"],
        input_images=input_images
    )

    for result in results:
        if result.success:
            # Move/rename to test_output with descriptive name
            if result.image_path:
                src = Path(result.image_path)
                dest = output_dir / f"test_{test_num}_{test['name'].lower().replace(' ', '_')}{src.suffix}"
                src.rename(dest)

                # Apply QR code if configured
                if qr_url:
                    print(f"   📱 Adding QR code...")
                    qr_service.composite_qr_onto_flyer(dest, qr_url)
                    print(f"   ✅ QR code added to flyer")

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
    python test_flyer.py 1                      # Run test case 1
    python test_flyer.py 3                      # Run test case 3
    python test_flyer.py all                    # Run all test cases
    python test_flyer.py --list                 # List all test cases
    python test_flyer.py 1 --logo logo.png      # Run with custom logo
    python test_flyer.py 1 --qr https://...     # Run with custom QR URL
    python test_flyer.py 1 --no-qr              # Run without QR code
        """
    )
    parser.add_argument("test", nargs="?", help="Test case number or 'all'")
    parser.add_argument("--list", action="store_true", help="List all test cases")
    parser.add_argument("--openai", action="store_true",
                        help="Use OpenAI directly instead of OpenRouter")
    parser.add_argument("--logo", type=str, metavar="PATH",
                        help="Path to logo image (overrides test case default)")
    parser.add_argument("--qr", type=str, metavar="URL",
                        help="QR code URL (overrides test case default)")
    parser.add_argument("--no-logo", action="store_true",
                        help="Disable logo even if test case has one")
    parser.add_argument("--no-qr", action="store_true",
                        help="Disable QR code even if test case has one")

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
            success = run_test(
                num,
                use_openrouter=use_openrouter,
                logo_override=args.logo,
                qr_override=args.qr,
                disable_logo=args.no_logo,
                disable_qr=args.no_qr
            )
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
            run_test(
                test_num,
                use_openrouter=use_openrouter,
                logo_override=args.logo,
                qr_override=args.qr,
                disable_logo=args.no_logo,
                disable_qr=args.no_qr
            )
        except ValueError:
            print(f"❌ Invalid test number: {args.test}")
            print("   Use a number (1-13) or 'all'")


if __name__ == "__main__":
    main()
