import SwiftUI

/// FlyGen Design System - Animation Presets
/// Smooth, polished animations for a premium feel
struct FGAnimations {

    // MARK: - Spring Animations

    /// Standard spring for selections and interactions
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Bouncy spring for playful interactions
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Snappy spring for quick feedback
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Gentle spring for subtle movements
    static let springGentle = Animation.spring(response: 0.5, dampingFraction: 0.85)

    // MARK: - Ease Animations

    /// Quick ease out for press states
    static let quickEaseOut = Animation.easeOut(duration: 0.1)

    /// Standard ease for transitions
    static let ease = Animation.easeInOut(duration: 0.25)

    /// Slow ease for page transitions
    static let slowEase = Animation.easeInOut(duration: 0.4)

    // MARK: - Repeating Animations

    /// Pulse animation for loading states
    static let pulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)

    /// Shimmer animation for skeleton loading
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)

    /// Gentle breathing effect
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

    /// Rotation animation for spinners
    static let spin = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)

    // MARK: - Durations

    /// Quick duration - 0.15s
    static let durationQuick: Double = 0.15

    /// Standard duration - 0.25s
    static let durationStandard: Double = 0.25

    /// Slow duration - 0.4s
    static let durationSlow: Double = 0.4

    /// Page transition duration - 0.35s
    static let durationPage: Double = 0.35
}

// MARK: - Button Style

/// FlyGen card button style with press animation
struct FGCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(FGAnimations.quickEaseOut, value: configuration.isPressed)
    }
}

/// FlyGen primary button style
struct FGPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(FGAnimations.spring, value: configuration.isPressed)
    }
}

/// FlyGen scale button style for icons
struct FGScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(FGAnimations.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Slide and fade from right
    static var fgSlideIn: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Scale and fade for modals
    static var fgScale: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }

    /// Pop in from center
    static var fgPop: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }

    /// Slide up from bottom
    static var fgSlideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply spring animation on value change
    func fgSpring<V: Equatable>(_ value: V) -> some View {
        self.animation(FGAnimations.spring, value: value)
    }

    /// Apply bounce animation on value change
    func fgBounce<V: Equatable>(_ value: V) -> some View {
        self.animation(FGAnimations.springBouncy, value: value)
    }

    /// Apply pulse animation for loading states
    func fgPulse(_ isPulsing: Bool) -> some View {
        self.opacity(isPulsing ? 0.6 : 1.0)
            .animation(isPulsing ? FGAnimations.pulse : .default, value: isPulsing)
    }

    /// Apply glow effect that pulses
    func fgGlowPulse(_ isActive: Bool, color: Color = FGColors.accentPrimary) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.5) : .clear,
            radius: isActive ? 12 : 0
        )
        .animation(isActive ? FGAnimations.breathe : .default, value: isActive)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(FGAnimations.shimmer) {
                    phase = 400
                }
            }
    }
}

extension View {
    /// Apply shimmer loading effect
    func fgShimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("FGAnimations") {
    AnimationsPreviewView()
}

private struct AnimationsPreviewView: View {
    @State private var isSelected = false
    @State private var isPulsing = false
    @State private var showCard = true

    var body: some View {
        ScrollView {
            VStack(spacing: FGSpacing.xl) {
                Text("Animations")
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)

                // Spring animation
                VStack(spacing: FGSpacing.md) {
                    Text("Spring Selection")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    Button {
                        isSelected.toggle()
                    } label: {
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .fill(isSelected ? FGColors.accentPrimary : FGColors.surfaceDefault)
                            .frame(width: 120, height: 80)
                            .overlay(
                                Text(isSelected ? "Selected" : "Tap me")
                                    .font(FGTypography.label)
                                    .foregroundColor(FGColors.textPrimary)
                            )
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                    }
                    .buttonStyle(FGCardButtonStyle())
                    .fgSpring(isSelected)
                }

                Divider().background(FGColors.borderSubtle)

                // Pulse animation
                VStack(spacing: FGSpacing.md) {
                    Text("Pulse Loading")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    Button("Toggle Pulse") {
                        isPulsing.toggle()
                    }
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.accentPrimary)

                    RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                        .fill(FGColors.surfaceDefault)
                        .frame(width: 120, height: 80)
                        .fgPulse(isPulsing)
                        .fgGlowPulse(isPulsing)
                }

                Divider().background(FGColors.borderSubtle)

                // Transitions
                VStack(spacing: FGSpacing.md) {
                    Text("Transitions")
                        .font(FGTypography.label)
                        .foregroundColor(FGColors.textSecondary)

                    Button("Toggle Card") {
                        withAnimation(FGAnimations.spring) {
                            showCard.toggle()
                        }
                    }
                    .font(FGTypography.label)
                    .foregroundColor(FGColors.accentPrimary)

                    if showCard {
                        RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                            .fill(FGColors.accentPrimary)
                            .frame(width: 120, height: 80)
                            .transition(.fgScale)
                    }
                }
            }
            .padding(FGSpacing.screenHorizontal)
        }
        .background(FGColors.backgroundPrimary)
    }
}
