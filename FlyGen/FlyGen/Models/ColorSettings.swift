import Foundation

struct ColorSettings: Codable, Equatable {
    var preset: ColorSchemePreset = .warm
    var primaryColor: String?
    var secondaryColor: String?
    var accentColor: String?
    var backgroundType: BackgroundType = .light
    var backgroundColor: String?
    var gradientColors: [String]?
}
