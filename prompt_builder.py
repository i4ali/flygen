"""
Prompt Builder - The Core Value Proposition

Transforms structured FlyerProject data into optimized prompts
for AI image generation. This is the "secret sauce" of the app.
"""
from typing import Dict, List, Optional
from models import (
    FlyerProject, FlyerCategory, VisualStyle, Mood, AspectRatio,
    ColorSchemePreset, BackgroundType, TextProminence, ImageryType,
    CATEGORY_SUGGESTED_ELEMENTS
)


# =============================================================================
# CATEGORY-SPECIFIC PROMPT CONTEXT
# =============================================================================

CATEGORY_CONTEXT: Dict[FlyerCategory, str] = {
    FlyerCategory.EVENT: "event promotional flyer design",
    FlyerCategory.SALE_PROMO: "sale and promotion flyer with urgency-driving design elements",
    FlyerCategory.ANNOUNCEMENT: "announcement flyer with clear information hierarchy",
    FlyerCategory.RESTAURANT_FOOD: "restaurant or food service promotional flyer with appetizing appeal",
    FlyerCategory.REAL_ESTATE: "real estate listing flyer with professional property showcase",
    FlyerCategory.JOB_POSTING: "job recruitment flyer with professional yet approachable design",
    FlyerCategory.CLASS_WORKSHOP: "educational class or workshop promotional flyer",
    FlyerCategory.GRAND_OPENING: "grand opening celebration flyer with festive excitement",
    FlyerCategory.PARTY_CELEBRATION: "party or celebration event flyer with fun energetic design",
    FlyerCategory.FITNESS_WELLNESS: "fitness or wellness promotional flyer with energizing appeal",
    FlyerCategory.NONPROFIT_CHARITY: "nonprofit or charity flyer with heartfelt community appeal",
    FlyerCategory.MUSIC_CONCERT: "music event or concert flyer with dynamic artistic style",
}


# =============================================================================
# STYLE DESCRIPTORS - Expanded descriptions for each visual style
# =============================================================================

STYLE_DESCRIPTORS: Dict[VisualStyle, str] = {
    VisualStyle.MODERN_MINIMAL: (
        "modern minimalist design with clean lines, generous white space, "
        "contemporary sans-serif typography aesthetic, uncluttered composition, "
        "sophisticated simplicity"
    ),
    VisualStyle.BOLD_VIBRANT: (
        "bold vibrant design with strong saturated colors, high contrast, "
        "impactful heavy typography, energetic dynamic composition, "
        "eye-catching visual punch"
    ),
    VisualStyle.ELEGANT_LUXURY: (
        "elegant luxury design with sophisticated muted color palette, "
        "refined serif typography, premium high-end feel, subtle gold or metallic accents, "
        "tasteful restraint"
    ),
    VisualStyle.RETRO_VINTAGE: (
        "retro vintage design with nostalgic color palette, classic typography, "
        "aged paper textures, throwback aesthetic from mid-century era, "
        "warm nostalgic feeling"
    ),
    VisualStyle.PLAYFUL_FUN: (
        "playful fun design with bright cheerful colors, rounded friendly shapes, "
        "whimsical illustrated elements, bouncy typography, "
        "joyful energetic composition"
    ),
    VisualStyle.CORPORATE_PROFESSIONAL: (
        "corporate professional design with business-appropriate colors, "
        "structured grid layout, clean sans-serif typography, "
        "trustworthy and credible appearance"
    ),
    VisualStyle.HAND_DRAWN_ORGANIC: (
        "hand-drawn organic design with sketched illustrated elements, "
        "natural textures, artisanal craft feel, warm imperfect hand-made lines, "
        "authentic character"
    ),
    VisualStyle.NEON_GLOW: (
        "neon glow design with vibrant glowing colors on dark background, "
        "electric lighting effects, cyberpunk-inspired aesthetic, "
        "nightlife energy and excitement"
    ),
    VisualStyle.GRADIENT_MODERN: (
        "modern gradient design with smooth color transitions, "
        "contemporary tech aesthetic, fluid shapes, "
        "fresh and forward-looking appearance"
    ),
    VisualStyle.WATERCOLOR_ARTISTIC: (
        "watercolor artistic design with soft painted textures, "
        "flowing organic shapes, artistic hand-crafted feel, "
        "gentle and creative aesthetic"
    ),
}


