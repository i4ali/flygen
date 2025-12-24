import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var credits: Int = 10
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var createdAt: Date = Date()
    var lastSyncedAt: Date = Date()

    /// User's preferred flyer categories (stored as raw values for CloudKit compatibility)
    var preferredCategories: [String] = []

    init() {
        self.id = UUID()
        self.credits = 10
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
        self.preferredCategories = []
    }

    /// Get preferred categories as FlyerCategory enum values
    var preferredFlyerCategories: [FlyerCategory] {
        preferredCategories.compactMap { FlyerCategory(rawValue: $0) }
    }

    /// Set preferred categories from FlyerCategory enum values
    func setPreferredCategories(_ categories: [FlyerCategory]) {
        preferredCategories = categories.map { $0.rawValue }
    }
}
