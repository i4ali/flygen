import Foundation
import UIKit

/// Errors that can occur during image generation
enum ImageGenerationError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noImageInResponse
    case decodingError(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
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

/// Service for generating images via OpenRouter API through Cloudflare Worker proxy
actor OpenRouterService {
    private let baseURL = URL(string: "https://flygen-api.ali-muhammadimran.workers.dev")!
    private let model = "google/gemini-3-pro-image-preview"

    /// Generate an image from a flyer project
    func generateImage(
        project: FlyerProject
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
            userPhotoData: project.userPhotoData,
            startTime: startTime
        )
    }

    /// Generate an image with a raw prompt (for refinements)
    func generateImage(
        prompt: String,
        aspectRatio: AspectRatio,
        logoImageData: Data? = nil,
        userPhotoData: Data? = nil,
        previousFlyerData: Data? = nil,
        startTime: Date = Date()
    ) async throws -> ImageGenerationResult {

        // Build request content
        var content: [[String: Any]] = []

        // Note: Logo is no longer sent to API - it's composited programmatically after generation

        // Add previous flyer image for refinement (first so AI sees it before instructions)
        if let previousData = previousFlyerData {
            let base64Previous = previousData.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/png;base64,\(base64Previous)"]
            ])
        }

        // Add user photo if provided
        if let photoData = userPhotoData {
            let base64Photo = photoData.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/png;base64,\(base64Photo)"]
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

        // Create request - API key is handled by Cloudflare Worker proxy
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
