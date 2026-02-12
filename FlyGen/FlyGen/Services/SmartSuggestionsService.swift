import Foundation

/// Service for generating AI-powered smart suggestions for the extras step
actor SmartSuggestionsService {
    private let baseURL = "https://flygen-api.ali-muhammadimran.workers.dev"
    private let model = "openai/gpt-4o"

    enum SmartSuggestionError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case noSuggestionsGenerated
    }

    /// Generates contextual smart suggestions for the extras step
    func generateSuggestions(for project: FlyerProject) async throws -> SmartExtrasState {
        guard let url = URL(string: baseURL) else {
            throw SmartSuggestionError.invalidURL
        }

        let prompt = buildPrompt(for: project)

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
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
                throw SmartSuggestionError.invalidResponse
            }

            return try parseResponse(from: data)
        } catch let error as SmartSuggestionError {
            throw error
        } catch {
            throw SmartSuggestionError.networkError(error)
        }
    }

    // MARK: - System Prompt

    private var systemPrompt: String {
        """
        You are analyzing a flyer to generate smart suggestions. Based on the context provided, return personalized suggestions in JSON format.

        Return a JSON object with exactly this structure:
        {
          "headerTitle": "Short personalized header (3-5 words)",
          "photoSuggestions": [
            {
              "title": "Suggestion title",
              "description": "Brief description of why this photo helps",
              "icon": "SF Symbol name",
              "detectedItems": ["item1", "item2", "item3", "item4", "item5"] (MUST include EVERY item from body text),
              "allowsUpload": true,
              "allowsAIGeneration": true or false,
              "allowsMultiplePhotos": true or false,
              "photoCount": 1
            }
          ],
          "elementSuggestions": ["element1", "element2", "element3", "element4", "element5", "element6"]
        }

        Guidelines:
        - headerTitle: Personalized based on flyer type (e.g., "Make it appetizing" for food, "Set the stage" for concerts)
        - photoSuggestions: 1-3 relevant photo suggestions based on the flyer type
          - For food/restaurant: extract ALL dish/menu item names from body text (include every item, do not limit or summarize), allow AI generation
          - For people (performers, instructors, birthday): suggest photo upload only, NO AI generation
          - For properties/products: suggest photo upload, AI generation for products only
          - icon: Use SF Symbols (fork.knife, music.mic, house, person.circle, building.2, storefront, bag, photo)
        - elementSuggestions: 6 visual elements appropriate for this flyer's category, mood, and cultural context
          - Be culturally aware (Islamic events, Hindu festivals, Christian holidays, etc.)
          - Match the mood (festive, somber, urgent, elegant, etc.)

        CRITICAL FOR PEOPLE-BASED CATEGORIES (concerts, classes, parties, fitness, events with performers):
        - Set allowsMultiplePhotos: true for photo suggestions featuring people
        - Analyze the flyer content (headline, body text) to count people mentioned
        - Set photoCount to match the exact number of people/performers detected
        - Default to photoCount: 1 if unclear
        - No hard maximum - if 10 people mentioned, return photoCount: 10
        - Examples:
          - "DJ Night with Mike" → photoCount: 1
          - "Live Music by The Duo" → photoCount: 2
          - "Yoga with Sarah, Mike & Lisa" → photoCount: 3
          - "The Full Band: John, Paul, George, Ringo" → photoCount: 4
          - "Birthday party for the twins" → photoCount: 2
          - "10-piece orchestra" → photoCount: 10

        CRITICAL FOR FOOD/RESTAURANT FLYERS:
        - You MUST include EVERY dish name found in the body text in detectedItems
        - NEVER stop at 3 items - include ALL items found
        - Do NOT truncate, summarize, or limit the list
        - If body text has 4 items, return exactly 4 items in detectedItems
        - If body text has 10 items, return exactly 10 items in detectedItems
        - Count the items in the input and verify your output has the same count
        - Set allowsMultiplePhotos: true for food/restaurant categories
        - Set photoCount to match the exact number of dishes detected in detectedItems
        - Example: If body text has "Margherita Pizza, Caesar Salad, Chicken Parmesan"
          → detectedItems: ["Margherita Pizza", "Caesar Salad", "Chicken Parmesan"]
          → allowsMultiplePhotos: true
          → photoCount: 3
        - User can upload real photos of their dishes

        Return ONLY the JSON object, no other text.
        """
    }

    // MARK: - Build Prompt

    private func buildPrompt(for project: FlyerProject) -> String {
        var contextParts: [String] = []

        // Category
        contextParts.append("Category: \(project.category.displayName)")

        // Mood
        contextParts.append("Mood: \(project.visuals.mood.displayName)")

        // Visual style
        contextParts.append("Style: \(project.visuals.style.displayName)")

        // Text content
        contextParts.append("Headline: \(project.textContent.headline)")

        if let subheadline = project.textContent.subheadline, !subheadline.isEmpty {
            contextParts.append("Subheadline: \(subheadline)")
        }

        if let bodyText = project.textContent.bodyText, !bodyText.isEmpty {
            contextParts.append("Body text: \(bodyText)")
        }

        if let venueName = project.textContent.venueName, !venueName.isEmpty {
            contextParts.append("Venue: \(venueName)")
        }

        if let date = project.textContent.date, !date.isEmpty {
            contextParts.append("Date: \(date)")
        }

        // Colors
        if let primaryColor = project.colors.primaryColor, !primaryColor.isEmpty {
            contextParts.append("Primary color: \(primaryColor)")
        }

        let context = contextParts.joined(separator: "\n")

        return """
        Generate smart suggestions for this flyer:

        \(context)

        Analyze the content and provide culturally appropriate, contextually relevant suggestions.
        """
    }

    // MARK: - Parse Response

    private func parseResponse(from data: Data) throws -> SmartExtrasState {
        // Parse the OpenRouter response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SmartSuggestionError.invalidResponse
        }

        // Clean the content (remove markdown code blocks if present)
        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse the JSON object
        guard let jsonData = cleanedContent.data(using: .utf8),
              let resultDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw SmartSuggestionError.noSuggestionsGenerated
        }

        // Extract header title
        let headerTitle = resultDict["headerTitle"] as? String ?? "Finishing touches"

        // Extract photo suggestions
        var photoSuggestions: [PhotoSuggestion] = []
        if let photoArray = resultDict["photoSuggestions"] as? [[String: Any]] {
            for photoDict in photoArray.prefix(3) {
                if let title = photoDict["title"] as? String,
                   let description = photoDict["description"] as? String {
                    let icon = photoDict["icon"] as? String ?? "photo"
                    let detectedItems = photoDict["detectedItems"] as? [String]
                    let allowsUpload = photoDict["allowsUpload"] as? Bool ?? true
                    let allowsAIGeneration = photoDict["allowsAIGeneration"] as? Bool ?? false
                    let allowsMultiplePhotos = photoDict["allowsMultiplePhotos"] as? Bool ?? false
                    let photoCount = photoDict["photoCount"] as? Int ?? 1

                    let suggestion = PhotoSuggestion(
                        title: title,
                        description: description,
                        icon: icon,
                        detectedItems: detectedItems,
                        allowsUpload: allowsUpload,
                        allowsAIGeneration: allowsAIGeneration,
                        allowsMultiplePhotos: allowsMultiplePhotos,
                        photoCount: max(1, photoCount)  // Ensure at least 1
                    )
                    photoSuggestions.append(suggestion)
                }
            }
        }

        // Extract element suggestions
        var elementSuggestions: [ElementSuggestion] = []
        if let elements = resultDict["elementSuggestions"] as? [String] {
            for element in elements.prefix(8) {
                let icon = iconForElement(element)
                elementSuggestions.append(ElementSuggestion(element: element, icon: icon))
            }
        }

        // Ensure we have at least some suggestions
        if photoSuggestions.isEmpty && elementSuggestions.isEmpty {
            throw SmartSuggestionError.noSuggestionsGenerated
        }

        return SmartExtrasState(
            headerTitle: headerTitle,
            photoSuggestions: photoSuggestions,
            elementSuggestions: elementSuggestions
        )
    }

    // MARK: - Icon Mapping

    private func iconForElement(_ element: String) -> String {
        let lowercased = element.lowercased()

        // Party/Celebration
        if lowercased.contains("balloon") { return "balloon.2" }
        if lowercased.contains("confetti") { return "party.popper" }
        if lowercased.contains("sparkle") { return "sparkles" }
        if lowercased.contains("star") { return "star.fill" }
        if lowercased.contains("cake") { return "birthday.cake" }
        if lowercased.contains("gift") || lowercased.contains("ribbon") { return "gift" }

        // Religious/Cultural
        if lowercased.contains("crescent") || lowercased.contains("islamic") { return "moon.stars" }
        if lowercased.contains("calligraphy") { return "text.word.spacing" }
        if lowercased.contains("candle") { return "flame" }
        if lowercased.contains("cross") { return "cross" }
        if lowercased.contains("diya") || lowercased.contains("lamp") { return "lightbulb.fill" }

        // Nature/Organic
        if lowercased.contains("flower") || lowercased.contains("floral") { return "leaf.fill" }
        if lowercased.contains("heart") { return "heart.fill" }
        if lowercased.contains("sun") { return "sun.max.fill" }
        if lowercased.contains("moon") { return "moon.fill" }

        // Food
        if lowercased.contains("food") || lowercased.contains("dish") { return "fork.knife" }

        // Music/Entertainment
        if lowercased.contains("music") || lowercased.contains("note") { return "music.note" }

        // Geometric/Design
        if lowercased.contains("geometric") { return "square.grid.2x2" }
        if lowercased.contains("border") { return "rectangle" }
        if lowercased.contains("gradient") { return "rectangle.fill" }
        if lowercased.contains("glow") { return "light.max" }
        if lowercased.contains("burst") { return "seal" }

        // Default
        return "wand.and.stars"
    }
}
