import Foundation

/// Builds refinement prompts based on user feedback
struct RefinementBuilder {

    /// Common feedback patterns and their prompt modifications
    static let feedbackPatterns: [String: String] = [
        "bigger text": "larger, more prominent text that commands attention",
        "larger text": "larger, more prominent text that commands attention",
        "can't read": "larger, more prominent text with better contrast for readability",
        "more readable": "clearer, more legible text with improved contrast",
        "too busy": "simplified composition with more white space and less clutter",
        "cluttered": "cleaner, more organized layout with breathing room",
        "too much": "simplified design with fewer elements",
        "cleaner": "more minimalist design with cleaner composition",
        "boring": "more dynamic and visually exciting composition",
        "plain": "more visually interesting design with engaging elements",
        "more exciting": "more dynamic, energetic, and attention-grabbing design",
        "brighter": "more vibrant and colorful palette with higher saturation",
        "more color": "richer, more colorful design with varied hues",
        "vibrant": "bold, saturated colors with high visual impact",
        "darker": "deeper, moodier color treatment",
        "muted": "more subtle and restrained color palette",
        "subtle": "more understated and refined visual treatment",
        "professional": "more polished, business-appropriate aesthetic",
        "corporate": "more formal, corporate-style design",
        "serious": "more professional and serious tone",
        "fun": "more playful and casual feel",
        "playful": "more whimsical and fun design elements",
        "casual": "more relaxed and approachable aesthetic",
        "modern": "more contemporary and current design style",
        "dynamic": "more energetic layout with visual movement",
        "more contrast": "higher contrast between elements for better visibility",
        "softer": "gentler, more subtle tones and transitions",
        "bolder": "stronger, more impactful visual presence",
        "warmer": "warmer color tones with reds, oranges, and yellows",
        "cooler": "cooler color tones with blues, greens, and purples"
    ]

    /// Build a prompt that removes all text from the current design
    static func buildNoTextRefinement(originalPrompt: String) -> String {
        return """
            \(originalPrompt)

            CRITICAL CHANGE: Remove ALL text from this design. \
            Do NOT render any text, letters, words, numbers, or written content of any kind. \
            Keep the same visual design, colors, layout, and imagery but with NO TEXT whatsoever. \
            Leave clean space where text was so it can be added later using design tools.
            """
    }

    /// Build a refinement prompt based on user feedback
    static func buildRefinement(originalPrompt: String, userFeedback: String) -> String {
        let feedbackLower = userFeedback.lowercased()
        var modifications = Set<String>()

        // Check for matching patterns
        for (pattern, modification) in feedbackPatterns {
            if feedbackLower.contains(pattern) {
                modifications.insert(modification)
            }
        }

        // Build the refined prompt
        if !modifications.isEmpty {
            let modString = modifications.joined(separator: ", ")
            return """
                \(originalPrompt)

                IMPORTANT MODIFICATIONS: Apply these changes: \(modString).
                """
        } else {
            // Fallback: append raw feedback
            return """
                \(originalPrompt)

                IMPORTANT CHANGES REQUESTED: \(userFeedback)
                """
        }
    }
}