# =============================================================================
# MOOD DESCRIPTORS
# =============================================================================

MOOD_DESCRIPTORS: Dict[Mood, str] = {
    Mood.URGENT: "creates strong sense of urgency and immediate action needed, time-sensitive feel",
    Mood.EXCITING: "builds excitement and anticipation, energetic and thrilling atmosphere",
    Mood.CALM: "peaceful and calming visual atmosphere, serene and relaxing",
    Mood.ELEGANT: "sophisticated and refined aesthetic, upscale and tasteful",
    Mood.FRIENDLY: "warm, approachable, and welcoming feel, inviting and accessible",
    Mood.PROFESSIONAL: "business-appropriate and trustworthy, competent and reliable",
    Mood.FESTIVE: "celebratory and joyful atmosphere, party-ready excitement",
    Mood.SERIOUS: "serious and important tone, gravitas and significance",
    Mood.INSPIRATIONAL: "uplifting and motivating feel, aspirational and empowering",
    Mood.ROMANTIC: "romantic and intimate atmosphere, love and warmth",
}


# =============================================================================
# COLOR PALETTE DESCRIPTORS
# =============================================================================

COLOR_PALETTE_DESCRIPTORS: Dict[ColorSchemePreset, str] = {
    ColorSchemePreset.WARM: "warm color palette with reds, oranges, yellows, and warm browns",
    ColorSchemePreset.COOL: "cool color palette with blues, teals, purples, and cool grays",
    ColorSchemePreset.EARTH_TONES: "earthy natural palette with browns, tans, olive greens, and terracotta",
    ColorSchemePreset.NEON: "vibrant neon palette with electric pinks, bright greens, and glowing colors",
    ColorSchemePreset.PASTEL: "soft pastel palette with gentle muted tones, light and airy colors",
    ColorSchemePreset.MONOCHROME: "monochromatic palette with variations of a single color, sophisticated restraint",
    ColorSchemePreset.BLACK_GOLD: "luxurious black and gold palette, premium and elegant",
    ColorSchemePreset.CUSTOM: "",
}


# =============================================================================
# BACKGROUND DESCRIPTORS
# =============================================================================

BACKGROUND_DESCRIPTORS: Dict[BackgroundType, str] = {
    BackgroundType.SOLID: "solid color background, clean and simple",
    BackgroundType.GRADIENT: "gradient background with smooth color transition",
    BackgroundType.TEXTURED: "textured background with subtle visual interest",
    BackgroundType.LIGHT: "light colored background, bright and airy",
    BackgroundType.DARK: "dark colored background, dramatic and bold",
}


# =============================================================================
# ASPECT RATIO INSTRUCTIONS
# =============================================================================

ASPECT_RATIO_INSTRUCTIONS: Dict[AspectRatio, str] = {
    AspectRatio.SQUARE_1_1: "square 1:1 aspect ratio composition",
    AspectRatio.PORTRAIT_4_5: "portrait 4:5 aspect ratio, taller than wide",
    AspectRatio.STORY_9_16: "vertical 9:16 story format, very tall and narrow",
    AspectRatio.LANDSCAPE_16_9: "landscape 16:9 aspect ratio, wide banner format",
    AspectRatio.LETTER: "US letter size 8.5x11 proportions for print",
    AspectRatio.A4: "A4 paper proportions for international print",
}


# =============================================================================
# NEGATIVE PROMPTS - What to avoid (critical for quality)
# =============================================================================

UNIVERSAL_NEGATIVE_PROMPTS = [
    "blurry or fuzzy text",
    "misspelled words",
    "illegible unreadable text",
    "cut-off cropped text",
    "overlapping colliding elements",
    "cluttered busy composition",
    "low resolution pixelated",
    "watermarks",
    "amateur unprofessional design",
    "cheap clipart",
    "cheesy dated effects",
    "excessive drop shadows",
    "word art",
    "stretched distorted images",
    "poor contrast",
    "random floating elements",
    "inconsistent style mixing",
    "too many fonts",
    "unbalanced layout",
]

