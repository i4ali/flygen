#!/usr/bin/env python3
"""
Flyer Generator - Interactive CLI

Full flow: Guided intake → Prompt generation → Image generation

Usage:
    python main.py                  # Interactive mode (OpenAI)
    python main.py --openrouter     # Use OpenRouter API
    python main.py --mock           # Test without API key
"""
import argparse
import json
import os
from typing import Optional, List, Tuple
from pathlib import Path

from models import (
    FlyerProject, FlyerCategory, TextContent, ColorSettings, 
    VisualSettings, OutputSettings,
    VisualStyle, Mood, ColorSchemePreset, BackgroundType,
    TextProminence, ImageryType, AspectRatio,
    CATEGORY_TEXT_FIELDS, CATEGORY_SUGGESTED_ELEMENTS
)
from prompt_builder import FlyerPromptBuilder, RefinementPromptBuilder
from image_generator import create_generator


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def clear():
    print("\n" + "=" * 60 + "\n")


def print_header(title: str, subtitle: str = ""):
    print(f"\n📱 {title}")
    if subtitle:
        print(f"   {subtitle}")
    print("-" * 50)


def get_choice(options: List[Tuple[str, str]], prompt: str = "Select") -> str:
    """Display numbered options and get user selection"""
    print()
    for i, (value, display) in enumerate(options, 1):
        print(f"  {i}. {display}")
    print()
    
    while True:
        try:
            choice = input(f"{prompt} (1-{len(options)}): ").strip()
            if choice.lower() == 'q':
                return None
            idx = int(choice) - 1
            if 0 <= idx < len(options):
                return options[idx][0]
            print(f"Please enter 1-{len(options)}")
        except ValueError:
            print("Please enter a number")


def get_text(prompt: str, required: bool = False) -> Optional[str]:
    """Get text input"""
    marker = " *" if required else ""
    value = input(f"{prompt}{marker}: ").strip()
    
    if not value and required:
        print("This field is required.")
        return get_text(prompt, required)
    
    return value if value else None


def get_list(prompt: str) -> Optional[List[str]]:
    """Get comma-separated list"""
    value = input(f"{prompt} (comma-separated, or Enter to skip): ").strip()
    if not value:
        return None
    return [item.strip() for item in value.split(",") if item.strip()]


def confirm(prompt: str, default: bool = True) -> bool:
    """Get yes/no confirmation"""
    hint = "[Y/n]" if default else "[y/N]"
    response = input(f"{prompt} {hint}: ").strip().lower()
    if not response:
        return default
    return response in ['y', 'yes']


# =============================================================================
# INTAKE SCREENS
# =============================================================================

def screen_category() -> FlyerCategory:
    """Screen 1: Select flyer category"""
    print_header("FLYER TYPE", "What kind of flyer are you creating?")
    
    options = [
        (FlyerCategory.EVENT.value, "🎉 Event"),
        (FlyerCategory.SALE_PROMO.value, "🏷️ Sale / Promotion"),
        (FlyerCategory.GRAND_OPENING.value, "🎊 Grand Opening"),
        (FlyerCategory.RESTAURANT_FOOD.value, "🍽️ Restaurant / Food"),
        (FlyerCategory.CLASS_WORKSHOP.value, "📚 Class / Workshop"),
        (FlyerCategory.PARTY_CELEBRATION.value, "🎈 Party / Celebration"),
        (FlyerCategory.FITNESS_WELLNESS.value, "💪 Fitness / Wellness"),
        (FlyerCategory.MUSIC_CONCERT.value, "🎵 Music / Concert"),
        (FlyerCategory.JOB_POSTING.value, "💼 Job Posting"),
        (FlyerCategory.REAL_ESTATE.value, "🏠 Real Estate"),
        (FlyerCategory.NONPROFIT_CHARITY.value, "❤️ Nonprofit / Charity"),
        (FlyerCategory.ANNOUNCEMENT.value, "📢 Announcement"),
    ]
    
    choice = get_choice(options, "Select type")
    return FlyerCategory(choice)


