import SwiftUI

/// FlyGen Design System - Color Tokens
/// Dark-first Midjourney-inspired color palette
struct FGColors {

    // MARK: - Backgrounds (Dark-first)

    /// Primary background - near black (#0D0D0D)
    static let backgroundPrimary = Color(hex: "0D0D0D")

    /// Secondary background - dark gray (#1A1A1A)
    static let backgroundSecondary = Color(hex: "1A1A1A")

    /// Tertiary background - medium dark (#262626)
    static let backgroundTertiary = Color(hex: "262626")

    /// Elevated surfaces like cards (#2D2D2D)
    static let backgroundElevated = Color(hex: "2D2D2D")

    // MARK: - Surfaces (Interactive elements)

    /// Default interactive surface (#1F1F1F)
    static let surfaceDefault = Color(hex: "1F1F1F")

    /// Hover state surface (#2A2A2A)
    static let surfaceHover = Color(hex: "2A2A2A")

    /// Selected state surface (#3D3D3D)
    static let surfaceSelected = Color(hex: "3D3D3D")

    // MARK: - Accent Colors (AI-forward, vibrant)

    /// Primary accent - violet (#7C3AED)
    static let accentPrimary = Color(hex: "7C3AED")

    /// Secondary accent - cyan (#06B6D4)
    static let accentSecondary = Color(hex: "06B6D4")

    /// Accent gradient start - violet (#7C3AED)
    static let accentGradientStart = Color(hex: "7C3AED")

    /// Accent gradient end - pink (#EC4899)
    static let accentGradientEnd = Color(hex: "EC4899")

    // MARK: - Text Colors

    /// Primary text - white (#FFFFFF)
    static let textPrimary = Color.white

    /// Secondary text - light gray (#A3A3A3)
    static let textSecondary = Color(hex: "A3A3A3")

    /// Tertiary text - darker gray (#737373)
    static let textTertiary = Color(hex: "737373")

    /// Text on accent backgrounds (#FFFFFF)
    static let textOnAccent = Color.white

    // MARK: - Semantic Colors

    /// Success state - green (#22C55E)
    static let success = Color(hex: "22C55E")
    static let statusSuccess = success

    /// Warning state - amber (#F59E0B)
    static let warning = Color(hex: "F59E0B")
    static let statusWarning = warning

    /// Error state - red (#EF4444)
    static let error = Color(hex: "EF4444")
    static let statusError = error

    /// Info state - blue (#3B82F6)
    static let info = Color(hex: "3B82F6")

    // MARK: - Border Colors

    /// Default border (#404040)
    static let borderDefault = Color(hex: "404040")

    /// Subtle border (#2D2D2D)
    static let borderSubtle = Color(hex: "2D2D2D")

    /// Focus/selected border - matches accent (#7C3AED)
    static let borderFocus = accentPrimary
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
            // Backgrounds
            colorSection(title: "Backgrounds", colors: [
                ("Primary", FGColors.backgroundPrimary),
                ("Secondary", FGColors.backgroundSecondary),
                ("Tertiary", FGColors.backgroundTertiary),
                ("Elevated", FGColors.backgroundElevated)
            ])

            // Surfaces
            colorSection(title: "Surfaces", colors: [
                ("Default", FGColors.surfaceDefault),
                ("Hover", FGColors.surfaceHover),
                ("Selected", FGColors.surfaceSelected)
            ])

            // Accents
            colorSection(title: "Accents", colors: [
                ("Primary", FGColors.accentPrimary),
                ("Secondary", FGColors.accentSecondary),
                ("Gradient End", FGColors.accentGradientEnd)
            ])

            // Text
            colorSection(title: "Text", colors: [
                ("Primary", FGColors.textPrimary),
                ("Secondary", FGColors.textSecondary),
                ("Tertiary", FGColors.textTertiary)
            ])

            // Semantic
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
