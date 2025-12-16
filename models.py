"""
Data Models for Flyer Generation

These models represent the structured data collected through the app UI.
Each field maps to a screen or input element in the app.
"""
from dataclasses import dataclass, field
from typing import Optional, List, Dict
from enum import Enum


# =============================================================================
# ENUMS - These become picker/selection UI elements in the app
# =============================================================================

class FlyerCategory(Enum):
    """What type of flyer? (Card/Grid selection)"""
    EVENT = "event"
    SALE_PROMO = "sale_promo"
    ANNOUNCEMENT = "announcement"
    RESTAURANT_FOOD = "restaurant_food"
    REAL_ESTATE = "real_estate"
    JOB_POSTING = "job_posting"
    CLASS_WORKSHOP = "class_workshop"
    GRAND_OPENING = "grand_opening"
    PARTY_CELEBRATION = "party_celebration"
    FITNESS_WELLNESS = "fitness_wellness"
    NONPROFIT_CHARITY = "nonprofit_charity"
    MUSIC_CONCERT = "music_concert"
    
    @property
    def display_name(self) -> str:
        names = {
            "event": "Event",
            "sale_promo": "Sale / Promotion",
            "announcement": "Announcement",
            "restaurant_food": "Restaurant / Food",
            "real_estate": "Real Estate",
            "job_posting": "Job Posting",
            "class_workshop": "Class / Workshop",
            "grand_opening": "Grand Opening",
            "party_celebration": "Party / Celebration",
            "fitness_wellness": "Fitness / Wellness",
            "nonprofit_charity": "Nonprofit / Charity",
            "music_concert": "Music / Concert",
        }
        return names.get(self.value, self.value)


class VisualStyle(Enum):
    """Style picker - visual cards showing each style"""
    MODERN_MINIMAL = "modern_minimal"
    BOLD_VIBRANT = "bold_vibrant"
    ELEGANT_LUXURY = "elegant_luxury"
    RETRO_VINTAGE = "retro_vintage"
    PLAYFUL_FUN = "playful_fun"
    CORPORATE_PROFESSIONAL = "corporate_professional"
    HAND_DRAWN_ORGANIC = "hand_drawn_organic"
    NEON_GLOW = "neon_glow"
    GRADIENT_MODERN = "gradient_modern"
    WATERCOLOR_ARTISTIC = "watercolor_artistic"
    
    @property
    def display_name(self) -> str:
        return self.value.replace("_", " ").title()


class Mood(Enum):
    """Mood/Tone selector"""
    URGENT = "urgent"
    EXCITING = "exciting"
    CALM = "calm"
    ELEGANT = "elegant"
    FRIENDLY = "friendly"
    PROFESSIONAL = "professional"
    FESTIVE = "festive"
    SERIOUS = "serious"
    INSPIRATIONAL = "inspirational"
    ROMANTIC = "romantic"
    
    @property
    def display_name(self) -> str:
        return self.value.title()


class AspectRatio(Enum):
    """Size/Format picker"""
    SQUARE_1_1 = "1:1"
    PORTRAIT_4_5 = "4:5"
    STORY_9_16 = "9:16"
    LANDSCAPE_16_9 = "16:9"
    LETTER = "letter"
    A4 = "a4"
    
    @property
    def display_name(self) -> str:
        names = {
            "1:1": "Square (1:1) - Instagram",
            "4:5": "Portrait (4:5) - Instagram",
            "9:16": "Story (9:16) - Stories/Reels",
            "16:9": "Landscape (16:9) - Banner",
            "letter": "Letter (8.5x11) - Print",
            "a4": "A4 - International Print",
        }
        return names.get(self.value, self.value)


class ColorSchemePreset(Enum):
    """Predefined color palettes"""
    WARM = "warm"
    COOL = "cool"
    EARTH_TONES = "earth_tones"
    NEON = "neon"
    PASTEL = "pastel"
    MONOCHROME = "monochrome"
    BLACK_GOLD = "black_gold"
    CUSTOM = "custom"


class BackgroundType(Enum):
    """Background style"""
    SOLID = "solid"
    GRADIENT = "gradient"
    TEXTURED = "textured"
    LIGHT = "light"
    DARK = "dark"


