import SwiftUI

/// Screen 1: Welcome screen with Lottie animation
struct WelcomeScreen: View {
    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lottie animation with glow
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

                // Lottie animation
                LottieAnimationView(animationName: "welcome-flyer", loopMode: .loop)
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
            }

            Spacer()
                .frame(height: FGSpacing.xxl)

            // Text content
            VStack(spacing: FGSpacing.md) {
                // Time-based greeting
                Text(timeBasedGreeting)
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.accentPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Welcome to FlyGen")
                    .font(FGTypography.displayMedium)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Create stunning flyers in seconds\nwith the power of AI")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
        }
    }

    // MARK: - Time-based Greeting

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}

#Preview("Welcome Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        WelcomeScreen()
    }
}
