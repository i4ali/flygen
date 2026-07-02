import Foundation

/// Single source of truth for subscription tunables.
enum SubscriptionConfig {
    /// Legacy consumable-credit cost per image action (pre-subscription rules).
    static let legacyCostPerImage = 10

    enum Product {
        static let weekly = "com.flygen.premium.weekly.v2"
        static let monthly = "com.flygen.premium.monthly.v2"
        static let all: Set<String> = [weekly, monthly]
    }

    /// Per-plan flyer allotment, refilled each billing period.
    static let weeklyQuota = 12
    static let monthlyQuota = 50

    /// Quota allotment for the given active subscription product (0 if none/unknown).
    static func quota(for productID: String?) -> Int {
        switch productID {
        case Product.weekly: return weeklyQuota
        case Product.monthly: return monthlyQuota
        default: return 0
        }
    }

    /// Reset/billing period unit for the given active subscription product.
    static func periodUnit(for productID: String?) -> Calendar.Component {
        switch productID {
        case Product.weekly: return .weekOfYear
        default: return .month
        }
    }
}
