import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var credits: Int = 15
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var createdAt: Date = Date()
    var lastSyncedAt: Date = Date()

    /// User's preferred flyer categories (stored as raw values for CloudKit compatibility)
    var preferredCategories: [String] = []

    // MARK: - Onboarding Preferences

    /// User's role/identity selected during onboarding
    var userRole: String?

    /// Visual preferences (stored as raw values for CloudKit compatibility)
    var preferredVisualStyle: String?
    var preferredMood: String?
    var preferredColorScheme: String?

    /// Preferred languages (stored as raw values)
    var preferredLanguages: [String] = []

    init() {
        self.id = UUID()
        self.credits = 15
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
        self.preferredCategories = []
        self.userRole = nil
        self.preferredVisualStyle = nil
        self.preferredMood = nil
        self.preferredColorScheme = nil
        self.preferredLanguages = []
    }

    /// Get preferred categories as FlyerCategory enum values
    var preferredFlyerCategories: [FlyerCategory] {
        preferredCategories.compactMap { FlyerCategory(rawValue: $0) }
    }

    /// Set preferred categories from FlyerCategory enum values
    func setPreferredCategories(_ categories: [FlyerCategory]) {
        preferredCategories = categories.map { $0.rawValue }
    }

    // MARK: - Computed Enum Properties

    var userRoleEnum: UserRole? {
        guard let role = userRole else { return nil }
        return UserRole(rawValue: role)
    }

    var preferredVisualStyleEnum: VisualStyle? {
        guard let style = preferredVisualStyle else { return nil }
        return VisualStyle(rawValue: style)
    }

    var preferredMoodEnum: Mood? {
        guard let mood = preferredMood else { return nil }
        return Mood(rawValue: mood)
    }

    var preferredColorSchemeEnum: ColorSchemePreset? {
        guard let scheme = preferredColorScheme else { return nil }
        return ColorSchemePreset(rawValue: scheme)
    }

    var preferredFlyerLanguages: [FlyerLanguage] {
        preferredLanguages.compactMap { FlyerLanguage(rawValue: $0) }
    }

    func setPreferredLanguages(_ languages: [FlyerLanguage]) {
        preferredLanguages = languages.map { $0.rawValue }
    }

    func setUserRole(_ role: UserRole?) {
        userRole = role?.rawValue
    }

    func setPreferredVisualStyle(_ style: VisualStyle?) {
        preferredVisualStyle = style?.rawValue
    }

    func setPreferredMood(_ mood: Mood?) {
        preferredMood = mood?.rawValue
    }

    func setPreferredColorScheme(_ scheme: ColorSchemePreset?) {
        preferredColorScheme = scheme?.rawValue
    }
}
