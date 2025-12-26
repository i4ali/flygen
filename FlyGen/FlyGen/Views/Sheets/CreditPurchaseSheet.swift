import SwiftUI
import SwiftData
import StoreKit

struct CreditPurchaseSheet: View {
    @EnvironmentObject var storeKitService: StoreKitService
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    /// When true, shows promotional 50% off products instead of regular products
    var isPromoMode: Bool = false

    @State private var showingPurchaseSuccess = false
    @State private var purchasedCredits: Int = 0

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    /// Calculate the highest discount percentage across all promo packs
    private var maxDiscountPercentage: Int? {
        var maxDiscount: Int?
        for promoPack in PromoCreditPack.allCases {
            guard let promoProduct = storeKitService.promoProduct(for: promoPack),
                  let regularProduct = storeKitService.product(for: promoPack.regularPack) else {
                continue
            }
            let regularPrice = regularProduct.price
            let promoPrice = promoProduct.price
            guard regularPrice > 0 else { continue }
            let discount = ((regularPrice - promoPrice) / regularPrice) * 100
            let discountInt = Int(NSDecimalNumber(decimal: discount).doubleValue.rounded())
            if let current = maxDiscount {
                maxDiscount = max(current, discountInt)
            } else {
                maxDiscount = discountInt
            }
        }
        return maxDiscount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
                    // Header
                    headerSection

                    // Value comparison
                    comparisonBanner

                    // Current credits
                    creditsDisplay

                    // Credit Packs
                    creditPacksSection

                    Spacer(minLength: FGSpacing.xl)
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Get Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(FGColors.textTertiary)
                    }
                }
            }
            .alert("Purchase Successful!", isPresented: $showingPurchaseSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("You've received \(purchasedCredits) credits. Happy creating!")
            }
            .task {
                // Ensure both regular and promo products are loaded for discount calculation
                if storeKitService.products.isEmpty {
                    await storeKitService.loadProducts()
                }
                if storeKitService.promoProducts.isEmpty {
                    await storeKitService.loadPromoProducts()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: FGSpacing.md) {
            ZStack {
                Circle()
                    .fill(FGColors.accentSecondary.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Image(systemName: isPromoMode ? "gift.fill" : "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentSecondary, FGColors.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            if isPromoMode {
                if let discount = maxDiscountPercentage {
                    Text("\(discount)% OFF")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("Welcome Offer")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)

                Text("One-time discount for new users\nClaim before this offer expires!")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Credit Packs")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)

                Text("Purchase credits to create\nmore AI-powered flyers")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, FGSpacing.lg)
    }

    // MARK: - Comparison Banner

    private var comparisonBanner: some View {
        VStack(spacing: FGSpacing.sm) {
            // Top label
            Text("Skip the Designer")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            // Giant strikethrough price
            Text("$200+")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .strikethrough(true, color: .white.opacity(0.6))

            // FlyGen price - the star
            VStack(spacing: 2) {
                Text("Just 30¢")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("per professional flyer")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Time savings
            HStack(spacing: FGSpacing.xs) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                Text("Create instantly")
                    .font(FGTypography.captionBold)
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.top, FGSpacing.xs)

            // User testimonial
            VStack(spacing: 6) {
                Text("\"Game-changer... honestly a lifesaver!\"")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)

                HStack(spacing: FGSpacing.xs) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundColor(FGColors.warning)

                    Text("— wisementor274, App Store")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, FGSpacing.sm)
        }
        .padding(.vertical, FGSpacing.lg)
        .padding(.horizontal, FGSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    FGColors.accentPrimary.opacity(0.4),
                    FGColors.accentSecondary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Credits Display

    private var creditsDisplay: some View {
        VStack(spacing: FGSpacing.xs) {
            HStack(spacing: FGSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundColor(FGColors.accentSecondary)
                Text("Current Credits:")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                Text("\(credits)")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)
            }

            // Credits never expire note
            HStack(spacing: FGSpacing.xxs) {
                Image(systemName: "infinity")
                    .font(.system(size: 12))
                Text("Credits never expire")
                    .font(FGTypography.caption)
            }
            .foregroundColor(FGColors.textTertiary)
        }
        .padding(FGSpacing.md)
        .frame(maxWidth: .infinity)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.accentSecondary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Credit Packs Section

    private var creditPacksSection: some View {
        VStack(spacing: FGSpacing.md) {
            if storeKitService.isLoading {
                VStack(spacing: FGSpacing.sm) {
                    ProgressView()
                        .tint(FGColors.accentPrimary)
                    Text("Loading products...")
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                }
                .padding(FGSpacing.xl)
            } else if isPromoMode {
                // Promo mode - show discounted products
                if storeKitService.promoProducts.isEmpty {
                    // Fallback to regular products if promo products not available
                    regularProductsList
                } else {
                    promoProductsList
                }
            } else if storeKitService.products.isEmpty {
                VStack(spacing: FGSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(FGColors.warning)

                    Text("Unable to load products")
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    Text("Please check your connection and try again")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)

                    Button {
                        Task {
                            await storeKitService.loadProducts()
                        }
                    } label: {
                        Text("Retry")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.accentPrimary)
                            .padding(.horizontal, FGSpacing.lg)
                            .padding(.vertical, FGSpacing.sm)
                            .background(FGColors.surfaceDefault)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(FGColors.accentPrimary, lineWidth: 1)
                            )
                    }
                }
                .padding(FGSpacing.lg)
            } else {
                regularProductsList
            }

            if let error = storeKitService.errorMessage {
                Text(error)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.error)
                    .padding(.horizontal, FGSpacing.screenHorizontal)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    private var regularProductsList: some View {
        ForEach(CreditPack.allCases, id: \.rawValue) { pack in
            if let product = storeKitService.product(for: pack) {
                CreditPackCard(
                    pack: pack,
                    product: product,
                    isLoading: storeKitService.purchaseInProgress
                ) {
                    await purchaseCredits(product: product, creditAmount: pack.creditAmount)
                }
            }
        }
    }

    private var promoProductsList: some View {
        ForEach(PromoCreditPack.allCases, id: \.rawValue) { promoPack in
            if let promoProduct = storeKitService.promoProduct(for: promoPack) {
                let regularProduct = storeKitService.product(for: promoPack.regularPack)
                PromoCreditPackCard(
                    promoPack: promoPack,
                    promoProduct: promoProduct,
                    regularProduct: regularProduct,
                    isLoading: storeKitService.purchaseInProgress
                ) {
                    await purchaseCredits(product: promoProduct, creditAmount: promoPack.creditAmount)
                }
            }
        }
    }

    // MARK: - Purchase Action

    private func purchaseCredits(product: Product, creditAmount: Int) async {
        if let creditsAdded = await storeKitService.purchase(product) {
            // Add credits to user profile
            if let profile = userProfiles.first {
                profile.credits += creditsAdded
                profile.lastSyncedAt = Date()
                try? modelContext.save()

                // Sync credits to CloudKit
                await cloudKitService.saveCredits(profile.credits)

                // Cancel scheduled notification since credits restored
                notificationService.onCreditsChanged(newCredits: profile.credits)

                purchasedCredits = creditsAdded
                showingPurchaseSuccess = true
            }
        }
    }
}

// MARK: - Credit Pack Card

struct CreditPackCard: View {
    let pack: CreditPack
    let product: Product
    let isLoading: Bool
    let onPurchase: () async -> Void

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            // Credits amount
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                HStack(spacing: FGSpacing.sm) {
                    Text(pack.displayName)
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    if let badge = pack.badge {
                        Text(badge)
                            .font(FGTypography.captionBold)
                            .foregroundColor(FGColors.textOnAccent)
                            .padding(.horizontal, FGSpacing.sm)
                            .padding(.vertical, FGSpacing.xxxs)
                            .background(FGColors.warning)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                    }
                }

                Text(product.description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            // Price button
            Button {
                Task {
                    await onPurchase()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(FGColors.textOnAccent)
                        .frame(width: 80)
                } else {
                    Text(product.displayPrice)
                        .font(FGTypography.buttonLarge)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(width: 80)
                        .padding(.vertical, FGSpacing.sm)
                        .background(FGColors.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                }
            }
            .disabled(isLoading)
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Promo Credit Pack Card

struct PromoCreditPackCard: View {
    let promoPack: PromoCreditPack
    let promoProduct: Product
    let regularProduct: Product?
    let isLoading: Bool
    let onPurchase: () async -> Void

    /// Calculate actual discount percentage from prices
    private var discountPercentage: Int? {
        guard let regularProduct = regularProduct else { return nil }
        let regularPrice = regularProduct.price
        let promoPrice = promoProduct.price
        guard regularPrice > 0 else { return nil }
        let discount = ((regularPrice - promoPrice) / regularPrice) * 100
        return Int(NSDecimalNumber(decimal: discount).doubleValue.rounded())
    }

    /// Dynamic badge text based on actual discount
    private var badgeText: String {
        if let percent = discountPercentage {
            return "\(percent)% OFF"
        }
        return promoPack.badge
    }

    /// Original price display from regular product
    private var originalPriceDisplay: String? {
        regularProduct?.displayPrice
    }

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            // Credits amount
            VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                HStack(spacing: FGSpacing.sm) {
                    Text(promoPack.displayName)
                        .font(FGTypography.h4)
                        .foregroundColor(FGColors.textPrimary)

                    Text(badgeText)
                        .font(FGTypography.captionBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, FGSpacing.sm)
                        .padding(.vertical, FGSpacing.xxxs)
                        .background(
                            LinearGradient(
                                colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                }

                Text(promoProduct.description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            // Price section with strikethrough original price
            VStack(alignment: .trailing, spacing: 2) {
                if let originalPrice = originalPriceDisplay {
                    Text(originalPrice)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .strikethrough()
                }

                Button {
                    Task {
                        await onPurchase()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(FGColors.textOnAccent)
                            .frame(width: 80)
                    } else {
                        Text(promoProduct.displayPrice)
                            .font(FGTypography.buttonLarge)
                            .foregroundColor(.white)
                            .frame(width: 80)
                            .padding(.vertical, FGSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                }
                .disabled(isLoading)
            }
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [FGColors.accentPrimary.opacity(0.5), FGColors.accentSecondary.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    CreditPurchaseSheet()
        .environmentObject(StoreKitService())
        .environmentObject(CloudKitService())
        .environmentObject(NotificationService())
}
