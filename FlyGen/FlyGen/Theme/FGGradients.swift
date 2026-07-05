import SwiftUI

/// FlyGen Design System - Gradient Presets
/// "Aurora" direction: controlled indigo→cyan. Pink is retired; mood gradients are desaturated
/// into the indigo/cyan family. Property names are stable so call sites keep working.
struct FGGradients {

    // MARK: - Background Gradients

    /// Hero background - near-black with a faint indigo lift
    static let heroBackground = LinearGradient(
        colors: [
            Color(hex: "0A0B0F"),
            Color(hex: "0D0F18"),
            Color(hex: "0A0B0F")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark ambient gradient for screens
    static let ambientBackground = LinearGradient(
        colors: [
            FGColors.backgroundPrimary,
            Color(hex: "0C0E16"),
            FGColors.backgroundPrimary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle radial glow for focus areas (indigo)
    static let radialGlow = RadialGradient(
        colors: [
            FGColors.accentPrimary.opacity(0.15),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )

    /// Home hero panel fill - radial 90% 120% at 30% 10%, #1C2140 → #0D0F18
    static let heroPanelRadial = EllipticalGradient(
        colors: [Color(hex: "1C2140"), Color(hex: "0D0F18")],
        center: UnitPoint(x: 0.3, y: 0.1),
        startRadiusFraction: 0,
        endRadiusFraction: 0.95
    )

    /// Generating screen backdrop - radial 120% 55% at 50% 24%, #161A30 → #0A0B0F
    static let generatingRadial = EllipticalGradient(
        colors: [Color(hex: "161A30"), Color(hex: "0A0B0F")],
        center: UnitPoint(x: 0.5, y: 0.24),
        startRadiusFraction: 0,
        endRadiusFraction: 0.62
    )

    /// Paywall backdrop - radial 120% 50% at 50% 0%, #1A1F3D → #0A0B0F
    static let paywallRadial = EllipticalGradient(
        colors: [Color(hex: "1A1F3D"), Color(hex: "0A0B0F")],
        center: UnitPoint(x: 0.5, y: 0.0),
        startRadiusFraction: 0,
        endRadiusFraction: 0.55
    )

    /// Result flyer canvas - 165° #12162E → #0B0D18
    static let flyerCanvas = LinearGradient(
        colors: [Color(hex: "12162E"), Color(hex: "0B0D18")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Accent Gradients

    /// Primary CTA gradient - 135° indigo → deep indigo (#7C8CF8 → #8B7CF8)
    static let accent = LinearGradient(
        colors: [FGColors.accentPrimary, FGColors.accentIndigoDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Brand gradient - 140° indigo → cyan (#7C8CF8 → #63E6D2). Logo mark, premium badge.
    static let brand = LinearGradient(
        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary accent gradient - indigo → cyan (kept name; now the brand direction)
    static let accentSecondary = LinearGradient(
        colors: [FGColors.accentPrimary, FGColors.accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Conic sweep for the hero orb & generating spinner (indigo → cyan → indigo)
    static let orbConic = AngularGradient(
        colors: [FGColors.accentPrimary, FGColors.accentSecondary, FGColors.accentPrimary],
        center: .center
    )

    /// Restrained multi-stop sweep (indigo → deep indigo → cyan) - replaces the old rainbow
    static let rainbow = LinearGradient(
        colors: [
            Color(hex: "7C8CF8"),
            Color(hex: "8B7CF8"),
            Color(hex: "63E6D2")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Card Effects

    /// Shine/gloss effect for cards
    static let cardShine = LinearGradient(
        colors: [
            Color.white.opacity(0.06),
            Color.clear,
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Selected card glow overlay (indigo)
    static let selectedGlow = LinearGradient(
        colors: [
            FGColors.accentPrimary.opacity(0.2),
            FGColors.accentPrimary.opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Border gradient for premium elements (indigo → deep indigo → cyan)
    static let borderGlow = LinearGradient(
        colors: [
            FGColors.accentPrimary,
            FGColors.accentIndigoDeep,
            FGColors.accentSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Status Gradients (keep meaning-colors)

    static let success = LinearGradient(
        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let warning = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let error = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Mood Gradients (desaturated into the indigo/cyan family)

    /// All moods now read within the Aurora accent family. Subtle variation is kept for
    /// differentiation, but pink/amber/green mood colors are retired.
    static func moodGradient(for mood: String) -> LinearGradient {
        func lg(_ a: String, _ b: String) -> LinearGradient {
            LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        switch mood.lowercased() {
        case "urgent", "exciting", "festive", "inspirational":
            return lg("7C8CF8", "8B7CF8")   // energetic - indigo → deep indigo
        case "calm", "friendly":
            return lg("7C8CF8", "63E6D2")   // fresh - indigo → cyan
        case "professional", "serious", "somber":
            return lg("3A4166", "1C2033")   // muted indigo
        case "elegant", "romantic":
            return lg("8B7CF8", "63E6D2")   // deep indigo → cyan
        default:
            return brand
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

            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Backgrounds").font(FGTypography.label).foregroundColor(FGColors.textSecondary)
                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Hero", FGGradients.heroBackground)
                    gradientSwatch("Ambient", FGGradients.ambientBackground)
                }
            }

            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Accents").font(FGTypography.label).foregroundColor(FGColors.textSecondary)
                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("CTA", FGGradients.accent)
                    gradientSwatch("Brand", FGGradients.brand)
                    gradientSwatch("Sweep", FGGradients.rainbow)
                }
            }

            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Card Effects").font(FGTypography.label).foregroundColor(FGColors.textSecondary)
                HStack(spacing: FGSpacing.md) {
                    gradientSwatch("Shine", FGGradients.cardShine)
                    gradientSwatch("Selected", FGGradients.selectedGlow)
                    gradientSwatch("Border", FGGradients.borderGlow)
                }
            }

            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                Text("Status").font(FGTypography.label).foregroundColor(FGColors.textSecondary)
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
