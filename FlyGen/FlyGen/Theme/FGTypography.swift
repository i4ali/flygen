import SwiftUI

/// FlyGen Design System - Typography Scale
/// Bold, modern typography for AI-forward aesthetic
struct FGTypography {

    // MARK: - Display (Hero text)

    /// Large display text - 48pt bold rounded
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)

    /// Medium display text - 36pt bold rounded
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)

    /// Small display text - 28pt bold rounded
    static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)

    // MARK: - Headings

    /// Heading 1 - 28pt bold rounded
    static let h1 = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Heading 2 - 24pt semibold rounded
    static let h2 = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Heading 3 - 20pt semibold
    static let h3 = Font.system(size: 20, weight: .semibold, design: .default)

    /// Heading 4 - 17pt semibold
    static let h4 = Font.system(size: 17, weight: .semibold, design: .default)

    // MARK: - Body Text

    /// Large body text - 17pt regular
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Standard body text - 15pt regular
    static let body = Font.system(size: 15, weight: .regular, design: .default)

    /// Small body text - 13pt regular
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Labels

    /// Large label - 15pt medium
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)

    /// Standard label - 13pt medium
    static let label = Font.system(size: 13, weight: .medium, design: .default)

    /// Small label - 11pt medium
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Captions

    /// Caption text - 12pt regular
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Bold caption text - 12pt semibold
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

    /// Extra small caption - 10pt regular
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)

    // MARK: - Buttons

    /// Large button text - 17pt semibold
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .default)

    /// Standard button text - 15pt semibold
    static let button = Font.system(size: 15, weight: .semibold, design: .default)

    /// Small button text - 13pt semibold
    static let buttonSmall = Font.system(size: 13, weight: .semibold, design: .default)

    // MARK: - Monospace (for technical content)

    /// Monospace body - 14pt
    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)

    /// Small monospace - 12pt
    static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
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
        VStack(alignment: .leading, spacing: 24) {
            // Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Display")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textTertiary)

                Text("Display Large")
                    .font(FGTypography.displayLarge)
                    .foregroundColor(FGColors.textPrimary)

                Text("Display Medium")
                    .font(FGTypography.displayMedium)
                    .foregroundColor(FGColors.textPrimary)

                Text("Display Small")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
            }

            Divider().background(FGColors.borderSubtle)

            // Headings
            VStack(alignment: .leading, spacing: 8) {
                Text("Headings")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textTertiary)

                Text("Heading 1")
                    .font(FGTypography.h1)
                    .foregroundColor(FGColors.textPrimary)

                Text("Heading 2")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                Text("Heading 3")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)

                Text("Heading 4")
                    .font(FGTypography.h4)
                    .foregroundColor(FGColors.textPrimary)
            }

            Divider().background(FGColors.borderSubtle)

            // Body
            VStack(alignment: .leading, spacing: 8) {
                Text("Body")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textTertiary)

                Text("Body Large - Primary text for important content")
                    .font(FGTypography.bodyLarge)
                    .foregroundColor(FGColors.textPrimary)

                Text("Body Regular - Standard content text throughout the app")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)

                Text("Body Small - Secondary or supplementary information")
                    .font(FGTypography.bodySmall)
                    .foregroundColor(FGColors.textTertiary)
            }

            Divider().background(FGColors.borderSubtle)

            // Labels & Captions
            VStack(alignment: .leading, spacing: 8) {
                Text("Labels & Captions")
                    .font(FGTypography.labelSmall)
                    .foregroundColor(FGColors.textTertiary)

                Text("Label Large")
                    .font(FGTypography.labelLarge)
                    .foregroundColor(FGColors.textSecondary)

                Text("Label Regular")
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.textSecondary)

                Text("Caption Bold")
                    .font(FGTypography.captionBold)
                    .foregroundColor(FGColors.textSecondary)

                Text("Caption Regular")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textTertiary)
            }
        }
        .padding()
    }
    .background(FGColors.backgroundPrimary)
}
