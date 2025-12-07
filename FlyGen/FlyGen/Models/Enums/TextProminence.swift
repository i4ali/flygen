import Foundation

enum TextProminence: String, CaseIterable, Codable, Identifiable {
    case dominant = "dominant"
    case balanced = "balanced"
    case subtle = "subtle"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dominant: return "Text Dominant"
        case .balanced: return "Balanced"
        case .subtle: return "Image Dominant"
        }
    }

    var description: String {
        switch self {
        case .dominant: return "Text is the main focus, imagery supports"
        case .balanced: return "Equal emphasis on text and visuals"
        case .subtle: return "Imagery is the focus, text is secondary"
        }
    }

    var icon: String {
        switch self {
        case .dominant: return "textformat.size.larger"
        case .balanced: return "equal.square"
        case .subtle: return "photo"
        }
    }
}
