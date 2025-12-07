import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case urgent = "urgent"
    case exciting = "exciting"
    case calm = "calm"
    case elegant = "elegant"
    case friendly = "friendly"
    case professional = "professional"
    case festive = "festive"
    case serious = "serious"
    case inspirational = "inspirational"
    case romantic = "romantic"
    case somber = "somber"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .urgent: return "Urgent (Act Now!)"
        case .exciting: return "Exciting & Energetic"
        case .calm: return "Calm & Peaceful"
        case .elegant: return "Elegant & Sophisticated"
        case .friendly: return "Friendly & Welcoming"
        case .professional: return "Professional"
        case .festive: return "Festive & Celebratory"
        case .serious: return "Serious & Important"
        case .inspirational: return "Inspirational"
        case .romantic: return "Romantic"
        case .somber: return "Somber & Reflective"
        }
    }

    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.circle"
        case .exciting: return "bolt"
        case .calm: return "leaf"
        case .elegant: return "sparkles"
        case .friendly: return "hand.wave"
        case .professional: return "briefcase"
        case .festive: return "party.popper"
        case .serious: return "exclamationmark.triangle"
        case .inspirational: return "sun.max"
        case .romantic: return "heart"
        case .somber: return "moon.stars"
        }
    }
}
