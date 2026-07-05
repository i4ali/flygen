import SwiftUI

/// Chat-first onboarding: a single scrollable thread that demos the product (a sentence becomes
/// three flyers), then collects two quick preferences, then completes. Replaces the retired
/// 9-screen wizard. See docs/plans/2026-07-02-chat-onboarding-design.md.
struct ChatOnboardingView: View {
    /// Called when the user taps the final CTA; the host persists these and flips
    /// `hasCompletedOnboarding` to enter the app.
    let onComplete: ([FlyerCategory], [FlyerLanguage]) -> Void

    @StateObject private var vm = ChatOnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            AuroraBackground(reduceMotion: reduceMotion)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: FGSpacing.md) {
                        ForEach(vm.rendered) { beat in
                            beatView(beat)
                                .id(beat.id)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, FGSpacing.xl)      // generous margin for the premium thread
                    .padding(.top, 72)                       // clear the pinned top bar
                    .padding(.bottom, FGSpacing.xxl)
                }
                .onChange(of: vm.rendered.count) { _, _ in scrollToBottom(proxy) }
                .onChange(of: vm.isInteracting) { _, _ in scrollToBottom(proxy) }
            }

            topBar
        }
        .onAppear {
            vm.onComplete = onComplete
            vm.start(reduceMotion: reduceMotion)
        }
    }

    // MARK: - Beats

    @ViewBuilder private func beatView(_ beat: RenderedBeat) -> some View {
        switch beat.kind {
        case .assistant(let t):        AssistantBubble(text: t)
        case .user(let t, let typing): UserBubble(text: t, caret: typing)
        case .thinking(let t):         TypingBubble(text: t)
        case .brief(let chips):        briefRow(chips)
        case .worklog(let items):      WorklogView(items: items, reduceMotion: reduceMotion)
        case .reveal(let names):       DemoFlyerReveal(imageNames: names, reduceMotion: reduceMotion)
        case .chipQuestion(let q):     OnboardingChipQuestionView(question: q, vm: vm)
        case .cta(let title):          ctaButton(title)
        }
    }

    /// The comprehension chip-row proving the brief was understood.
    private func briefRow(_ chips: [String]) -> some View {
        FlowLayout(spacing: FGSpacing.xs) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(FGTypography.caption)
                    .foregroundColor(FGColors.textSecondary)
                    .padding(.horizontal, FGSpacing.sm)
                    .padding(.vertical, FGSpacing.xxs)
                    .background(FGColors.surfaceDefault)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(FGColors.borderSubtle, lineWidth: 1))
            }
        }
    }

    private func ctaButton(_ title: String) -> some View {
        VStack(spacing: FGSpacing.sm) {
            // The quiet value line - the "worth paying" nudge, designer-anchored, no price.
            HStack(alignment: .top, spacing: FGSpacing.xs) {
                Image(systemName: "sparkle").font(.system(size: 11)).foregroundColor(FGColors.accentGradientStart)
                Text("The polish you'd hire a designer for - ready whenever you need one.")
                    .font(FGTypography.caption).foregroundColor(FGColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            FGPrimaryButton(title: title, icon: "sparkles") { vm.finish() }
                .modifier(BreathingGlow(reduceMotion: reduceMotion))
        }
        .padding(.top, FGSpacing.xs)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            OnboardingBrandMark(reduceMotion: reduceMotion)
            Spacer()
        }
        .padding(.horizontal, FGSpacing.xl)                 // align the brand mark with the content margin
        .padding(.vertical, FGSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(FGColors.backgroundPrimary.opacity(0.9).ignoresSafeArea(edges: .top))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = vm.rendered.last else { return }
        withAnimation(FGAnimations.spring) { proxy.scrollTo(last.id, anchor: .bottom) }
    }
}

// MARK: - Premium brand + motion pieces

/// Animated FlyGen mark: a slowly rotating conic-gradient glyph beside the wordmark - a real
/// brand moment instead of a plain text label.
private struct OnboardingBrandMark: View {
    var reduceMotion: Bool = false
    @State private var rot = 0.0
    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            RoundedRectangle(cornerRadius: 7)
                .fill(AngularGradient(
                    colors: [FGColors.accentPrimary, FGColors.accentGradientEnd, FGColors.accentSecondary, FGColors.accentPrimary],
                    center: .center, angle: .degrees(rot)))
                .frame(width: 24, height: 24)
                .overlay(RoundedRectangle(cornerRadius: 4).fill(FGColors.backgroundPrimary).frame(width: 14, height: 14))
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [FGColors.accentGradientStart, FGColors.accentSecondary],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 7, height: 7))
                .shadow(color: FGColors.accentPrimary.opacity(0.5), radius: 8)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { rot = 360 }
                }
            Text("FlyGen").font(FGTypography.h4).foregroundColor(FGColors.textPrimary)
        }
    }
}

/// A gently breathing glow behind the primary CTA, so it reads as premium and alive.
private struct BreathingGlow: ViewModifier {
    var reduceMotion: Bool = false
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .shadow(color: FGColors.accentGradientEnd.opacity(on ? 0.55 : 0.28), radius: on ? 24 : 14, y: 8)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { on = true }
            }
    }
}
