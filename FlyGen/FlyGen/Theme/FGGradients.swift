import SwiftUI

/// FlyGen Design System - Gradient Presets
/// Dramatic gradients for the Midjourney-inspired aesthetic
struct FGGradients {

    // MARK: - Background Gradients

    /// Hero background gradient with subtle purple tint
    static let heroBackground = LinearGradient(
        colors: [
            Color(hex: "0D0D0D"),
            Color(hex: "1A0A2E"),  // Subtle purple tint
            Color(hex: "0D0D0D")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark ambient gradient for screens
    static let ambientBackground = LinearGradient(
        colors: [
            FGColors.backgroundPrimary,
            Color(hex: "0F0F1A"),  // Very subtle blue
            FGColors.backgroundPrimary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle radial glow for focus areas
    static let radialGlow = RadialGradient(
        colors: [
            FGColors.accentPrimary.opacity(0.15),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )

    // MARK: - Accent Gradients

    /// Primary accent gradient (violet to pink)
    static let accent = LinearGradient(
        colors: [FGColors.accentPrimary, FGColors.accentGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary accent gradient (cyan to violet)
    static let accentSecondary = LinearGradient(
        colors: [FGColors.accentSecondary, FGColors.accentPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Vibrant multi-color gradient
    static let rainbow = LinearGradient(
        colors: [
            Color(hex: "7C3AED"),  // Violet
            Color(hex: "EC4899"),  // Pink
            Color(hex: "F59E0B"),  // Amber
            Color(hex: "06B6D4")   // Cyan
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Card Effects

    /// Shine/gloss effect for cards
    static let cardShine = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.clear,
            Color.white.opacity(0.03)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Selected card glow overlay
    static let selectedGlow = LinearGradient(
        colors: [
            FGColors.accentPrimary.opacity(0.2),
            FGColors.accentPrimary.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Border gradient for premium elements
    static let borderGlow = LinearGradient(
        colors: [
            FGColors.accentPrimary,
            FGColors.accentGradientEnd,
            FGColors.accentSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Status Gradients

    /// Success gradient
    static let success = LinearGradient(
        colors: [
            Color(hex: "22C55E"),
            Color(hex: "16A34A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient
    static let warning = LinearGradient(
        colors: [
            Color(hex: "F59E0B"),
            Color(hex: "D97706")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Error gradient
    static let error = LinearGradient(
        colors: [
            Color(hex: "EF4444"),
            Color(hex: "DC2626")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Mood Gradients (for mood selection cards)

    static func moodGradient(for mood: String) -> LinearGradient {
        switch mood.lowercased() {
        case "urgent":
            return LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "F97316")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "exciting":
            return LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "EAB308")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "calm":
            return LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "0EA5E9")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "elegant":
            return LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "A855F7")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "friendly":
            return LinearGradient(colors: [Color(hex: "22C55E"), Color(hex: "10B981")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "professional":
            return LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "1D4ED8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "festive":
            return LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "F43F5E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "serious":
            return LinearGradient(colors: [Color(hex: "475569"), Color(hex: "334155")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "inspirational":
            return LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FB923C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "romantic":
            return LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "DB2777")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "somber":
            return LinearGradient(colors: [Color(hex: "6B7280"), Color(hex: "4B5563")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return accent
        }
    }
}

// MARK: - Gradient View Modifiers

extension View {
    /// Apply hero background gradient
    func fgHeroBackground() -> some View {
        self.background(FGGradients.heroBackground)
    }

    /// Apply ambient background gradient
    func fgAmbientBackground() -> some View {
        self.background(FGGradients.ambientBackground)
    }

    /// Apply card shine overlay
    func fgCardShine() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                .fill(FGGradients.cardShine)
        )
    }
}

// MARK: - Preview

#Preview("FGGradients") {
    ScrollView {
        VStack(spacing: FGSpacing.lg) {
            Text("Gradients")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)

            // Background gradients
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Backgrounds")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Hero", FGGradients.heroBackground)
                    gradientSwatch("Ambient", FGGradients.ambientBackground)
                }
            }

            // Accent gradients
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Accents")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Primary", FGGradients.accent)
                    gradientSwatch("Secondary", FGGradients.accentSecondary)
                    gradientSwatch("Rainbow", FGGradients.rainbow)
                }
            }

            // Card effects
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Card Effects")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Shine", FGGradients.cardShine)
                    gradientSwatch("Selected", FGGradients.selectedGlow)
                    gradientSwatch("Border", FGGradients.borderGlow)
                }
            }

            // Status gradients
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Status")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Success", FGGradients.success)
                    gradientSwatch("Warning", FGGradients.warning)
                    gradientSwatch("Error", FGGradients.error)
                }
            }
        }
        .padding(FGSpacing.screenHorizontal)
    }
    .background(FGColors.backgroundPrimary)
}

@ViewBuilder
private func gradientSwatch(_ name: String, _ gradient: LinearGradient) -> some View {
    VStack(spacing: FGSpacing.xs) {
        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
            .fill(gradient)
            .frame(width: 80, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                    .stroke(FGColors.borderSubtle, lineWidth: 1)
            )

        Text(name)
            .font(FGTypography.captionSmall)
            .foregroundColor(FGColors.textTertiary)
    }
}
