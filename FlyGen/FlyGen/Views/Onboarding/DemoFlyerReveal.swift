import SwiftUI
import UIKit

/// Beat ④, the reveal - the money shot: three flyer cards fan in with 3D depth while the
/// signature radial glow blooms behind them and a light sweeps across each. A single image
/// renders as one centered, untilted hero card (the edit-demo reveal). Real bundled images
/// when present; a styled placeholder until the owner drops the engine-generated BBQ flyers in.
struct DemoFlyerReveal: View {
    let imageNames: [String]
    var reduceMotion: Bool = false
    @State private var shown = false

    var body: some View {
        ZStack {
            // Signature glow bloom behind the cards.
            Circle()
                .fill(RadialGradient(
                    colors: [FGColors.accentPrimary.opacity(0.4),
                             FGColors.accentSecondary.opacity(0.15),
                             .clear],
                    center: .center, startRadius: 0, endRadius: 180))
                .frame(height: 300)
                .blur(radius: 44)
                .scaleEffect(shown ? 1.1 : 0.6)
                .opacity(shown ? 1 : 0)
                .animation(reduceMotion ? nil : FGAnimations.slowEase, value: shown)

            HStack(spacing: FGSpacing.xs) {
                ForEach(Array(imageNames.enumerated()), id: \.offset) { idx, name in
                    let hero = solo || idx == 1
                    DemoFlyerCard(name: name, sweep: shown, reduceMotion: reduceMotion)
                        .frame(width: solo ? 124 : (hero ? 104 : 88))
                        .rotation3DEffect(.degrees(shown ? fanAngle(idx) : 0),
                                          axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                        .scaleEffect(shown ? (hero ? 1.06 : 1.0) : 0.9)
                        .offset(y: shown ? (hero && !solo ? -10 : 0) : 26)
                        .opacity(shown ? 1 : 0)
                        .zIndex(hero ? 1 : 0)
                        .animation(reduceMotion ? nil
                                   : FGAnimations.springBouncy.delay(Double(idx) * OnboardingTiming.revealStagger),
                                   value: shown)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { shown = true }
    }

    private var solo: Bool { imageNames.count == 1 }

    private func fanAngle(_ idx: Int) -> Double {
        guard !solo else { return 0 }
        return idx == 0 ? 18 : (idx == 2 ? -18 : 0)
    }
}

/// A single portrait flyer card with a light-sweep gloss; falls back to a branded placeholder
/// when the image is absent.
private struct DemoFlyerCard: View {
    let name: String
    var sweep: Bool = false
    var reduceMotion: Bool = false
    @State private var sweepX: CGFloat = -1.4

    var body: some View {
        content
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
            .overlay(lightSweep)
            .overlay(RoundedRectangle(cornerRadius: FGSpacing.inputRadius)
                .stroke(FGColors.borderSubtle, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 16, y: 10)
    }

    @ViewBuilder private var content: some View {
        if let ui = UIImage(named: name) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            placeholder
        }
    }

    private var lightSweep: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, .white.opacity(0.5), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: geo.size.width * 0.7)
                .offset(x: sweepX * geo.size.width)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.inputRadius))
        .onChange(of: sweep) { _, on in if on { runSweep() } }
        .onAppear { if sweep { runSweep() } }
    }

    private func runSweep() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.9).delay(0.45)) { sweepX = 1.4 }
    }

    private var placeholder: some View {
        ZStack {
            FGGradients.accent
            VStack(spacing: FGSpacing.xxs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text("BBQ")
                    .font(FGTypography.captionBold)
                    .foregroundColor(.white.opacity(0.95))
            }
        }
    }
}
