import SwiftUI

/// Main coordinator for the interactive onboarding experience
struct InteractiveOnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: ([FlyerCategory], OnboardingViewModel) -> Void

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

            // Skip button (hidden on last screen, shown on skippable screens)
            if !viewModel.isLastScreen {
                if viewModel.currentScreen.isSkippable {
                    Button("Skip") {
                        viewModel.skipCurrentScreen()
                    }
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(FGSpacing.md)
                } else {
                    Button("Skip All") {
                        onComplete(Array(viewModel.selectedCategories), viewModel)
                    }
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(FGSpacing.md)
                }
            }
        }
        .padding(.top, FGSpacing.lg)
        .padding(.trailing, FGSpacing.sm)
    }

    // MARK: - Screen Content

    @ViewBuilder
    private var screenContent: some View {
        switch viewModel.currentScreen {
        case .welcome:
            WelcomeScreen()
                .transition(screenTransition)

        case .workflowDemo:
            WorkflowDemoScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .userRole:
            UserRoleScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .categoryPreferences:
            CategoryPreferencesScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .languagePreferences:
            LanguagePreferencesScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .brandKitIntro:
            BrandKitScreen()
                .transition(screenTransition)

        case .quickBrandSetup:
            QuickBrandSetupScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .buildingExperience:
            BuildingExperienceScreen(viewModel: viewModel) {
                viewModel.goToNextScreen()
            }
            .transition(screenTransition)

        case .personalizedSamples:
            SampleShowcaseScreen(viewModel: viewModel)
                .transition(screenTransition)

        case .readyToCreate:
            ReadyToCreateScreen(viewModel: viewModel)
                .transition(screenTransition)
        }
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        VStack(spacing: FGSpacing.lg) {
            // Progress indicator
            OnboardingProgressIndicator(
                currentPage: viewModel.currentScreen.rawValue,
                totalPages: viewModel.totalScreens
            )

            // Navigation buttons (hidden on building experience screen)
            if viewModel.currentScreen != .buildingExperience {
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
                            onComplete(Array(viewModel.selectedCategories), viewModel)
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
            } else {
                // Spacer for building experience screen
                Spacer()
                    .frame(height: FGSpacing.xxl + 60)
            }
        }
    }

    private var buttonText: String {
        switch viewModel.currentScreen {
        case .welcome:
            return "Get Started"
        case .workflowDemo:
            return viewModel.canContinue ? "Continue" : "Try it out!"
        case .userRole:
            return viewModel.selectedUserRole != nil ? "Continue" : "Skip"
        case .categoryPreferences:
            return viewModel.selectedFlyerCategories.isEmpty ? "Skip" : "Continue"
        case .languagePreferences:
            return "Continue"
        case .brandKitIntro:
            return "Continue"
        case .quickBrandSetup:
            return "Continue"
        case .buildingExperience:
            return "" // No button shown
        case .personalizedSamples:
            return "Continue"
        case .readyToCreate:
            return "Start Creating"
        }
    }
}

#Preview("Interactive Onboarding") {
    InteractiveOnboardingView { categories, viewModel in
        print("Onboarding complete with categories: \(categories)")
    }
}
