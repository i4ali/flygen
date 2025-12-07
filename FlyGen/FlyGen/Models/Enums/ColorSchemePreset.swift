import SwiftUI

enum ColorSchemePreset: String, CaseIterable, Codable, Identifiable {
    case warm = "warm"
    case cool = "cool"
    case earthTones = "earth_tones"
    case neon = "neon"
    case pastel = "pastel"
    case monochrome = "monochrome"
    case blackGold = "black_gold"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .earthTones: return "Earth Tones"
        case .neon: return "Neon"
        case .pastel: return "Pastel"
        case .monochrome: return "Monochrome"
        case .blackGold: return "Black & Gold"
        case .custom: return "Custom"
        }
    }

    var previewColors: [Color] {
        switch self {
        case .warm:
            return [.red, .orange, .yellow]
        case .cool:
            return [.blue, .cyan, .teal]
        case .earthTones:
            return [Color(red: 0.6, green: 0.4, blue: 0.2), .brown, .green]
        case .neon:
            return [.pink, .green, .cyan]
        case .pastel:
            return [Color(red: 1, green: 0.8, blue: 0.8), Color(red: 0.8, green: 0.9, blue: 1), Color(red: 0.8, green: 1, blue: 0.8)]
        case .monochrome:
            return [.black, .gray, .white]
        case .blackGold:
            return [.black, Color(red: 0.85, green: 0.65, blue: 0.13)]
        case .custom:
            return [.purple, .pink, .orange]
        }
    }
}
