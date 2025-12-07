import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background
            FGColors.backgroundPrimary
                .ignoresSafeArea()

            // Subtle gradient overlay
            LinearGradient(
                colors: [FGColors.accentPrimary.opacity(0.05), FGColors.accentPrimary.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            onComplete()
                        }
                        .font(FGTypography.body)
                        .foregroundColor(FGColors.textSecondary)
                        .padding(FGSpacing.md)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    WelcomeView()
                        .tag(0)

                    ValuePropView(
                        icon: "wand.and.stars",
                        title: "AI-Powered Creation",
                        description: "Create professional flyers in seconds with the power of AI. No design skills needed!",
                        color: FGColors.accentPrimary
                    )
                    .tag(1)

                    ValuePropView(
                        icon: "bolt.fill",
                        title: "Fast & Simple",
                        description: "Just answer a few questions and watch your flyer come to life. Create stunning designs in minutes!",
                        color: FGColors.warning
                    )
                    .tag(2)

                    ValuePropView(
                        icon: "paintpalette.fill",
                        title: "Endless Customization",
                        description: "Choose from 12 categories, 10 visual styles, 9 moods, and 8 color palettes to make your flyer unique.",
                        color: FGColors.accentSecondary
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: FGSpacing.sm) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? FGColors.accentPrimary : FGColors.textTertiary.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, FGSpacing.lg)

                // Navigation buttons
                HStack(spacing: FGSpacing.md) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack(spacing: FGSpacing.xs) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(FGTypography.button)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpacing.md)
                            .background(FGColors.surfaceDefault)
                            .foregroundColor(FGColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: FGSpacing.buttonRadius)
                                    .stroke(FGColors.borderSubtle, lineWidth: 1)
                            )
                        }
                    }

                    Button {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: FGSpacing.xs) {
                            Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            if currentPage < totalPages - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(FGTypography.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FGSpacing.md)
                        .background(FGColors.accentPrimary)
                        .foregroundColor(FGColors.textOnAccent)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.buttonRadius))
                        .shadow(color: FGColors.accentPrimary.opacity(0.4), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, FGSpacing.xl)
                .padding(.bottom, FGSpacing.xxl)
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: FGSpacing.xl) {
            Spacer()

            // App icon with glow
            ZStack {
                Circle()
                    .fill(FGColors.accentPrimary.opacity(0.15))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)

                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FGColors.accentPrimary, FGColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: FGSpacing.md) {
                Text("Welcome to FlyGen")
                    .font(FGTypography.displayMedium)
                    .foregroundColor(FGColors.textPrimary)

                Text("Create beautiful flyers\nwith the power of AI")
                    .font(FGTypography.h3)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(FGSpacing.screenHorizontal)
    }
}

struct ValuePropView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: FGSpacing.xl) {
            Spacer()

            // Icon with glow
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
            }

            VStack(spacing: FGSpacing.md) {
                Text(title)
                    .font(FGTypography.h2)
                    .foregroundColor(FGColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FGSpacing.xl)
            }

            Spacer()
            Spacer()
        }
        .padding(FGSpacing.screenHorizontal)
    }
}

#Preview {
    OnboardingContainerView {
        print("Onboarding complete")
    }
}
