import SwiftUI

// MARK: - User Preference Type (Legacy - kept for backwards compatibility)

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

    // MARK: - Screen Navigation (10 screens)

    enum OnboardingScreen: Int, CaseIterable {
        case welcome = 0
        case workflowDemo = 1
        case userRole = 2
        case categoryPreferences = 3
        case languagePreferences = 4
        case brandKitIntro = 5
        case buildingExperience = 6
        case personalizedSamples = 7
        case readyToCreate = 8

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .workflowDemo: return "How It Works"
            case .userRole: return "About You"
            case .categoryPreferences: return "Your Needs"
            case .languagePreferences: return "Languages"
            case .brandKitIntro: return "Brand Kit"
            case .buildingExperience: return "Almost Ready"
            case .personalizedSamples: return "For You"
            case .readyToCreate: return "Let's Go"
            }
        }

        var isSkippable: Bool {
            switch self {
            case .userRole:
                return true
            default:
                return false
            }
        }
    }

    @Published var currentScreen: OnboardingScreen = .welcome

    // MARK: - User Role Selection

    @Published var selectedUserRole: UserRole?

    // MARK: - Visual Preferences (single selections for streamlined flow)

    @Published var selectedVisualStyle: VisualStyle?
    @Published var selectedMood: Mood?
    @Published var selectedColorScheme: ColorSchemePreset?

    // MARK: - Interactive Demo State (8 Steps)

    enum DemoStep: Int, CaseIterable {
        case category = 0
        case style = 1
        case textDetails = 2
        case logo = 3
        case qrCode = 4
        case colors = 5
        case aiAnalysis = 6
        case ready = 7

        var title: String {
            switch self {
            case .category: return "Choose a Category"
            case .style: return "Pick a Style"
            case .textDetails: return "Add Your Details"
            case .logo: return "Upload Your Logo"
            case .qrCode: return "Add a QR Code"
            case .colors: return "Choose Colors"
            case .aiAnalysis: return "AI Enhances Your Flyer"
            case .ready: return "Ready to Create!"
            }
        }

        var stepNumber: Int {
            // Ready doesn't show step number
            if self == .ready {
                return 0
            }
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
            case .aiAnalysis: return "onboarding-ai-analysis"
            case .ready: return "onboarding-ready"
            }
        }
    }

    @Published var demoStep: DemoStep = .category

    // MARK: - Mock Selections (for workflow demo)

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

    @Published var selectedMockCategory: MockCategory?
    @Published var selectedMockStyle: MockStyle?
    @Published var selectedMockColorTheme: MockColorTheme?

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
        case .userRole:
            return true // Can skip or select
        case .categoryPreferences:
            return true // Can always continue (skip is allowed)
        case .languagePreferences:
            return true // Can always continue
        case .brandKitIntro:
            return true
        case .buildingExperience:
            return true // Auto-advances
        case .personalizedSamples:
            return true
        case .readyToCreate:
            return true
        }
    }

    var isLastScreen: Bool {
        currentScreen == .readyToCreate
    }

    // MARK: - Category Preferences (Direct selection of FlyerCategory)

    @Published var selectedFlyerCategories: Set<FlyerCategory> = []

    /// Legacy: for backwards compatibility with old preference type
    @Published var selectedPreferences: Set<UserPreferenceType> = []

    func toggleFlyerCategory(_ category: FlyerCategory) {
        if selectedFlyerCategories.contains(category) {
            selectedFlyerCategories.remove(category)
        } else {
            selectedFlyerCategories.insert(category)
        }
    }

    func togglePreference(_ preference: UserPreferenceType) {
        if selectedPreferences.contains(preference) {
            selectedPreferences.remove(preference)
        } else {
            selectedPreferences.insert(preference)
        }
    }

    /// Get all selected categories (now using direct FlyerCategory selection)
    var selectedCategories: [FlyerCategory] {
        Array(selectedFlyerCategories)
    }

    /// Pre-select categories based on user role
    func applyRoleRecommendations() {
        guard let role = selectedUserRole else { return }
        for category in role.recommendedCategories {
            selectedFlyerCategories.insert(category)
        }
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
        !selectedFlyerCategories.isEmpty
    }

    /// Check if any style preferences were set
    var hasStylePreferences: Bool {
        selectedVisualStyle != nil || selectedMood != nil || selectedColorScheme != nil
    }

    /// Personalized sample filtering using ALL preferences
    var personalizedSamples: [SampleFlyer] {
        let candidates = SampleLibrary.samples

        let scored = candidates.map { sample -> (SampleFlyer, Int) in
            var score = 0

            // Language match (highest priority)
            if selectedLanguages.contains(sample.language) { score += 100 }

            // Category match
            if selectedFlyerCategories.contains(sample.category) { score += 75 }

            // Visual style match
            if let style = selectedVisualStyle, sample.visuals.style == style {
                score += 40
            }

            // Mood match
            if let mood = selectedMood, sample.visuals.mood == mood {
                score += 30
            }

            // Color scheme match
            if let scheme = selectedColorScheme, sample.colors.preset == scheme {
                score += 20
            }

            return (sample, score)
        }

        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(6)
            .map { $0.0 }
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

        // Priority 4: If still no results, show a variety of samples to showcase capabilities
        if result.isEmpty {
            // Return a diverse set of English samples
            result = SampleLibrary.samples
                .filter { $0.language == .english }
                .prefix(6)
                .map { $0 }
        }

        return Array(result.prefix(6))
    }

    // MARK: - Navigation Actions

    func goToNextScreen() {
        guard !isTransitioning else { return }

        var nextScreen = OnboardingScreen(rawValue: currentScreen.rawValue + 1)

        // Apply role recommendations when leaving userRole screen
        if currentScreen == .userRole {
            applyRoleRecommendations()
        }

        // Skip personalizedSamples if no categories selected
        if nextScreen == .personalizedSamples && !shouldShowSampleShowcase {
            nextScreen = .readyToCreate
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

        var prevScreen = OnboardingScreen(rawValue: currentScreen.rawValue - 1)

        // Skip personalizedSamples when going back if no categories selected
        if prevScreen == .personalizedSamples && !shouldShowSampleShowcase {
            prevScreen = .buildingExperience
        }

        if let prevIndex = prevScreen {
            isTransitioning = true
            withAnimation(FGAnimations.slowEase) {
                currentScreen = prevIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + FGAnimations.durationSlow) {
                self.isTransitioning = false
            }
        }
    }

    func skipCurrentScreen() {
        // Just advance to next screen without setting values
        goToNextScreen()
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
                selectedMockCategory = .event
                demoStep = .style

            case .style:
                selectedMockStyle = .modern
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
                selectedMockColorTheme = .vibrant
                demoStep = .aiAnalysis
                // Stop regular timer and use custom delay for AI step
                stopAutoDemo()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.advanceToNextStep()
                }

            case .aiAnalysis:
                demoStep = .ready
                showContinueButton = true

            case .ready:
                break
            }
        }
    }

    // MARK: - Reset

    func resetDemo() {
        selectedMockCategory = nil
        selectedMockStyle = nil
        selectedMockColorTheme = nil
        mockHeadline = ""
        mockDate = ""
        mockLocation = ""
        hasLogo = false
        hasQRCode = false
        demoStep = .category
        showContinueButton = false
    }
}
