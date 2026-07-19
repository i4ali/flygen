import SwiftUI

/// The onboarding demo of "save the prompt" - the chat's bookmark action that keeps a brief in the
/// Prompts tab to reuse. Plays itself: the bookmark fills (as if tapped) and a "Saved to your
/// Prompts" confirmation slides in. Display-only.
struct OnboardingSavePromptView: View {
    var saved: Bool

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                    .fill(FGColors.surfaceDefault)
                    .overlay(RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                        .stroke(FGColors.borderSubtle, lineWidth: 1))
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(saved ? FGColors.accentPrimary : FGColors.textSecondary)
                    .scaleEffect(saved ? 1.12 : 1)
                    .animation(FGAnimations.springBouncy, value: saved)
            }
            .frame(width: 44, height: 44)

            if saved {
                Label("Saved to your Prompts", systemImage: "checkmark")
                    .font(FGTypography.buttonSmall)
                    .foregroundColor(FGColors.success)
                    .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xs)
                    .background(FGColors.success.opacity(0.14)).clipShape(Capsule())
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }
}
