#!/usr/bin/env python3
"""
Demo Script - Test Prompt Generation Quality

Run this to see what prompts are generated for various flyer types.
No API key needed - just shows the prompt engineering in action.

Usage:
    python demo.py
"""
from models import (
    FlyerProject, FlyerCategory, VisualStyle, Mood, AspectRatio,
    TextContent, ColorSettings, VisualSettings, OutputSettings,
    TextProminence, ImageryType, ColorSchemePreset, BackgroundType
)
from prompt_builder import FlyerPromptBuilder, RefinementPromptBuilder


def print_divider(title: str = ""):
    print("\n" + "=" * 70)
    if title:
        print(f"  {title}")
        print("=" * 70)


def demo_bakery_sale():
    """Demo: Local bakery weekend sale flyer"""
    print_divider("DEMO 1: Bakery Weekend Sale")
    
    project = FlyerProject(
        category=FlyerCategory.SALE_PROMO,
        text_content=TextContent(
            headline="FRESH BAKED SAVINGS",
            subheadline="Weekend Special",
            date="December 7-8, 2024",
            venue_name="Sweet Dreams Bakery",
            address="123 Main St",
            discount_text="20% OFF All Pastries",
            cta_text="Visit Us This Weekend!"
        ),
        colors=ColorSettings(
            preset=ColorSchemePreset.WARM,
            primary_color="soft orange",
            secondary_color="cream",
            background_type=BackgroundType.LIGHT,
            background_color="cream"
        ),
        visuals=VisualSettings(
            style=VisualStyle.HAND_DRAWN_ORGANIC,
            mood=Mood.FRIENDLY,
            text_prominence=TextProminence.BALANCED,
            imagery_type=ImageryType.ILLUSTRATED,
            include_elements=["bread loaves", "croissants", "wheat motifs"],
            avoid_elements=["photorealistic food", "generic stock imagery", "clipart"]
        ),
        output=OutputSettings(
            aspect_ratio=AspectRatio.PORTRAIT_4_5
        ),
        target_audience="local families and food enthusiasts"
    )
    
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\n📋 MAIN PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    print("\n🚫 NEGATIVE PROMPT:")
    print("-" * 50)
    print(package["negative_prompt"])
    print(f"\n📐 Aspect Ratio: {package['aspect_ratio']}")


def demo_tech_event():
    """Demo: Tech conference/meetup event flyer"""
    print_divider("DEMO 2: Tech Conference Event")
    
    project = FlyerProject(
        category=FlyerCategory.EVENT,
        text_content=TextContent(
            headline="AI & FUTURE TECH SUMMIT",
            subheadline="Where Innovation Meets Community",
            date="January 15, 2025",
            time="9AM - 6PM",
            venue_name="Innovation Hub",
            address="San Francisco, CA",
            price="$49",
            cta_text="Register Now",
            website="summit.tech/register"
        ),
        colors=ColorSettings(
            preset=ColorSchemePreset.COOL,
            primary_color="electric blue",
            accent_color="cyan",
            background_type=BackgroundType.GRADIENT,
            gradient_colors=["#0a0a2e", "#1a1a4e"]
        ),
        visuals=VisualSettings(
            style=VisualStyle.MODERN_MINIMAL,
            mood=Mood.EXCITING,
            text_prominence=TextProminence.DOMINANT,
            imagery_type=ImageryType.ABSTRACT_GEOMETRIC,
            include_elements=["geometric shapes", "circuit patterns", "futuristic elements"],
            avoid_elements=["dated tech imagery", "stock photos of people", "busy backgrounds"]
        ),
        output=OutputSettings(
            aspect_ratio=AspectRatio.STORY_9_16
        ),
        target_audience="tech professionals, developers, entrepreneurs"
    )
    
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\n📋 MAIN PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    print("\n🚫 NEGATIVE PROMPT:")
    print("-" * 50)
    print(package["negative_prompt"])
    print(f"\n📐 Aspect Ratio: {package['aspect_ratio']}")


def demo_yoga_class():
    """Demo: Yoga class/workshop flyer"""
    print_divider("DEMO 3: Yoga Workshop")
    
    project = FlyerProject(
        category=FlyerCategory.CLASS_WORKSHOP,
        text_content=TextContent(
            headline="SUNRISE YOGA",
            subheadline="8-Week Beginner Series",
            date="Starting Jan 4",
            time="Saturdays 7AM",
            venue_name="Serenity Studio",
            address="45 Wellness Way",
            price="$120 for full series",
            cta_text="Book Your Mat"
        ),
        colors=ColorSettings(
            preset=ColorSchemePreset.PASTEL,
            primary_color="soft lavender",
            secondary_color="sage green",
            background_type=BackgroundType.GRADIENT
        ),
        visuals=VisualSettings(
            style=VisualStyle.ELEGANT_LUXURY,
            mood=Mood.CALM,
            text_prominence=TextProminence.BALANCED,
            imagery_type=ImageryType.ILLUSTRATED,
            include_elements=["lotus flower", "sunrise motif", "peaceful silhouette"],
            avoid_elements=["intimidating poses", "gym aesthetic", "crowded imagery"]
        ),
        output=OutputSettings(
            aspect_ratio=AspectRatio.SQUARE_1_1
        ),
        target_audience="beginners seeking stress relief and wellness"
    )
    
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\n📋 MAIN PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    print("\n🚫 NEGATIVE PROMPT:")
    print("-" * 50)
    print(package["negative_prompt"])
    print(f"\n📐 Aspect Ratio: {package['aspect_ratio']}")


