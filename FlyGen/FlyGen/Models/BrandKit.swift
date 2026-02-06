import Foundation
import SwiftData

@Model
final class BrandKit {
    // CloudKit requires default values for all non-optional properties
    var id: UUID = UUID()

    // Logo
    @Attribute(.externalStorage) var logoImageData: Data?
    var logoPositionRawValue: String = LogoPosition.topRight.rawValue

    // QR Code defaults (encoded QRCodeSettings JSON)
    var qrSettingsData: Data?

    // Contact info
    var businessName: String?
    var phone: String?
    var email: String?
    var website: String?
    var address: String?
    var socialHandle: String?

    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {
        // Default initializer required for CloudKit
    }

    // MARK: - Computed Helpers

    var logoPosition: LogoPosition {
        get { LogoPosition(rawValue: logoPositionRawValue) ?? .topRight }
        set { logoPositionRawValue = newValue.rawValue }
    }

    var qrSettings: QRCodeSettings? {
        get {
            guard let data = qrSettingsData else { return nil }
            return try? JSONDecoder().decode(QRCodeSettings.self, from: data)
        }
        set {
            qrSettingsData = try? JSONEncoder().encode(newValue)
        }
    }

    var hasContent: Bool {
        logoImageData != nil || hasContactInfo || (qrSettings?.enabled == true)
    }

    var hasContactInfo: Bool {
        [businessName, phone, email, website, address, socialHandle]
            .contains { $0?.isEmpty == false }
    }

    var contentSummary: String {
        var parts: [String] = []
        if logoImageData != nil { parts.append("Logo") }
        if qrSettings?.enabled == true { parts.append("QR Code") }
        if hasContactInfo { parts.append("Contact Info") }
        return parts.isEmpty ? "Not configured" : parts.joined(separator: " + ")
    }
}
