import SwiftUI
import UIKit

/// The onboarding demo of circle-to-edit. Mirrors the real `FlyerAnnotationView`: magenta (#FF0096)
/// numbered circles are drawn over the flyer and a note types out under each, then an "Apply" pill
/// flashes. It plays itself on appear; the runner waits out `duration(for:)` before revealing the
/// edited hero. Display-only - no real gestures.
struct OnboardingMarkupView: View {
    let demo: MarkupDemo
    var reduceMotion: Bool = false

    /// The exact mark color the real editor uses (`FlyerAnnotationView.markColor`).
    private static let mark = Color(red: 1.0, green: 0.0, blue: 0.588)
    private static let badgeFill = Color(red: 0.82, green: 0.0, blue: 0.48)
    private static let perMark: Double = 2.0
    private static let applyFlash: Double = 1.0

    /// Total play time, so the view model knows how long to wait before ticking the edit worklog.
    static func duration(for demo: MarkupDemo) -> Double {
        Double(demo.marks.count) * perMark + applyFlash
    }

    @State private var drawnCount = 0          // circles fully drawn so far
    @State private var typed: [String] = []    // typed note per mark (parallel to demo.marks)
    @State private var applied = false

    private let cardWidth: CGFloat = 210
    private var cardHeight: CGFloat { cardWidth * 4.0 / 3.0 }

    var body: some View {
        VStack(spacing: FGSpacing.sm) {
            ZStack {
                flyer
                marksOverlay
            }
            .frame(width: cardWidth, height: cardHeight)
            .auroraFlyerCard()

            applyPill
        }
        .frame(maxWidth: .infinity)
        .task { await run() }
    }

    @ViewBuilder private var flyer: some View {
        if let ui = UIImage(named: demo.baseImage) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            FGGradients.accent
        }
    }

    private var marksOverlay: some View {
        GeometryReader { geo in
            ForEach(Array(demo.marks.enumerated()), id: \.offset) { i, m in
                let cx = m.center.x * geo.size.width
                let cy = m.center.y * geo.size.height
                let drawn = i < drawnCount

                Circle()
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(Self.mark, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 66, height: 66)
                    .rotationEffect(.degrees(-90))       // start the stroke from the top
                    .position(x: cx, y: cy)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: drawnCount)

                if drawn {
                    Text("\(i + 1)")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Self.badgeFill.opacity(0.92)).clipShape(Circle())
                        .position(x: cx - 30, y: cy - 30)
                        .transition(.scale.combined(with: .opacity))
                }

                if i < typed.count, !typed[i].isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.and.outline").font(.system(size: 10))
                        Text(typed[i]).font(FGTypography.captionSmall)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, FGSpacing.xs).padding(.vertical, 3)
                    .background(Self.mark.opacity(0.92)).clipShape(Capsule())
                    .fixedSize()
                    .position(x: cx, y: m.center.y > 0.72 ? cy - 44 : cy + 46)   // above if near the bottom
                }
            }
        }
    }

    private var applyPill: some View {
        Label("Apply", systemImage: "checkmark")
            .font(FGTypography.buttonSmall).foregroundColor(FGColors.textOnAccent)
            .padding(.horizontal, FGSpacing.md).padding(.vertical, FGSpacing.xs)
            .background(FGColors.accentPrimary).clipShape(Capsule())
            .scaleEffect(applied ? 1.0 : 0.9)
            .opacity(applied ? 1 : 0)
            .animation(FGAnimations.springBouncy, value: applied)
    }

    private func run() async {
        typed = Array(repeating: "", count: demo.marks.count)
        if reduceMotion {
            drawnCount = demo.marks.count
            for i in demo.marks.indices { typed[i] = demo.marks[i].note }
            applied = true
            return
        }
        for i in demo.marks.indices {
            withAnimation { drawnCount = i + 1 }
            try? await Task.sleep(nanoseconds: UInt64(0.55 * 1_000_000_000))   // circle draws
            for ch in demo.marks[i].note {                                     // typewriter the note
                if Task.isCancelled { return }
                typed[i].append(ch)
                try? await Task.sleep(nanoseconds: UInt64(0.03 * 1_000_000_000))
            }
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))    // hold
        }
        withAnimation(FGAnimations.springBouncy) { applied = true }
    }
}
