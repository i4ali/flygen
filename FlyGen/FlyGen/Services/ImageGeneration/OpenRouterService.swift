import Foundation
import UIKit

/// Errors that can occur during image generation
enum ImageGenerationError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noImageInResponse
    case decodingError(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenRouter API key in Settings."
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .noImageInResponse:
            return "No image was returned from the API."
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

/// Result of image generation
struct ImageGenerationResult {
    let imageData: Data
    let image: UIImage
    let model: String
    let generationTime: TimeInterval
}

/// Service for generating images via OpenRouter API
actor OpenRouterService {
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let model = "google/gemini-2.5-flash-image-preview"

    /// Generate an image from a flyer project
    func generateImage(
        project: FlyerProject,
        apiKey: String
    ) async throws -> ImageGenerationResult {
        let startTime = Date()

        // Build the prompt
        let promptBuilder = PromptBuilder(project: project)
        let promptPackage = promptBuilder.build()

        // Combine main prompt with negative prompt
        var fullPrompt = promptPackage.mainPrompt
        if !promptPackage.negativePrompt.isEmpty {
            fullPrompt += "\n\nAVOID: \(promptPackage.negativePrompt)"
        }

        return try await generateImage(
            prompt: fullPrompt,
            aspectRatio: project.output.aspectRatio,
            logoImageData: project.logoImageData,
            apiKey: apiKey,
            startTime: startTime
        )
    }

    /// Generate an image with a raw prompt (for refinements)
    func generateImage(
        prompt: String,
        aspectRatio: AspectRatio,
        logoImageData: Data? = nil,
        apiKey: String,
        startTime: Date = Date()
    ) async throws -> ImageGenerationResult {
        guard !apiKey.isEmpty else {
            throw ImageGenerationError.noAPIKey
        }

        // Build request content
        var content: [[String: Any]] = []

        // Add logo if provided
        if let logoData = logoImageData {
            let base64Logo = logoData.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/png;base64,\(base64Logo)"]
            ])
        }

        // Add text prompt
        content.append([
            "type": "text",
            "text": prompt
        ])

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": content]
            ],
            "modalities": ["image", "text"],
            "image_config": ["aspect_ratio": aspectRatio.nanoBananaRatio]
        ]

        // Create request
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://flygen.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("FlyGen", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 120 // 2 minute timeout for image generation

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw ImageGenerationError.decodingError("Failed to encode request: \(error.localizedDescription)")
        }

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageGenerationError.invalidResponse
        }

        // Check for HTTP errors
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ImageGenerationError.apiError(message)
            }
            throw ImageGenerationError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw ImageGenerationError.decodingError("Failed to parse response structure")
        }

        // Extract image from response
        // OpenRouter returns images in message.images array
        guard let images = message["images"] as? [[String: Any]],
              let firstImage = images.first,
              let imageUrl = firstImage["image_url"] as? [String: Any],
              let dataUrl = imageUrl["url"] as? String else {
            throw ImageGenerationError.noImageInResponse
        }

        // Parse base64 from data URL: "data:image/png;base64,..."
        guard dataUrl.contains(","),
              let base64String = dataUrl.split(separator: ",").last else {
            throw ImageGenerationError.decodingError("Invalid image data URL format")
        }

        guard let imageData = Data(base64Encoded: String(base64String)) else {
            throw ImageGenerationError.decodingError("Failed to decode base64 image data")
        }

        guard let image = UIImage(data: imageData) else {
            throw ImageGenerationError.decodingError("Failed to create UIImage from data")
        }

        let generationTime = Date().timeIntervalSince(startTime)

        return ImageGenerationResult(
            imageData: imageData,
            image: image,
            model: model,
            generationTime: generationTime
        )
    }
}