def screen_text_content(category: FlyerCategory) -> TextContent:
    """Screen 2: Enter text content"""
    print_header("TEXT CONTENT", "What should the flyer say?")

    content = TextContent()

    # Headline is always required
    content.headline = get_text("Main headline (the big text)", required=True)
    content.subheadline = get_text("Subheadline or tagline")

    # Category-specific fields
    relevant_fields = CATEGORY_TEXT_FIELDS.get(category, [])
    
    if "date" in relevant_fields:
        content.date = get_text("Date")
    if "time" in relevant_fields:
        content.time = get_text("Time")
    if "venue_name" in relevant_fields:
        content.venue_name = get_text("Venue/Business name")
    if "address" in relevant_fields:
        content.address = get_text("Address/Location")
    if "price" in relevant_fields:
        content.price = get_text("Price")
    if "discount_text" in relevant_fields:
        content.discount_text = get_text("Discount/Offer (e.g., '20% OFF')")
    if "cta_text" in relevant_fields:
        content.cta_text = get_text("Call to action (e.g., 'Shop Now!')")
    if "website" in relevant_fields:
        content.website = get_text("Website")
    if "phone" in relevant_fields:
        content.phone = get_text("Phone number")
    if "email" in relevant_fields:
        content.email = get_text("Email")
    
    return content


def screen_visual_style() -> Tuple[VisualStyle, Mood]:
    """Screen 3: Select visual style and mood"""
    print_header("VISUAL STYLE", "How should it look?")
    
    style_options = [
        (VisualStyle.MODERN_MINIMAL.value, "✨ Modern & Minimal"),
        (VisualStyle.BOLD_VIBRANT.value, "🔥 Bold & Vibrant"),
        (VisualStyle.ELEGANT_LUXURY.value, "💎 Elegant & Luxury"),
        (VisualStyle.PLAYFUL_FUN.value, "🎨 Playful & Fun"),
        (VisualStyle.HAND_DRAWN_ORGANIC.value, "🖌️ Hand-drawn & Organic"),
        (VisualStyle.RETRO_VINTAGE.value, "📻 Retro / Vintage"),
        (VisualStyle.CORPORATE_PROFESSIONAL.value, "💼 Corporate / Professional"),
        (VisualStyle.NEON_GLOW.value, "🌟 Neon Glow"),
        (VisualStyle.GRADIENT_MODERN.value, "🌈 Gradient Modern"),
        (VisualStyle.WATERCOLOR_ARTISTIC.value, "🎭 Watercolor Artistic"),
    ]
    
    style_choice = get_choice(style_options, "Select style")
    style = VisualStyle(style_choice)
    
    clear()
    print_header("MOOD / TONE", "What feeling should it convey?")
    
    mood_options = [
        (Mood.FRIENDLY.value, "😊 Friendly & Welcoming"),
        (Mood.EXCITING.value, "🎉 Exciting & Energetic"),
        (Mood.URGENT.value, "⚡ Urgent (Act Now!)"),
        (Mood.PROFESSIONAL.value, "💼 Professional"),
        (Mood.ELEGANT.value, "✨ Elegant & Sophisticated"),
        (Mood.CALM.value, "🧘 Calm & Peaceful"),
        (Mood.FESTIVE.value, "🎊 Festive & Celebratory"),
        (Mood.INSPIRATIONAL.value, "🌟 Inspirational"),
        (Mood.SERIOUS.value, "📋 Serious & Important"),
    ]
    
    mood_choice = get_choice(mood_options, "Select mood")
    mood = Mood(mood_choice)
    
    return style, mood


def screen_colors() -> ColorSettings:
    """Screen 4: Color preferences"""
    print_header("COLORS", "Choose your color palette")
    
    palette_options = [
        (ColorSchemePreset.WARM.value, "🔥 Warm (oranges, reds, yellows)"),
        (ColorSchemePreset.COOL.value, "❄️ Cool (blues, teals, purples)"),
        (ColorSchemePreset.PASTEL.value, "🌸 Pastel (soft, light tones)"),
        (ColorSchemePreset.EARTH_TONES.value, "🌿 Earth Tones (browns, greens)"),
        (ColorSchemePreset.NEON.value, "💜 Neon (bright, electric)"),
        (ColorSchemePreset.MONOCHROME.value, "⬛ Monochrome"),
        (ColorSchemePreset.BLACK_GOLD.value, "🏆 Black & Gold (luxury)"),
        (ColorSchemePreset.CUSTOM.value, "🎨 Custom colors"),
    ]
    
    preset_choice = get_choice(palette_options, "Select palette")
    preset = ColorSchemePreset(preset_choice)
    
    settings = ColorSettings(preset=preset)
    
    if preset == ColorSchemePreset.CUSTOM:
        settings.primary_color = get_text("Primary color")
        settings.secondary_color = get_text("Secondary color")
        settings.accent_color = get_text("Accent color")
    
    clear()
    print_header("BACKGROUND", "Background style")
    
    bg_options = [
        (BackgroundType.LIGHT.value, "☀️ Light background"),
        (BackgroundType.DARK.value, "🌙 Dark background"),
        (BackgroundType.GRADIENT.value, "🌈 Gradient"),
        (BackgroundType.TEXTURED.value, "🧱 Textured"),
        (BackgroundType.SOLID.value, "⬜ Solid color"),
    ]
    
    bg_choice = get_choice(bg_options, "Select background")
    settings.background_type = BackgroundType(bg_choice)
    
    return settings


