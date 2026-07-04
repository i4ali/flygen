import SwiftUI

/// The "show its work" beat: a checklist of expert design decisions that ticks from a cyan
/// spinner to a green check, one at a time - so the engine's quality is *felt*, not claimed.
/// Every line maps to a real step the engine performs. Animates itself on appear; the view
/// model just waits out `duration(for:)`.
struct WorklogView: View {
    let items: [String]
    var reduceMotion: Bool = false

    @State private var visible = 0     // rows revealed so far
    @State private var completed = 0   // rows ticked done so far

    /// Total play time, so the view model knows how long to wait before the reveal.
    static func duration(for items: [String]) -> Double { Double(items.count) * 0.8 + 0.4 }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpacing.sm) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                if i < visible {
                    HStack(spacing: FGSpacing.sm) {
                        tick(done: i < completed)
                        Text(item)
                            .font(FGTypography.bodySmall)
                            .foregroundColor(i < completed ? FGColors.textPrimary : FGColors.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(FGSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FGColors.surfaceDefault.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: FGSpacing.cardRadius).stroke(FGColors.borderSubtle, lineWidth: 1))
        .task { await run() }
    }

    @ViewBuilder private func tick(done: Bool) -> some View {
        ZStack {
            if done {
                Circle().fill(FGColors.success.opacity(0.16))
                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(FGColors.success)
            } else {
                ProgressView().tint(FGColors.accentSecondary).scaleEffect(0.7)
            }
        }
        .frame(width: 20, height: 20)
    }

    private func run() async {
        for i in 0..<items.count {
            withAnimation(FGAnimations.spring) { visible = i + 1 }
            try? await Task.sleep(nanoseconds: UInt64((reduceMotion ? 0.12 : 0.64) * 1_000_000_000))
            withAnimation(FGAnimations.spring) { completed = i + 1 }
            try? await Task.sleep(nanoseconds: UInt64(0.15 * 1_000_000_000))
        }
    }
}
