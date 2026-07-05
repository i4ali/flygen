import SwiftUI

/// FlyGen Design System - Typography Scale
/// "Aurora" direction: a single precise typeface, Space Grotesk (weights 400/500/600/700).
/// Roles keep their names/sizes so the ~429 call sites inherit the new family automatically;
/// `.custom(_:fixedSize:)` preserves the current fixed-size (pixel-spec) behavior.
struct FGTypography {

    /// The four bundled Space Grotesk faces.
    private enum SGFace: String {
        case regular = "SpaceGrotesk-Regular"
        case medium = "SpaceGrotesk-Medium"
        case semibold = "SpaceGrotesk-SemiBold"
        case bold = "SpaceGrotesk-Bold"
    }

    /// Space Grotesk at a fixed point size (preserves the current fixed-size, pixel-spec behavior).
    private static func sg(_ size: CGFloat, _ face: SGFace = .regular) -> Font {
        .custom(face.rawValue, fixedSize: size)
    }

    // MARK: - Display (Hero text)

    static let displayLarge = sg(48, .bold)
    static let displayMedium = sg(36, .bold)
    static let displaySmall = sg(28, .bold)

    // MARK: - Headings

    static let h1 = sg(28, .bold)
    static let h2 = sg(24, .semibold)
    static let h3 = sg(20, .semibold)
    static let h4 = sg(17, .semibold)

    // MARK: - Body Text

    static let bodyLarge = sg(17, .regular)
    static let body = sg(15, .regular)
    static let bodySmall = sg(13, .regular)

    // MARK: - Labels

    static let labelLarge = sg(15, .medium)
    static let label = sg(13, .medium)
    static let labelSmall = sg(11, .medium)

    // MARK: - Captions

    static let caption = sg(12, .regular)
    static let captionBold = sg(12, .semibold)
    static let captionSmall = sg(10, .regular)

    // MARK: - Buttons

    static let buttonLarge = sg(17, .semibold)
    static let button = sg(15, .semibold)
    static let buttonSmall = sg(13, .semibold)

    // MARK: - Monospace (technical content - Space Grotesk isn't mono, keep system)

    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Aurora-exact roles (hero screens)

    /// Screen title - 29/700 (pair with Tracking.screenTitle)
    static let screenTitle = sg(29, .bold)
    /// Home hero title - 30/700 (pair with Tracking.heroTitle)
    static let heroTitle = sg(30, .bold)
    /// Section / result title - 16/600 (pair with Tracking.sectionTitle)
    static let sectionTitle = sg(16, .semibold)
    /// Wordmark "FlyGen" - 19/700 (pair with Tracking.wordmark)
    static let wordmark = sg(19, .bold)
    /// Filled input value - 16/600
    static let fieldValue = sg(16, .semibold)
    /// Field label - 13/400
    static let fieldLabel = sg(13, .regular)
    /// Review row label - 11.5/500 UPPERCASE (pair with Tracking.reviewLabel + .textCase(.uppercase))
    static let reviewLabel = sg(11.5, .medium)
    /// Button label - 16/600
    static let buttonLabel = sg(16, .semibold)
    /// Step count / meta - 12.5/500
    static let stepMeta = sg(12.5, .medium)
    /// Tab label - 11/600 active, use `tabLabelInactive` for inactive
    static let tabLabel = sg(11, .semibold)
    static let tabLabelInactive = sg(11, .regular)

    /// Aurora tracking values (points). `Font` can't carry tracking, so apply via `.tracking(_:)`
    /// on the matching role. Values = em × size.
    enum Tracking {
        static let screenTitle: CGFloat = -1.0    // -0.035em @ 29
        static let heroTitle: CGFloat = -1.05     // -0.035em @ 30
        static let sectionTitle: CGFloat = -0.32  // -0.02em  @ 16
        static let wordmark: CGFloat = -0.57      // -0.03em  @ 19
        static let reviewLabel: CGFloat = 0.92    // +0.08em  @ 11.5
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply FlyGen heading style
    func fgHeading(_ style: FGHeadingStyle = .h2) -> some View {
        self
            .font(style.font)
            .foregroundColor(FGColors.textPrimary)
    }

    /// Apply FlyGen body style
    func fgBody(_ style: FGBodyStyle = .regular) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }

    /// Apply FlyGen label style
    func fgLabel(_ style: FGLabelStyle = .regular) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }
}

enum FGHeadingStyle {
    case h1, h2, h3, h4

    var font: Font {
        switch self {
        case .h1: return FGTypography.h1
        case .h2: return FGTypography.h2
        case .h3: return FGTypography.h3
        case .h4: return FGTypography.h4
        }
    }
}

enum FGBodyStyle {
    case large, regular, small

    var font: Font {
        switch self {
        case .large: return FGTypography.bodyLarge
        case .regular: return FGTypography.body
        case .small: return FGTypography.bodySmall
        }
    }

    var color: Color {
        switch self {
        case .large: return FGColors.textPrimary
        case .regular: return FGColors.textSecondary
        case .small: return FGColors.textTertiary
        }
    }
}

enum FGLabelStyle {
    case large, regular, small

    var font: Font {
        switch self {
        case .large: return FGTypography.labelLarge
        case .regular: return FGTypography.label
        case .small: return FGTypography.labelSmall
        }
    }

    var color: Color {
        FGColors.textSecondary
    }
}

// MARK: - Preview

#Preview("FGTypography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Space Grotesk").font(FGTypography.labelSmall).foregroundColor(FGColors.textTertiary)
                Text("Screen title 29").font(FGTypography.screenTitle).tracking(FGTypography.Tracking.screenTitle).foregroundColor(FGColors.textPrimary)
                Text("Hero title 30").font(FGTypography.heroTitle).tracking(FGTypography.Tracking.heroTitle).foregroundColor(FGColors.textPrimary)
                Text("Heading 2").font(FGTypography.h2).foregroundColor(FGColors.textPrimary)
                Text("Section title 16").font(FGTypography.sectionTitle).foregroundColor(FGColors.textPrimary)
                Text("Body regular 15 - a guided brief in, a polished layout out.").font(FGTypography.body).foregroundColor(FGColors.textSecondary)
                Text("Field label 13").font(FGTypography.fieldLabel).foregroundColor(FGColors.textTertiary)
                Text("REVIEW LABEL").font(FGTypography.reviewLabel).tracking(FGTypography.Tracking.reviewLabel).textCase(.uppercase).foregroundColor(FGColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .background(FGColors.backgroundPrimary)
}
