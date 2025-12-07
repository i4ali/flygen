import SwiftUI
import Lottie

/// Reusable Lottie animation wrapper for onboarding
struct LottieAnimationView: View {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit

    var body: some View {
        LottieView(animation: .named(animationName))
            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: loopMode)))
            .animationSpeed(speed)
            .configure { view in
                view.contentMode = contentMode
            }
    }
}

/// Lottie view with completion callback
struct LottieAnimationViewWithCompletion: View {
    let animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var speed: CGFloat = 1.0
    var onComplete: (() -> Void)?

    @State private var playbackMode: LottiePlaybackMode = .paused

    var body: some View {
        LottieView(animation: .named(animationName))
            .playbackMode(playbackMode)
            .animationSpeed(speed)
            .animationDidFinish { completed in
                if completed {
                    onComplete?()
                }
            }
            .onAppear {
                playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: loopMode))
            }
    }
}

/// Controllable Lottie view with progress binding
struct LottieProgressView: View {
    let animationName: String
    @Binding var progress: CGFloat

    var body: some View {
        LottieView(animation: .named(animationName))
            .playbackMode(.progress(progress))
    }
}

#Preview("Lottie Animation") {
    VStack(spacing: 40) {
        LottieAnimationView(animationName: "welcome-flyer")
            .frame(width: 200, height: 200)

        LottieAnimationView(animationName: "ai-generation-magic", loopMode: .playOnce)
            .frame(width: 200, height: 200)
    }
    .background(FGColors.backgroundPrimary)
}
