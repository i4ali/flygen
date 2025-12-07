import Foundation
import SwiftData

@Model
final class SavedFlyer {
    // CloudKit requires default values for all non-optional properties
    var id: UUID = UUID()
    var projectData: Data = Data()  // Encoded FlyerProject
    @Attribute(.externalStorage) var imageData: Data?  // Generated image - stored externally for large files
    var prompt: String = ""
    var model: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {
        // Default initializer required for CloudKit
    }

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