class TextProminence(Enum):
    """How prominent should text be vs imagery"""
    DOMINANT = "dominant"      # Text is the star
    BALANCED = "balanced"      # Equal weight
    SUBTLE = "subtle"          # Imagery dominant


class ImageryType(Enum):
    """Type of visual elements"""
    ILLUSTRATED = "illustrated"
    PHOTO_REALISTIC = "photo_realistic"
    ABSTRACT_GEOMETRIC = "abstract_geometric"
    PATTERN = "pattern"
    MINIMAL_TEXT_ONLY = "minimal_text_only"
    NO_TEXT = "no_text"  # Generate without text for manual overlay


class FlyerLanguage(Enum):
    """Output language for flyer text"""
    ENGLISH = "en"
    SPANISH = "es"
    URDU = "ur"
    ARABIC = "ar"
    CHINESE = "zh"

    @property
    def display_name(self) -> str:
        names = {
            "en": "English",
            "es": "Español (Spanish)",
            "ur": "اردو (Urdu)",
            "ar": "العربية (Arabic)",
            "zh": "中文 (Chinese)",
        }
        return names.get(self.value, self.value)

    @property
    def prompt_instruction(self) -> str:
        instructions = {
            "en": "Generate all text content in English.",
            "es": "Generate all text content in Spanish (Español). Translate headlines, descriptions, and calls-to-action to Spanish. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided. If the user provides text in another language, translate it to Spanish while preserving the intended meaning and tone.",
            "ur": "Generate all text content in Urdu (اردو). Use Nastaliq script. Render Urdu text right-to-left. Translate headlines, descriptions, and calls-to-action to Urdu. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Urdu while preserving the intended meaning and tone.",
            "ar": "Generate all text content in Arabic (العربية). Render Arabic text right-to-left. Translate headlines, descriptions, and calls-to-action to Arabic. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided in left-to-right order. If the user provides text in another language, translate it to Arabic while preserving the intended meaning and tone.",
            "zh": "Generate all text content in Simplified Chinese (简体中文). Translate headlines, descriptions, and calls-to-action to Chinese. DO NOT translate addresses, phone numbers, emails, or URLs - keep them exactly as provided. If the user provides text in another language, translate it to Chinese while preserving the intended meaning and tone.",
        }
        return instructions.get(self.value, "")


# =============================================================================
# DATA CLASSES - Structured data collected from user
# =============================================================================

@dataclass
class TextContent:
    """All text elements for the flyer"""
    headline: str = ""
    subheadline: Optional[str] = None
    body_text: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    venue_name: Optional[str] = None
    address: Optional[str] = None
    price: Optional[str] = None
    discount_text: Optional[str] = None
    cta_text: Optional[str] = None  # Call to action
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    social_handle: Optional[str] = None
    additional_info: Optional[List[str]] = None
    fine_print: Optional[str] = None


@dataclass
class ColorSettings:
    """Color preferences"""
    preset: ColorSchemePreset = ColorSchemePreset.WARM
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    accent_color: Optional[str] = None
    background_type: BackgroundType = BackgroundType.LIGHT
    background_color: Optional[str] = None
    gradient_colors: Optional[List[str]] = None


@dataclass
class VisualSettings:
    """Visual style preferences"""
    style: VisualStyle = VisualStyle.MODERN_MINIMAL
    mood: Mood = Mood.FRIENDLY
    text_prominence: TextProminence = TextProminence.BALANCED
    imagery_type: ImageryType = ImageryType.ILLUSTRATED
    include_elements: Optional[List[str]] = None
    avoid_elements: Optional[List[str]] = None


@dataclass
class OutputSettings:
    """Output format settings"""
    aspect_ratio: AspectRatio = AspectRatio.PORTRAIT_4_5
    quality: str = "hd"
    model: str = "nano-banana"


@dataclass
class QRCodeSettings:
    """QR code configuration for flyer"""
    enabled: bool = False
    url: str = ""  # URL to encode in QR code


