import SwiftUI

/// Onboarding screen showcasing the Brand Kit feature
struct BrandKitScreen: View {
    @State private var showBriefcase = false
    @State private var showLogo = false
    @State private var showQR = false
    @State private var showContact = false
    @State private var showGlow = false
    @State private var showText = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animation area
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FGColors.accentPrimary.opacity(showGlow ? 0.4 : 0.15),
                                FGColors.accentSecondary.opacity(showGlow ? 0.2 : 0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 40)
                    .scaleEffect(showGlow ? 1.1 : 1.0)
                    .animation(FGAnimations.breathe, value: showGlow)

                // Briefcase icon (center)
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showBriefcase ? 1 : 0.3)
                    .opacity(showBriefcase ? 1 : 0)

                // Logo card - slides in from left
                brandCard(icon: "photo", label: "Logo")
                    .offset(x: showLogo ? -90 : -200, y: showLogo ? -70 : -70)
                    .opacity(showLogo ? 1 : 0)
                    .rotationEffect(.degrees(showLogo ? -8 : -20))

                // QR Code card - slides in from right
                brandCard(icon: "qrcode", label: "QR Code")
                    .offset(x: showQR ? 90 : 200, y: showQR ? -60 : -60)
                    .opacity(showQR ? 1 : 0)
                    .rotationEffect(.degrees(showQR ? 8 : 20))

                // Contact Info card - slides up from below
                brandCard(icon: "person.text.rectangle", label: "Contact")
                    .offset(x: 0, y: showContact ? 80 : 200)
                    .opacity(showContact ? 1 : 0)
            }
            .frame(height: 280)

            Spacer()
                .frame(height: FGSpacing.xxl)

            // Text content
            VStack(spacing: FGSpacing.lg) {
                Text("Your Brand, Always Ready")
                    .font(FGTypography.displayMedium)
                    .foregroundColor(FGColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)

                Text("Save your logo, contact details, and QR code once — they'll auto-fill every new flyer.")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)

                VStack(spacing: FGSpacing.xs) {
                    featureRow(icon: "briefcase.fill", text: "Set up once in your Profile")
                    featureRow(icon: "arrow.triangle.2.circlepath", text: "Auto-fills new flyers instantly")
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FGSpacing.screenHorizontal)
        .onAppear {
            // Briefcase fades in
            withAnimation(FGAnimations.spring.delay(0.2)) {
                showBriefcase = true
            }
            // Logo card from left
            withAnimation(FGAnimations.spring.delay(0.5)) {
                showLogo = true
            }
            // QR card from right
            withAnimation(FGAnimations.spring.delay(0.8)) {
                showQR = true
            }
            // Contact card from below
            withAnimation(FGAnimations.spring.delay(1.1)) {
                showContact = true
            }
            // Glow pulse after cards arrive
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(FGAnimations.spring) {
                    showGlow = true
                }
            }
            // Text content
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(FGAnimations.spring) {
                    showText = true
                }
            }
        }
    }

    // MARK: - Components

    private func brandCard(icon: String, label: String) -> some View {
        VStack(spacing: FGSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(FGColors.accentPrimary)

            Text(label)
                .font(FGTypography.caption)
                .foregroundColor(FGColors.textSecondary)
        }
        .frame(width: 80, height: 72)
        .background(FGColors.surfaceDefault)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FGColors.accentPrimary.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: FGColors.accentPrimary.opacity(0.2), radius: 8, y: 4)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: FGSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FGColors.accentPrimary)

            Text(text)
                .font(FGTypography.body)
                .foregroundColor(FGColors.textSecondary)
        }
    }
}

// MARK: - Brand Kit Intro Sheet (for existing users)

struct BrandKitIntroSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FGColors.backgroundPrimary.ignoresSafeArea()
                VStack {
                    BrandKitScreen()

                    // "Got It" button
                    Button { onDismiss() } label: {
                        Text("Got It")
                            .font(FGTypography.button)
                            .foregroundColor(FGColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                    }
                    .padding(.horizontal, FGSpacing.xl)
                    .padding(.bottom, FGSpacing.xxl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(FGColors.textTertiary)
                    }
                }
            }
            .toolbarBackground(FGColors.backgroundPrimary, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Brand Kit Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()
        BrandKitScreen()
    }
}

#Preview("Brand Kit Intro Sheet") {
    BrandKitIntroSheet(onDismiss: {})
}
