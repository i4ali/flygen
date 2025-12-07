import Foundation

enum BackgroundType: String, CaseIterable, Codable, Identifiable {
    case solid = "solid"
    case gradient = "gradient"
    case textured = "textured"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solid: return "Solid Color"
        case .gradient: return "Gradient"
        case .textured: return "Textured"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .solid: return "square.fill"
        case .gradient: return "circle.lefthalf.filled"
        case .textured: return "square.grid.3x3"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
