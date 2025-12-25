import SwiftUI

// MARK: - User Preference Type

/// Simplified user-facing preference options that map to internal FlyerCategory values
enum UserPreferenceType: String, CaseIterable, Identifiable {
    case newsletters
    case salesMarketing
    case eventsParties
    case business
    case foodDining
    case classesFitness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newsletters: return "Newsletters"
        case .salesMarketing: return "Sales & Marketing"
        case .eventsParties: return "Events & Parties"
        case .business: return "Business"
        case .foodDining: return "Food & Dining"
        case .classesFitness: return "Classes & Fitness"
        }
    }

    var icon: String {
        switch self {
        case .newsletters: return "newspaper"
        case .salesMarketing: return "tag"
        case .eventsParties: return "party.popper"
        case .business: return "briefcase"
        case .foodDining: return "fork.knife"
        case .classesFitness: return "figure.run"
        }
    }

    /// Maps to actual FlyerCategory values for internal use
    var mappedCategories: [FlyerCategory] {
        switch self {
        case .newsletters: return [.announcement]
        case .salesMarketing: return [.salePromo, .grandOpening]
        case .eventsParties: return [.event, .partyCelebration, .musicConcert]
        case .business: return [.salePromo, .grandOpening, .realEstate, .jobPosting]
        case .foodDining: return [.restaurantFood]
        case .classesFitness: return [.classWorkshop, .fitnessWellness]
        }
    }
}

/// View model for interactive onboarding flow
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Screen Navigation

    enum OnboardingScreen: Int, CaseIterable {
        case welcome = 0
        case workflowDemo = 1
        case categoryPreferences = 2
        case languagePreferences = 3
        case sampleShowcase = 4
        case aiGeneration = 5

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .workflowDemo: return "How It Works"
            case .categoryPreferences: return "Your Preferences"
            case .languagePreferences: return "Languages"
            case .sampleShowcase: return "What's Possible"
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
        case .categoryPreferences:
            return true  // Can always continue (skip is allowed)
        case .languagePreferences:
            return true  // Can always continue
        case .sampleShowcase:
            return true
        case .aiGeneration:
            return true
        }
    }

    var isLastScreen: Bool {
        currentScreen == .aiGeneration
    }

    // MARK: - Category Preferences

    @Published var selectedPreferences: Set<UserPreferenceType> = []

    func togglePreference(_ preference: UserPreferenceType) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }

    /// Get all selected categories (flattened from user preferences)
    var selectedCategories: [FlyerCategory] {
        selectedPreferences.flatMap { $0.mappedCategories }
    }

    // MARK: - Language Preferences

    @Published var selectedLanguages: Set<FlyerLanguage> = [.english]

    func toggleLanguage(_ language: FlyerLanguage) {
        if selectedLanguages.contains(language) {
            // Don't allow deselecting the last language
            if selectedLanguages.count > 1 {
                selectedLanguages.remove(language)
            }
        } else {
            selectedLanguages.insert(language)
        }
    }

    /// Check if sample showcase should be shown (only if preferences were selected)
    var shouldShowSampleShowcase: Bool {
        !selectedPreferences.isEmpty
    }

    /// Get samples filtered by selected categories AND languages with smart fallbacks
    var filteredSamples: [SampleFlyer] {
        let categories = selectedCategories
        let languages = selectedLanguages

        guard !categories.isEmpty else { return [] }

        var result: [SampleFlyer] = []

        // Priority 1: Exact matches (selected language + selected category)
        for language in languages {
            let exactMatches = SampleLibrary.samples.filter { sample in
                categories.contains(sample.category) && sample.language == language
            }
            result.append(contentsOf: exactMatches)
        }

        // Priority 2: Fill gaps with English fallbacks for missing categories
        let coveredCategories = Set(result.map { $0.category })
        let missingCategories = categories.filter { !coveredCategories.contains($0) }

        for category in missingCategories {
            // Try English first
            if let englishSample = SampleLibrary.samples.first(where: {
                $0.category == category && $0.language == .english
            }) {
                result.append(englishSample)
            }
            // Priority 3: If no English, use any available sample for this category
            else if let anySample = SampleLibrary.samples.first(where: {
                $0.category == category
            }) {
                result.append(anySample)
            }
        }

        // Remove duplicates and limit to 6
        var seen = Set<String>()
        result = result.filter { seen.insert($0.id).inserted }

        return Array(result.prefix(6))
    }

    // MARK: - Navigation Actions

    func goToNextScreen() {
        guard !isTransitioning else { return }

        var nextScreen = OnboardingScreen(rawValue: currentScreen.rawValue + 1)

        // Skip language preferences AND sample showcase if no categories selected
        if nextScreen == .languagePreferences && !shouldShowSampleShowcase {
            nextScreen = .aiGeneration
        }
        // Skip sample showcase if no categories selected (in case we're coming from language prefs)
        else if nextScreen == .sampleShowcase && !shouldShowSampleShowcase {
            nextScreen = .aiGeneration
        }

        if let nextIndex = nextScreen {
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
