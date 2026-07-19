import SwiftUI

/// The onboarding demo of the app's proactive QR offer. Visually mirrors the real `QROfferBubble`
/// (accent-tinted card, `qrcode` glyph, Yes / No thanks). It plays itself: when `accepted` flips
/// true the "Yes, add it" button glows as if tapped and the choices dim - no real action; the
/// runner reveals the QR'd hero next. Display-only.
struct OnboardingQROfferView: View {
    let demo: QROfferDemo
    var accepted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            HStack(alignment: .top, spacing: FGSpacing.sm) {
                Image(systemName: "qrcode").font(.system(size: 16))
                    .foregroundColor(FGColors.accentSecondary).padding(.top, 2)
                Text(demo.prompt).font(FGTypography.body).foregroundColor(FGColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: FGSpacing.sm) {
                Label(demo.acceptLabel, systemImage: "checkmark").font(FGTypography.button)
                    .foregroundColor(FGColors.textOnAccent)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(FGColors.accentPrimary).clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .scaleEffect(accepted ? 0.96 : 1)
                    .shadow(color: FGColors.accentPrimary.opacity(accepted ? 0.6 : 0), radius: 14, y: 4)
                    .animation(FGAnimations.springBouncy, value: accepted)

                Text(demo.declineLabel)
                    .font(FGTypography.button).foregroundColor(FGColors.textSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, FGSpacing.sm)
                    .background(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius).stroke(FGColors.borderDefault, lineWidth: 1))
            }
            .opacity(accepted ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FGSpacing.md)
        .background(FGColors.accentSecondary.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.accentSecondary.opacity(0.35), lineWidth: 1))
        .allowsHitTesting(false)   // display-only demo
    }
}
