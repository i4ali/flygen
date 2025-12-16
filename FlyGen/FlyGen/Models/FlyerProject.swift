import Foundation

struct FlyerProject: Codable, Identifiable, Equatable {
    let id: UUID
    var category: FlyerCategory
    var language: FlyerLanguage
    var textContent: TextContent
    var colors: ColorSettings
    var visuals: VisualSettings
    var output: OutputSettings
    var targetAudience: String?
    var specialInstructions: String?
    var logoImageData: Data?
    var userPhotoData: Data?           // User's uploaded photo for AI to incorporate
    var imageryDescription: String?     // Text description for AI-generated imagery
    var qrSettings: QRCodeSettings
    let createdAt: Date
    var updatedAt: Date

    init(category: FlyerCategory, language: FlyerLanguage = .english) {
        self.id = UUID()
        self.category = category
        self.language = language
        self.textContent = TextContent()
        self.colors = ColorSettings()
        self.visuals = VisualSettings()
        self.output = OutputSettings()
        self.qrSettings = QRCodeSettings()
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Creates a copy of another project with a new ID and timestamps
    init(copyFrom source: FlyerProject) {
        self.id = UUID()
        self.category = source.category
        self.language = source.language
        self.textContent = source.textContent
        self.colors = source.colors
        self.visuals = source.visuals
        self.output = source.output
        self.targetAudience = source.targetAudience
        self.specialInstructions = source.specialInstructions
        self.logoImageData = source.logoImageData
        self.userPhotoData = source.userPhotoData
        self.imageryDescription = source.imageryDescription
        self.qrSettings = source.qrSettings
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Updates the updatedAt timestamp
    mutating func touch() {
        updatedAt = Date()
    }

    /// Returns true if the project has minimum required data
    var isReadyForGeneration: Bool {
        textContent.isValid
    }
}

/// Result of a flyer generation
struct GeneratedFlyer: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let imageData: Data
    let prompt: String
    let negativePrompt: String
    let model: String
    let createdAt: Date

    init(projectId: UUID, imageData: Data, prompt: String, negativePrompt: String, model: String) {
        self.id = UUID()
        self.projectId = projectId
        self.imageData = imageData
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.model = model
        self.createdAt = Date()
    }
}
