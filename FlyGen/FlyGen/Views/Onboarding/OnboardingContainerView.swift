import SwiftUI

/// Main onboarding container - now uses the new interactive Lottie-based experience
struct OnboardingContainerView: View {
    let onComplete: () -> Void

    var body: some View {
        InteractiveOnboardingView(onComplete: onComplete)
    }
}

#Preview {
    OnboardingContainerView {
        print("Onboarding complete")
    }
}
