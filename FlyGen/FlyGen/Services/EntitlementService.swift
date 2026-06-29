import Foundation
import StoreKit
import SwiftData

@MainActor
final class EntitlementService: ObservableObject {
    @Published private(set) var isSubscribed = false
    @Published private(set) var renewalDate: Date?
    @Published private(set) var products: [Product] = []
    @Published private(set) var activeProductID: String?
    @Published private(set) var didAttemptProductLoad = false

    init() {
        Task {
            await loadProducts()
            await refreshEntitlements()
        }

        Task {
            for await verificationResult in Transaction.updates {
                if let transaction = try? checkVerified(verificationResult) {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            }
        }
    }

    // MARK: - Products

    func loadProducts() async {
        let ids = Array(SubscriptionConfig.Product.all)
        do {
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted { $0.price < $1.price }
            if fetched.isEmpty {
                let probe = (try? await Product.products(for: ["com.flygen.credits.10"]))?.count ?? -1
                print("EntitlementService: 0 subscription products for \(ids). DIAG consumable probe (com.flygen.credits.10) -> \(probe). probe<=0 => StoreKit config NOT active for this run (Scheme > Run > Options > StoreKit Configuration / clean+reinstall); probe==1 => config active but the subscription group isn't being read.")
            } else {
                print("EntitlementService: loaded \(fetched.count) product(s): \(fetched.map { $0.id })")
            }
        } catch {
            print("EntitlementService: Failed to load products: \(error)")
        }
        didAttemptProductLoad = true
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var subscribed = false
        var latestExpiry: Date? = nil
        var foundProductID: String? = nil

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard SubscriptionConfig.Product.all.contains(transaction.productID) else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expiry = transaction.expirationDate {
                guard expiry > Date() else { continue }
                if latestExpiry == nil || expiry > latestExpiry! {
                    latestExpiry = expiry
                    foundProductID = transaction.productID
                }
            } else if foundProductID == nil {
                foundProductID = transaction.productID
            }

            subscribed = true
        }

        isSubscribed = subscribed
        renewalDate = latestExpiry
        activeProductID = subscribed ? foundProductID : nil
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Quota

    func quotaRemaining(for profile: UserProfile) -> Int {
        let unit = SubscriptionConfig.periodUnit(for: activeProductID)
        let quota = SubscriptionConfig.quota(for: activeProductID)
        return QuotaState(usedThisPeriod: profile.quotaUsedThisPeriod, periodStart: profile.quotaPeriodStart)
            .advancing(now: Date(), unit: unit)
            .remaining(quota: quota)
    }

    func access(for profile: UserProfile) -> GenerationAccess {
        GenerationAccess.decide(
            isSubscribed: isSubscribed,
            quotaRemaining: quotaRemaining(for: profile),
            legacyCredits: profile.credits
        )
    }

    // MARK: - Consume

    /// Roll the quota period forward (persisting the reset) before any
    /// decision or mutation that depends on current usage. Idempotent within a period.
    private func rollQuotaPeriod(_ profile: UserProfile) {
        let unit = SubscriptionConfig.periodUnit(for: activeProductID)
        let state = QuotaState(
            usedThisPeriod: profile.quotaUsedThisPeriod,
            periodStart: profile.quotaPeriodStart
        ).advancing(now: Date(), unit: unit)
        profile.quotaUsedThisPeriod = state.usedThisPeriod
        profile.quotaPeriodStart = state.periodStart
    }

    func consume(for profile: UserProfile, context: ModelContext, cloudKit: CloudKitService) async {
        rollQuotaPeriod(profile)
        switch access(for: profile) {
        case .subscriptionQuota:
            profile.quotaUsedThisPeriod += 1
        case .legacyCredits:
            profile.credits -= SubscriptionConfig.legacyCostPerImage
        case .blocked:
            return
        }
        try? context.save()
        await cloudKit.saveCreditsAndQuota(
            credits: profile.credits,
            quotaUsed: profile.quotaUsedThisPeriod,
            periodStart: profile.quotaPeriodStart
        )
    }

    // MARK: - Refresh Profile

    func refresh(profile: UserProfile, context: ModelContext, cloudKit: CloudKitService) async {
        rollQuotaPeriod(profile)

        if isSubscribed && profile.quotaPeriodStart == nil {
            profile.quotaPeriodStart = Date()
        }

        profile.isPremium = isSubscribed
        profile.premiumExpiresAt = renewalDate
        try? context.save()
        await cloudKit.saveQuota(used: profile.quotaUsedThisPeriod, periodStart: profile.quotaPeriodStart)
    }
}
