import Foundation

/// Service for persisting draft flyer projects locally
/// Uses UserDefaults for metadata and file system for large image data
class DraftStorageService {

    // MARK: - Constants

    private let draftKey = "activeDraft"
    private let draftImagesFolderName = "draft-images"
    private let logoFileName = "logo.dat"
    private let userPhotoFileName = "userPhoto.dat"

    // MARK: - Data Model

    /// Stored draft data (without large images)
    private struct DraftData: Codable {
        let projectId: UUID
        let currentStepRawValue: Int
        let savedAt: Date
        let project: FlyerProject
    }

    // MARK: - Public Interface

    /// Check if there's a saved draft
    func hasDraft() -> Bool {
        return UserDefaults.standard.data(forKey: draftKey) != nil
    }

    /// Get the saved date of the current draft (for display)
    func draftSavedAt() -> Date? {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draftData = try? JSONDecoder().decode(DraftData.self, from: data) else {
            return nil
        }
        return draftData.savedAt
    }

    /// Get draft category name (for display in resume prompt)
    func draftCategoryName() -> String? {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draftData = try? JSONDecoder().decode(DraftData.self, from: data) else {
            return nil
        }
        return draftData.project.category.displayName
    }

    /// Save the current project as a draft
    func saveDraft(project: FlyerProject, currentStep: CreationStep) {
        // Create a copy of the project without large image data
        var projectForStorage = project
        let logoData = project.logoImageData
        let userPhotoData = project.userPhotoData

        // Strip images from the project (will store separately)
        projectForStorage.logoImageData = nil
        projectForStorage.userPhotoData = nil

        // Create draft data
        let draftData = DraftData(
            projectId: project.id,
            currentStepRawValue: currentStep.rawValue,
            savedAt: Date(),
            project: projectForStorage
        )

        // Encode and save to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(draftData)
            UserDefaults.standard.set(encoded, forKey: draftKey)

            // Save images to file system
            saveImageData(logoData, fileName: logoFileName)
            saveImageData(userPhotoData, fileName: userPhotoFileName)

        } catch {
            print("Failed to save draft: \(error)")
        }
    }

    /// Load the saved draft
    /// Returns the project with images restored, and the step to resume from
    func loadDraft() -> (project: FlyerProject, step: CreationStep)? {
        guard let data = UserDefaults.standard.data(forKey: draftKey),
              let draftData = try? JSONDecoder().decode(DraftData.self, from: data) else {
            return nil
        }

        // Restore project with images
        var project = draftData.project
        project.logoImageData = loadImageData(fileName: logoFileName)
        project.userPhotoData = loadImageData(fileName: userPhotoFileName)

        // Get the step (default to textContent if invalid)
        let step = CreationStep(rawValue: draftData.currentStepRawValue) ?? .textContent

        return (project, step)
    }

    /// Clear the saved draft
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)

        // Clean up image files
        deleteImageData(fileName: logoFileName)
        deleteImageData(fileName: userPhotoFileName)
    }

    // MARK: - Private Helpers

    /// Get the URL for the draft images folder
    private func draftImagesFolder() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let folderURL = documentsURL.appendingPathComponent(draftImagesFolderName)

        // Create folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        return folderURL
    }

    /// Save image data to file
    private func saveImageData(_ data: Data?, fileName: String) {
        guard let data = data,
              let folderURL = draftImagesFolder() else {
            // If no data, delete existing file
            deleteImageData(fileName: fileName)
            return
        }

        let fileURL = folderURL.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }

    /// Load image data from file
    private func loadImageData(fileName: String) -> Data? {
        guard let folderURL = draftImagesFolder() else { return nil }

        let fileURL = folderURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    /// Delete image file
    private func deleteImageData(fileName: String) {
        guard let folderURL = draftImagesFolder() else { return }

        let fileURL = folderURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
