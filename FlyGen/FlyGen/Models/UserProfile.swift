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

    // Subscription tracking
    var subscriptionTier: String?  // "plus" or "pro"
    var subscriptionCredits: Int = 0  // Monthly credits from subscription
    var lastCreditRefreshAt: Date?  // When subscription credits were last refreshed

    init() {
        self.id = UUID()
        self.credits = 10
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.createdAt = Date()
        self.lastSyncedAt = Date()
        self.subscriptionTier = nil
        self.subscriptionCredits = 0
        self.lastCreditRefreshAt = nil
    }

    /// Total available credits (purchased + subscription)
    var totalCredits: Int {
        credits + subscriptionCredits
    }

    /// Check if subscription credits need refreshing (new billing period)
    func shouldRefreshSubscriptionCredits(renewalDate: Date?) -> Bool {
        guard isPremium, let lastRefresh = lastCreditRefreshAt else {
            return isPremium  // First time subscriber, needs credits
        }

        // Check if we're in a new billing period
        if let renewal = renewalDate {
            // If renewal date is in the past, credits should be refreshed
            return renewal > lastRefresh
        }

        // Fallback: refresh if it's been more than 30 days
        let daysSinceRefresh = Calendar.current.dateComponents([.day], from: lastRefresh, to: Date()).day ?? 0
        return daysSinceRefresh >= 30
    }

    /// Refresh subscription credits for a new billing period
    func refreshSubscriptionCredits(tier: String, monthlyCredits: Int) {
        self.subscriptionTier = tier
        self.subscriptionCredits = monthlyCredits
        self.lastCreditRefreshAt = Date()
        self.isPremium = true
    }

    /// Deduct credits, preferring subscription credits first
    func deductCredits(_ amount: Int) -> Bool {
        guard totalCredits >= amount else { return false }

        var remaining = amount

        // First use subscription credits
        if subscriptionCredits > 0 {
            let fromSubscription = min(subscriptionCredits, remaining)
            subscriptionCredits -= fromSubscription
            remaining -= fromSubscription
        }

        // Then use purchased credits
        if remaining > 0 {
            credits -= remaining
        }

        return true
    }

    /// Cancel subscription (called when subscription expires)
    func cancelSubscription() {
        isPremium = false
        subscriptionTier = nil
        premiumExpiresAt = nil
        // Keep remaining subscription credits until they're used
    }
}