CATEGORY_NEGATIVE_PROMPTS: Dict[FlyerCategory, List[str]] = {
    FlyerCategory.EVENT: ["boring static composition", "unclear date and time"],
    FlyerCategory.SALE_PROMO: ["subtle hidden pricing", "calm muted urgency", "buried discount"],
    FlyerCategory.RESTAURANT_FOOD: ["unappetizing imagery", "cold sterile colors"],
    FlyerCategory.REAL_ESTATE: ["cluttered property view", "unprofessional layout"],
    FlyerCategory.JOB_POSTING: ["too casual", "unclear position"],
    FlyerCategory.CLASS_WORKSHOP: ["intimidating imagery", "overly complex confusing"],
    FlyerCategory.GRAND_OPENING: ["subdued underwhelming", "no celebration feeling"],
    FlyerCategory.PARTY_CELEBRATION: ["boring serious tone", "corporate stiffness"],
    FlyerCategory.FITNESS_WELLNESS: ["intimidating extreme imagery", "unhealthy appearance"],
    FlyerCategory.NONPROFIT_CHARITY: ["exploitative imagery", "guilt-inducing"],
    FlyerCategory.MUSIC_CONCERT: ["static boring composition", "silent feeling"],
}


# =============================================================================
# TEXT PROMINENCE INSTRUCTIONS
# =============================================================================

TEXT_PROMINENCE_INSTRUCTIONS: Dict[TextProminence, str] = {
    TextProminence.DOMINANT: (
        "Text should be the dominant visual element, large and commanding, "
        "with imagery playing a supporting role in the background or as subtle accents"
    ),
    TextProminence.BALANCED: (
        "Text and imagery should have balanced visual weight, "
        "complementing each other in a harmonious composition"
    ),
    TextProminence.SUBTLE: (
        "Imagery should be the dominant visual element, "
        "with text elegantly integrated but not overpowering the visuals"
    ),
}


# =============================================================================
# IMAGERY TYPE INSTRUCTIONS
# =============================================================================

IMAGERY_TYPE_INSTRUCTIONS: Dict[ImageryType, str] = {
    ImageryType.ILLUSTRATED: "with custom illustrated graphic elements, artistic drawings",
    ImageryType.PHOTO_REALISTIC: "with photo-realistic imagery, lifelike visual elements",
    ImageryType.ABSTRACT_GEOMETRIC: "with abstract geometric shapes and patterns, modern graphic elements",
    ImageryType.PATTERN: "with decorative pattern elements, repeating motifs",
    ImageryType.MINIMAL_TEXT_ONLY: "typography-focused with minimal to no imagery, text as the visual element",
    ImageryType.NO_TEXT: (
        "with NO text or words rendered in the image. "
        "Create a clean design with appropriate empty space where text can be added later. "
        "Do NOT include any text, letters, numbers, or written content."
    ),
}


# =============================================================================
# PROMPT BUILDER CLASS
# =============================================================================

