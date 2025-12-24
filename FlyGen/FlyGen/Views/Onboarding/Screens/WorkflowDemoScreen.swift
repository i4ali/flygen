import SwiftUI

/// Screen 2: Auto-flow workflow demo showcasing app features
struct WorkflowDemoScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 0) {
            // Top: Animation area (55%)
            animationArea
                .frame(maxHeight: .infinity)

            // Bottom: Demo content area (45%)
            demoContentArea
                .frame(height: UIScreen.main.bounds.height * 0.40)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap to skip to next step
            viewModel.advanceToNextStep()
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
            // Start auto-advancing demo
            viewModel.startAutoDemo()
        }
        .onDisappear {
            viewModel.stopAutoDemo()
        }
    }

    // MARK: - Animation Area

    private var animationArea: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentAccentColor.opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 30)

            // Lottie animation based on demo step
            LottieAnimationView(
                animationName: viewModel.demoStep.animationName,
                loopMode: .loop
            )
            .frame(width: 280, height: 200)
            .id(viewModel.demoStep.animationName) // Only recreate when animation changes
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(FGAnimations.spring, value: viewModel.demoStep)
        }
        .opacity(animateContent ? 1 : 0)
    }

    private var currentAccentColor: Color {
        switch viewModel.demoStep {
        case .category:
            return FGColors.accentPrimary
        case .style:
            return FGColors.accentSecondary
        case .textDetails:
            return .orange
        case .logo:
            return .green
        case .qrCode:
            return .blue
        case .colors:
            return .purple
        case .ready:
            return FGColors.accentGradientEnd
        }
    }

    // MARK: - Demo Content Area

    private var demoContentArea: some View {
        VStack(spacing: FGSpacing.md) {
            // Progress indicator
            progressDots
                .padding(.bottom, FGSpacing.xs)

            // Step title with step number
            VStack(spacing: FGSpacing.xxs) {
                if viewModel.demoStep != .ready {
                    Text("Step \(viewModel.demoStep.stepNumber) of 6")
                        .font(FGTypography.caption)
                        .foregroundColor(FGColors.textSecondary)
                }

                Text(viewModel.demoStep.title)
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textPrimary)
            }
            .animation(FGAnimations.spring, value: viewModel.demoStep)
            .id(viewModel.demoStep.title)

            // Dynamic content based on step
            Group {
                switch viewModel.demoStep {
                case .category:
                    categoryContent
                case .style:
                    styleContent
                case .textDetails:
                    textDetailsContent
                case .logo:
                    logoContent
                case .qrCode:
                    qrCodeContent
                case .colors:
                    colorsContent
                case .ready:
                    readyContent
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(FGAnimations.spring, value: viewModel.demoStep)

            Spacer()

            // Tap hint
            if viewModel.demoStep != .ready {
                Text("Tap anywhere to skip ahead")
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(.bottom, FGSpacing.sm)
            }
        }
        .padding(.top, FGSpacing.lg)
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: FGSpacing.xs) {
            ForEach(0..<7) { index in
                Circle()
                    .fill(index <= viewModel.demoStep.rawValue ? currentAccentColor : FGColors.borderSubtle)
                    .frame(width: index == viewModel.demoStep.rawValue ? 10 : 6,
                           height: index == viewModel.demoStep.rawValue ? 10 : 6)
                    .animation(FGAnimations.spring, value: viewModel.demoStep)
            }
        }
    }

    // MARK: - Step Contents

    private var categoryContent: some View {
        HStack(spacing: FGSpacing.sm) {
            ForEach(OnboardingViewModel.MockCategory.allCases) { category in
                AutoSelectChip(
                    title: category.rawValue,
                    emoji: category.emoji,
                    isSelected: viewModel.selectedCategory == category
                )
            }
        }
    }

    private var styleContent: some View {
        HStack(spacing: FGSpacing.sm) {
            ForEach(OnboardingViewModel.MockStyle.allCases) { style in
                AutoSelectChip(
                    title: style.rawValue,
                    emoji: style.emoji,
                    isSelected: viewModel.selectedStyle == style
                )
            }
        }
    }

    private var textDetailsContent: some View {
        VStack(spacing: FGSpacing.sm) {
            MockTextField(label: "Headline", value: viewModel.mockHeadline, icon: "text.quote")
            MockTextField(label: "Date", value: viewModel.mockDate, icon: "calendar")
            MockTextField(label: "Location", value: viewModel.mockLocation, icon: "mappin.circle")
        }
        .frame(maxWidth: 280)
    }

    private var logoContent: some View {
        VStack(spacing: FGSpacing.sm) {
            ZStack {
                Circle()
                    .fill(FGColors.surfaceHover)
                    .frame(width: 80, height: 80)

                if viewModel.hasLogo {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 36))
                        .foregroundColor(FGColors.textSecondary)
                }
            }
            .animation(FGAnimations.spring, value: viewModel.hasLogo)

            Text(viewModel.hasLogo ? "Logo added!" : "Your brand logo here")
                .font(FGTypography.caption)
                .foregroundColor(viewModel.hasLogo ? FGColors.accentPrimary : FGColors.textSecondary)
        }
    }

    private var qrCodeContent: some View {
        VStack(spacing: FGSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(FGColors.surfaceHover)
                    .frame(width: 90, height: 90)

                if viewModel.hasQRCode {
                    Image(systemName: "qrcode")
                        .font(.system(size: 50))
                        .foregroundColor(FGColors.textPrimary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 36))
                        .foregroundColor(FGColors.textSecondary)
                }
            }
            .animation(FGAnimations.spring, value: viewModel.hasQRCode)

            Text(viewModel.hasQRCode ? "QR Code ready!" : "Link to your website")
                .font(FGTypography.caption)
                .foregroundColor(viewModel.hasQRCode ? FGColors.accentPrimary : FGColors.textSecondary)
        }
    }

    private var colorsContent: some View {
        HStack(spacing: FGSpacing.sm) {
            ForEach(OnboardingViewModel.MockColorTheme.allCases) { theme in
                ColorThemeChip(
                    theme: theme,
                    isSelected: viewModel.selectedColorTheme == theme
                )
            }
        }
    }

    private var readyContent: some View {
        VStack(spacing: FGSpacing.md) {
            // Summary of all selections
            VStack(spacing: FGSpacing.sm) {
                // Row 1: Category + Style
                HStack(spacing: FGSpacing.sm) {
                    if let category = viewModel.selectedCategory {
                        SummaryBadge(emoji: category.emoji, label: category.rawValue)
                    }
                    if let style = viewModel.selectedStyle {
                        SummaryBadge(emoji: style.emoji, label: style.rawValue)
                    }
                }

                // Row 2: Features
                HStack(spacing: FGSpacing.sm) {
                    if viewModel.hasLogo {
                        SummaryBadge(icon: "photo.circle.fill", label: "Logo")
                    }
                    if viewModel.hasQRCode {
                        SummaryBadge(icon: "qrcode", label: "QR Code")
                    }
                    if let theme = viewModel.selectedColorTheme {
                        SummaryBadge(colors: theme.colors, label: theme.rawValue)
                    }
                }
            }

            Text("Your flyer is ready to generate!")
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Supporting Views

/// Auto-select chip (non-interactive, just displays state)
private struct AutoSelectChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            Text(emoji)
                .font(.system(size: 18))

            Text(title)
                .font(FGTypography.label)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textSecondary)
        }
        .padding(.horizontal, FGSpacing.md)
        .padding(.vertical, FGSpacing.sm)
        .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
            radius: isSelected ? 8 : 0
        )
        .animation(FGAnimations.spring, value: isSelected)
    }
}