def screen_format() -> AspectRatio:
    """Screen 5: Output format"""
    print_header("FORMAT", "Where will this flyer be used?")

    format_options = [
        (AspectRatio.PORTRAIT_4_5.value, "📱 Instagram Post (4:5)"),
        (AspectRatio.SQUARE_1_1.value, "⬜ Square (1:1)"),
        (AspectRatio.STORY_9_16.value, "📲 Story / Reel (9:16)"),
        (AspectRatio.LANDSCAPE_16_9.value, "🖥️ Banner / Landscape (16:9)"),
        (AspectRatio.LETTER.value, "📄 Print - Letter (8.5x11)"),
        (AspectRatio.A4.value, "📄 Print - A4"),
    ]

    choice = get_choice(format_options, "Select format")
    return AspectRatio(choice)


def screen_text_mode() -> ImageryType:
    """Screen 5b: Text rendering mode - with AI or text-free for manual overlay"""
    print_header("TEXT MODE", "How should text be handled?")

    print("\n   AI image models sometimes misspell text.")
    print("   Choose how you want to handle text in your flyer:\n")

    text_options = [
        (ImageryType.ILLUSTRATED.value, "✏️  AI renders text - let AI include text in the image"),
        (ImageryType.NO_TEXT.value, "🖼️  Text-free design - generate image without text, add text later in Canva/Photoshop"),
    ]

    choice = get_choice(text_options, "Select text mode")

    if choice == ImageryType.NO_TEXT.value:
        print("\n   Great choice! You'll get a clean design with space for text overlay.")
        return ImageryType.NO_TEXT
    else:
        return ImageryType.ILLUSTRATED


def screen_extras(category: FlyerCategory) -> Tuple[List[str], List[str], str, str]:
    """Screen 6: Extra preferences"""
    print_header("FINISHING TOUCHES", "Any specific requests?")

    # Suggest elements based on category
    suggested = CATEGORY_SUGGESTED_ELEMENTS.get(category, [])
    if suggested:
        print(f"\n💡 Suggested elements for {category.display_name}:")
        print(f"   {', '.join(suggested)}")

    include = get_list("Visual elements to include")
    avoid = get_list("Anything to avoid")
    audience = get_text("Target audience (e.g., 'young professionals')")
    special = get_text("Any other special instructions")

    return include, avoid, audience, special


def screen_reformat_choice(current_format: str) -> Optional[str]:
    """Let user pick a new format, excluding the current one"""
    print_header("REFORMAT", "Choose a new aspect ratio")

    all_formats = [
        ("1:1", "⬜ Square (1:1) - Instagram"),
        ("4:5", "📱 Portrait (4:5) - Instagram Post"),
        ("9:16", "📲 Story (9:16) - Stories/Reels"),
        ("16:9", "🖥️ Landscape (16:9) - Banner"),
        ("letter", "📄 Letter (8.5x11) - Print"),
        ("a4", "📄 A4 - International Print"),
    ]

    # Filter out current format
    available = [(k, v) for k, v in all_formats if k != current_format]

    print(f"\n   Current format: {current_format}")
    return get_choice(available, "Select new format")


def reformat_image(source_path: str, target_format: str, generator) -> Optional[str]:
    """Reformat an existing image to a new aspect ratio. Returns new image path."""
    print(f"\n⏳ Reformatting to {target_format}...")

    prompt = (
        f"Reformat this flyer image to {target_format} aspect ratio. "
        f"Preserve ALL text exactly as shown - do not change any words or spelling. "
        f"Maintain the same visual style, colors, and layout as much as possible. "
        f"Adapt the composition to fit the new dimensions naturally."
    )

    results = generator.generate(
        prompt=prompt,
        aspect_ratio=target_format,
        save_images=True,
        input_images=[source_path]
    )

    for result in results:
        if result.success:
            print(f"\n✅ Reformatted image saved to: {result.image_path}")
            return result.image_path
        else:
            print(f"\n❌ Reformat failed: {result.error_message}")
            return None

    return None


