import SwiftUI
import SwiftData
import StoreKit

// MARK: - Subscription Plan Definitions

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case starter = "com.flygen.subscription.starter"
    case creator = "com.flygen.subscription.creator"
    case pro = "com.flygen.subscription.pro"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .creator: return "Creator"
        case .pro: return "Pro"
        }
    }

    var monthlyFlyers: Int? {
        switch self {
        case .starter: return 20
        case .creator: return 75
        case .pro: return nil // Unlimited
        }
    }

    var flyerDisplayText: String {
        if let count = monthlyFlyers {
            return "\(count) flyers/month"
        }
        return "Unlimited flyers"
    }

    var icon: String {
        switch self {
        case .starter: return "sparkle"
        case .creator: return "star.fill"
        case .pro: return "crown.fill"
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            return [
                "20 AI-generated flyers per month",
                "All basic templates",
                "High-resolution exports",
                "Save to camera roll"
            ]
        case .creator:
            return [
                "75 AI-generated flyers per month",
                "All premium templates",
                "Priority generation queue",
                "No watermarks",
                "Custom brand colors"
            ]
        case .pro:
            return [
                "Unlimited AI-generated flyers",
                "All premium templates",
                "Fastest generation speed",
                "Priority support",
                "Team sharing (coming soon)",
                "API access (coming soon)"
            ]
        }
    }

    var isPopular: Bool {
        self == .creator
    }

    var accentColor: Color {
        switch self {
        case .starter: return FGColors.accentSecondary
        case .creator: return FGColors.accentPrimary
        case .pro: return FGColors.warning
        }
    }

    /// Monthly product ID
    var monthlyProductId: String {
        rawValue + ".monthly"
    }

    /// Yearly product ID
    var yearlyProductId: String {
        rawValue + ".yearly"
    }
}

// MARK: - Subscription Plan Sheet

