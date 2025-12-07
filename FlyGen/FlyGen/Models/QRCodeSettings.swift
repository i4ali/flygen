import Foundation

/// Types of content a QR code can encode
enum QRContentType: String, CaseIterable, Codable, Identifiable {
    case url = "url"
    case vcard = "vcard"
    case text = "text"
    case email = "email"
    case phone = "phone"
    case wifi = "wifi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .url: return "Website URL"
        case .vcard: return "Contact Card"
        case .text: return "Plain Text"
        case .email: return "Email"
        case .phone: return "Phone Number"
        case .wifi: return "WiFi Network"
        }
    }

    var icon: String {
        switch self {
        case .url: return "link"
        case .vcard: return "person.crop.rectangle"
        case .text: return "text.alignleft"
        case .email: return "envelope"
        case .phone: return "phone"
        case .wifi: return "wifi"
        }
    }
}

/// Position for QR code on flyer
enum QRPosition: String, CaseIterable, Codable, Identifiable {
    case bottomRight = "bottom_right"
    case bottomLeft = "bottom_left"
    case topRight = "top_right"
    case topLeft = "top_left"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bottomRight: return "Bottom Right"
        case .bottomLeft: return "Bottom Left"
        case .topRight: return "Top Right"
        case .topLeft: return "Top Left"
        }
    }

    var icon: String {
        switch self {
        case .bottomRight: return "arrow.down.right.square"
        case .bottomLeft: return "arrow.down.left.square"
        case .topRight: return "arrow.up.right.square"
        case .topLeft: return "arrow.up.left.square"
        }
    }
}

/// QR code configuration for flyer
struct QRCodeSettings: Codable, Equatable {
    var enabled: Bool = false
    var contentType: QRContentType = .url
    var position: QRPosition = .bottomRight

    // URL content
    var url: String?

    // vCard content
    var vcardName: String?
    var vcardPhone: String?
    var vcardEmail: String?
    var vcardCompany: String?
    var vcardTitle: String?
    var vcardWebsite: String?

    // Other content
    var text: String?
    var emailAddress: String?
    var emailSubject: String?
    var phoneNumber: String?

    // WiFi content
    var wifiSSID: String?
    var wifiPassword: String?
    var wifiSecurity: String? = "WPA" // "WPA", "WEP", "nopass"

    /// Returns true if the QR code has valid content for its type
    var hasValidContent: Bool {
        guard enabled else { return true }

        switch contentType {
        case .url:
            return url?.isEmpty == false
        case .vcard:
            return vcardName?.isEmpty == false
        case .text:
            return text?.isEmpty == false
        case .email:
            return emailAddress?.isEmpty == false
        case .phone:
            return phoneNumber?.isEmpty == false
        case .wifi:
            return wifiSSID?.isEmpty == false
        }
    }
}
