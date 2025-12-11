import SwiftUI
import SwiftData
import StoreKit

struct PremiumTab: View {
    @EnvironmentObject var storeKitService: StoreKitService
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var showingPurchaseSuccess = false
    @State private var purchasedCredits: Int = 0
    @State private var showingSubscriptionSuccess = false
    @State private var subscribedTier: SubscriptionTier?
    @State private var selectedTab: PurchaseTab = .subscriptions

    enum PurchaseTab: String, CaseIterable {
        case subscriptions = "Subscribe"
        case credits = "Credit Packs"
    }

    private var profile: UserProfile? {
        userProfiles.first
    }

    private var totalCredits: Int {
        profile?.totalCredits ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
                    // Header
                    headerSection

                    // Current status (subscription or credits)
                    statusSection

                    // Tab picker
                    tabPicker

                    // Content based on selected tab
                    if selectedTab == .subscriptions {
                        subscriptionsSection
                    } else {
                        creditPacksSection
                    }

                    // Features list
                    featuresSection

                    Spacer(minLength: FGSpacing.xl)
                }
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("FlyGen Premium")
            .alert("Purchase Successful!", isPresented: $showingPurchaseSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You've received \(purchasedCredits) credits. Happy creating!")
            }
            .alert("Welcome to \(subscribedTier?.displayName ?? "Premium")!", isPresented: $showingSubscriptionSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You now have \(subscribedTier?.monthlyGenerations ?? 0) flyer generations per month!")
            }
            .task {
                await checkAndRefreshSubscriptionCredits()
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

                Image(systemName: storeKitService.hasActiveSubscription ? "crown.fill" : "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentSecondary, FGColors.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(storeKitService.hasActiveSubscription ? "You're a Subscriber!" : "Upgrade to Premium")
                .font(FGTypography.displaySmall)
                .foregroundColor(FGColors.textPrimary)

            Text(storeKitService.hasActiveSubscription
                 ? "Enjoy your monthly flyer generations"
                 : "Subscribe for monthly generations\nor buy credit packs")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FGSpacing.xl)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: FGSpacing.sm) {
            // Credits display
            HStack(spacing: FGSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundColor(FGColors.accentSecondary)
                Text("Available Credits:")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                Text("\(totalCredits)")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)
            }

