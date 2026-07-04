import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @EnvironmentObject var entitlementService: EntitlementService
    @Environment(\.dismiss) var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://i4ali.github.io/flygen/privacy-policy.html")!

    // MARK: - Computed

    private var resolvedSelected: Product? {
        selectedProduct
            ?? entitlementService.products.first { $0.id == SubscriptionConfig.Product.monthly }
            ?? entitlementService.products.first
    }

    private var isLoading: Bool {
        entitlementService.products.isEmpty && !entitlementService.didAttemptProductLoad
    }

    private var loadFailed: Bool {
        entitlementService.products.isEmpty && entitlementService.didAttemptProductLoad
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FGSpacing.xl) {
                    heroSection
                    featureList
                    socialProof
                    planSelector
                    VStack(spacing: FGSpacing.sm) {
                        subscribeButton
                        cancelAnytime
                    }
                    restoreButton
                    disclosureText
                    legalLinks
                    Spacer(minLength: FGSpacing.xl)
                }
                .padding(.horizontal, FGSpacing.screenHorizontal)
            }
            .background(premiumBackground)
            .navigationTitle("")
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
        }
    }

    // MARK: - Background

    /// Near-black with a soft violet glow behind the hero - lifts the paywall off flat black.
    private var premiumBackground: some View {
        FGColors.backgroundPrimary
            .overlay(alignment: .top) {
                RadialGradient(colors: [FGColors.accentPrimary.opacity(0.20), .clear],
                               center: .top, startRadius: 0, endRadius: 360)
                    .frame(height: 520)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: FGSpacing.md) {
            ZStack {
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Image(systemName: "crown.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("FlyGen Premium")
                .font(FGTypography.displaySmall)
                .foregroundColor(FGColors.textPrimary)

            Text("Create flyers all month long")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, FGSpacing.lg)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: FGSpacing.sm) {
            FeatureRow(icon: "sparkles", text: "AI flyer generations, reset each period")
            FeatureRow(icon: "wand.and.stars", text: "Refine & resize your flyers")
            FeatureRow(icon: "globe", text: "All styles, formats & languages")
            FeatureRow(icon: "arrow.clockwise", text: "Quota resets every billing period")
        }
        .padding(FGSpacing.cardPadding)
        .background(FGColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Social Proof

    /// Real App Store reviews build trust right before the plan/price. Reviews live in
    /// `PaywallReview.reviews` - keep them real (App Store Review Guideline 2.3.1).
    private var socialProof: some View {
        VStack(spacing: FGSpacing.sm) {
            Text("LOVED ON THE APP STORE")
                .font(FGTypography.captionBold)
                .tracking(1.6)
                .foregroundStyle(
                    LinearGradient(colors: [FGColors.accentGradientStart, FGColors.accentGradientEnd],
                                   startPoint: .leading, endPoint: .trailing)
                )

            ForEach(PaywallReview.reviews) { review in
                ReviewCardView(review: review)
            }
        }
    }

    // MARK: - Plan Selector

    @ViewBuilder
    private var planSelector: some View {
        if isLoading {
            VStack(spacing: FGSpacing.sm) {
                ProgressView()
                    .tint(FGColors.accentPrimary)
                Text("Loading plans...")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.xl)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        } else if loadFailed {
            VStack(spacing: FGSpacing.sm) {
                Text("Couldn't load plans")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textPrimary)
                Text("Check your connection and try again.")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await entitlementService.loadProducts() }
                } label: {
                    Text("Retry")
                        .font(FGTypography.button)
                        .foregroundColor(FGColors.accentPrimary)
                }
                .padding(.top, FGSpacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(FGSpacing.xl)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        } else {
            VStack(spacing: FGSpacing.sm) {
                ForEach(entitlementService.products, id: \.id) { product in
                    PlanCard(
                        product: product,
                        isSelected: resolvedSelected?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            guard let product = resolvedSelected else { return }
            isPurchasing = true
            Task {
                defer { isPurchasing = false }
                if (try? await entitlementService.purchase(product)) == true
                    || entitlementService.isSubscribed
                {
                    dismiss()
                }
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(FGColors.textOnAccent)
                } else {
                    Text("Subscribe")
                        .font(FGTypography.buttonLarge)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FGSpacing.md)
            .foregroundColor(FGColors.textOnAccent)
            .background(
                entitlementService.products.isEmpty
                    ? AnyShapeStyle(FGColors.textTertiary)
                    : AnyShapeStyle(LinearGradient(
                        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
        }
        .disabled(entitlementService.products.isEmpty || isPurchasing || isRestoring)
    }

    // MARK: - Cancel Anytime reassurance

    /// Lowers purchase anxiety right at the CTA. Truthful - Apple subscriptions can be
    /// cancelled anytime in App Store settings (see the disclosure below).
    private var cancelAnytime: some View {
        HStack(spacing: FGSpacing.xxs) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 12))
                .foregroundColor(FGColors.success)
            Text("Cancel anytime")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            isRestoring = true
            Task {
                defer { isRestoring = false }
                await entitlementService.restore()
                if entitlementService.isSubscribed {
                    dismiss()
                }
            }
        } label: {
            if isRestoring {
                ProgressView()
                    .tint(FGColors.accentPrimary)
            } else {
                Text("Restore Purchases")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.accentPrimary)
            }
        }
        .disabled(isPurchasing || isRestoring)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: FGSpacing.sm) {
            Link("Terms of Use", destination: termsURL)
            Text("-")
                .foregroundColor(FGColors.textTertiary)
            Link("Privacy Policy", destination: privacyURL)
        }
        .font(FGTypography.caption)
        .foregroundColor(FGColors.textTertiary)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Disclosure

    private var subscriptionDescription: String {
        guard let product = resolvedSelected,
              let period = product.subscription?.subscriptionPeriod else { return "" }
        return "\(product.displayName) is \(product.displayPrice) per \(periodNoun(period))."
    }

    /// Human-readable billing-period noun.
    ///
    /// Normalizes on both `unit` and `value` because StoreKit reports a weekly
    /// subscription as `.day` / 7 (not `.week` / 1). Switching on `unit` alone
    /// would render "per day" for a weekly plan.
    private func periodNoun(_ period: Product.SubscriptionPeriod) -> String {
        switch (period.unit, period.value) {
        case (.day, 1):                return "day"
        case (.day, 7), (.week, 1):    return "week"
        case (.month, 1):              return "month"
        case (.month, 12), (.year, 1): return "year"
        default:
            let unit: String
            switch period.unit {
            case .day:   unit = "day"
            case .week:  unit = "week"
            case .month: unit = "month"
            case .year:  unit = "year"
            @unknown default: unit = "period"
            }
            return period.value == 1 ? unit : "\(period.value) \(unit)s"
        }
    }

    private var disclosureText: some View {
        VStack(spacing: FGSpacing.xs) {
            if !subscriptionDescription.isEmpty {
                Text(subscriptionDescription)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
            }
            Text("Payment will be charged to your Apple Account at confirmation of purchase. The subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage or cancel your subscription anytime in your App Store account settings.")
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textTertiary)
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24)

            Text(text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Review Card

private struct ReviewCardView: View {
    let review: PaywallReview

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            // Reviewer: gradient avatar + name/date + App Store mark.
            HStack(spacing: FGSpacing.sm) {
                Text(String(review.author.prefix(1)).uppercased())
                    .font(FGTypography.h4)
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: [FGColors.accentGradientStart, FGColors.accentGradientEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: FGColors.accentPrimary.opacity(0.45), radius: 8, y: 2)

                VStack(alignment: .leading, spacing: 1) {
                    Text(review.author)
                        .font(FGTypography.labelLarge)
                        .foregroundColor(FGColors.textPrimary)
                    if let date = review.date, !date.isEmpty {
                        Text(date)
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "apple.logo")
                    .font(.system(size: 15))
                    .foregroundColor(FGColors.textSecondary)
            }

            // Gold stars + review title.
            HStack(spacing: FGSpacing.xs) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(i < review.stars ? FGColors.warning : FGColors.borderDefault)
                    }
                }
                .shadow(color: FGColors.warning.opacity(0.5), radius: 5)
                if let title = review.title, !title.isEmpty {
                    Text(title)
                        .font(FGTypography.captionBold)
                        .foregroundColor(FGColors.textPrimary)
                }
            }

            Text(review.quote)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(FGSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [FGColors.accentPrimary.opacity(0.12), FGColors.backgroundElevated],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                Text("\u{201D}")   // decorative closing-quote watermark
                    .font(.system(size: 96, weight: .bold, design: .serif))
                    .foregroundColor(FGColors.accentPrimary.opacity(0.13))
                    .offset(x: -10, y: 14)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .stroke(
                    LinearGradient(colors: [FGColors.accentPrimary.opacity(0.45), FGColors.accentSecondary.opacity(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: FGColors.accentPrimary.opacity(0.16), radius: 18, y: 8)
    }
}

private struct PaywallReview: Identifiable {
    let id = UUID()
    let stars: Int
    let title: String?
    let quote: String
    let author: String
    let date: String?

    /// REAL App Store reviews. Add more real ones here as they come in - never fabricate
    /// testimonials (App Store Review Guideline 2.3.1 prohibits fake reviews).
    static let reviews: [PaywallReview] = [
        PaywallReview(
            stars: 5,
            title: "Game-changer",
            quote: "Just amazing, honestly a lifesaver.",
            author: "wisementor274",
            date: "Dec 19, 2025"
        ),
    ]
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    private var isMonthly: Bool {
        product.id == SubscriptionConfig.Product.monthly
    }

    private var allotmentText: String {
        switch product.id {
        case SubscriptionConfig.Product.weekly:  return "\(SubscriptionConfig.weeklyQuota) flyers / week"
        case SubscriptionConfig.Product.monthly: return "\(SubscriptionConfig.monthlyQuota) flyers / month"
        default: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FGSpacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? FGColors.accentPrimary : FGColors.textTertiary)

                VStack(alignment: .leading, spacing: FGSpacing.xxs) {
                    HStack(spacing: FGSpacing.xs) {
                        Text(product.displayName)
                            .font(FGTypography.h4)
                            .foregroundColor(FGColors.textPrimary)

                        if isMonthly {
                            Text("Best Value")
                                .font(FGTypography.captionBold)
                                .foregroundColor(FGColors.textOnAccent)
                                .padding(.horizontal, FGSpacing.sm)
                                .padding(.vertical, FGSpacing.xxxs)
                                .background(FGGradients.accent)
                                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
                                .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 6, y: 2)
                        }
                    }

                    if !allotmentText.isEmpty {
                        Text(allotmentText)
                            .font(FGTypography.caption)
                            .foregroundColor(FGColors.textSecondary)
                    }

                    Text(product.description.isEmpty ? product.displayPrice : product.description)
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(FGTypography.h4)
                    .foregroundColor(FGColors.textPrimary)
            }
            .padding(FGSpacing.cardPadding)
            .background(FGColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(
                        isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? FGColors.accentPrimary.opacity(0.35) : .clear, radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .animation(FGAnimations.spring, value: isSelected)
    }
}

#Preview {
    SubscriptionPaywallView()
        .environmentObject(EntitlementService())
}