class FlyerPromptBuilder:
    """Builds optimized prompts from structured FlyerProject data"""
    
    def __init__(self, project: FlyerProject):
        self.project = project
    
    def build(self) -> Dict[str, str]:
        """Build complete prompt package"""
        return {
            "main_prompt": self._build_main_prompt(),
            "negative_prompt": self._build_negative_prompt(),
            "aspect_ratio": self.project.output.aspect_ratio.value,
            "model": self.project.output.model,
            "quality": self.project.output.quality,
        }
    
    def _build_main_prompt(self) -> str:
        """Construct the main generation prompt"""
        sections = []
        
        # 1. Core instruction with category context
        category_context = CATEGORY_CONTEXT.get(
            self.project.category,
            "promotional flyer design"
        )
        sections.append(f"Create a professional high-quality {category_context}.")
        
        # 2. Aspect ratio / format
        aspect_instruction = ASPECT_RATIO_INSTRUCTIONS.get(
            self.project.output.aspect_ratio,
            "standard flyer proportions"
        )
        sections.append(f"Format: {aspect_instruction}.")
        
        # 3. Visual style
        style_desc = STYLE_DESCRIPTORS.get(
            self.project.visuals.style,
            "clean professional design"
        )
        sections.append(f"Visual style: {style_desc}.")
        
        # 4. Mood / tone
        mood_desc = MOOD_DESCRIPTORS.get(
            self.project.visuals.mood,
            "appropriate and engaging mood"
        )
        sections.append(f"Mood and tone: {mood_desc}.")
        
        # 5. Color palette
        sections.append(self._build_color_section())

        # 6. Text content (only if not in NO_TEXT mode)
        if self.project.visuals.imagery_type != ImageryType.NO_TEXT:
            sections.append(self._build_text_section())
        else:
            sections.append(
                "IMPORTANT: Do NOT render any text in this image. "
                "Leave clean space for text to be added using external design tools like Canva or Photoshop."
            )

        # 7. Text prominence (skip for NO_TEXT mode)
        if self.project.visuals.imagery_type != ImageryType.NO_TEXT:
            prominence_instruction = TEXT_PROMINENCE_INSTRUCTIONS.get(
                self.project.visuals.text_prominence,
                ""
            )
            if prominence_instruction:
                sections.append(f"IMPORTANT: {prominence_instruction}.")
        
        # 8. Imagery type
        imagery_instruction = IMAGERY_TYPE_INSTRUCTIONS.get(
            self.project.visuals.imagery_type,
            ""
        )
        if imagery_instruction:
            sections.append(f"Visual elements {imagery_instruction}.")
        
        # 9. Specific elements to include
        if self.project.visuals.include_elements:
            elements = ", ".join(self.project.visuals.include_elements)
            sections.append(f"Include visual elements such as: {elements}.")
        
        # 10. Category-specific hints
        sections.append(self._build_category_hints())
        
        # 11. Target audience
        if self.project.target_audience:
            sections.append(f"Design should appeal to: {self.project.target_audience}.")
        
        # 12. Special instructions
        if self.project.special_instructions:
            sections.append(f"Additional requirements: {self.project.special_instructions}.")

        # 13. Logo integration (if provided)
        if self.project.logo_path:
            sections.append(
                "IMPORTANT: Incorporate the provided logo image into the flyer design. "
                "Place it prominently but tastefully, ensuring it is clearly visible and "
                "integrates well with the overall design. The logo should be positioned "
                "appropriately (typically top or bottom of the flyer) without overwhelming "
                "the main content."
            )

        # 14. Quality reminders (conditional based on NO_TEXT mode)
        if self.project.visuals.imagery_type != ImageryType.NO_TEXT:
            sections.append(
                "CRITICAL TEXT REQUIREMENTS: "
                "All text must be spelled EXACTLY as specified above - double-check every letter. "
                "Do not paraphrase, abbreviate, or modify any text. "
                "Ensure all text is crisp, clear, and perfectly legible. "
                "Professional print-ready quality. "
                "Visually striking and memorable design. "
                "Balanced composition with clear visual hierarchy."
            )
        else:
            sections.append(
                "CRITICAL: This design must have NO TEXT whatsoever. "
                "No letters, words, numbers, or written content of any kind. "
                "Create empty space in key areas where text can be overlaid later. "
                "Professional print-ready quality. "
                "Visually striking and memorable design. "
                "Balanced composition suitable for text overlay."
            )
        
        return " ".join([s for s in sections if s])
    
    def _build_color_section(self) -> str:
        """Build color palette instructions"""
        parts = []
        
        # Preset palette
        palette_desc = COLOR_PALETTE_DESCRIPTORS.get(
            self.project.colors.preset,
            ""
        )
        if palette_desc:
            parts.append(f"Color scheme: {palette_desc}.")
        
        # Specific colors
        color_specs = []
        if self.project.colors.primary_color:
            color_specs.append(f"primary: {self.project.colors.primary_color}")
        if self.project.colors.secondary_color:
            color_specs.append(f"secondary: {self.project.colors.secondary_color}")
        if self.project.colors.accent_color:
            color_specs.append(f"accent: {self.project.colors.accent_color}")
        
        if color_specs:
            parts.append(f"Specific colors: {', '.join(color_specs)}.")
        
        # Background
        if self.project.colors.gradient_colors:
            gradient = " to ".join(self.project.colors.gradient_colors)
            parts.append(f"Background: gradient from {gradient}.")
        elif self.project.colors.background_color:
            bg_type_desc = BACKGROUND_DESCRIPTORS.get(
                self.project.colors.background_type,
                ""
            )
            parts.append(f"Background: {self.project.colors.background_color} {bg_type_desc}.")
        else:
            bg_desc = BACKGROUND_DESCRIPTORS.get(
                self.project.colors.background_type,
                ""
            )
            if bg_desc:
                parts.append(f"Background: {bg_desc}.")
        
        return " ".join(parts)
    
    def _spell_out(self, text: str) -> str:
        """Return character-by-character spelling for emphasis."""
        return " ".join(list(text))

    def _chunk_text(self, text: str, max_words: int = 5) -> list:
        """Split text into smaller chunks for better spelling accuracy."""
        words = text.split()
        chunks = []
        for i in range(0, len(words), max_words):
            chunk = " ".join(words[i:i + max_words])
            chunks.append(chunk)
        return chunks

    def _build_text_section(self) -> str:
        """Build text content instructions with spelling emphasis"""
        text = self.project.text_content
        parts = []

        parts.append("TEXT CONTENT - CRITICAL: Spell ALL text EXACTLY as shown, letter by letter:")

        # Headline - most important, with character-by-character spelling
        if text.headline:
            spelled = self._spell_out(text.headline.upper())
            parts.append(
                f'MAIN HEADLINE must read EXACTLY: "{text.headline}" '
                f'(SPELLING: {spelled}) - '
                f"this should be the most visually dominant text element. "
                f"Double-check every letter is correct."
            )

        # Subheadline - chunk long text for better accuracy
        if text.subheadline:
            if len(text.subheadline.split()) > 8:
                parts.append('Secondary headline (display across multiple lines if needed):')
                for chunk in self._chunk_text(text.subheadline, 5):
                    spelled = self._spell_out(chunk)
                    parts.append(f'  Line: "{chunk}" (SPELLING: {spelled}).')
            else:
                spelled = self._spell_out(text.subheadline)
                parts.append(f'Secondary headline must read EXACTLY: "{text.subheadline}" (SPELLING: {spelled}).')

        # Body text - chunk long text for better accuracy
        if text.body_text:
            if len(text.body_text.split()) > 10:
                parts.append('Body content (display across multiple lines/sections):')
                for chunk in self._chunk_text(text.body_text, 8):
                    spelled = self._spell_out(chunk)
                    parts.append(f'  Section: "{chunk}" (SPELLING: {spelled}).')
            else:
                spelled = self._spell_out(text.body_text)
                parts.append(f'Body text must read EXACTLY: "{text.body_text}" (SPELLING: {spelled}).')

        # Date and time
        if text.date and text.time:
            combined = f"{text.date} | {text.time}"
            spelled = self._spell_out(combined)
            parts.append(f'Date/time must read EXACTLY: "{combined}" (SPELLING: {spelled}).')
        elif text.date:
            spelled = self._spell_out(text.date)
            parts.append(f'Date must read EXACTLY: "{text.date}" (SPELLING: {spelled}).')
        elif text.time:
            spelled = self._spell_out(text.time)
            parts.append(f'Time must read EXACTLY: "{text.time}" (SPELLING: {spelled}).')

        # Location - simplify address by removing redundant country for US addresses
        address = text.address
        if address:
            for suffix in [", United States", ", USA", ", US"]:
                if address.endswith(suffix):
                    address = address[:-len(suffix)]
                    break

        if text.venue_name and address:
            location = f"{text.venue_name} - {address}"
            spelled = self._spell_out(location)
            parts.append(f'Location must read EXACTLY: "{location}" (SPELLING: {spelled}).')
        elif text.venue_name:
            spelled = self._spell_out(text.venue_name)
            parts.append(f'Venue must read EXACTLY: "{text.venue_name}" (SPELLING: {spelled}).')
        elif address:
            spelled = self._spell_out(address)
            parts.append(f'Address must read EXACTLY: "{address}" (SPELLING: {spelled}).')

        # Price / Discount
        if text.discount_text:
            spelled = self._spell_out(text.discount_text)
            parts.append(
                f'Discount/offer must read EXACTLY: "{text.discount_text}" (SPELLING: {spelled}) - '
                f"make this eye-catching and prominent."
            )
        elif text.price:
            spelled = self._spell_out(text.price)
            parts.append(f'Price must read EXACTLY: "{text.price}" (SPELLING: {spelled}).')

        # CTA
        if text.cta_text:
            spelled = self._spell_out(text.cta_text)
            parts.append(f'Call-to-action must read EXACTLY: "{text.cta_text}" (SPELLING: {spelled}).')

        # Contact info - each with individual spelling
        if text.phone:
            spelled = self._spell_out(text.phone)
            parts.append(f'Phone must read EXACTLY: "{text.phone}" (SPELLING: {spelled}).')
        if text.email:
            spelled = self._spell_out(text.email)
            parts.append(f'Email must read EXACTLY: "{text.email}" (SPELLING: {spelled}).')
        if text.website:
            spelled = self._spell_out(text.website)
            parts.append(f'Website must read EXACTLY: "{text.website}" (SPELLING: {spelled}).')
        if text.social_handle:
            spelled = self._spell_out(text.social_handle)
            parts.append(f'Social handle must read EXACTLY: "{text.social_handle}" (SPELLING: {spelled}).')

        # Additional info
        if text.additional_info:
            for info_item in text.additional_info:
                spelled = self._spell_out(info_item)
                parts.append(f'Additional detail must read EXACTLY: "{info_item}" (SPELLING: {spelled}).')

        # Fine print - chunk long text for better accuracy
        if text.fine_print:
            if len(text.fine_print.split()) > 8:
                parts.append('Fine print (can span multiple lines):')
                for chunk in self._chunk_text(text.fine_print, 5):
                    spelled = self._spell_out(chunk)
                    parts.append(f'  Line: "{chunk}" (SPELLING: {spelled}).')
            else:
                spelled = self._spell_out(text.fine_print)
                parts.append(f'Fine print must read EXACTLY: "{text.fine_print}" (SPELLING: {spelled}).')

        return " ".join(parts)
    
    def _build_category_hints(self) -> str:
        """Build category-specific design hints"""
        hints = []
        
        # Sale/promo specific
        if self.project.category == FlyerCategory.SALE_PROMO:
            if self.project.text_content.discount_text:
                hints.append("Ensure discount/offer is immediately visible and attention-grabbing.")
        
        # Event specific
        if self.project.category == FlyerCategory.EVENT:
            if self.project.text_content.date:
                hints.append("Date and time should be clearly visible and easy to find.")
        
        # Grand opening specific
        if self.project.category == FlyerCategory.GRAND_OPENING:
            hints.append("Convey excitement and celebration of a new beginning.")
        
        return " ".join(hints)
    
    def _build_negative_prompt(self) -> str:
        """Build negative prompt (what to avoid)"""
        negatives = UNIVERSAL_NEGATIVE_PROMPTS.copy()
        
        # Add category-specific negatives
        category_negatives = CATEGORY_NEGATIVE_PROMPTS.get(self.project.category, [])
        negatives.extend(category_negatives)
        
        # Add user-specified avoidances
        if self.project.visuals.avoid_elements:
            negatives.extend(self.project.visuals.avoid_elements)
        
        return ", ".join(negatives)


