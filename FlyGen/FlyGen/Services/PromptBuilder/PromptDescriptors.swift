import Foundation

/// All the descriptor dictionaries ported from Python prompt_builder.py
struct PromptDescriptors {

    // MARK: - Category Context

    static let categoryContext: [FlyerCategory: String] = [
        .event: "event promotional flyer design",
        .salePromo: "sale and promotion flyer with urgency-driving design elements",
        .announcement: "announcement flyer with clear information hierarchy",
        .restaurantFood: "restaurant or food service promotional flyer with appetizing appeal",
        .realEstate: "real estate listing flyer with professional property showcase",
        .jobPosting: "job recruitment flyer with professional yet approachable design",
        .classWorkshop: "educational class or workshop promotional flyer",
        .grandOpening: "grand opening celebration flyer with festive excitement",
        .partyCelebration: "party or celebration event flyer with fun energetic design",
        .fitnessWellness: "fitness or wellness promotional flyer with energizing appeal",
        .nonprofitCharity: "nonprofit or charity flyer with heartfelt community appeal",
        .musicConcert: "music event or concert flyer with dynamic artistic style"
    ]

    // MARK: - Style Descriptors

    static let styleDescriptors: [VisualStyle: String] = [
        .modernMinimal: """
            modern minimalist design with clean lines, generous white space, \
            contemporary sans-serif typography aesthetic, uncluttered composition, \
            sophisticated simplicity
            """,
        .boldVibrant: """
            bold vibrant design with strong saturated colors, high contrast, \
            impactful heavy typography, energetic dynamic composition, \
            eye-catching visual punch
            """,
        .elegantLuxury: """
            elegant luxury design with sophisticated muted color palette, \
            refined serif typography, premium high-end feel, subtle gold or metallic accents, \
            tasteful restraint
            """,
        .retroVintage: """
            retro vintage design with nostalgic color palette, classic typography, \
            aged paper textures, throwback aesthetic from mid-century era, \
            warm nostalgic feeling
            """,
        .playfulFun: """
            playful fun design with bright cheerful colors, rounded friendly shapes, \
            whimsical illustrated elements, bouncy typography, \
            joyful energetic composition
            """,
        .corporateProfessional: """
            corporate professional design with business-appropriate colors, \
            structured grid layout, clean sans-serif typography, \
            trustworthy and credible appearance
            """,
        .handDrawnOrganic: """
            hand-drawn organic design with sketched illustrated elements, \
            natural textures, artisanal craft feel, warm imperfect hand-made lines, \
            authentic character
            """,
        .neonGlow: """
            neon glow design with vibrant glowing colors on dark background, \
            electric lighting effects, cyberpunk-inspired aesthetic, \
            nightlife energy and excitement
            """,
        .gradientModern: """
            modern gradient design with smooth color transitions, \
            contemporary tech aesthetic, fluid shapes, \
            fresh and forward-looking appearance
            """,
        .watercolorArtistic: """
            watercolor artistic design with soft painted textures, \
            flowing organic shapes, artistic hand-crafted feel, \
            gentle and creative aesthetic
            """
    ]

    // MARK: - Mood Descriptors

    static let moodDescriptors: [Mood: String] = [
        .urgent: "creates strong sense of urgency and immediate action needed, time-sensitive feel",
        .exciting: "builds excitement and anticipation, energetic and thrilling atmosphere",
        .calm: "peaceful and calming visual atmosphere, serene and relaxing",
        .elegant: "sophisticated and refined aesthetic, upscale and tasteful",
        .friendly: "warm, approachable, and welcoming feel, inviting and accessible",
        .professional: "business-appropriate and trustworthy, competent and reliable",
        .festive: "celebratory and joyful atmosphere, party-ready excitement",
        .serious: "serious and important tone, gravitas and significance",
        .inspirational: "uplifting and motivating feel, aspirational and empowering",
        .romantic: "romantic and intimate atmosphere, love and warmth",
        .somber: "somber and reflective atmosphere, melancholic and contemplative, respectful memorial tone"
    ]

    // MARK: - Color Palette Descriptors

    static let colorPaletteDescriptors: [ColorSchemePreset: String] = [
        .warm: "warm color palette with reds, oranges, yellows, and warm browns",
        .cool: "cool color palette with blues, teals, purples, and cool grays",
        .earthTones: "earthy natural palette with browns, tans, olive greens, and terracotta",
        .neon: "vibrant neon palette with electric pinks, bright greens, and glowing colors",
        .pastel: "soft pastel palette with gentle muted tones, light and airy colors",
        .monochrome: "monochromatic palette with variations of a single color, sophisticated restraint",
        .blackGold: "luxurious black and gold palette, premium and elegant",
        .custom: ""
    ]

    // MARK: - Background Descriptors

    static let backgroundDescriptors: [BackgroundType: String] = [
        .solid: "solid color background, clean and simple",
        .gradient: "gradient background with smooth color transition",
        .textured: "textured background with subtle visual interest",
        .light: "light colored background, bright and airy",
        .dark: "dark colored background, dramatic and bold"
    ]

    // MARK: - Aspect Ratio Instructions

    static let aspectRatioInstructions: [AspectRatio: String] = [
        .square: "square 1:1 aspect ratio composition",
        .portrait: "portrait 4:5 aspect ratio, taller than wide",
        .story: "vertical 9:16 story format, very tall and narrow",
        .landscape: "landscape 16:9 aspect ratio, wide banner format",
        .letter: "US letter size 8.5x11 proportions for print",
        .a4: "A4 paper proportions for international print"
    ]

    // MARK: - Text Prominence Instructions

    static let textProminenceInstructions: [TextProminence: String] = [
        .dominant: """
            Text should be the dominant visual element, large and commanding, \
            with imagery playing a supporting role in the background or as subtle accents
            """,
        .balanced: """
            Text and imagery should have balanced visual weight, \
            complementing each other in a harmonious composition
            """,
        .subtle: """
            Imagery should be the dominant visual element, \
            with text elegantly integrated but not overpowering the visuals
            """
    ]

    // MARK: - Imagery Type Instructions

    static let imageryTypeInstructions: [ImageryType: String] = [
        .illustrated: "with custom illustrated graphic elements, artistic drawings",
        .photoRealistic: "with photo-realistic imagery, lifelike visual elements",
        .abstractGeometric: "with abstract geometric shapes and patterns, modern graphic elements",
        .pattern: "with decorative pattern elements, repeating motifs",
        .minimalTextOnly: "typography-focused with minimal to no imagery, text as the visual element",
        .noText: """
            with NO text or words rendered in the image. \
            Create a clean design with appropriate empty space where text can be added later. \
            Do NOT include any text, letters, numbers, or written content.
            """
    ]
}
