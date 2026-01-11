import Foundation

// MARK: - Photo Suggestion

/// Represents a smart photo suggestion based on category and content analysis
struct PhotoSuggestion: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let detectedItems: [String]?
    let allowsUpload: Bool
    let allowsAIGeneration: Bool
    var isEnabled: Bool
    var uploadedPhotoData: Data?
    var aiGenerationPrompt: String?

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        detectedItems: [String]? = nil,
        allowsUpload: Bool = true,
        allowsAIGeneration: Bool = false,
        isEnabled: Bool = false,
        uploadedPhotoData: Data? = nil,
        aiGenerationPrompt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.detectedItems = detectedItems
        self.allowsUpload = allowsUpload
        self.allowsAIGeneration = allowsAIGeneration
        self.isEnabled = isEnabled
        self.uploadedPhotoData = uploadedPhotoData
        self.aiGenerationPrompt = aiGenerationPrompt
    }
}

// MARK: - Element Suggestion

/// Represents a visual element suggestion (balloons, confetti, etc.)
struct ElementSuggestion: Identifiable, Equatable, Codable {
    let id: UUID
    let element: String
    let icon: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        element: String,
        icon: String = "wand.and.stars",
        isEnabled: Bool = false
    ) {
        self.id = id
        self.element = element
        self.icon = icon
        self.isEnabled = isEnabled
    }
}

// MARK: - Smart Extras State

/// Holds all smart suggestion state for the extras step
struct SmartExtrasState: Codable, Equatable {
    var headerTitle: String?
    var photoSuggestions: [PhotoSuggestion]
    var elementSuggestions: [ElementSuggestion]
    var additionalNotes: String?

    init(
        headerTitle: String? = nil,
        photoSuggestions: [PhotoSuggestion] = [],
        elementSuggestions: [ElementSuggestion] = [],
        additionalNotes: String? = nil
    ) {
        self.headerTitle = headerTitle
        self.photoSuggestions = photoSuggestions
        self.elementSuggestions = elementSuggestions
        self.additionalNotes = additionalNotes
    }

    /// Returns enabled photo suggestions
    var enabledPhotoSuggestions: [PhotoSuggestion] {
        photoSuggestions.filter { $0.isEnabled }
    }

    /// Returns enabled element suggestions as strings for prompt building
    var enabledElements: [String] {
        elementSuggestions.filter { $0.isEnabled }.map { $0.element }
    }

    /// Returns the first uploaded photo data if any
    var firstUploadedPhotoData: Data? {
        photoSuggestions.first { $0.isEnabled && $0.uploadedPhotoData != nil }?.uploadedPhotoData
    }

    /// Returns the first AI generation prompt if any
    var firstAIGenerationPrompt: String? {
        photoSuggestions.first { $0.isEnabled && $0.aiGenerationPrompt != nil }?.aiGenerationPrompt
    }
}

// MARK: - AI Response Models

/// Response structure from the smart suggestions API
struct SmartSuggestionsResponse: Codable {
    let headerTitle: String
    let photoSuggestions: [PhotoSuggestionResponse]
    let elementSuggestions: [String]
}

/// Photo suggestion from AI response
struct PhotoSuggestionResponse: Codable {
    let title: String
    let description: String
    let icon: String?
    let detectedItems: [String]?
    let allowsUpload: Bool
    let allowsAIGeneration: Bool

    /// Convert to PhotoSuggestion model
    func toPhotoSuggestion() -> PhotoSuggestion {
        PhotoSuggestion(
            title: title,
            description: description,
            icon: icon ?? "photo",
            detectedItems: detectedItems,
            allowsUpload: allowsUpload,
            allowsAIGeneration: allowsAIGeneration
        )
    }
}
