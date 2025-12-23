import SwiftUI

struct NewUserOfferSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onClaimOffer: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Outer card container with border
            VStack(spacing: FGSpacing.lg) {
                Spacer()
                    .frame(height: FGSpacing.lg)

                    // Celebration icons
                    HStack(spacing: FGSpacing.xl) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundStyle(FGColors.accentSecondary)
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(FGColors.accentPrimary)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundStyle(FGColors.accentSecondary)
                    }

                    // Welcome text
                    VStack(spacing: FGSpacing.sm) {
                        Text("Welcome to FlyGen!")
                            .font(FGTypography.h1)
                            .foregroundColor(FGColors.textPrimary)

                        Text("ONE-TIME OFFER")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                            .foregroundColor(FGColors.accentSecondary)
                    }

                    // Discount badge
                    VStack(spacing: FGSpacing.xs) {
                        Text("50% OFF")
                            .font(.system(size: 52, weight: .black))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("YOUR FIRST PURCHASE")
                            .font(.system(size: 16, weight: .semibold))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .tracking(1.5)
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(.vertical, FGSpacing.lg)
                    .padding(.horizontal, FGSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .fill(Color(white: 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.cyan,
                                        Color.purple
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 12)
                    .shadow(color: Color.purple.opacity(0.3), radius: 20)

                    // Value proposition
                    VStack(spacing: FGSpacing.sm) {
                        Text("Start creating stunning AI-powered flyers")
                            .font(FGTypography.body)
                            .foregroundColor(FGColors.textPrimary)

                        Text("at HALF PRICE!")
                            .font(FGTypography.h3)
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    .multilineTextAlignment(.center)

                    // Urgency warning
                    HStack(spacing: FGSpacing.sm) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("This offer expires when you close this screen")
                            .font(FGTypography.labelSmall)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, FGSpacing.md)
                    .padding(.vertical, FGSpacing.sm)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )

                    Spacer()
                        .frame(height: FGSpacing.md)

                    // CTA Button
                    Button {
                        onClaimOffer()
                    } label: {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "flame.fill")
                            Text("Claim 50% Off Now")
                                .font(FGTypography.button)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(
                            LinearGradient(
                                colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.horizontal, FGSpacing.screenHorizontal)

                // Decline button (de-emphasized)
                Button {
                    onDecline()
                } label: {
                    Text("No thanks, I'll pay full price")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textTertiary)
                        .underline()
                }
                .padding(.top, FGSpacing.sm)

                Spacer()
                    .frame(height: FGSpacing.lg)
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(FGColors.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
            )
            .padding(.horizontal, FGSpacing.lg)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    NewUserOfferSheet(
        onClaimOffer: {},
        onDecline: {}
    )
}
