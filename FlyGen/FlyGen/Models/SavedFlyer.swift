import Foundation
import SwiftData

@Model
final class SavedFlyer {
    var id: UUID
    var projectData: Data  // Encoded FlyerProject
    var imageData: Data?   // Generated image
    var prompt: String
    var model: String
    var createdAt: Date
    var updatedAt: Date

    init(project: FlyerProject, generatedFlyer: GeneratedFlyer) {
        self.id = UUID()
        self.projectData = (try? JSONEncoder().encode(project)) ?? Data()
        self.imageData = generatedFlyer.imageData
        self.prompt = generatedFlyer.prompt
        self.model = generatedFlyer.model
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Decodes the stored FlyerProject
    var project: FlyerProject? {
        try? JSONDecoder().decode(FlyerProject.self, from: projectData)
    }

    /// Returns the category name from the stored project
    var categoryName: String {
        project?.category.rawValue ?? "Unknown"
    }

    /// Returns the headline from the stored project
    var headline: String {
        project?.textContent.headline ?? "Untitled Flyer"
    }
}
