import SwiftUI

/// FlyGen Design System - Color Tokens
/// "Aurora" direction: controlled indigo→cyan accent on a cool near-black base, glass surfaces.
/// Property names are stable; only values change (plus new Aurora-specific tokens at the bottom).
struct FGColors {

    // MARK: - Backgrounds (cool near-black)

    /// Primary background - cool near-black (#0A0B0F)  [Aurora bg/base]
    static let backgroundPrimary = Color(hex: "0A0B0F")

    /// Secondary background - slightly lifted base (#0F1116)
    static let backgroundSecondary = Color(hex: "0F1116")

    /// Tertiary background - chip/scrim tone (#1B1E27)
    static let backgroundTertiary = Color(hex: "1B1E27")

    /// Elevated surfaces (#1E2129)
    static let backgroundElevated = Color(hex: "1E2129")

    // MARK: - Surfaces (glass-like interactive elements)

    /// Default interactive surface - cards, inputs, pills (#13151B)  [Aurora surface]
    static let surfaceDefault = Color(hex: "13151B")

    /// Hover/pressed surface (#191C24)
    static let surfaceHover = Color(hex: "191C24")

    /// Selected surface - indigo-tinted (#1C2033)
    static let surfaceSelected = Color(hex: "1C2033")

    // MARK: - Accent Colors (controlled indigo → cyan)

    /// Primary accent - indigo (#7C8CF8). Active states, icons, rings.
    static let accentPrimary = Color(hex: "7C8CF8")

    /// Secondary accent - cyan (#63E6D2). Live dot, brand gradient, highlights.
    static let accentSecondary = Color(hex: "63E6D2")

    /// Accent gradient start - indigo (#7C8CF8)
    static let accentGradientStart = Color(hex: "7C8CF8")

    /// Accent gradient end - deep indigo (#8B7CF8). Replaces the retired pink.
    static let accentGradientEnd = Color(hex: "8B7CF8")

    // MARK: - Text Colors

    /// Primary text - near-white (#EDEFF4). Headlines, primary labels.
    static let textPrimary = Color(hex: "EDEFF4")

    /// Secondary text - cool gray (#8A90A0). Body copy, sublabels.
    static let textSecondary = Color(hex: "8A90A0")

    /// Tertiary text - muted (#565C6B). Field labels, meta, inactive tab.
    static let textTertiary = Color(hex: "565C6B")

    /// Text on accent/gradient backgrounds - white (#FFFFFF)
    static let textOnAccent = Color.white

    // MARK: - Semantic Colors (keep meaning-colors)

    /// Success state - green (#22C55E)
    static let success = Color(hex: "22C55E")
    static let statusSuccess = success

    /// Warning state - amber (#F59E0B)
    static let warning = Color(hex: "F59E0B")
    static let statusWarning = warning

    /// Error state - red (#EF4444)
    static let error = Color(hex: "EF4444")
    static let statusError = error

    /// Info state - indigo (aligns to accent) (#7C8CF8)
    static let info = Color(hex: "7C8CF8")

    // MARK: - Border Colors (hairline glass edges)

    /// Default border - subtle white hairline
    static let borderDefault = Color.white.opacity(0.12)

    /// Subtle border - card/input hairline (Aurora border/card ≈ rgba(255,255,255,0.07))
    static let borderSubtle = Color.white.opacity(0.07)

    /// Focus/selected border - matches indigo accent
    static let borderFocus = accentPrimary

    // MARK: - Aurora tokens (new)

    /// Deep indigo - CTA gradient end (#8B7CF8)
    static let accentIndigoDeep = Color(hex: "8B7CF8")

    /// Filled input value text on cards (#DDE0E8)
    static let textOnCardBody = Color(hex: "DDE0E8")

    /// Input field label text on cards (#B4BAC8)
    static let textOnCardLabel = Color(hex: "B4BAC8")

    /// Card & input border (rgba(255,255,255,0.07))
    static let borderCard = Color.white.opacity(0.07)

    /// Dividers, hero panel, tab-bar top (rgba(255,255,255,0.06))
    static let borderHairline = Color.white.opacity(0.06)

    /// Selected card/input glow ring (rgba(124,140,248,0.12))
    static let selectionRing = accentPrimary.opacity(0.12)

    /// Progress dash (unfilled) (#20222C)
    static let segmentInactive = Color(hex: "20222C")
}

// MARK: - Color Extensions for Theme

extension Color {
    /// Convenience for creating colors with opacity
    func fg_opacity(_ value: Double) -> Color {
        self.opacity(value)
    }
}

// MARK: - Preview

#Preview("FGColors Palette") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            colorSection(title: "Backgrounds", colors: [
                ("Primary", FGColors.backgroundPrimary),
                ("Secondary", FGColors.backgroundSecondary),
                ("Tertiary", FGColors.backgroundTertiary),
                ("Elevated", FGColors.backgroundElevated)
            ])

            colorSection(title: "Surfaces", colors: [
                ("Default", FGColors.surfaceDefault),
                ("Hover", FGColors.surfaceHover),
                ("Selected", FGColors.surfaceSelected)
            ])

            colorSection(title: "Accents", colors: [
                ("Indigo", FGColors.accentPrimary),
                ("Cyan", FGColors.accentSecondary),
                ("Indigo Deep", FGColors.accentIndigoDeep)
            ])

            colorSection(title: "Text", colors: [
                ("Primary", FGColors.textPrimary),
                ("Secondary", FGColors.textSecondary),
                ("Tertiary", FGColors.textTertiary)
            ])

            colorSection(title: "Semantic", colors: [
                ("Success", FGColors.success),
                ("Warning", FGColors.warning),
                ("Error", FGColors.error),
                ("Info", FGColors.info)
            ])
        }
        .padding()
    }
    .background(FGColors.backgroundPrimary)
}

@ViewBuilder
private func colorSection(title: String, colors: [(String, Color)]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.headline)
            .foregroundColor(FGColors.textPrimary)

        HStack(spacing: 12) {
            ForEach(colors, id: \.0) { name, color in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FGColors.borderDefault, lineWidth: 1)
                        )

                    Text(name)
                        .font(.caption2)
                        .foregroundColor(FGColors.textSecondary)
                }
            }
        }
    }
}