# =============================================================================
# REFINEMENT BUILDER - For iterating on generated results
# =============================================================================

class RefinementPromptBuilder:
    """Builds refinement prompts based on user feedback"""
    
    # Common feedback patterns and their prompt modifications
    FEEDBACK_PATTERNS = {
        "bigger text": "larger, more prominent text that commands attention",
        "larger text": "larger, more prominent text that commands attention",
        "can't read": "larger, more prominent text with better contrast for readability",
        "more readable": "clearer, more legible text with improved contrast",
        "too busy": "simplified composition with more white space and less clutter",
        "cluttered": "cleaner, more organized layout with breathing room",
        "too much": "simplified design with fewer elements",
        "cleaner": "more minimalist design with cleaner composition",
        "boring": "more dynamic and visually exciting composition",
        "plain": "more visually interesting design with engaging elements",
        "more exciting": "more dynamic, energetic, and attention-grabbing design",
        "brighter": "more vibrant and colorful palette with higher saturation",
        "more color": "richer, more colorful design with varied hues",
        "vibrant": "bold, saturated colors with high visual impact",
        "darker": "deeper, moodier color treatment",
        "muted": "more subtle and restrained color palette",
        "subtle": "more understated and refined visual treatment",
        "professional": "more polished, business-appropriate aesthetic",
        "corporate": "more formal, corporate-style design",
        "serious": "more professional and serious tone",
        "fun": "more playful and casual feel",
        "playful": "more whimsical and fun design elements",
        "casual": "more relaxed and approachable aesthetic",
        "modern": "more contemporary and current design style",
        "dynamic": "more energetic layout with visual movement",
    }
    
    @classmethod
    def build_refinement(cls, original_prompt: str, user_feedback: str) -> str:
        """Build refined prompt based on user feedback"""
        feedback_lower = user_feedback.lower()
        modifications = []
        
        # Check for matching patterns
        for pattern, modification in cls.FEEDBACK_PATTERNS.items():
            if pattern in feedback_lower:
                modifications.append(modification)
        
        # Build the refined prompt
        if modifications:
            mod_string = ", ".join(set(modifications))  # Remove duplicates
            return (
                f"{original_prompt}\n\n"
                f"IMPORTANT MODIFICATIONS: Apply these changes: {mod_string}."
            )
        else:
            # Fallback: append raw feedback
            return (
                f"{original_prompt}\n\n"
                f"IMPORTANT CHANGES REQUESTED: {user_feedback}"
            )


