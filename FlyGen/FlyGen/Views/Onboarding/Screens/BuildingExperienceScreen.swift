import SwiftUI

/// Screen 8: Animated personalization loading screen
struct BuildingExperienceScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onAutoAdvance: () -> Void

    @State private var animateContent = false
    @State private var checklistProgress = 0
    @State private var showCheck1 = false
    @State private var showCheck2 = false
    @State private var showCheck3 = false

    private let checklistItems = [
        "Personalizing your templates...",
        "Setting up your workspace...",
        "Almost ready..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lottie animation
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FGColors.accentPrimary.opacity(0.3),
                                FGColors.accentSecondary.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 40)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1.05 : 1)
                    .animation(FGAnimations.breathe, value: animateContent)

                // Lottie animation
                LottieAnimationView(animationName: "onboarding-loading", loopMode: .loop)
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
            }

            Spacer()
                .frame(height: FGSpacing.xxl)

            // Checklist
            VStack(spacing: FGSpacing.md) {
                ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, item in
                    ChecklistItem(
                        text: item,
                        isComplete: checklistProgress > index,
                        isActive: checklistProgress == index
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
            }
            .padding(.horizontal, FGSpacing.screenHorizontal)

            Spacer()
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Fade in content
        withAnimation(FGAnimations.spring.delay(0.2)) {
            animateContent = true
        }

        // Progress through checklist items
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(FGAnimations.spring) {
                checklistProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(FGAnimations.spring) {
                checklistProgress = 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(FGAnimations.spring) {
                checklistProgress = 3
            }
        }

        // Auto-advance after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onAutoAdvance()
        }
    }
}

// MARK: - Checklist Item

private struct ChecklistItem: View {
    let text: String
    let isComplete: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: FGSpacing.md) {
            // Check icon
            ZStack {
                Circle()
                    .fill(isComplete ? FGColors.accentPrimary : FGColors.surfaceHover)
                    .frame(width: 28, height: 28)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FGColors.textOnAccent)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    // Loading spinner
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FGColors.accentPrimary))
                        .scaleEffect(0.7)
                }
            }
            .animation(FGAnimations.spring, value: isComplete)

            // Text
            Text(text)
                .font(FGTypography.body)
                .foregroundColor(isComplete ? FGColors.textPrimary : (isActive ? FGColors.textSecondary : FGColors.textTertiary))
                .animation(FGAnimations.spring, value: isComplete)

            Spacer()
        }
    }
}

#Preview("Building Experience Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        BuildingExperienceScreen(viewModel: OnboardingViewModel()) {
            print("Auto advance triggered")
        }
    }
}