@dataclass
class FlyerProject:
    """Complete flyer project specification"""
    category: FlyerCategory
    language: FlyerLanguage = FlyerLanguage.ENGLISH
    text_content: TextContent = field(default_factory=TextContent)
    colors: ColorSettings = field(default_factory=ColorSettings)
    visuals: VisualSettings = field(default_factory=VisualSettings)
    output: OutputSettings = field(default_factory=OutputSettings)
    target_audience: Optional[str] = None
    special_instructions: Optional[str] = None
    logo_path: Optional[str] = None  # Path to brand logo image
    user_photo_path: Optional[str] = None  # Path to user's uploaded photo
    imagery_description: Optional[str] = None  # Text description for AI-generated imagery
    qr_settings: Optional[QRCodeSettings] = None  # QR code configuration


# =============================================================================
# CATEGORY-SPECIFIC CONFIGURATIONS
# =============================================================================

# Which text fields are relevant for each category
# NOTE: iOS uses scheduleEntries for EVENT/CLASS_WORKSHOP; Python uses date as equivalent
CATEGORY_TEXT_FIELDS: Dict[FlyerCategory, List[str]] = {
    FlyerCategory.EVENT: ["headline", "subheadline", "date", "venue_name", "address", "cta_text", "website"],
    FlyerCategory.SALE_PROMO: ["headline", "subheadline", "discount_text", "date", "address", "cta_text", "fine_print", "website"],
    FlyerCategory.ANNOUNCEMENT: ["headline", "subheadline", "body_text", "date", "cta_text"],
    FlyerCategory.RESTAURANT_FOOD: ["headline", "subheadline", "venue_name", "address", "phone", "website", "price", "cta_text"],
    FlyerCategory.REAL_ESTATE: ["headline", "price", "address", "body_text", "phone", "email", "website"],
    FlyerCategory.JOB_POSTING: ["headline", "subheadline", "body_text", "cta_text", "email", "website"],
    FlyerCategory.CLASS_WORKSHOP: ["headline", "subheadline", "date", "venue_name", "price", "cta_text"],
    FlyerCategory.GRAND_OPENING: ["headline", "subheadline", "body_text", "date", "time", "venue_name", "address", "discount_text", "cta_text", "phone", "website"],
    FlyerCategory.PARTY_CELEBRATION: ["headline", "subheadline", "date", "time", "venue_name", "address", "cta_text", "phone"],
    FlyerCategory.FITNESS_WELLNESS: ["headline", "subheadline", "date", "time", "venue_name", "address", "price", "discount_text", "cta_text", "phone"],
    FlyerCategory.NONPROFIT_CHARITY: ["headline", "subheadline", "body_text", "date", "time", "venue_name", "address", "cta_text", "phone", "email", "website"],
    FlyerCategory.MUSIC_CONCERT: ["headline", "subheadline", "date", "time", "venue_name", "address", "price", "cta_text", "website"],
}

# Suggested visual elements by category
CATEGORY_SUGGESTED_ELEMENTS: Dict[FlyerCategory, List[str]] = {
    FlyerCategory.EVENT: ["decorative borders", "event-themed graphics"],
    FlyerCategory.SALE_PROMO: ["sale tags", "burst shapes", "percentage badges", "shopping bags"],
    FlyerCategory.RESTAURANT_FOOD: ["food imagery", "utensils", "plate arrangements"],
    FlyerCategory.REAL_ESTATE: ["property silhouette", "key motifs", "house icons"],
    FlyerCategory.JOB_POSTING: ["professional icons", "growth arrows", "team silhouettes"],
    FlyerCategory.CLASS_WORKSHOP: ["learning icons", "notebook motifs", "lightbulb"],
    FlyerCategory.GRAND_OPENING: ["ribbon cutting", "celebration confetti", "grand banner"],
    FlyerCategory.PARTY_CELEBRATION: ["balloons", "confetti", "party decorations"],
    FlyerCategory.FITNESS_WELLNESS: ["fitness silhouettes", "wellness symbols", "nature elements"],
    FlyerCategory.NONPROFIT_CHARITY: ["helping hands", "heart motifs", "community symbols"],
    FlyerCategory.MUSIC_CONCERT: ["musical notes", "instruments", "sound waves", "stage lights"],
}
