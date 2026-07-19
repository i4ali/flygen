import SwiftUI
import UIKit

/// The onboarding demo of Resize: format chips slide in, the selected one highlights, and the hero
/// morphs from a poster (3:4) into the selected crop (a 9:16 Story) - "one design, every platform".
/// Plays itself on appear; the runner waits out `duration`.
struct OnboardingResizeView: View {
    let demo: ResizeDemo
    var reduceMotion: Bool = false

    /// Total play time so the runner knows how long to wait.
    static let duration: Double = 2.6

    @State private var selectedFormat: String? = nil
    @State private var morphed = false

    private let baseWidth: CGFloat = 150

    var body: some View {
        VStack(spacing: FGSpacing.sm) {
            HStack(spacing: FGSpacing.xs) {
                ForEach(demo.formats, id: \.self) { f in
                    let on = selectedFormat == f
                    Label(f, systemImage: icon(for: f))
                        .font(FGTypography.captionBold)
                        .foregroundColor(on ? FGColors.textOnAccent : FGColors.textSecondary)
                        .padding(.horizontal, FGSpacing.sm).padding(.vertical, FGSpacing.xxs)
                        .background(on ? FGColors.accentPrimary : FGColors.surfaceDefault)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(on ? Color.clear : FGColors.borderSubtle, lineWidth: 1))
                        .animation(FGAnimations.spring, value: selectedFormat)
                }
            }

            heroImage
                .frame(width: baseWidth, height: baseWidth * (morphed ? 16.0 / 9.0 : 4.0 / 3.0))
                .clipShape(RoundedRectangle(cornerRadius: FGSpacing.flyerCardRadius, style: .continuous))
                .auroraFlyerCard()
                .animation(reduceMotion ? nil : FGAnimations.springBouncy, value: morphed)
        }
        .frame(maxWidth: .infinity)
        .task { await run() }
    }

    @ViewBuilder private var heroImage: some View {
        if let ui = UIImage(named: demo.resultImage) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            FGGradients.accent.overlay(
                Image(systemName: "aspectratio").font(.system(size: 24)).foregroundColor(.white.opacity(0.9)))
        }
    }

    private func icon(for f: String) -> String {
        switch f {
        case "Story":  return "rectangle.portrait"
        case "Square": return "square"
        default:       return "doc"
        }
    }

    private func run() async {
        try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        withAnimation(FGAnimations.spring) { selectedFormat = demo.selected }
        try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        if Task.isCancelled { return }
        withAnimation(reduceMotion ? nil : FGAnimations.springBouncy) { morphed = true }
    }
}
