import SwiftUI

/// View model for interactive onboarding flow
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Screen Navigation

    enum OnboardingScreen: Int, CaseIterable {
        case welcome = 0
        case workflowDemo = 1
        case aiGeneration = 2

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .workflowDemo: return "How It Works"
            case .aiGeneration: return "AI Magic"
            }
        }
    }

    @Published var currentScreen: OnboardingScreen = .welcome

    // MARK: - Interactive Demo State (7 Steps)

    enum DemoStep: Int, CaseIterable {
        case category = 0
        case style = 1
        case textDetails = 2
        case logo = 3
        case qrCode = 4
        case colors = 5
        case ready = 6

        var title: String {
            switch self {
            case .category: return "Choose a Category"
            case .style: return "Pick a Style"
            case .textDetails: return "Add Your Details"
            case .logo: return "Upload Your Logo"
            case .qrCode: return "Add a QR Code"
            case .colors: return "Choose Colors"
            case .ready: return "Ready to Create!"
            }
        }

        var stepNumber: Int {
            return rawValue + 1
        }

        var animationName: String {
            switch self {
            case .category: return "onboarding-category"
            case .style: return "onboarding-category"
            case .textDetails: return "onboarding-text"
            case .logo: return "onboarding-logo"
            case .qrCode: return "onboarding-qrcode"
            case .colors: return "onboarding-colors"
            case .ready: return "onboarding-ready"
            }
        }
    }

    @Published var demoStep: DemoStep = .category

    // MARK: - Mock Selections

    enum MockCategory: String, CaseIterable, Identifiable {
        case event = "Event"
        case sale = "Sale"
        case announcement = "News"

        var id: String { rawValue }

        var emoji: String {
            switch self {
            case .event: return "📅"
            case .sale: return "🏷️"
            case .announcement: return "📢"
            }
        }
    }

    enum MockStyle: String, CaseIterable, Identifiable {
        case modern = "Modern"
        case bold = "Bold"
        case elegant = "Elegant"

        var id: String { rawValue }

        var emoji: String {
            switch self {
            case .modern: return "◼️"
            case .bold: return "🔥"
            case .elegant: return "✨"
            }
        }
    }

    enum MockColorTheme: String, CaseIterable, Identifiable {
        case vibrant = "Vibrant"
        case minimal = "Minimal"
        case dark = "Dark"
        case pastel = "Pastel"

        var id: String { rawValue }

        var colors: [Color] {
            switch self {
            case .vibrant: return [.cyan, .pink, .yellow]
            case .minimal: return [.gray, .white, .black]
            case .dark: return [.purple, .blue, .black]
            case .pastel: return [.pink.opacity(0.5), .mint.opacity(0.5), .yellow.opacity(0.5)]
            }
        }
    }

    @Published var selectedCategory: MockCategory?
    @Published var selectedStyle: MockStyle?
    @Published var selectedColorTheme: MockColorTheme?

    // Text detail mock data
    @Published var mockHeadline: String = ""
    @Published var mockDate: String = ""
    @Published var mockLocation: String = ""

    // Feature toggles
    @Published var hasLogo: Bool = false
    @Published var hasQRCode: Bool = false

    // MARK: - Animation State

    @Published var isTransitioning: Bool = false
    @Published var showContinueButton: Bool = false

    // MARK: - Auto-Advance Timer

    private var autoAdvanceTimer: Timer?
    private let autoAdvanceInterval: TimeInterval = 2.5

    // MARK: - Computed Properties

    var totalScreens: Int { OnboardingScreen.allCases.count }
    var totalDemoSteps: Int { DemoStep.allCases.count }

    var canGoBack: Bool {
        currentScreen.rawValue > 0
    }

    var canContinue: Bool {
        switch currentScreen {
        case .welcome:
            return true
        case .workflowDemo:
            return demoStep == .ready
        case .aiGeneration:
            return true
        }
    }

    var isLastScreen: Bool {
        currentScreen == .aiGeneration
    }

    // MARK: - Navigation Actions

    func goToNextScreen() {
        guard !isTransitioning else { return }

        if let nextIndex = OnboardingScreen(rawValue: currentScreen.rawValue + 1) {
            isTransitioning = true
            withAnimation(FGAnimations.slowEase) {
                currentScreen = nextIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + FGAnimations.durationSlow) {
                self.isTransitioning = false
            }
        }
    }

    func goToPreviousScreen() {
        guard !isTransitioning, canGoBack else { return }

        if let prevIndex = OnboardingScreen(rawValue: currentScreen.rawValue - 1) {
            isTransitioning = true
            withAnimation(FGAnimations.slowEase) {
                currentScreen = prevIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + FGAnimations.durationSlow) {
                self.isTransitioning = false
            }
        }
    }

    func skip() {
        // Will be handled by the container to complete onboarding
    }

    // MARK: - Auto Demo Control

    func startAutoDemo() {
        // Reset to beginning if needed
        if demoStep == .ready {
            resetDemo()
        }

        // Start timer for auto-advance
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceToNextStep()
            }
        }
    }

    func stopAutoDemo() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }

    func advanceToNextStep() {
        guard demoStep != .ready else {
            stopAutoDemo()
            return
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(FGAnimations.spring) {
            switch demoStep {
            case .category:
                selectedCategory = .event
                demoStep = .style

            case .style:
                selectedStyle = .modern
                demoStep = .textDetails

            case .textDetails:
                mockHeadline = "Summer Festival 2024"
                mockDate = "July 15th"
                mockLocation = "Central Park"
                demoStep = .logo

            case .logo:
                hasLogo = true
                demoStep = .qrCode

            case .qrCode:
                hasQRCode = true
                demoStep = .colors

            case .colors:
                selectedColorTheme = .vibrant
                demoStep = .ready
                showContinueButton = true
                stopAutoDemo()

            case .ready:
                break
            }
        }
    }

    // MARK: - Reset

    func resetDemo() {
        selectedCategory = nil
        selectedStyle = nil
        selectedColorTheme = nil
        mockHeadline = ""
        mockDate = ""
        mockLocation = ""
        hasLogo = false
        hasQRCode = false
        demoStep = .category
        showContinueButton = false
    }
}
