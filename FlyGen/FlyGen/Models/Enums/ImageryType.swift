import Foundation

enum ImageryType: String, CaseIterable, Codable, Identifiable {
    case illustrated = "illustrated"
    case photoRealistic = "photo_realistic"
    case abstractGeometric = "abstract_geometric"
    case pattern = "pattern"
    case minimalTextOnly = "minimal_text_only"
    case noText = "no_text"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .illustrated: return "Illustrated"
        case .photoRealistic: return "Photo Realistic"
        case .abstractGeometric: return "Abstract / Geometric"
        case .pattern: return "Pattern"
        case .minimalTextOnly: return "Minimal (Text Focus)"
        case .noText: return "No Text (Image Only)"
        }
    }

    var description: String {
        switch self {
        case .illustrated: return "Custom illustrated graphics"
        case .photoRealistic: return "Lifelike imagery"
        case .abstractGeometric: return "Modern geometric shapes"
        case .pattern: return "Decorative patterns"
        case .minimalTextOnly: return "Typography focused"
        case .noText: return "Clean design for text overlay later"
        }
    }

    var icon: String {
        switch self {
        case .illustrated: return "paintbrush"
        case .photoRealistic: return "camera"
        case .abstractGeometric: return "triangle"
        case .pattern: return "square.grid.2x2"
        case .minimalTextOnly: return "textformat"
        case .noText: return "photo"
        }
    }
}