            // Show credit breakdown for subscribers
            if let profile = profile, profile.isPremium && profile.subscriptionCredits > 0 {
                HStack(spacing: FGSpacing.lg) {
                    Label("\(profile.subscriptionCredits) subscription", systemImage: "arrow.clockwise")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.accentPrimary)

                    if profile.credits > 0 {
                        Label("\(profile.credits) purchased", systemImage: "bag")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
            }

            // Subscription status
            if storeKitService.hasActiveSubscription, let tier = storeKitService.currentTier {
                HStack(spacing: FGSpacing.sm) {
                    Image(systemName: tier.icon)
                        .foregroundColor(FGColors.warning)
                    Text(tier.displayName)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)

                    if let renewalDate = storeKitService.subscriptionRenewalDate {
                        Text("renews \(renewalDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
                .padding(.top, FGSpacing.xs)
            }
        }
        .padding(FGSpacing.md)
        .frame(maxWidth: .infinity)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(storeKitService.hasActiveSubscription ? FGColors.warning.opacity(0.5) : FGColors.accentSecondary.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("Purchase Type", selection: $selectedTab) {
            ForEach(PurchaseTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Subscriptions Section

    private var subscriptionsSection: some View {
        VStack(spacing: FGSpacing.md) {
            if storeKitService.isLoading {
                loadingView
            } else if storeKitService.subscriptions.isEmpty {
                emptyProductsView
            } else {
                ForEach(SubscriptionTier.allCases, id: \.rawValue) { tier in
                    if let product = storeKitService.product(for: tier) {
                        SubscriptionCard(
                            tier: tier,
                            product: product,
                            isCurrentPlan: storeKitService.currentTier == tier,
                            isLoading: storeKitService.purchaseInProgress
                        ) {
                            await purchaseSubscription(product: product, tier: tier)
                        }
                    }
                }

                // Manage subscription link
                if storeKitService.hasActiveSubscription {
                    Button {
                        Task {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                try? await AppStore.showManageSubscriptions(in: windowScene)
                            }
                        }
                    } label: {
                        Text("Manage Subscription")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    .padding(.top, FGSpacing.sm)
                }
            }

            if let error = storeKitService.errorMessage {
                Text(error)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.error)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Credit Packs Section

    private var creditPacksSection: some View {
        VStack(spacing: FGSpacing.md) {
            Text("One-time purchases, no subscription required")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)

            if storeKitService.isLoading {
                loadingView
            } else if storeKitService.products.isEmpty {
                emptyProductsView
            } else {
                ForEach(CreditPack.allCases, id: \.rawValue) { pack in
                    if let product = storeKitService.product(for: pack) {
                        CreditPackCard(
                            pack: pack,
                            product: product,
                            isLoading: storeKitService.purchaseInProgress
                        ) {
                            await purchaseCredits(product: product, pack: pack)
                        }
                    }
                }
            }

            if let error = storeKitService.errorMessage {
                Text(error)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.error)
            }
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    // MARK: - Helper Views

    private var loadingView: some View {
        VStack(spacing: FGSpacing.sm) {
            ProgressView()
                .tint(FGColors.accentPrimary)
            Text("Loading products...")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
        }
        .padding(FGSpacing.xl)
    }

    private var emptyProductsView: some View {
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
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            Text("What You Get")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)
                .padding(.horizontal, FGSpacing.screenHorizontal)

            VStack(spacing: FGSpacing.sm) {
                FeatureRow(icon: "wand.and.stars", title: "AI-Powered Design", description: "Professional flyers in seconds")
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited Refinements", description: "Perfect your design with feedback")
                FeatureRow(icon: "icloud", title: "Cloud Sync", description: "Access flyers on all your devices")
                FeatureRow(icon: "square.and.arrow.up", title: "Easy Sharing", description: "Share directly to social media")
            }
        }
        .padding(.vertical, FGSpacing.md)
    }

    // MARK: - Actions

    private func purchaseCredits(product: Product, pack: CreditPack) async {
        if let creditsAdded = await storeKitService.purchase(product) {
            if let profile = profile {
                profile.credits += creditsAdded
                profile.lastSyncedAt = Date()
                try? modelContext.save()

                await cloudKitService.saveCredits(profile.credits)

                purchasedCredits = creditsAdded
                showingPurchaseSuccess = true
            }
        }
    }

    private func purchaseSubscription(product: Product, tier: SubscriptionTier) async {
        if let purchasedTier = await storeKitService.purchaseSubscription(product) {
            if let profile = profile {
                profile.refreshSubscriptionCredits(tier: purchasedTier.rawValue, monthlyCredits: purchasedTier.monthlyCredits)
                profile.premiumExpiresAt = storeKitService.subscriptionRenewalDate
                try? modelContext.save()

                await cloudKitService.saveCredits(profile.totalCredits)

                subscribedTier = purchasedTier
                showingSubscriptionSuccess = true
            }
        }
    }

    private func checkAndRefreshSubscriptionCredits() async {
        guard let profile = profile,
              storeKitService.hasActiveSubscription,
              let tier = storeKitService.currentTier else {
            return
        }

        // Check if we need to refresh credits for a new billing period
        if profile.shouldRefreshSubscriptionCredits(renewalDate: storeKitService.subscriptionRenewalDate) {
            profile.refreshSubscriptionCredits(tier: tier.rawValue, monthlyCredits: tier.monthlyCredits)
            profile.premiumExpiresAt = storeKitService.subscriptionRenewalDate
            try? modelContext.save()

            await cloudKitService.saveCredits(profile.totalCredits)
        }
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let tier: SubscriptionTier
    let product: Product
    let isCurrentPlan: Bool
    let isLoading: Bool
    let onPurchase: () async -> Void

    var body: some View {
        VStack(spacing: FGSpacing.md) {
            HStack(spacing: FGSpacing.md) {
                // Icon
                Image(systemName: tier.icon)
                    .font(.title)
                    .foregroundColor(tier == .pro ? FGColors.warning : FGColors.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        (tier == .pro ? FGColors.warning : FGColors.accentPrimary).opacity(0.15)
                    )
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack(spacing: FGSpacing.sm) {
                        Text(tier.displayName)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        if let badge = tier.badge {
                            Text(badge)
                                .font(FGTypography.captionBold)
                                .foregroundColor(FGColors.textOnAccent)
                                .padding(.horizontal, FGSpacing.sm)
                                .padding(.vertical, FGSpacing.xxxs)
                                .background(tier == .pro ? FGColors.warning : FGColors.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                        }

                        if isCurrentPlan {
                            Text("Current")
                                .font(FGTypography.captionBold)
                                .foregroundColor(FGColors.success)
                                .padding(.horizontal, FGSpacing.sm)
                                .padding(.vertical, FGSpacing.xxxs)
                                .background(FGColors.success.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                        }
                    }

                    Text(tier.description)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()
            }

            // Price and subscribe button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayPrice)
                        .font(FGTypography.h3)
                        .foregroundColor(FGColors.textPrimary)
                    Text("per month")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                }

                Spacer()

                Button {
                    Task {
                        await onPurchase()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(FGColors.textOnAccent)
                            .frame(width: 100)
                    } else {
                        Text(isCurrentPlan ? "Subscribed" : "Subscribe")
                            .font(FGTypography.buttonLarge)
                            .foregroundColor(isCurrentPlan ? FGColors.textTertiary : FGColors.textOnAccent)
                            .frame(width: 100)
                            .padding(.vertical, FGSpacing.sm)
                            .background(isCurrentPlan ? FGColors.surfaceDefault : FGColors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(isCurrentPlan ? FGColors.borderSubtle : Color.clear, lineWidth: 1)
                            )
                    }
                }
                .disabled(isLoading || isCurrentPlan)
            }
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(isCurrentPlan ? FGColors.success.opacity(0.5) : FGColors.borderSubtle, lineWidth: isCurrentPlan ? 2 : 1)
        )
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

                Text("\(pack.generationCount) flyer generations")
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

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(FGColors.accentPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                Text(title)
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textPrimary)

                Text(description)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(FGColors.success)
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }
}

#Preview {
    PremiumTab()
        .environmentObject(StoreKitService())
        .environmentObject(CloudKitService())
}
