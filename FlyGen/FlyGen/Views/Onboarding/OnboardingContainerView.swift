import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.purple.opacity(0.1)],
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
                        .foregroundColor(.secondary)
                        .padding()
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
                        color: .purple
                    )
                    .tag(1)

                    ValuePropView(
                        icon: "bolt.fill",
                        title: "Fast & Simple",
                        description: "Just answer a few questions and watch your flyer come to life. Create stunning designs in minutes!",
                        color: .orange
                    )
                    .tag(2)

                    ValuePropView(
                        icon: "paintpalette.fill",
                        title: "Endless Customization",
                        description: "Choose from 12 categories, 10 visual styles, 9 moods, and 8 color palettes to make your flyer unique.",
                        color: .blue
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
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
                        HStack {
                            Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            if currentPage < totalPages - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon
            Image(systemName: "doc.richtext.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Welcome to FlyGen")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create beautiful flyers\nwith the power of AI")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct ValuePropView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingContainerView {
        print("Onboarding complete")
    }
}
