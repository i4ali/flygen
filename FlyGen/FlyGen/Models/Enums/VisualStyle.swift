import Foundation

enum VisualStyle: String, CaseIterable, Codable, Identifiable {
    case modernMinimal = "modern_minimal"
    case boldVibrant = "bold_vibrant"
    case elegantLuxury = "elegant_luxury"
    case retroVintage = "retro_vintage"
    case playfulFun = "playful_fun"
    case corporateProfessional = "corporate_professional"
    case handDrawnOrganic = "hand_drawn_organic"
    case neonGlow = "neon_glow"
    case gradientModern = "gradient_modern"
    case watercolorArtistic = "watercolor_artistic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .modernMinimal: return "Modern & Minimal"
        case .boldVibrant: return "Bold & Vibrant"
        case .elegantLuxury: return "Elegant & Luxury"
        case .retroVintage: return "Retro / Vintage"
        case .playfulFun: return "Playful & Fun"
        case .corporateProfessional: return "Corporate / Professional"
        case .handDrawnOrganic: return "Hand-drawn & Organic"
        case .neonGlow: return "Neon Glow"
        case .gradientModern: return "Gradient Modern"
        case .watercolorArtistic: return "Watercolor Artistic"
        }
    }

    var icon: String {
        switch self {
        case .modernMinimal: return "square"
        case .boldVibrant: return "flame"
        case .elegantLuxury: return "crown"
        case .retroVintage: return "radio"
        case .playfulFun: return "paintpalette"
        case .corporateProfessional: return "building.2"
        case .handDrawnOrganic: return "pencil.and.outline"
        case .neonGlow: return "lightbulb"
        case .gradientModern: return "circle.lefthalf.filled"
        case .watercolorArtistic: return "drop"
        }
    }
}
