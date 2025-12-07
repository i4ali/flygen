import Foundation

enum AspectRatio: String, CaseIterable, Codable, Identifiable {
    case square = "1:1"
    case portrait = "4:5"
    case story = "9:16"
    case landscape = "16:9"
    case letter = "letter"
    case a4 = "a4"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .square: return "Square (1:1)"
        case .portrait: return "Portrait (4:5)"
        case .story: return "Story (9:16)"
        case .landscape: return "Landscape (16:9)"
        case .letter: return "Letter (8.5x11)"
        case .a4: return "A4"
        }
    }

    var subtitle: String {
        switch self {
        case .square: return "Instagram, Facebook"
        case .portrait: return "Instagram Feed"
        case .story: return "Stories, Reels, TikTok"
        case .landscape: return "Banner, YouTube"
        case .letter: return "US Print"
        case .a4: return "International Print"
        }
    }

    var icon: String {
        switch self {
        case .square: return "square"
        case .portrait: return "rectangle.portrait"
        case .story: return "iphone"
        case .landscape: return "rectangle"
        case .letter: return "doc"
        case .a4: return "doc.text"
        }
    }

    /// Maps to Nano Banana supported ratios
    var nanoBananaRatio: String {
        switch self {
        case .square: return "1:1"
        case .portrait: return "3:4"
        case .story: return "9:16"
        case .landscape: return "16:9"
        case .letter: return "3:4"
        case .a4: return "3:4"
        }
    }

    /// Aspect ratio as a decimal for preview sizing
    var aspectValue: CGFloat {
        switch self {
        case .square: return 1.0
        case .portrait: return 4.0 / 5.0
        case .story: return 9.0 / 16.0
        case .landscape: return 16.0 / 9.0
        case .letter: return 8.5 / 11.0
        case .a4: return 210.0 / 297.0
        }
    }
}
