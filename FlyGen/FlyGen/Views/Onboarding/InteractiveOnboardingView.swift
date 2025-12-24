import SwiftUI

/// Main coordinator for the interactive onboarding experience
struct InteractiveOnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: ([FlyerCategory]) -> Void

    var body: some View {
        ZStack {
            // Background
            FGColors.backgroundPrimary
                .ignoresSafeArea()

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    FGColors.accentPrimary.opacity(0.03),
                    FGColors.accentSecondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with skip button
                topBar

                // Screen content
                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom area with progress and buttons
                bottomArea
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            // Skip button (hidden on last screen)
            if !viewModel.isLastScreen {
                Button("Skip") {
                    onComplete(Array(viewModel.selectedCategories))
                }
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
                .padding(FGSpacing.md)
            }
        }
    }

    // MARK: - Screen Content

    @ViewBuilder
    private var screenContent: some View {
        switch viewModel.currentScreen {
        case .welcome:
            WelcomeScreen()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .workflowDemo:
            WorkflowDemoScreen(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .categoryPreferences:
            CategoryPreferencesScreen(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .sampleShowcase:
            SampleShowcaseScreen(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .aiGeneration:
            AIGenerationScreen()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        VStack(spacing: FGSpacing.lg) {
            // Progress indicator
            OnboardingProgressIndicator(
                currentPage: viewModel.currentScreen.rawValue,
                totalPages: viewModel.totalScreens
            )

            // Navigation buttons
            HStack(spacing: FGSpacing.md) {
                // Back button
                if viewModel.canGoBack {
                    Button {
                        viewModel.goToPreviousScreen()
                    } label: {
                        HStack(spacing: FGSpacing.xs) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(FGTypography.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(FGColors.surfaceDefault)
                        .foregroundColor(FGColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(FGCardButtonStyle())
                }

                // Continue / Get Started button
                Button {
                    if viewModel.isLastScreen {
                        // Complete onboarding
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onComplete(Array(viewModel.selectedCategories))
                    } else {
                        viewModel.goToNextScreen()
                    }
                } label: {
                    HStack(spacing: FGSpacing.xs) {
                        Text(buttonText)
                        if !viewModel.isLastScreen {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(FGTypography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FGSpacing.md)
                    .background(viewModel.canContinue ? FGColors.accentPrimary : FGColors.surfaceDefault)
                    .foregroundColor(viewModel.canContinue ? FGColors.textOnAccent : FGColors.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    .shadow(
                        color: viewModel.canContinue ? FGColors.accentPrimary.opacity(0.4) : .clear,
                        radius: 8,
                        y: 4
                    )
                }
                .buttonStyle(FGPrimaryButtonStyle(isEnabled: viewModel.canContinue))
                .disabled(!viewModel.canContinue)
            }
            .padding(.horizontal, FGSpacing.xl)
            .padding(.bottom, FGSpacing.xxl)
        }
    }

    private var buttonText: String {
        switch viewModel.currentScreen {
        case .welcome:
            return "Get Started"
        case .workflowDemo:
            return viewModel.canContinue ? "Continue" : "Try it out!"
        case .categoryPreferences:
            return viewModel.selectedPreferences.isEmpty ? "Skip" : "Continue"
        case .sampleShowcase:
            return "Continue"
        case .aiGeneration:
            return "Let's Create!"
        }
    }
}

#Preview("Interactive Onboarding") {
    InteractiveOnboardingView { categories in
        print("Onboarding complete with categories: \(categories)")
    }
}
