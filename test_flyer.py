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
    TextProminence, AspectRatio, FlyerLanguage
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
                body_text="Your Dream Home Awaits\nSaturday, December 21st | 10 AM - 4 PM\nSchedule a Tour Today!",
                address="17710 S Cypress Villas Dr, Spring, TX 77379, United States",
                price="$450,000",
                phone="(555) 123-4567",
                website="example.com/property/17710-cypress-villas"
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
                date="January 15, 2025 | 6:30 PM - 9:00 PM",
                address="1234 Community Drive, Cypress TX",
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
                date="December 21, 2024 | 9 AM - 9 PM",
                venue_name="MegaStore Plaza",
                address="4521 Commerce Blvd, Houston, TX",
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
        "description": "All text fields populated - maximum text content for SALE_PROMO category",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="MEGA WEEKEND SALE",
                subheadline="The Biggest Sale of the Year",
                date="December 14-15, 2024 | 10:00 AM - 8:00 PM",
                address="Fashion District Mall, 8899 Retail Row, Suite 200, Dallas, TX 75201",
                discount_text="UP TO 70% OFF",
                cta_text="Shop Now - Limited Time!",
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
                date="Every Saturday in January | 2:00 PM - 5:00 PM",
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
                date="December 26-30, 2024 | 9:00 AM - 3:00 PM",
                venue_name="TechKids Academy",
                price="$299 per week",
                cta_text="Register Now - Limited Spots!"
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
                date="Friday, January 10th, 2025 | 5:00 PM - 11:00 PM",
                venue_name="Bella Vista Ristorante",
                address="445 Main Street, Downtown Seattle",
                discount_text="COMPLIMENTARY CHAMPAGNE",
                cta_text="Reserve Your Table"
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
                phone="(303) 555-7890"
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
                date="DEC 14-15, 21-22, 28-29 | Sat 10AM-9PM, Sun 11AM-6PM",
                venue_name="Riverside Plaza",
                address="500 Commerce Street, Portland, OR 97204",
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
                date="March 15-17, 2025 | 9:00 AM - 6:00 PM",
                venue_name="Austin Convention Center",
                address="500 E Cesar Chavez Street, Austin, TX 78701",
                cta_text="Register Now at TechSummit2025.com",
                website="www.techsummit2025.com"
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
        "description": "Showcase: Text density stress-test for MUSIC_CONCERT category",
        "project": FlyerProject(
            category=FlyerCategory.MUSIC_CONCERT,
            text_content=TextContent(
                headline="SOUNDWAVE MUSIC FESTIVAL 2025",
                subheadline="3 Days • 5 Stages • 50+ Artists • The Ultimate Music Experience",
                date="June 13-15, 2025",
                time="Gates 11AM | Music 12PM-12AM | Camping Available",
                venue_name="Riverside Amphitheater & Festival Grounds",
                address="12500 Festival Drive, Austin, TX 78701",
                price="Single Day $89 | Weekend $199 | VIP $449",
                cta_text="Get Tickets Now - Don't Miss Out!",
                website="www.soundwavefest.com"
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
                subheadline="Shop Local • Support Local • 75+ Vendors • Live Entertainment",
                date="April 12-13, 2025 | Sat 9AM-8PM, Sun 10AM-6PM",
                venue_name="Spring Valley Town Center & Civic Plaza",
                address="1250 Main Street, Spring Valley, TX 77386",
                cta_text="Register Your Business Today at SpringValleyFair.com!",
                website="www.springvalleyfair.com"
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
"A child is raised upon what he is exposed to." - Al-Kāfī

Visit: www.nwsaturdayschool.org""",
                cta_text="Learn More"
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

    # =========================================================================
    # MULTI-LANGUAGE FLYERS - Testing Urdu and Chinese rendering
    # =========================================================================

    15: {
        "name": "Urdu Event Flyer - Urdu Input",
        "description": "Tests Urdu language rendering with native Urdu text input",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.URDU,
            text_content=TextContent(
                headline="کمیونٹی میلا",
                subheadline="آئیں اور خاندان کے ساتھ مزے کریں",
                date="15 جنوری 2025 | شام 5 بجے سے رات 9 بجے تک",
                venue_name="اسلامک سینٹر",
                address="123 Main Street, Houston TX",
                cta_text="ابھی رجسٹر کریں!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    16: {
        "name": "Chinese Restaurant Flyer - Chinese Input",
        "description": "Tests Chinese character rendering with native Chinese text input",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            language=FlyerLanguage.CHINESE,
            text_content=TextContent(
                headline="金龙餐厅",
                subheadline="正宗川菜 · 美味可口",
                address="北京路123号",
                phone="010-1234-5678",
                price="人均 ¥80-120",
                cta_text="欢迎光临!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    17: {
        "name": "Urdu Sale Flyer - Urdu Input",
        "description": "Tests Urdu language with sale/promo category - native Urdu text input",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            language=FlyerLanguage.URDU,
            text_content=TextContent(
                headline="بڑی سیل",
                subheadline="سال کی سب سے بڑی چھوٹ",
                date="14-15 دسمبر 2024",
                discount_text="70% تک چھوٹ",
                cta_text="ابھی خریداری کریں!",
                fine_print="سٹاک ختم ہونے تک۔ شرائط لاگو۔"
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
            )
        )
    },

    18: {
        "name": "Chinese Fitness Class - Chinese Input",
        "description": "Tests Chinese with fitness/wellness category - native Chinese text input",
        "project": FlyerProject(
            category=FlyerCategory.FITNESS_WELLNESS,
            language=FlyerLanguage.CHINESE,
            text_content=TextContent(
                headline="30天健身挑战",
                subheadline="新年新气象 · 改变从今天开始",
                date="2025年1月6日起",
                time="每日课程: 早6点, 中午12点, 晚6点",
                venue_name="巅峰健身中心",
                price="30天仅需¥499",
                discount_text="前50名报名享6折优惠",
                cta_text="立即加入挑战!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.NEON,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    19: {
        "name": "Urdu Niaz Invitation - Urdu Input",
        "description": "Tests Urdu religious event invitation - native Urdu text input",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.URDU,
            text_content=TextContent(
                headline="نیاز امام جعفر صادق (علیہ السلام)",
                subheadline="براہ کرم ہمارے ساتھ شامل ہوں",
                date="یکم جنوری 2026 | شام 6 بجے سے رات 10 بجے تک",
                address="4521 Meadow Brook Drive, Houston TX 77084",
                cta_text="فاطمہ اور علی کی طرف سے دعوت"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.ELEGANT,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    20: {
        "name": "Spanish Restaurant Flyer - Spanish Input",
        "description": "Tests Spanish language rendering with native Spanish text input",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            language=FlyerLanguage.SPANISH,
            text_content=TextContent(
                headline="Taquería El Sol",
                subheadline="Auténtica Comida Mexicana",
                address="2547 Main Street, Houston TX 77002",
                phone="(713) 555-1234",
                price="Tacos desde $2.50",
                cta_text="¡Visítanos Hoy!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    21: {
        "name": "Arabic Eid Event Flyer - Arabic Input",
        "description": "Tests Arabic language rendering with native Arabic text input",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.ARABIC,
            text_content=TextContent(
                headline="عيد مبارك",
                subheadline="احتفال عيد الفطر المبارك",
                date="٣٠ مارس ٢٠٢٥ | بعد صلاة العشاء",
                venue_name="المركز الإسلامي",
                address="1234 Islamic Center Drive, Houston TX",
                cta_text="الدعوة عامة للجميع"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    # =========================================================================
    # ENGLISH INPUT TESTS - Testing auto-translation from English
    # =========================================================================

    22: {
        "name": "Urdu Event Flyer - English Input",
        "description": "Tests Urdu translation from English input - Community Fair",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.URDU,
            text_content=TextContent(
                headline="Community Fair",
                subheadline="Come and have fun with family",
                date="January 15, 2025 | 5 PM to 9 PM",
                venue_name="Islamic Center",
                address="123 Main Street, Houston TX",
                cta_text="Register Now!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    23: {
        "name": "Chinese Restaurant Flyer - English Input",
        "description": "Tests Chinese translation from English input - Golden Dragon",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            language=FlyerLanguage.CHINESE,
            text_content=TextContent(
                headline="Golden Dragon Restaurant",
                subheadline="Authentic Sichuan Cuisine - Delicious",
                address="123 Beijing Road",
                phone="010-1234-5678",
                price="Average ¥80-120 per person",
                cta_text="Welcome!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    24: {
        "name": "Spanish Restaurant Flyer - English Input",
        "description": "Tests Spanish translation from English input - Taqueria",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            language=FlyerLanguage.SPANISH,
            text_content=TextContent(
                headline="The Sun Taqueria",
                subheadline="Authentic Mexican Food",
                address="2547 Main Street, Houston TX 77002",
                phone="(713) 555-1234",
                price="Tacos from $2.50",
                cta_text="Visit Us Today!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    25: {
        "name": "Arabic Eid Event Flyer - English Input",
        "description": "Tests Arabic translation from English input - Eid celebration",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.ARABIC,
            text_content=TextContent(
                headline="Eid Mubarak",
                subheadline="Eid Al-Fitr Celebration",
                date="March 30, 2025 | After Isha Prayer",
                venue_name="Islamic Center",
                address="1234 Islamic Center Drive, Houston TX",
                cta_text="Everyone is welcome!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    26: {
        "name": "Urdu Majlis Imam Hussain - English Input",
        "description": "Tests Urdu translation from English input - Somber religious gathering",
        "project": FlyerProject(
            category=FlyerCategory.EVENT,
            language=FlyerLanguage.URDU,
            text_content=TextContent(
                headline="Majlis Imam Hussain",
                subheadline="Commemorating the Sacrifice of Karbala",
                date="July 15, 2025 | After Maghrib Prayer",
                venue_name="Hussaini Center",
                address="5678 Ashura Lane, Houston TX",
                cta_text="All are welcome to attend"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.MONOCHROME,
                primary_color="black",
                accent_color="dark green",
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.SERIOUS,
                text_prominence=TextProminence.DOMINANT,
                include_elements=["Islamic geometric patterns", "crescent moon"]
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    # =========================================================================
    # USER PHOTO & IMAGERY DESCRIPTION TESTS
    # =========================================================================

    27: {
        "name": "Concert Flyer with User Photo",
        "description": "Tests user photo integration - Band/artist photo incorporated into flyer design",
        "project": FlyerProject(
            category=FlyerCategory.MUSIC_CONCERT,
            text_content=TextContent(
                headline="THE BEATLES TRIBUTE NIGHT",
                subheadline="A Magical Mystery Tour Through the Hits",
                date="Saturday, February 15, 2025 | 8:00 PM",
                venue_name="Abbey Road Live",
                address="1969 Penny Lane, Liverpool, TX 77001",
                price="$45 General | $75 VIP",
                cta_text="Get Your Tickets Now!",
                website="www.abbeyroadlive.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.RETRO_VINTAGE,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            user_photo_path="test_images/beatles_photo.jpg",  # User's band photo
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.abbeyroadlive.com/beatles-tribute"
            )
        )
    },

    28: {
        "name": "Pet Grooming with User Photo",
        "description": "Tests user photo integration - Pet photo for grooming service flyer",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="PAMPERED PAWS GROOMING",
                subheadline="Your Pet Deserves the Best!",
                date="Open 7 Days a Week",
                discount_text="20% OFF First Visit",
                address="456 Pet Paradise Blvd, Austin, TX 78701",
                phone="(512) 555-PAWS",
                cta_text="Book Your Appointment Today!",
                website="www.pamperedpawsatx.com"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            user_photo_path="test_images/cute_dog.jpg",  # User's pet photo
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.pamperedpawsatx.com/book"
            )
        )
    },

    29: {
        "name": "AI-Generated Imagery - Beach Vacation",
        "description": "Tests imagery_description - AI generates beach scene for travel flyer",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="SUMMER ESCAPE SALE",
                subheadline="Your Dream Beach Vacation Awaits",
                discount_text="SAVE UP TO 40%",
                date="Book by March 31, 2025",
                cta_text="Book Now & Save Big!",
                website="www.tropicalgetaways.com",
                fine_print="Restrictions apply. Based on availability."
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.GRADIENT
            ),
            visuals=VisualSettings(
                style=VisualStyle.MODERN_MINIMAL,
                mood=Mood.CALM,
                text_prominence=TextProminence.BALANCED
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            imagery_description="A pristine tropical beach with crystal clear turquoise water, white sand, palm trees swaying in the breeze, and a colorful sunset sky",
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.tropicalgetaways.com/summer-sale"
            )
        )
    },

    30: {
        "name": "AI-Generated Imagery - Gourmet Food",
        "description": "Tests imagery_description - AI generates appetizing food imagery for restaurant",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            text_content=TextContent(
                headline="CHEF'S TABLE EXPERIENCE",
                subheadline="A Culinary Journey Like No Other",
                venue_name="La Maison Élégante",
                address="789 Gourmet Avenue, San Francisco, CA 94102",
                price="$150 per person",
                phone="(415) 555-CHEF",
                cta_text="Reserve Your Seat",
                website="www.lamaisonelegante.com"
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
            imagery_description="An exquisite gourmet dish beautifully plated with artistic garnishes, warm ambient lighting, fine dining atmosphere with elegant table setting",
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.lamaisonelegante.com/reserve"
            )
        )
    },

    31: {
        "name": "AI-Generated Imagery - Fitness Motivation",
        "description": "Tests imagery_description - AI generates motivational fitness imagery",
        "project": FlyerProject(
            category=FlyerCategory.FITNESS_WELLNESS,
            text_content=TextContent(
                headline="TRANSFORM YOUR LIFE",
                subheadline="Join Our 12-Week Body Transformation Program",
                date="New Classes Starting Monthly",
                time="Morning, Afternoon & Evening Sessions",
                venue_name="Iron Will Fitness",
                address="1000 Strength Street, Miami, FL 33101",
                price="$299 for 12 weeks",
                discount_text="ENROLL TODAY: GET 2 WEEKS FREE",
                cta_text="Start Your Journey!",
                phone="(305) 555-LIFT"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.NEON,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.INSPIRATIONAL,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            ),
            imagery_description="A determined athlete in a modern gym, dramatic lighting, sweat glistening, showing strength and dedication, motivational fitness atmosphere"
        )
    },

    32: {
        "name": "User Photo + Logo Combined",
        "description": "Tests both user photo and logo together - Real estate with agent photo",
        "project": FlyerProject(
            category=FlyerCategory.REAL_ESTATE,
            text_content=TextContent(
                headline="LUXURY LIVING AWAITS",
                body_text="Stunning 4BR/3BA home with pool, gourmet kitchen, and panoramic views",
                address="12345 Mansion Drive, Beverly Hills, CA 90210",
                price="$4,500,000",
                phone="(310) 555-HOME",
                email="sarah@luxuryhomesla.com",
                website="www.luxuryhomesla.com/mansion-drive"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.BLACK_GOLD,
                background_type=BackgroundType.LIGHT
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
            logo_path="logos/luxuryhomes_logo.png",  # Agency logo
            user_photo_path="test_images/property_photo.jpg",  # Property/agent photo
            qr_settings=QRCodeSettings(
                enabled=True,
                url="https://www.luxuryhomesla.com/mansion-drive"
            )
        )
    },

    # =========================================================================
    # NEWSLETTER SHOWCASE FLYERS - For Marketing FlyGen Newsletter Feature
    # =========================================================================

    33: {
        "name": "Small Business Newsletter",
        "description": "Showcase: Local bakery monthly newsletter with seasonal updates and customer appreciation",
        "project": FlyerProject(
            category=FlyerCategory.ANNOUNCEMENT,
            text_content=TextContent(
                headline="The Monthly Buzz",
                subheadline="Sweet Delights Bakery Newsletter - January 2025",
                body_text="""What's New This Month

NEW ON THE MENU
Introducing our Winter Warmers collection! Try our new Maple Pecan Danish, Spiced Apple Croissant, and Hot Honey Butter Biscuits.

CUSTOMER SPOTLIGHT
Thank you to the Martinez family for being our Customer of the Month! They've been visiting us every Saturday morning for 3 years.

UPCOMING EVENTS
• Jan 18: Kids Cookie Decorating Class (Ages 5-12)
• Jan 25: Valentine's Day Pre-Order Opens
• Feb 1: Couples' Baking Night

JANUARY SPECIAL
Show this newsletter for 15% off any specialty cake order!

Visit: www.sweetdelightsbakery.com""",
                cta_text="Follow us @SweetDelightsBakery"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.PASTEL,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    34: {
        "name": "Community Newsletter",
        "description": "Showcase: HOA/neighborhood community newsletter with updates and events",
        "project": FlyerProject(
            category=FlyerCategory.ANNOUNCEMENT,
            text_content=TextContent(
                headline="Riverside Community News",
                subheadline="Your Neighborhood Update - Spring 2025",
                body_text="""From the HOA Board

Spring is here and our community is thriving! Here's what you need to know:

COMMUNITY UPDATES
• Pool opens May 1st - new hours: 8 AM - 9 PM
• Landscaping improvements completed on Oak Drive
• New playground equipment installed at Central Park

IMPORTANT REMINDERS
• Annual dues are due by March 15th
• Garage sale weekend: April 5-6
• Lawn maintenance standards in effect

UPCOMING EVENTS
March 22 - Spring Block Party (4-8 PM)
April 12 - Easter Egg Hunt at Central Park
April 26 - Community Clean-Up Day

CONTACT US
Email: board@riversidehoa.org
Portal: www.riversidecommunity.org""",
                cta_text="Join our Facebook Group!"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.LIGHT
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

    35: {
        "name": "Tech Startup Newsletter",
        "description": "Showcase: SaaS product update newsletter with feature announcements",
        "project": FlyerProject(
            category=FlyerCategory.ANNOUNCEMENT,
            text_content=TextContent(
                headline="Product Update",
                subheadline="CloudSync Monthly - January 2025",
                body_text="""What's New in CloudSync

NEW FEATURES
• Real-time collaboration - Edit documents with your team simultaneously
• AI-powered search - Find files instantly with natural language
• Mobile app v3.0 - Completely redesigned for speed

PERFORMANCE IMPROVEMENTS
We've reduced sync times by 60% and improved offline mode reliability.

BY THE NUMBERS
• 2M+ files synced daily
• 99.99% uptime in 2024
• 50+ new integrations added

COMING SOON
• Advanced analytics dashboard
• Custom workflow automation
• Enterprise SSO improvements

PRO TIP
Try the new keyboard shortcut Cmd+K to access quick actions from anywhere!

Learn more: blog.cloudsync.io""",
                cta_text="Upgrade to Pro - 20% Off"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.GRADIENT_MODERN,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    36: {
        "name": "Internet Safety Newsletter",
        "description": "Showcase: School newsletter about online safety, cyberbullying prevention, and digital citizenship",
        "project": FlyerProject(
            category=FlyerCategory.ANNOUNCEMENT,
            text_content=TextContent(
                headline="Digital Safety Corner",
                subheadline="Northwest Saturday School Newsletter",
                body_text="""Keeping Our Children Safe Online
By Officer Jameel Hassan, School Resource Officer

The internet is a powerful tool for learning, but it comes with real risks. Here's what every parent should know:

WARNING SIGNS YOUR CHILD MAY BE AT RISK
• Hiding screens when you walk by
• Becoming withdrawn or secretive
• New "friends" you've never heard of
• Unexpected gifts or money
• Using devices late at night

CYBERBULLYING: WHAT TO WATCH FOR
• Sudden reluctance to use devices
• Emotional after being online
• Deleting social media accounts
• Declining grades or school avoidance

5 RULES EVERY FAMILY NEEDS
1. Devices stay in common areas - no phones in bedrooms
2. Know your child's passwords and accounts
3. Set daily time limits (use Screen Time or Family Link)
4. Talk openly about what they see online
5. Report suspicious contact immediately

ISLAMIC PERSPECTIVE
The Prophet (PBUH) said: "Each of you is a shepherd and each is responsible for his flock."

Our children are our trust (amanah). Protecting their eyes, hearts, and minds from harmful content is part of our duty as parents.

Resources: www.nwsaturdayschool.org/safety""",
                cta_text="Download Our Family Safety Guide"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.LIGHT
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

    # =========================================================================
    # GARAGE SALE FLYERS
    # =========================================================================

    37: {
        "name": "Family Moving Sale",
        "description": "Garage sale: Family relocating, selling household items, furniture, and kids' stuff",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="HUGE MOVING SALE",
                subheadline="Everything Must Go! 20+ Years of Treasures",
                discount_text="Up to 75% Off Retail",
                date="Saturday & Sunday, January 11-12 | 7 AM - 3 PM",
                address="4521 Maple Grove Drive, Pleasanton",
                cta_text="Cash & Venmo Accepted",
                fine_print="Rain or shine • Early birds welcome at 6:30 AM for $5 entry"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    38: {
        "name": "Estate Sale",
        "description": "Garage sale: Estate liquidation with antiques, collectibles, and vintage items",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="ESTATE SALE",
                subheadline="Vintage Furniture • Antiques • Fine China • Collectibles",
                discount_text="50% Off Sunday",
                date="Fri-Sun, January 17-19 | 9 AM - 4 PM",
                address="892 Heritage Oak Lane, Walnut Creek",
                cta_text="Don't Miss This Once-in-a-Lifetime Find",
                fine_print="No early birds please • Numbers given at 8:30 AM • Cash preferred"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.EARTH_TONES,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.ELEGANT,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    39: {
        "name": "Multi-Family Yard Sale",
        "description": "Garage sale: Neighborhood multi-family sale with variety of items",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="5-FAMILY YARD SALE",
                subheadline="Baby Gear • Tools • Electronics • Clothes • Sports Equipment • Toys",
                discount_text="Prices Starting at $1",
                date="Saturday, January 25 | 8 AM - 2 PM",
                address="Sunset Hills Cul-de-sac, 1200 Block of Hillview Dr",
                cta_text="Something for Everyone!",
                fine_print="Street parking available • Follow the signs from Main St"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.WARM,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.PLAYFUL_FUN,
                mood=Mood.FRIENDLY,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    40: {
        "name": "Downsizing Sale",
        "description": "Garage sale: Retired couple downsizing with quality furniture and home goods",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="DOWNSIZING SALE",
                subheadline="Quality Furniture • Kitchen Appliances • Garden Tools • Home Decor",
                discount_text="Priced to Sell",
                date="Feb 1-2 | Sat 8 AM - 4 PM, Sun 10 AM - 2 PM",
                address="7834 Orchard View Court, Dublin",
                cta_text="All Reasonable Offers Considered",
                fine_print="Large items available for pickup through Feb 5 • Cash or Zelle"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.LIGHT
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

    41: {
        "name": "Community Garage Sale",
        "description": "Garage sale: HOA-organized community-wide garage sale event",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="SPRING BROOK COMMUNITY GARAGE SALE",
                subheadline="50+ Homes Participating • Maps Available at Clubhouse",
                discount_text="Free Admission",
                date="Saturday, March 8 | 7 AM - 1 PM",
                address="Spring Brook Subdivision, Enter on Brookfield Rd",
                cta_text="Shop the Whole Neighborhood!",
                fine_print="Hosted by Spring Brook HOA • Refreshments at clubhouse • Restrooms available",
                website="springbrookhoa.org/garagesale"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.COOL,
                background_type=BackgroundType.LIGHT
            ),
            visuals=VisualSettings(
                style=VisualStyle.BOLD_VIBRANT,
                mood=Mood.EXCITING,
                text_prominence=TextProminence.DOMINANT
            ),
            output=OutputSettings(
                aspect_ratio=AspectRatio.PORTRAIT_4_5,
                model="nano-banana-pro"
            )
        )
    },

    42: {
        "name": "Garage Cleanout Sale",
        "description": "Garage sale: Tools, outdoor equipment, and man-cave items",
        "project": FlyerProject(
            category=FlyerCategory.SALE_PROMO,
            text_content=TextContent(
                headline="GARAGE CLEANOUT",
                subheadline="Power Tools • Lawn Equipment • Camping Gear • Fishing Tackle • Workbenches",
                discount_text="Make an Offer!",
                date="Saturday, January 18 | 6 AM - Noon",
                address="2847 Industrial Way, Livermore",
                cta_text="Serious Tools for Serious DIYers",
                fine_print="DeWalt • Milwaukee • Craftsman • Husqvarna • Cash only please"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.MONOCHROME,
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
            )
        )
    },

    43: {
        "name": "Holiday Restaurant Special",
        "description": "Dark elegant holiday-themed restaurant flyer with gold accents (Oh My Chai style)",
        "project": FlyerProject(
            category=FlyerCategory.RESTAURANT_FOOD,
            text_content=TextContent(
                headline="Christmas Day",
                subheadline="WE'RE OPEN | 12 PM - 5 PM",
                venue_name="Oh My Chai",
                price="Bihari Kabob Rolls",
                cta_text="LIMITED & EXCLUSIVE",
                address="46090 Michigan Ave, Canton MI"
            ),
            colors=ColorSettings(
                preset=ColorSchemePreset.BLACK_GOLD,
                background_type=BackgroundType.DARK
            ),
            visuals=VisualSettings(
                style=VisualStyle.ELEGANT_LUXURY,
                mood=Mood.FESTIVE,
                text_prominence=TextProminence.BALANCED,
                include_elements=["snowflakes", "holiday garland", "gold ornamental accents", "Christmas decorations"]
            ),
            output=OutputSettings(aspect_ratio=AspectRatio.PORTRAIT_4_5),
            special_instructions="Professional food photography style. Dark elegant holiday theme with gold and champagne accents. Christmas atmosphere with snowflakes and ornamental decorations. Feature chai drink and kabob rolls as hero visual elements. Luxurious upscale restaurant feel."
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
    disable_qr: bool = False,
    user_photo_override: str = None,
    disable_user_photo: bool = False
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

    # Handle user photo override
    user_photo_path = None
    if not disable_user_photo:
        user_photo_path = user_photo_override or project.user_photo_path

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
    if user_photo_path:
        print(f"   📷 User Photo: {user_photo_path}")
    if project.imagery_description:
        print(f"   🎨 Imagery Description: {project.imagery_description[:50]}...")
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

    # Prepare input images (for logo and user photo)
    input_images = []

    # Add logo if provided
    if logo_path:
        if Path(logo_path).exists():
            input_images.append(logo_path)
            print(f"   📎 Logo will be sent to AI for integration")
        else:
            print(f"   ⚠️  Logo file not found: {logo_path}")

    # Add user photo if provided
    if user_photo_path:
        if Path(user_photo_path).exists():
            input_images.append(user_photo_path)
            print(f"   📎 User photo will be sent to AI for integration")
        else:
            print(f"   ⚠️  User photo file not found: {user_photo_path}")

    # Set to None if empty list
    if not input_images:
        input_images = None

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
    python test_flyer.py 1 --photo photo.jpg    # Run with custom user photo
    python test_flyer.py 1 --qr https://...     # Run with custom QR URL
    python test_flyer.py 1 --no-qr              # Run without QR code
    python test_flyer.py 27                     # Run user photo test case
    python test_flyer.py 29                     # Run imagery description test case
        """
    )
    parser.add_argument("test", nargs="?", help="Test case number or 'all'")
    parser.add_argument("--list", action="store_true", help="List all test cases")
    parser.add_argument("--openai", action="store_true",
                        help="Use OpenAI directly instead of OpenRouter")
    parser.add_argument("--logo", type=str, metavar="PATH",
                        help="Path to logo image (overrides test case default)")
    parser.add_argument("--photo", type=str, metavar="PATH",
                        help="Path to user photo image (overrides test case default)")
    parser.add_argument("--qr", type=str, metavar="URL",
                        help="QR code URL (overrides test case default)")
    parser.add_argument("--no-logo", action="store_true",
                        help="Disable logo even if test case has one")
    parser.add_argument("--no-photo", action="store_true",
                        help="Disable user photo even if test case has one")
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
                disable_qr=args.no_qr,
                user_photo_override=args.photo,
                disable_user_photo=args.no_photo
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
                disable_qr=args.no_qr,
                user_photo_override=args.photo,
                disable_user_photo=args.no_photo
            )
        except ValueError:
            print(f"❌ Invalid test number: {args.test}")
            print("   Use a number (1-32) or 'all'")


if __name__ == "__main__":
    main()
