import SwiftUI

/// Screen 3: AI generation magic reveal
struct AIGenerationScreen: View {
    @State private var animationComplete = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lottie animation area
            ZStack {
                // Background glow that intensifies
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FGColors.accentPrimary.opacity(animationComplete ? 0.4 : 0.2),
                                FGColors.accentSecondary.opacity(animationComplete ? 0.2 : 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
                    .scaleEffect(animationComplete ? 1.1 : 1.0)
                    .animation(FGAnimations.breathe, value: animationComplete)

                // Lottie animation - plays once
                LottieAnimationViewWithCompletion(
                    animationName: "ai-generation-magic",
                    loopMode: .playOnce,
                    speed: 1.0
                ) {
                    withAnimation(FGAnimations.spring) {
                        animationComplete = true
                    }
                    // Delay text reveal slightly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(FGAnimations.spring) {
                            showText = true
                        }
                    }
                }
                .frame(width: 280, height: 280)
            }

            Spacer()
                .frame(height: FGSpacing.xxl)

            // Text content - fades in after animation
            VStack(spacing: FGSpacing.lg) {
                Text("Your flyer, created in seconds")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)

                VStack(spacing: FGSpacing.xs) {
                    featureRow(icon: "wand.and.stars", text: "AI handles the design")
                    featureRow(icon: "checkmark.circle.fill", text: "You get professional results")
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FGColors.accentPrimary)

            Text(text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
        }
    }
}

#Preview("AI Generation Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        AIGenerationScreen()
    }
}