def screen_logo() -> Optional[str]:
    """Screen 7: Optional logo upload"""
    print_header("BRAND LOGO", "Include your logo in the flyer? (optional)")

    if not confirm("Do you have a logo to include?", default=False):
        return None

    logo_path = get_text("Path to logo image file")

    # Validate file exists
    if logo_path:
        path = Path(logo_path).expanduser()
        if path.exists():
            print(f"   ✅ Logo found: {path.name}")
            return str(path)
        else:
            print("   ⚠️  File not found. Continuing without logo.")

    return None


# =============================================================================
# MAIN FLOW
# =============================================================================

def run_intake() -> FlyerProject:
    """Run the complete intake flow"""
    print("\n" + "🎨" * 30)
    print("      FLYER GENERATOR")
    print("🎨" * 30)
    print("\nLet's create your perfect flyer!\n")
    
    # Screen 1: Category
    category = screen_category()
    clear()
    
    # Screen 2: Text content
    text_content = screen_text_content(category)
    clear()
    
    # Screen 3: Visual style
    style, mood = screen_visual_style()
    clear()
    
    # Screen 4: Colors
    colors = screen_colors()
    clear()
    
    # Screen 5: Format
    aspect_ratio = screen_format()
    clear()

    # Screen 5b: Text mode (AI-rendered vs text-free)
    text_mode = screen_text_mode()
    clear()

    # Screen 6: Extras
    include, avoid, audience, special = screen_extras(category)
    clear()

    # Screen 7: Logo (optional)
    logo_path = screen_logo()

    # Build project
    project = FlyerProject(
        category=category,
        text_content=text_content,
        colors=colors,
        visuals=VisualSettings(
            style=style,
            mood=mood,
            imagery_type=text_mode,
            include_elements=include,
            avoid_elements=avoid
        ),
        output=OutputSettings(
            aspect_ratio=aspect_ratio
        ),
        target_audience=audience,
        special_instructions=special,
        logo_path=logo_path
    )

    return project


