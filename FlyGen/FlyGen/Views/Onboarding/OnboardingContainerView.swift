import SwiftUI

/// Main onboarding container - now uses the new interactive Lottie-based experience
struct OnboardingContainerView: View {
    let onComplete: ([FlyerCategory]) -> Void

    var body: some View {
        InteractiveOnboardingView(onComplete: onComplete)
    }
}

#Preview {
    OnboardingContainerView { categories in
        print("Onboarding complete with categories: \(categories)")
    }
}