# =============================================================================
# TEST / DEMO
# =============================================================================

if __name__ == "__main__":
    # Example: Create a sale promo flyer
    from models import TextContent, ColorSettings, VisualSettings, OutputSettings
    
    project = FlyerProject(
        category=FlyerCategory.SALE_PROMO,
        text_content=TextContent(
            headline="MEGA WEEKEND SALE",
            subheadline="Everything Must Go",
            date="December 14-15",
            time="10 AM - 8 PM",
            venue_name="MegaStore",
            address="123 Main Street, Downtown",
            discount_text="UP TO 70% OFF",
            cta_text="Shop Now!",
            website="www.megastore.com",
            additional_info=["Free parking", "Refreshments available"],
            fine_print="While supplies last. Some exclusions apply."
        ),
        colors=ColorSettings(
            preset=ColorSchemePreset.WARM,
            primary_color="red",
            accent_color="yellow",
            background_type=BackgroundType.LIGHT
        ),
        visuals=VisualSettings(
            style=VisualStyle.BOLD_VIBRANT,
            mood=Mood.URGENT,
            text_prominence=TextProminence.DOMINANT,
            imagery_type=ImageryType.ILLUSTRATED,
            include_elements=["sale tags", "shopping bags", "burst shapes"],
            avoid_elements=["people faces", "stock photo feel"]
        ),
        output=OutputSettings(
            aspect_ratio=AspectRatio.PORTRAIT_4_5,
            quality="hd",
            model="gpt-image-1"
        ),
        target_audience="bargain hunters and families",
        special_instructions="Instagram post and print flyer for storefront"
    )
    
    builder = FlyerPromptBuilder(project)
    result = builder.build()
    
    print("=" * 70)
    print("MAIN PROMPT:")
    print("=" * 70)
    print(result["main_prompt"])
    print()
    print("=" * 70)
    print("NEGATIVE PROMPT:")
    print("=" * 70)
    print(result["negative_prompt"])
    print()
    print(f"Aspect Ratio: {result['aspect_ratio']}")
    print(f"Model: {result['model']}")
    print(f"Quality: {result['quality']}")