def run_generation(project: FlyerProject, mock: bool = False, use_openrouter: bool = False):
    """Run prompt building and image generation"""
    clear()
    
    provider = "OpenRouter" if use_openrouter else "OpenAI"
    print_header("GENERATING YOUR FLYER", f"Building optimized prompt... (using {provider})")
    
    # Build prompt
    builder = FlyerPromptBuilder(project)
    package = builder.build()
    
    print("\n📋 GENERATED PROMPT:")
    print("-" * 50)
    print(package["main_prompt"])
    
    print("\n🚫 NEGATIVE PROMPT:")
    print("-" * 50)
    print(package["negative_prompt"][:200] + "..." if len(package["negative_prompt"]) > 200 else package["negative_prompt"])
    
    print(f"\n📐 Format: {package['aspect_ratio']}")
    print(f"🤖 Model: {package['model']}")
    
    # Confirm generation
    if not confirm("\n\nGenerate image with this prompt?"):
        print("\n💾 Prompt saved. You can copy it to test manually.")
        return
    
    # Generate
    print("\n⏳ Generating image... (this may take 10-30 seconds)")

    generator = create_generator(mock=mock, use_openrouter=use_openrouter)

    # Prepare input images (logo) if provided
    input_images = [project.logo_path] if project.logo_path else None
    if input_images:
        print(f"   📎 Including logo: {Path(project.logo_path).name}")

    results = generator.generate(
        prompt=package["main_prompt"],
        negative_prompt=package["negative_prompt"],
        model=package["model"],
        aspect_ratio=package["aspect_ratio"],
        quality=package["quality"],
        input_images=input_images
    )

    # Track last generated image and current format
    last_generated_path = None
    current_format = package["aspect_ratio"]

    # Show results
    for i, result in enumerate(results):
        if result.success:
            print(f"\n✅ Image {i+1} generated successfully!")
            if result.image_path:
                print(f"   Saved to: {result.image_path}")
                last_generated_path = result.image_path  # Track for refinement
            if result.image_url:
                print(f"   URL: {result.image_url}")
            if result.revised_prompt:
                print(f"   AI revised prompt: {result.revised_prompt[:100]}...")
        else:
            print(f"\n❌ Generation failed: {result.error_message}")

    # Post-generation loop with 3 options: done, refine, reformat
    while last_generated_path:
        print("\n📐 What would you like to do next?")
        next_options = [
            ("done", "✅ Done - keep this image"),
            ("refine", "🔄 Refine - make changes to content/style"),
            ("reformat", "📐 Reformat - get this image in a different size"),
        ]
        next_action = get_choice(next_options, "Select option")

        if next_action is None or next_action == "done":
            break

        elif next_action == "reformat":
            new_format = screen_reformat_choice(current_format)
            if new_format:
                new_path = reformat_image(last_generated_path, new_format, generator)
                if new_path:
                    last_generated_path = new_path
                    current_format = new_format

        elif next_action == "refine":
            feedback = get_text("What changes would you like?")
            if not feedback:
                continue

            refined_prompt = RefinementPromptBuilder.build_refinement(
                package["main_prompt"],
                feedback
            )

            print("\n📋 REFINED PROMPT:")
            print("-" * 50)
            print(refined_prompt)

            # Ask user whether to edit existing image or create new
            print("\n🎨 How would you like to refine?")
            edit_options = [
                ("edit", "✏️  Edit the existing image (recommended for small changes)"),
                ("new", "🆕 Create a new image from scratch"),
            ]
            refine_mode = get_choice(edit_options, "Select mode")

            if refine_mode is None:  # User pressed 'q'
                continue

            # Determine input images for this generation
            refine_input_images = list(input_images) if input_images else []

            if refine_mode == "edit" and last_generated_path:
                # Add the last generated image as input for editing
                refine_input_images.append(last_generated_path)
                print(f"   📎 Using previous image: {Path(last_generated_path).name}")
                # Append edit instructions to the refined prompt (keeps original context)
                refined_prompt = (
                    f"{refined_prompt}\n\n"
                    f"EDIT MODE: Modify the provided image with these specific changes: {feedback}. "
                    f"Preserve all other elements exactly as they appear in the original image."
                )

            print("\n⏳ Generating refined version...")
            results = generator.generate(
                prompt=refined_prompt,
                negative_prompt=package["negative_prompt"],
                model=package["model"],
                aspect_ratio=current_format,
                input_images=refine_input_images if refine_input_images else None
            )

            for result in results:
                if result.success:
                    print(f"\n✅ Refined image saved to: {result.image_path}")
                    last_generated_path = result.image_path  # Track for next iteration
                else:
                    print(f"\n❌ Failed: {result.error_message}")


def check_api_key(use_openrouter: bool = False) -> bool:
    """Check if the required API key is set. Returns True if key exists."""
    if use_openrouter:
        key_name = "OPENROUTER_API_KEY"
    else:
        key_name = "OPENAI_API_KEY"

    return bool(os.environ.get(key_name))


def main():
    parser = argparse.ArgumentParser(description="Flyer Generator CLI")
    parser.add_argument("--mock", action="store_true",
                       help="Use mock generator (no API key needed)")
    parser.add_argument("--openrouter", action="store_true",
                       help="Use OpenRouter API instead of OpenAI directly")
    args = parser.parse_args()

    # Check for API key if not in mock mode
    if not args.mock:
        key_name = "OPENROUTER_API_KEY" if args.openrouter else "OPENAI_API_KEY"
        if not check_api_key(use_openrouter=args.openrouter):
            print(f"\n⚠️  WARNING: {key_name} environment variable is not set.")
            print(f"   Image generation will fail without a valid API key.")
            print(f"   Set it with: export {key_name}=your-api-key")
            print(f"   Or use --mock mode for testing without an API key.\n")
            if not confirm("Continue anyway?", default=False):
                print("\n👋 Exiting. Set your API key and try again.")
                return

    try:
        project = run_intake()
        run_generation(project, mock=args.mock, use_openrouter=args.openrouter)
        
        print("\n" + "=" * 60)
        print("🎉 Done! Thanks for using Flyer Generator.")
        print("=" * 60 + "\n")
        
    except KeyboardInterrupt:
        print("\n\n👋 Cancelled. Goodbye!")


if __name__ == "__main__":
    main()
