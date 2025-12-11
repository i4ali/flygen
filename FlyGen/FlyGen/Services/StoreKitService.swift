import StoreKit
import SwiftUI

/// Credit pack product identifiers
enum CreditPack: String, CaseIterable {
    case credits100 = "com.flygen.credits.100"
    case credits250 = "com.flygen.credits.250"
    case credits500 = "com.flygen.credits.500"

    var creditAmount: Int {
        switch self {
        case .credits100: return 100
        case .credits250: return 250
        case .credits500: return 500
        }
    }

    var displayName: String {
        switch self {
        case .credits100: return "100 Credits"
        case .credits250: return "250 Credits"
        case .credits500: return "500 Credits"
        }
    }

    /// Number of generations this pack provides (10 credits per generation)
    var generationCount: Int {
        creditAmount / 10
    }

    var badge: String? {
        switch self {
        case .credits100: return nil
        case .credits250: return "Save 20%"
        case .credits500: return "Best Value"
        }
    }
}

/// Subscription tier identifiers
enum SubscriptionTier: String, CaseIterable {
    case plus = "com.flygen.subscription.plus"
    case pro = "com.flygen.subscription.pro"

    var displayName: String {
        switch self {
        case .plus: return "FlyGen Plus"
        case .pro: return "FlyGen Pro"
        }
    }

    var monthlyCredits: Int {
        switch self {
        case .plus: return 200  // 20 generations
        case .pro: return 500   // 50 generations
        }
    }

    var monthlyGenerations: Int {
        monthlyCredits / 10
    }

    var description: String {
        switch self {
        case .plus: return "20 flyer generations per month"
        case .pro: return "50 flyer generations per month"
        }
    }

    var badge: String? {
        switch self {
        case .plus: return "Popular"
        case .pro: return "Best Value"
        }
    }

    var icon: String {
        switch self {
        case .plus: return "star.fill"
        case .pro: return "crown.fill"
        }
    }
}

@MainActor
class StoreKitService: ObservableObject {
    @Published var products: [Product] = []
    @Published var subscriptions: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress: Bool = false

    // Subscription state
    @Published var currentSubscription: Product?
    @Published var subscriptionStatus: Product.SubscriptionInfo.Status?
    @Published var subscriptionRenewalDate: Date?

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load credit packs
            let creditProductIDs = CreditPack.allCases.map { $0.rawValue }
            let creditProducts = try await Product.products(for: creditProductIDs)
            products = creditProducts.sorted { $0.price < $1.price }

            // Load subscriptions
            let subscriptionProductIDs = SubscriptionTier.allCases.map { $0.rawValue }
            let subscriptionProducts = try await Product.products(for: subscriptionProductIDs)
            subscriptions = subscriptionProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreKit: Failed to load products: \(error)")
        }

        isLoading = false
    }

    /// Purchase a consumable product (credits)
    func purchase(_ product: Product) async -> Int? {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Get credit amount for this product
                let creditPack = CreditPack(rawValue: product.id)
                let creditsToAdd = creditPack?.creditAmount ?? 0

                // Finish the transaction
                await transaction.finish()

                purchaseInProgress = false
                return creditsToAdd

            case .userCancelled:
                purchaseInProgress = false
                return nil

            case .pending:
                errorMessage = "Purchase is pending approval"
                purchaseInProgress = false
                return nil

            @unknown default:
                purchaseInProgress = false
                return nil
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("StoreKit: Purchase failed: \(error)")
            purchaseInProgress = false
            return nil
        }
    }

    /// Purchase a subscription
    func purchaseSubscription(_ product: Product) async -> SubscriptionTier? {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Finish the transaction
                await transaction.finish()

                // Update subscription status
                await updateSubscriptionStatus()

                purchaseInProgress = false
                return SubscriptionTier(rawValue: product.id)

            case .userCancelled:
                purchaseInProgress = false
                return nil

            case .pending:
                errorMessage = "Purchase is pending approval"
                purchaseInProgress = false
                return nil

            @unknown default:
                purchaseInProgress = false
                return nil
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("StoreKit: Subscription purchase failed: \(error)")
            purchaseInProgress = false
            return nil
        }
    }

    /// Update the current subscription status
    func updateSubscriptionStatus() async {
        var highestTier: Product? = nil
        var latestStatus: Product.SubscriptionInfo.Status? = nil

        for subscription in subscriptions {
            guard let status = try? await subscription.subscription?.status.first else {
                continue
            }

            // Check if subscription is active
            switch status.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                // Get renewal info
                if let renewalInfo = try? checkVerified(status.renewalInfo) {
                    subscriptionRenewalDate = renewalInfo.expirationDate
                }

                // Keep track of highest tier subscription
                if let currentTier = SubscriptionTier(rawValue: subscription.id) {
                    if highestTier == nil {
                        highestTier = subscription
                        latestStatus = status
                    } else if let existingTier = SubscriptionTier(rawValue: highestTier!.id),
                              currentTier.monthlyCredits > existingTier.monthlyCredits {
                        highestTier = subscription
                        latestStatus = status
                    }
                }
            default:
                break
            }
        }

        currentSubscription = highestTier
        subscriptionStatus = latestStatus
    }

    /// Check if user has an active subscription
    var hasActiveSubscription: Bool {
        guard let status = subscriptionStatus else { return false }
        switch status.state {
        case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
            return true
        default:
            return false
        }
    }

    /// Get the current subscription tier
    var currentTier: SubscriptionTier? {
        guard let subscription = currentSubscription else { return nil }
        return SubscriptionTier(rawValue: subscription.id)
    }

    /// Listen for transactions (handles interrupted purchases)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Handle the transaction on main actor
                    await MainActor.run {
                        // For consumables, we just finish the transaction
                        // Credits were already added during the purchase flow

                        // For subscriptions, update the status
                        if SubscriptionTier(rawValue: transaction.productID) != nil {
                            Task {
                                await self.updateSubscriptionStatus()
                            }
                        }
                    }

                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Get product for a credit pack
    func product(for creditPack: CreditPack) -> Product? {
        products.first { $0.id == creditPack.rawValue }
    }

    /// Get product for a subscription tier
    func product(for tier: SubscriptionTier) -> Product? {
        subscriptions.first { $0.id == tier.rawValue }
    }

    /// Format price for display
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
}

enum StoreKitError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
