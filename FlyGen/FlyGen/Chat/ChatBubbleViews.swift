import SwiftUI

// Shared chat bubble primitives. Rendered identically by the live chat (`FlyerChatView`)
// and the onboarding demo (`ChatOnboardingView`) so the demo can never drift from the real
// thing. Keep these visually in lock-step with the assistant/user/typing styling used across
// the chat surface - one source of truth.

/// User message: right-aligned violet pill with a subtle gradient + glow. `caret` shows a
/// blinking cursor while text is being typed (used by onboarding's self-typing demo).
struct UserBubble: View {
    let text: String
    var caret: Bool = false
    var body: some View {
        HStack { Spacer(minLength: FGSpacing.xl)
            HStack(alignment: .bottom, spacing: 2) {
                Text(text).font(FGTypography.body).foregroundColor(FGColors.textOnAccent)
                if caret { TypingCaret() }
            }
            .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.sm)
            .background(
                LinearGradient(colors: [Color(hex: "8B5CF6"), FGColors.accentPrimary, Color(hex: "6D28D9")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
            .shadow(color: FGColors.accentPrimary.opacity(0.35), radius: 10, y: 4)
        }
    }
}

/// Blinking text cursor for the self-typing demo bubble.
private struct TypingCaret: View {
    @State private var on = true
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(FGColors.textOnAccent)
            .frame(width: 2, height: 17)
            .opacity(on ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { on = false }
            }
    }
}

/// Assistant message: bare left-aligned gray text (the deliberate asymmetry with the user pill).
struct AssistantBubble: View {
    let text: String
    var body: some View {
        Text(text).font(FGTypography.body).foregroundColor(FGColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The "thinking" indicator: cyan spinner + contextual status text.
struct TypingBubble: View {
    let text: String
    var body: some View {
        HStack(spacing: FGSpacing.xs) {
            ProgressView().tint(FGColors.accentSecondary).scaleEffect(0.8)
            Text(text).font(FGTypography.bodySmall).foregroundColor(FGColors.textTertiary)
        }
    }
}