def demo_restaurant_opening():
    """Demo: Restaurant grand opening flyer"""
    print_divider("DEMO 4: Restaurant Grand Opening")
    
    project = FlyerProject(
        category=FlyerCategory.GRAND_OPENING,
        text_content=TextContent(
            headline="NOW OPEN",
            subheadline="Authentic Mexican Cuisine",
            date="Grand Opening: December 20th",
            venue_name="La Mesa Cantina",
            address="789 Food Court",
            discount_text="FREE appetizer with any entrée!",
            cta_text="Join the Fiesta!"
        ),
        colors=ColorSettings(
            preset=ColorSchemePreset.WARM,
            primary_color="vibrant orange",
            secondary_color="turquoise",
            accent_color="hot pink",
            background_type=BackgroundType.TEXTURED
        ),
        visuals=VisualSettings(
            style=VisualStyle.BOLD_VIBRANT,
            mood=Mood.FESTIVE,
            text_prominence=TextProminence.DOMINANT,
            imagery_type=ImageryType.ILLUSTRATED,
            include_elements=["papel picado banners", "chili peppers", "festive ribbons"],
            avoid_elements=["stereotypical imagery", "sombreros", "generic mexican flags"]
        ),
        output=OutputSettings(
            aspect_ratio=AspectRatio.PORTRAIT_4_5
        ),
        target_audience="local food lovers, families"
    )
    
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\n📋 MAIN PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    print("\n🚫 NEGATIVE PROMPT:")
    print("-" * 50)
    print(package["negative_prompt"])
    print(f"\n📐 Aspect Ratio: {package['aspect_ratio']}")


def demo_refinement():
    """Demo: Show how refinement prompts are built from feedback"""
    print_divider("DEMO 5: Refinement Examples")
    
    original_prompt = (
        "Professional sale flyer with bold headline 'BIG SALE' and warm colors, "
        "modern design with eye-catching discount display..."
    )
    
    feedback_examples = [
        "make the text bigger and more readable",
        "it's too busy, I want something cleaner",
        "can you make it more professional and corporate",
        "I want brighter, more exciting colors",
        "the layout feels boring, make it more dynamic"
    ]
    
    print("\nOriginal prompt (truncated):")
    print(f'  "{original_prompt[:60]}..."')
    print("\nHow user feedback gets translated into prompt modifications:")
    print("-" * 50)
    
    for feedback in feedback_examples:
        refined = RefinementPromptBuilder.build_refinement(original_prompt, feedback)
        
        # Extract the modification part
        if "MODIFICATIONS:" in refined:
            mod_part = refined.split("MODIFICATIONS:")[-1].strip()
        else:
            mod_part = refined.split("CHANGES REQUESTED:")[-1].strip()
        
        print(f'\n  User says: "{feedback}"')
        print(f'  → Adds to prompt: "{mod_part[:70]}..."')


def demo_minimal_input():
    """Demo: Show what happens with minimal user input"""
    print_divider("DEMO 6: Minimal Input (Just Headline)")
    
    # User only provides headline - everything else is defaults
    project = FlyerProject(
        category=FlyerCategory.EVENT,
        text_content=TextContent(
            headline="SUMMER CONCERT"
        )
    )
    
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\nWith just a headline, the system still generates a complete prompt:")
    print("-" * 50)
    print(package["main_prompt"])
    print(f"\n📐 Defaults applied: {package['aspect_ratio']} aspect ratio")


def main():
    print("\n" + "🎨" * 35)
    print("     FLYER GENERATOR - PROMPT ENGINEERING DEMO")
    print("🎨" * 35)
    print("\nThis demo shows how structured user input is transformed")
    print("into optimized prompts for AI image generation.\n")
    print("No API key needed - this just demonstrates the prompt logic.\n")
    
    demo_bakery_sale()
    demo_tech_event()
    demo_yoga_class()
    demo_restaurant_opening()
    demo_refinement()
    demo_minimal_input()
    
    print_divider("DEMO COMPLETE")
    print("\n✅ Key takeaways:")
    print("   • Category-specific context is automatically added")
    print("   • Style/mood choices expand into detailed descriptions")
    print("   • Negative prompts prevent common AI failures")
    print("   • User feedback is parsed into actionable modifications")
    print("   • Sensible defaults fill in missing information")
    print()
    print("📝 To test with actual image generation:")
    print("   1. Set OPENAI_API_KEY environment variable")
    print("   2. Run: python main.py")
    print()
    print("💡 Copy any prompt above and paste it into ChatGPT or")
    print("   DALL-E to test the output quality manually!")
    print()


if __name__ == "__main__":
    main()
