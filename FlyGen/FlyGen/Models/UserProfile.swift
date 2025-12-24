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

    // Subscription-related properties
    var subscriptionPlan: String?
    var subscriptionExpiresAt: Date?
    var monthlyCreditsUsed: Int = 0
    var creditsResetDate: Date?

    init() {
        self.id = UUID()
        self.credits = 10
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
        self.subscriptionPlan = nil
        self.subscriptionExpiresAt = nil
        self.monthlyCreditsUsed = 0
        self.creditsResetDate = nil
    }

    /// Check if subscription is active
    var hasActiveSubscription: Bool {
        guard let expiresAt = subscriptionExpiresAt else { return false }
        return expiresAt > Date()
    }

    /// Get the subscription plan type
    var currentPlan: String? {
        guard hasActiveSubscription else { return nil }
        return subscriptionPlan
    }
}
