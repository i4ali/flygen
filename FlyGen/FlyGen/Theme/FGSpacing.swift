import SwiftUI

/// FlyGen Design System - Spacing Constants
/// Consistent spacing scale for layout and components
struct FGSpacing {

    // MARK: - Base Scale

    /// Extra extra extra small - 2pt
    static let xxxs: CGFloat = 2

    /// Extra extra small - 4pt
    static let xxs: CGFloat = 4

    /// Extra small - 8pt
    static let xs: CGFloat = 8

    /// Small - 12pt
    static let sm: CGFloat = 12

    /// Medium (base unit) - 16pt
    static let md: CGFloat = 16

    /// Large - 24pt
    static let lg: CGFloat = 24

    /// Extra large - 32pt
    static let xl: CGFloat = 32

    /// Extra extra large - 48pt
    static let xxl: CGFloat = 48

    /// Extra extra extra large - 64pt
    static let xxxl: CGFloat = 64

    // MARK: - Component-Specific

    /// Standard card internal padding - 16pt
    static let cardPadding: CGFloat = 16

    /// Card corner radius - 16pt
    static let cardRadius: CGFloat = 16

    /// Button corner radius - 12pt
    static let buttonRadius: CGFloat = 12

    /// Input field corner radius - 10pt
    static let inputRadius: CGFloat = 10

    /// Small component radius (chips, badges) - 8pt
    static let chipRadius: CGFloat = 8

    /// Full rounded (pills, toggles)
    static let pillRadius: CGFloat = 999

    // MARK: - Layout

    /// Screen horizontal padding - 16pt
    static let screenHorizontal: CGFloat = 16

    /// Screen vertical padding - 24pt
    static let screenVertical: CGFloat = 24

    /// Section spacing - 32pt
    static let sectionSpacing: CGFloat = 32

    /// Grid gap - 12pt
    static let gridGap: CGFloat = 12

    /// List item spacing - 8pt
    static let listSpacing: CGFloat = 8

    // MARK: - Touch Targets

    /// Minimum touch target - 44pt (Apple HIG)
    static let minTouchTarget: CGFloat = 44

    /// Standard button height - 50pt
    static let buttonHeight: CGFloat = 50

    /// Compact button height - 40pt
    static let buttonHeightCompact: CGFloat = 40

    /// Tab bar height - 83pt (including safe area)
    static let tabBarHeight: CGFloat = 83
}

// MARK: - Padding Helpers

extension View {
    /// Apply standard screen padding
    func fgScreenPadding() -> some View {
        self.padding(.horizontal, FGSpacing.screenHorizontal)
            .padding(.vertical, FGSpacing.screenVertical)
    }

    /// Apply standard card padding
    func fgCardPadding() -> some View {
        self.padding(FGSpacing.cardPadding)
    }

    /// Apply horizontal screen padding only
    func fgHorizontalPadding() -> some View {
        self.padding(.horizontal, FGSpacing.screenHorizontal)
    }
}

// MARK: - Frame Helpers

extension View {
    /// Set minimum touch target size
    func fgTouchTarget() -> some View {
        self.frame(minWidth: FGSpacing.minTouchTarget, minHeight: FGSpacing.minTouchTarget)
    }
}

// MARK: - Preview

#Preview("FGSpacing Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: FGSpacing.lg) {
            Text("Spacing Scale")
                .font(FGTypography.h2)
                .foregroundColor(FGColors.textPrimary)

            // Visual spacing scale
            VStack(alignment: .leading, spacing: FGSpacing.sm) {
                spacingRow("xxxs", FGSpacing.xxxs)
                spacingRow("xxs", FGSpacing.xxs)
                spacingRow("xs", FGSpacing.xs)
                spacingRow("sm", FGSpacing.sm)
                spacingRow("md", FGSpacing.md)
                spacingRow("lg", FGSpacing.lg)
                spacingRow("xl", FGSpacing.xl)
                spacingRow("xxl", FGSpacing.xxl)
            }

            Divider().background(FGColors.borderSubtle)

            Text("Component Radii")
                .font(FGTypography.h3)
                .foregroundColor(FGColors.textPrimary)

            HStack(spacing: FGSpacing.md) {
                radiusExample("Card", FGSpacing.cardRadius)
                radiusExample("Button", FGSpacing.buttonRadius)
                radiusExample("Input", FGSpacing.inputRadius)
                radiusExample("Chip", FGSpacing.chipRadius)
            }
        }
        .padding(FGSpacing.screenHorizontal)
    }
    .background(FGColors.backgroundPrimary)
}

@ViewBuilder
private func spacingRow(_ name: String, _ value: CGFloat) -> some View {
    HStack(spacing: FGSpacing.md) {
        Text(name)
            .font(FGTypography.label)
            .foregroundColor(FGColors.textSecondary)
            .frame(width: 40, alignment: .leading)

        RoundedRectangle(cornerRadius: 2)
            .fill(FGColors.accentPrimary)
            .frame(width: value, height: 16)

        Text("\(Int(value))pt")
            .font(FGTypography.caption)
            .foregroundColor(FGColors.textTertiary)
    }
}

@ViewBuilder
private func radiusExample(_ name: String, _ radius: CGFloat) -> some View {
    VStack(spacing: FGSpacing.xs) {
        RoundedRectangle(cornerRadius: radius)
            .fill(FGColors.surfaceDefault)
            .frame(width: 50, height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(FGColors.accentPrimary, lineWidth: 2)
            )

        Text(name)
            .font(FGTypography.captionSmall)
            .foregroundColor(FGColors.textTertiary)
    }
}