/// Mock text field for text details step
private struct MockTextField: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(value.isEmpty ? FGColors.textSecondary : FGColors.accentPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)

                Text(value.isEmpty ? "..." : value)
                    .font(FGTypography.body)
                    .foregroundColor(value.isEmpty ? FGColors.textSecondary : FGColors.textPrimary)
            }

            Spacer()

            if !value.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(FGColors.accentPrimary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, FGSpacing.md)
        .padding(.vertical, FGSpacing.sm)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(value.isEmpty ? FGColors.borderSubtle : FGColors.accentPrimary.opacity(0.5), lineWidth: 1)
        )
        .animation(FGAnimations.spring, value: value)
    }
}

/// Color theme chip
private struct ColorThemeChip: View {
    let theme: OnboardingViewModel.MockColorTheme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: FGSpacing.xxs) {
            // Color preview
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.colors[index])
                        .frame(width: 12, height: 12)
                }
            }

            Text(theme.rawValue)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? FGColors.textPrimary : FGColors.textTertiary)
        }
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(isSelected ? FGColors.surfaceSelected : FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? FGColors.accentPrimary : FGColors.borderSubtle,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? FGColors.accentPrimary.opacity(0.3) : .clear,
            radius: isSelected ? 6 : 0
        )
        .animation(FGAnimations.spring, value: isSelected)
    }
}

/// Summary badge for ready state
private struct SummaryBadge: View {
    var emoji: String? = nil
    var icon: String? = nil
    var colors: [Color]? = nil
    let label: String

    var body: some View {
        HStack(spacing: FGSpacing.xxs) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 14))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(FGColors.accentPrimary)
            } else if let colors = colors {
                HStack(spacing: 1) {
                    ForEach(0..<colors.count, id: \.self) { index in
                        Circle()
                            .fill(colors[index])
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Text(label)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textPrimary)
        }
        .padding(.horizontal, FGSpacing.sm)
        .padding(.vertical, FGSpacing.xs)
        .background(FGColors.surfaceSelected)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(FGColors.accentPrimary.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview("Workflow Demo Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        WorkflowDemoScreen(viewModel: OnboardingViewModel())
    }
}
