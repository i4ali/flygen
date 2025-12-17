import SwiftUI
import SwiftData

struct HomeTab: View {
    @ObservedObject var viewModel: FlyerCreationViewModel
    @Binding var showingSettings: Bool
    @Query private var userProfiles: [UserProfile]
    @State private var showingTemplates = false
    @State private var showingCreditPurchase = false

    private var credits: Int {
        userProfiles.first?.credits ?? 3
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("FlyGen")
                        .font(FGTypography.displayMedium)
                        .foregroundColor(FGColors.textPrimary)

                    Spacer()

                    // Credits display (tappable to purchase)
                    Button {
                        showingCreditPurchase = true
                    } label: {
                        HStack(spacing: FGSpacing.xs) {
                            Image(systemName: "sparkles")
                                .foregroundColor(FGColors.accentSecondary)
                            Text("\(credits)")
                                .font(FGTypography.labelLarge)
                                .foregroundColor(FGColors.textPrimary)
                        }
                        .padding(.horizontal, FGSpacing.sm)
                        .padding(.vertical, FGSpacing.xs)
                        .background(FGColors.surfaceDefault)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(FGColors.borderSubtle, lineWidth: 1)
                        )
                    }

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(FGColors.textSecondary)
                    }
                    .padding(.leading, FGSpacing.sm)
                }
                .padding(FGSpacing.screenHorizontal)
                .padding(.top, FGSpacing.md)

                Spacer()

                // Main content
                VStack(spacing: FGSpacing.xl) {
                    // Animated flyer stack
                    FlyerStackAnimation()
                        .frame(width: 150, height: 150)
                        .padding(.bottom, FGSpacing.sm)

                    VStack(spacing: FGSpacing.xs) {
                        Text("Create stunning flyers")
                            .font(FGTypography.h2)
                            .foregroundColor(FGColors.textPrimary)

                        Text("with AI")
                            .font(FGTypography.h2)
                            .foregroundColor(FGColors.accentPrimary)
                    }
                    .multilineTextAlignment(.center)

                    // Create button with gradient
                    Button {
                        if credits > 0 {
                            viewModel.showingCreationFlow = true
                        }
                    } label: {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Flyer")
                        }
                        .font(FGTypography.buttonLarge)
                        .foregroundColor(FGColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(
                            credits > 0
                                ? LinearGradient(
                                    colors: [FGColors.accentPrimary, FGColors.accentPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [FGColors.textTertiary, FGColors.textTertiary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .shadow(color: credits > 0 ? FGColors.accentPrimary.opacity(0.4) : .clear, radius: 12, y: 4)
                    }
                    .disabled(credits <= 0)
                    .padding(.horizontal, FGSpacing.xl)
                    .padding(.top, FGSpacing.md)

                    // Use Template button
                    Button {
                        if credits > 0 {
                            showingTemplates = true
                        }
                    } label: {
                        HStack(spacing: FGSpacing.sm) {
                            Image(systemName: "doc.on.doc")
                            Text("Use Template")
                        }
                        .font(FGTypography.button)
                        .foregroundColor(credits > 0 ? FGColors.accentPrimary : FGColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(FGColors.surfaceDefault)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                .stroke(credits > 0 ? FGColors.accentPrimary : FGColors.borderSubtle, lineWidth: 1.5)
                        )
                    }
                    .disabled(credits <= 0)
                    .padding(.horizontal, FGSpacing.xl)

                    // Credits warning
                    if credits <= 0 {
                        WarningBanner(
                            icon: "exclamationmark.triangle.fill",
                            message: "No credits remaining. Upgrade to Premium for unlimited flyers!",
                            color: FGColors.warning
                        )
                        .padding(.horizontal, FGSpacing.screenHorizontal)
                    }
                }

                Spacer()
                Spacer()
            }
            .background(FGColors.backgroundPrimary)
            .fullScreenCover(isPresented: $viewModel.showingCreationFlow) {
                CreationFlowView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingTemplates) {
                TemplatePickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreditPurchase) {
                CreditPurchaseSheet()
            }
        }
    }
}

// MARK: - Flyer Stack Animation

/// Animated stack of flyer shapes for the home screen
private struct FlyerStackAnimation: View {
    @State private var isAnimating = false
    @State private var glowPulse = false

    // Gradient colors using FGColors
    private var gradient1: LinearGradient {
        LinearGradient(
            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradient2: LinearGradient {
        LinearGradient(
            colors: [FGColors.accentSecondary, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gradient3: LinearGradient {
        LinearGradient(
            colors: [FGColors.accentPrimary, FGColors.accentPrimary.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            // Background glow - more pronounced pulse
            Circle()
                .fill(FGColors.accentPrimary.opacity(glowPulse ? 0.35 : 0.15))
                .frame(width: glowPulse ? 160 : 140, height: glowPulse ? 160 : 140)
                .blur(radius: 30)

            // Back flyer - more dramatic rotation
            FlyerShape()
                .fill(gradient1)
                .frame(width: 70, height: 90)
                .rotationEffect(.degrees(-20 + (isAnimating ? 12 : 0)))
                .offset(x: isAnimating ? -20 : -12, y: isAnimating ? 8 : 2)
                .opacity(0.75)
                .shadow(color: FGColors.accentSecondary.opacity(0.3), radius: 8)

            // Middle flyer - more dramatic rotation
            FlyerShape()
                .fill(gradient2)
                .frame(width: 75, height: 95)
                .rotationEffect(.degrees(12 + (isAnimating ? -10 : 0)))
                .offset(x: isAnimating ? 15 : 8, y: isAnimating ? -8 : -2)
                .opacity(0.85)
                .shadow(color: Color.pink.opacity(0.3), radius: 8)

            // Front flyer - more noticeable scale pulse
            FlyerShape()
                .fill(gradient3)
                .frame(width: 80, height: 100)
                .scaleEffect(isAnimating ? 1.12 : 0.95)
                .rotationEffect(.degrees(isAnimating ? 2 : -2))
                .shadow(color: FGColors.accentPrimary.opacity(0.5), radius: isAnimating ? 15 : 8)

            // Sparkle accent - bouncing effect
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .offset(x: 35, y: isAnimating ? -45 : -38)
                .opacity(isAnimating ? 1.0 : 0.5)
                .scaleEffect(isAnimating ? 1.2 : 0.9)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

/// Custom flyer shape - rounded rectangle with folded corner
private struct FlyerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = 8
        let foldSize: CGFloat = rect.width * 0.2

        // Start from top-left, going clockwise
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // Top edge to fold start
        path.addLine(to: CGPoint(x: rect.width - foldSize, y: 0))

        // Folded corner (diagonal line down)
        path.addLine(to: CGPoint(x: rect.width, y: foldSize))

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.closeSubpath()

        return path
    }
}

/// Warning banner component
private struct WarningBanner: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)
        }
        .padding(FGSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.chipRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FGSpacing.chipRadius)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HomeTab(
        viewModel: FlyerCreationViewModel(),
        showingSettings: .constant(false)
    )
}