struct SubscriptionPlanSheet: View {
    @EnvironmentObject var storeKitService: StoreKitService
    @EnvironmentObject var cloudKitService: CloudKitService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]

    @State private var selectedPlan: SubscriptionPlan = .creator
    @State private var isYearly: Bool = true
    @State private var showingSuccessAlert = false
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.lg) {
                    // Header
                    headerSection

                    // Billing Toggle
                    billingToggle

                    // Plan Cards
                    planCardsSection

                    // Features List
                    featuresSection

                    // Subscribe Button
                    subscribeButton

                    // Terms
                    termsSection

                    Spacer(minLength: FGSpacing.xxl)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .background(FGColors.backgroundPrimary)
            .navigationTitle("Choose Your Plan")
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
            .alert("Welcome to FlyGen \(selectedPlan.displayName)!", isPresented: $showingSuccessAlert) {
                Button("Start Creating", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your subscription is now active. Enjoy creating beautiful flyers!")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: FGSpacing.md) {
            // Animated gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FGColors.accentPrimary.opacity(0.3), FGColors.accentSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Unlock Unlimited Creativity")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Choose the plan that fits your needs")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
        }
        .padding(.top, FGSpacing.lg)
    }

    // MARK: - Billing Toggle

    private var billingToggle: some View {
        HStack(spacing: 0) {
            billingOption(title: "Monthly", isSelected: !isYearly) {
                withAnimation(.spring(response: 0.3)) {
                    isYearly = false
                }
            }

            billingOption(title: "Yearly", subtitle: "Save 33%", isSelected: isYearly) {
                withAnimation(.spring(response: 0.3)) {
                    isYearly = true
                }
            }
        }
        .padding(FGSpacing.xxs)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
    }

    private func billingOption(title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(FGTypography.button)
                    .foregroundColor(isSelected ? FGColors.textOnAccent : FGColors.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(FGTypography.captionBold)
                        .foregroundColor(isSelected ? FGColors.textOnAccent.opacity(0.9) : FGColors.success)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.sm)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                ) : nil
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius - 2))
        }
    }

    // MARK: - Plan Cards Section

    private var planCardsSection: some View {
        VStack(spacing: FGSpacing.sm) {
            ForEach(SubscriptionPlan.allCases) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    isYearly: isYearly,
                    monthlyProduct: storeKitService.subscriptionProduct(for: plan, yearly: false),
                    yearlyProduct: storeKitService.subscriptionProduct(for: plan, yearly: true)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: FGSpacing.md) {
            HStack {
                Image(systemName: selectedPlan.icon)
                    .foregroundColor(selectedPlan.accentColor)
                Text("\(selectedPlan.displayName) includes:")
                    .font(FGTypography.h4)
                    .foregroundColor(FGColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                ForEach(selectedPlan.features, id: \.self) { feature in
                    HStack(spacing: FGSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(FGColors.success)
                            .font(.system(size: 16))

                        Text(feature)
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task {
                await subscribe()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(FGColors.textOnAccent)
                } else {
                    Text("Subscribe to \(selectedPlan.displayName)")
                        .font(FGTypography.buttonLarge)

                    if let product = storeKitService.subscriptionProduct(for: selectedPlan, yearly: isYearly) {
                        Text("• \(product.displayPrice)/\(isYearly ? "year" : "month")")
                            .font(FGTypography.button)
                            .opacity(0.9)
                    }
                }
            }
            .foregroundColor(FGColors.textOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: FGSpacing.buttonHeight)
            .background(
                LinearGradient(
                    colors: [FGColors.accentPrimary, FGColors.accentGradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
            .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: FGSpacing.xs) {
            Text("Cancel anytime. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: FGSpacing.md) {
                Button("Terms of Use") {
                    // Open terms
                }
                .font(FGTypography.caption)
                .foregroundColor(FGColors.accentSecondary)

                Text("•")
                    .foregroundColor(FGColors.textTertiary)

                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(FGTypography.caption)
                .foregroundColor(FGColors.accentSecondary)

                Text("•")
                    .foregroundColor(FGColors.textTertiary)

                Button("Restore Purchases") {
                    Task {
                        await restorePurchases()
                    }
                }
                .font(FGTypography.caption)
                .foregroundColor(FGColors.accentSecondary)
            }
        }
        .padding(.top, FGSpacing.sm)
    }

    // MARK: - Actions

    private func subscribe() async {
        guard let product = storeKitService.subscriptionProduct(for: selectedPlan, yearly: isYearly) else {
            return
        }

        isPurchasing = true

        if let _ = await storeKitService.purchaseSubscription(product, plan: selectedPlan) {
            // Update user profile with subscription
            if let profile = userProfiles.first {
                profile.isPremium = true
                profile.subscriptionPlan = selectedPlan.rawValue
                profile.subscriptionExpiresAt = Calendar.current.date(
                    byAdding: isYearly ? .year : .month,
                    value: 1,
                    to: Date()
                )
                // Give them their monthly credits immediately
                if let monthlyFlyers = selectedPlan.monthlyFlyers {
                    profile.credits = monthlyFlyers * 10 // Convert flyers to credits
                } else {
                    profile.credits = 9999 // Unlimited represented as high number
                }
                try? modelContext.save()

                await cloudKitService.saveCredits(profile.credits)
            }

            showingSuccessAlert = true
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        isPurchasing = true
        await storeKitService.restorePurchases()
        isPurchasing = false
    }
}

// MARK: - Plan Card Component

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isYearly: Bool
    let monthlyProduct: Product?
    let yearlyProduct: Product?
    let onSelect: () -> Void

    private var displayProduct: Product? {
        isYearly ? yearlyProduct : monthlyProduct
    }

    private var monthlyEquivalent: String? {
        guard isYearly, let yearly = yearlyProduct else { return nil }
        let monthlyPrice = yearly.price / 12
        return yearly.priceFormatStyle.format(monthlyPrice)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: FGSpacing.md) {
                // Plan icon
                ZStack {
                    Circle()
                        .fill(plan.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: plan.icon)
                        .font(.system(size: 20))
                        .foregroundColor(plan.accentColor)
                }

                // Plan details
                VStack(alignment: .leading, spacing: FGSpacing.xxxs) {
                    HStack(spacing: FGSpacing.xs) {
                        Text(plan.displayName)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        if plan.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [FGColors.accentPrimary, FGColors.accentGradientEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(plan.flyerDisplayText)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    if let product = displayProduct {
                        Text(product.displayPrice)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        if isYearly, let monthly = monthlyEquivalent {
                            Text("\(monthly)/mo")
                                .font(FGTypography.captionSmall)
                                .foregroundColor(FGColors.textTertiary)
                        } else {
                            Text("/month")
                                .font(FGTypography.captionSmall)
                                .foregroundColor(FGColors.textTertiary)
                        }
                    } else {
                        // Fallback prices if products not loaded
                        Text(fallbackPrice)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        Text(isYearly ? "/year" : "/month")
                            .font(FGTypography.captionSmall)
                            .foregroundColor(FGColors.textTertiary)
                    }
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? plan.accentColor : FGColors.borderDefault, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(plan.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(FGSpacing.cardPadding)
            .background(
                isSelected ? plan.accentColor.opacity(0.08) : FGColors.backgroundElevated
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(
                        isSelected ? plan.accentColor : FGColors.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var fallbackPrice: String {
        switch plan {
        case .starter:
            return isYearly ? "$54.99" : "$6.99"
        case .creator:
            return isYearly ? "$119.99" : "$14.99"
        case .pro:
            return isYearly ? "$279.99" : "$34.99"
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionPlanSheet()
        .environmentObject(StoreKitService())
        .environmentObject(CloudKitService())
}
