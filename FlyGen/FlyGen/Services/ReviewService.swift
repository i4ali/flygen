import StoreKit
import SwiftUI

/// Service for managing App Store review requests
/// Uses Apple's SKStoreReviewController which is rate-limited by the system
@MainActor
class ReviewService: ObservableObject {

    // MARK: - Configuration

    /// Number of successful generations before first review prompt
    private let generationsBeforeFirstPrompt = 1

    /// Number of generations between subsequent prompts
    private let generationsBetweenPrompts = 10

    /// Minimum days between review prompts
    private let minimumDaysBetweenPrompts = 30

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let successfulGenerations = "reviewService.successfulGenerations"
        static let lastPromptDate = "reviewService.lastPromptDate"
        static let promptCount = "reviewService.promptCount"
    }

    // MARK: - State

    private var successfulGenerations: Int {
        get { UserDefaults.standard.integer(forKey: Keys.successfulGenerations) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.successfulGenerations) }
    }

    private var lastPromptDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastPromptDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPromptDate) }
    }

    private var promptCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.promptCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.promptCount) }
    }

    // MARK: - Public Methods

    /// Call this after a successful flyer generation
    /// The service will determine if it's appropriate to show a review prompt
    func recordSuccessfulGeneration() {
        successfulGenerations += 1

        if shouldRequestReview() {
            requestReview()
        }
    }

    /// Manually request a review (e.g., from settings)
    func requestReviewManually() {
        requestReview()
    }

    // MARK: - Private Methods

    private func shouldRequestReview() -> Bool {
        // Check if we've reached the threshold for first prompt
        if promptCount == 0 {
            return successfulGenerations >= generationsBeforeFirstPrompt
        }

        // For subsequent prompts, check generation count since last prompt
        let generationsSinceLastPrompt = successfulGenerations - (promptCount * generationsBetweenPrompts + generationsBeforeFirstPrompt)
        guard generationsSinceLastPrompt >= generationsBetweenPrompts else {
            return false
        }

        // Check minimum days between prompts
        if let lastDate = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysBetweenPrompts else {
                return false
            }
        }

        return true
    }

    private func requestReview() {
        // Update tracking
        lastPromptDate = Date()
        promptCount += 1

        // Request review using the appropriate API
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
