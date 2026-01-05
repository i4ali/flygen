import Foundation

/// Result containing both element and special instruction suggestions
struct SuggestionResult {
    let elements: [String]
    let specialInstructions: [String]
}

/// Service for generating AI-powered suggestions for flyer creation
actor SuggestionService {
    private let baseURL = "https://flygen-api.ali-muhammadimran.workers.dev"
    private let model = "openai/gpt-4o-mini"
    private var lastCallTime: Date?
    private let rateLimitInterval: TimeInterval = 60 // 1 minute

    enum SuggestionError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case noSuggestionsGenerated
        case rateLimited
    }

    /// Generates contextual suggestions for both elements and special instructions
    func generateSuggestions(for project: FlyerProject) async throws -> SuggestionResult {
        // Rate limit: 1 call per 60 seconds
        if let lastCall = lastCallTime, Date().timeIntervalSince(lastCall) < rateLimitInterval {
            throw SuggestionError.rateLimited
        }

        guard let url = URL(string: baseURL) else {
            throw SuggestionError.invalidURL
        }

        let prompt = buildPrompt(for: project)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a professional graphic designer assistant. Generate suggestions for a flyer design.

                    Return a JSON object with exactly this structure:
                    {
                      "elements": ["element1", "element2", "element3", "element4", "element5"],
                      "specialInstructions": ["instruction1", "instruction2", "instruction3", "instruction4", "instruction5"]
                    }

                    - "elements": 5 visual elements/objects to include (e.g., "snowflakes", "golden ribbons", "confetti")
                    - "specialInstructions": 5 design techniques or effects (e.g., "Soft gradient background", "Text with golden glow")

                    Each item should be a concise phrase (3-8 words). Return ONLY the JSON object, no other text.
                    """
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 400
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SuggestionError.invalidResponse
            }

            let result = try parseSuggestions(from: data)
            lastCallTime = Date() // Update after successful call
            return result
        } catch let error as SuggestionError {
            throw error
        } catch {
            throw SuggestionError.networkError(error)
        }
    }

    /// Builds the prompt with relevant context from the project
    private func buildPrompt(for project: FlyerProject) -> String {
        var contextParts: [String] = []

        // Category
        contextParts.append("Flyer type: \(project.category.displayName)")

        // Mood
        contextParts.append("Mood: \(project.visuals.mood.displayName)")

        // Visual style
        contextParts.append("Style: \(project.visuals.style.displayName)")

        // Text content
        if !project.textContent.headline.isEmpty {
            contextParts.append("Headline: \(project.textContent.headline)")
        }

        if let subheadline = project.textContent.subheadline, !subheadline.isEmpty {
            contextParts.append("Subheadline: \(subheadline)")
        }

        // Colors
        if let primaryColor = project.colors.primaryColor, !primaryColor.isEmpty {
            contextParts.append("Primary color: \(primaryColor)")
        }

        // Note: We don't include existing elements since we're generating them

        let context = contextParts.joined(separator: "\n")

        return """
        Generate creative suggestions for this flyer:

        \(context)

        Provide visual elements that fit the theme and special instructions for design techniques that would enhance this flyer.
        """
    }

    /// Parses the AI response to extract both element and instruction suggestions
    private func parseSuggestions(from data: Data) throws -> SuggestionResult {
        // Parse the OpenRouter response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SuggestionError.invalidResponse
        }

        // Clean the content (remove markdown code blocks if present)
        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse the JSON object
        guard let jsonData = cleanedContent.data(using: .utf8),
              let resultDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw SuggestionError.noSuggestionsGenerated
        }

        // Extract elements array
        let elements: [String]
        if let elementsArray = resultDict["elements"] as? [String] {
            elements = Array(elementsArray.prefix(5))
        } else {
            elements = []
        }

        // Extract special instructions array
        let specialInstructions: [String]
        if let instructionsArray = resultDict["specialInstructions"] as? [String] {
            specialInstructions = Array(instructionsArray.prefix(5))
        } else {
            specialInstructions = []
        }

        // Ensure we have at least some suggestions
        if elements.isEmpty && specialInstructions.isEmpty {
            throw SuggestionError.noSuggestionsGenerated
        }

        return SuggestionResult(elements: elements, specialInstructions: specialInstructions)
    }
}
