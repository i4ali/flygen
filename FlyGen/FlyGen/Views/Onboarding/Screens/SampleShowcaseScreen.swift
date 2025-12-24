import SwiftUI

/// Screen 4: Sample showcase carousel showing flyers from selected categories
struct SampleShowcaseScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateContent = false
    @State private var currentIndex = 0
    @State private var autoAdvanceTimer: Timer?

    private let autoAdvanceInterval: TimeInterval = 3.0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: FGSpacing.sm) {
                Text("See what's possible")
                    .font(FGTypography.displaySmall)
                    .foregroundColor(FGColors.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                Text("Made with FlyGen")
                    .font(FGTypography.body)
                    .foregroundColor(FGColors.textSecondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }
            .padding(.top, FGSpacing.xl)
            .padding(.bottom, FGSpacing.lg)

            // Carousel - takes remaining space
            if !viewModel.filteredSamples.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.filteredSamples.enumerated()), id: \.element.id) { index, sample in
                        SampleCard(sample: sample)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.9)

                // Page indicators
                HStack(spacing: FGSpacing.xs) {
                    ForEach(0..<viewModel.filteredSamples.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? FGColors.accentPrimary : FGColors.textSecondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1)
                            .animation(FGAnimations.spring, value: currentIndex)
                    }
                }
                .padding(.vertical, FGSpacing.md)
                .opacity(animateContent ? 1 : 0)
            } else {
                Spacer()
            }
        }
        .onAppear {
            withAnimation(FGAnimations.spring.delay(0.2)) {
                animateContent = true
            }
            startAutoAdvance()
        }
        .onDisappear {
            stopAutoAdvance()
        }
        .onChange(of: currentIndex) { _, _ in
            // Reset timer when user manually swipes
            restartAutoAdvance()
        }
    }

    // MARK: - Auto Advance

    private func startAutoAdvance() {
        guard viewModel.filteredSamples.count > 1 else { return }

        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            withAnimation(FGAnimations.slowEase) {
                currentIndex = (currentIndex + 1) % viewModel.filteredSamples.count
            }
        }
    }

    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }

    private func restartAutoAdvance() {
        stopAutoAdvance()
        startAutoAdvance()
    }
}

// MARK: - Sample Card

struct SampleCard: View {
    let sample: SampleFlyer

    var body: some View {
        GeometryReader { geometry in
            let maxImageHeight = geometry.size.height - 80 // Leave room for label

            VStack(spacing: FGSpacing.md) {
                // Sample image - use UIImage(named:) pattern for reliable loading
                if let uiImage = UIImage(named: sample.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(8.5/11, contentMode: .fit)
                        .frame(maxHeight: maxImageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: FGSpacing.cardRadius))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                } else {
                    // Placeholder when image not found
                    RoundedRectangle(cornerRadius: FGSpacing.cardRadius)
                        .fill(FGColors.surfaceDefault)
                        .aspectRatio(8.5/11, contentMode: .fit)
                        .frame(maxHeight: maxImageHeight)
                        .overlay(
                            VStack(spacing: FGSpacing.sm) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(FGColors.textSecondary)
                                Text(sample.imageName)
                                    .font(FGTypography.caption)
                                    .foregroundColor(FGColors.textSecondary)
                            }
                        )
                }

                // Category label
                HStack(spacing: FGSpacing.xs) {
                    Image(systemName: sample.category.icon)
                        .font(.system(size: 12))
                    Text(sample.category.displayName)
                        .font(FGTypography.captionBold)
                }
                .foregroundColor(FGColors.accentSecondary)
                .padding(.horizontal, FGSpacing.md)
                .padding(.vertical, FGSpacing.xs)
                .background(FGColors.surfaceDefault)
                .clipShape(Capsule())
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .padding(.horizontal, FGSpacing.xl)
    }
}

#Preview("Sample Showcase Screen") {
    ZStack {
        FGColors.backgroundPrimary.ignoresSafeArea()

        // Create a mock viewModel with some selections
        let vm = OnboardingViewModel()

        SampleShowcaseScreen(viewModel: vm)
            .onAppear {
                vm.selectedPreferences = [.eventsParties, .salesMarketing]
            }
    }
}
