import Foundation

/// How a single image action (new / refine / resize) will be paid for.
enum GenerationAccess: Equatable {
    case subscriptionQuota
    case legacyCredits
    case blocked   // caller must present the paywall

    static func decide(isSubscribed: Bool, quotaRemaining: Int, legacyCredits: Int,
                       legacyCost: Int = SubscriptionConfig.legacyCostPerImage) -> GenerationAccess {
        if isSubscribed && quotaRemaining > 0 { return .subscriptionQuota }
        if legacyCredits >= legacyCost { return .legacyCredits }
        return .blocked
    }
}
