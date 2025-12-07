import Photos
import UIKit

/// Errors that can occur when saving to photo library
enum PhotoLibraryError: Error, LocalizedError {
    case accessDenied
    case saveFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo library access denied. Please allow access in Settings."
        case .saveFailed(let error):
            return "Failed to save photo: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred while saving the photo."
        }
    }
}

/// Service for saving images to the photo library
struct PhotoLibraryService {

    /// Request permission to add photos to the library
    static func requestPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    /// Check current permission status
    static var hasPermission: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        return status == .authorized || status == .limited
    }

    /// Save an image to the photo library
    static func saveImage(_ image: UIImage) async throws {
        // Check/request permission
        guard await requestPermission() else {
            throw PhotoLibraryError.accessDenied
        }

        // Save the image
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: PhotoLibraryError.saveFailed(error))
                } else {
                    continuation.resume(throwing: PhotoLibraryError.unknown)
                }
            }
        }
    }

    /// Save image data to the photo library
    static func saveImageData(_ data: Data) async throws {
        guard let image = UIImage(data: data) else {
            throw PhotoLibraryError.unknown
        }
        try await saveImage(image)
    }
}
