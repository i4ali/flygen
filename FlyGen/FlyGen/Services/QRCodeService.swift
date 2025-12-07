import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Service for generating and compositing QR codes onto flyer images
actor QRCodeService {

    private let context = CIContext()

    // MARK: - QR Code Generation

    /// Generate a QR code image from the given content string
    /// - Parameters:
    ///   - string: The content to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage containing the QR code, or nil if generation fails
    func generateQRCode(
        from string: String,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }

        filter.message = data
        filter.correctionLevel = "H" // High error correction (30% tolerance)

        guard let outputImage = filter.outputImage else { return nil }

        // Scale to desired size (QR codes are small by default)
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(
            by: CGAffineTransform(scaleX: scaleX, y: scaleY)
        )

        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Content String Generation

    /// Generate QR code content string based on settings
    /// - Parameter settings: The QR code settings containing content data
    /// - Returns: A formatted string suitable for QR encoding, or nil if invalid
    func generateContent(from settings: QRCodeSettings) -> String? {
        switch settings.contentType {
        case .url:
            return settings.url

        case .vcard:
            return generateVCard(settings)

        case .text:
            return settings.text

        case .email:
            return generateMailto(settings)

        case .phone:
            return generateTel(settings)

        case .wifi:
            return generateWiFiString(settings)
        }
    }

    private func generateVCard(_ settings: QRCodeSettings) -> String? {
        guard let name = settings.vcardName, !name.isEmpty else { return nil }

        var vcard = "BEGIN:VCARD\nVERSION:3.0\n"
        vcard += "N:\(name)\n"
        vcard += "FN:\(name)\n"

        if let company = settings.vcardCompany, !company.isEmpty {
            vcard += "ORG:\(company)\n"
        }
        if let title = settings.vcardTitle, !title.isEmpty {
            vcard += "TITLE:\(title)\n"
        }
        if let phone = settings.vcardPhone, !phone.isEmpty {
            vcard += "TEL:\(phone)\n"
        }
        if let email = settings.vcardEmail, !email.isEmpty {
            vcard += "EMAIL:\(email)\n"
        }
        if let website = settings.vcardWebsite, !website.isEmpty {
            vcard += "URL:\(website)\n"
        }

        vcard += "END:VCARD"
        return vcard
    }

    private func generateMailto(_ settings: QRCodeSettings) -> String? {
        guard let email = settings.emailAddress, !email.isEmpty else { return nil }

        if let subject = settings.emailSubject, !subject.isEmpty,
           let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return "mailto:\(email)?subject=\(encoded)"
        }
        return "mailto:\(email)"
    }

    private func generateTel(_ settings: QRCodeSettings) -> String? {
        guard let phone = settings.phoneNumber, !phone.isEmpty else { return nil }

        // Remove spaces and dashes for tel: protocol
        let cleaned = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        return "tel:\(cleaned)"
    }

    private func generateWiFiString(_ settings: QRCodeSettings) -> String? {
        guard let ssid = settings.wifiSSID, !ssid.isEmpty else { return nil }

        let security = settings.wifiSecurity ?? "WPA"
        let password = settings.wifiPassword ?? ""

        return "WIFI:T:\(security);S:\(ssid);P:\(password);;"
    }

    // MARK: - Image Compositing

    /// Composite QR code onto flyer image
    /// - Parameters:
    ///   - flyer: The base flyer image
    ///   - qrCode: The QR code image to overlay
    ///   - position: The corner position for the QR code
    ///   - sizePercent: QR width as percentage of flyer width (default 15%)
    ///   - marginPercent: Margin from edge as percentage of flyer width (default 3%)
    /// - Returns: The composited image, or nil if compositing fails
    func compositeQRCode(
        onto flyer: UIImage,
        qrCode: UIImage,
        position: QRPosition,
        sizePercent: CGFloat = 0.15,
        marginPercent: CGFloat = 0.03
    ) -> UIImage? {
        let flyerSize = flyer.size
        let qrSize = CGSize(
            width: flyerSize.width * sizePercent,
            height: flyerSize.width * sizePercent // Keep square
        )
        let margin = flyerSize.width * marginPercent
        let padding: CGFloat = 8 // White padding around QR

        // Calculate QR position
        let qrOrigin: CGPoint
        switch position {
        case .bottomRight:
            qrOrigin = CGPoint(
                x: flyerSize.width - qrSize.width - margin - padding,
                y: flyerSize.height - qrSize.height - margin - padding
            )
        case .bottomLeft:
            qrOrigin = CGPoint(
                x: margin,
                y: flyerSize.height - qrSize.height - margin - padding
            )
        case .topRight:
            qrOrigin = CGPoint(
                x: flyerSize.width - qrSize.width - margin - padding,
                y: margin
            )
        case .topLeft:
            qrOrigin = CGPoint(
                x: margin,
                y: margin
            )
        }

        // Create composite image
        let renderer = UIGraphicsImageRenderer(size: flyerSize)

        return renderer.image { ctx in
            // Draw flyer as base
            flyer.draw(at: .zero)

            // Draw white background rectangle for QR (ensures contrast on any background)
            let bgRect = CGRect(
                x: qrOrigin.x - padding,
                y: qrOrigin.y - padding,
                width: qrSize.width + (padding * 2),
                height: qrSize.height + (padding * 2)
            )
            UIColor.white.setFill()
            ctx.fill(bgRect)

            // Draw QR code
            qrCode.draw(in: CGRect(origin: qrOrigin, size: qrSize))
        }
    }
}
