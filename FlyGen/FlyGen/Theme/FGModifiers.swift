import SwiftUI

/// FlyGen Design System - Aurora reusable surface/selection modifiers.
/// These encode the Aurora card, selection-ring, and CTA-glow treatments once so screens
/// can apply them consistently.
extension View {

    /// Aurora glass card: surface fill + hairline border, clipped to `cornerRadius`.
    func auroraCard(cornerRadius: CGFloat = FGSpacing.cardRadius,
                    fill: Color = FGColors.surfaceDefault) -> some View {
        self
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(FGColors.borderCard, lineWidth: 1)
            )
    }

    /// Aurora selection treatment. Owns the card's border in BOTH states so callers should
    /// not add their own: unselected = 1pt hairline; selected = 1.5pt indigo + 3pt outer ring.
    func auroraSelectionRing(_ isSelected: Bool,
                             cornerRadius: CGFloat = FGSpacing.cardRadius) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? FGColors.accentPrimary : FGColors.borderCard,
                                  lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                    .stroke(FGColors.selectionRing, lineWidth: 3)
                    .padding(-2)
                    .opacity(isSelected ? 1 : 0)
            )
            .animation(FGAnimations.ease, value: isSelected)
    }

    /// Aurora primary-CTA glow (indigo drop shadow). Disable to clear it.
    func auroraCTAGlow(_ active: Bool = true) -> some View {
        self.shadow(color: active ? FGColors.accentPrimary.opacity(0.45) : .clear,
                    radius: 20, y: 12)
    }

    /// Aurora result flyer card: rounded, faint indigo ring, deep drop shadow. Apply to the
    /// generated flyer image so the "your flyer" moment reads as premium.
    func auroraFlyerCard(cornerRadius: CGFloat = FGSpacing.flyerCardRadius) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(FGColors.accentPrimary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
    }
}
