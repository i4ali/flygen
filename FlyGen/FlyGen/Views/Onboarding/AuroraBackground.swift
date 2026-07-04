import SwiftUI
import UIKit

/// Living atmospheric background for the onboarding: drifting violet / cyan / pink light over
/// near-black, with a fine grain and a vignette. This is the "premium stage" - it replaces the
/// flat static gradient the onboarding used to sit on. Pure SwiftUI; renders on Metal on-device.
struct AuroraBackground: View {
    var reduceMotion: Bool = false
    @State private var drift = false

    var body: some View {
        ZStack {
            Color(hex: "08080C")

            blob(FGColors.accentPrimary,     size: 460)
                .offset(x: drift ? -120 : -70, y: drift ? -240 : -180)
                .scaleEffect(drift ? 1.15 : 1.0)
            blob(FGColors.accentSecondary,   size: 420)
                .offset(x: drift ? 130 : 90,  y: drift ? -170 : -240)
                .scaleEffect(drift ? 0.9 : 1.05)
            blob(FGColors.accentGradientEnd, size: 400)
                .offset(x: drift ? -50 : -10, y: drift ? 300 : 360)
                .scaleEffect(drift ? 1.2 : 1.0)

            // Fine grain to kill banding and read as "expensive."
            Image(uiImage: Self.grain)
                .resizable(resizingMode: .tile)
                .opacity(0.05)
                .blendMode(.overlay)

            // Vignette to focus the center.
            RadialGradient(colors: [.clear, Color.black.opacity(0.55)],
                           center: .center, startRadius: 120, endRadius: 540)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func blob(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.5), .clear],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 60)
            .blendMode(.screen)
    }

    /// A small grayscale noise tile, generated once via a deterministic LCG (no per-frame cost).
    static let grain: UIImage = makeGrain()

    private static func makeGrain() -> UIImage {
        let side = 128
        var px = [UInt8](repeating: 0, count: side * side * 4)
        var seed: UInt64 = 0x9E3779B97F4A7C15
        for i in 0..<(side * side) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let v = UInt8((seed >> 56) & 0xFF)
            px[i*4] = v; px[i*4+1] = v; px[i*4+2] = v; px[i*4+3] = 255
        }
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &px, width: side, height: side, bitsPerComponent: 8,
                                  bytesPerRow: side * 4, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cg = ctx.makeImage() else { return UIImage() }
        return UIImage(cgImage: cg)
    }
}
