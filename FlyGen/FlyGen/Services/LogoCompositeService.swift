import UIKit

/// Service for compositing logos onto generated flyer images
actor LogoCompositeService {

    /// Composite logo onto flyer image
    /// - Parameters:
    ///   - flyer: The base flyer image
    ///   - logo: The logo image to overlay
    ///   - position: The corner position for the logo
    ///   - sizePercent: Logo width as percentage of flyer width (default 20%)
    ///   - marginPercent: Margin from edge as percentage of flyer width (default 3%)
    /// - Returns: The composited image, or nil if compositing fails
    func compositeLogo(
        onto flyer: UIImage,
        logo: UIImage,
        position: LogoPosition,
        sizePercent: CGFloat = 0.20,
        marginPercent: CGFloat = 0.03
    ) -> UIImage? {
        let flyerSize = flyer.size
        let margin = flyerSize.width * marginPercent

        // Calculate logo size maintaining aspect ratio
        let maxLogoWidth = flyerSize.width * sizePercent
        let logoAspect = logo.size.width / logo.size.height
        let logoSize: CGSize

        if logoAspect >= 1 {
            // Wider than tall - constrain by width
            logoSize = CGSize(
                width: maxLogoWidth,
                height: maxLogoWidth / logoAspect
            )
        } else {
            // Taller than wide - constrain by height
            let maxLogoHeight = maxLogoWidth
            logoSize = CGSize(
                width: maxLogoHeight * logoAspect,
                height: maxLogoHeight
            )
        }

        // Calculate logo position
        let logoOrigin: CGPoint
        switch position {
        case .bottomRight:
            logoOrigin = CGPoint(
                x: flyerSize.width - logoSize.width - margin,
                y: flyerSize.height - logoSize.height - margin
            )
        case .bottomLeft:
            logoOrigin = CGPoint(
                x: margin,
                y: flyerSize.height - logoSize.height - margin
            )
        case .topRight:
            logoOrigin = CGPoint(
                x: flyerSize.width - logoSize.width - margin,
                y: margin
            )
        case .topLeft:
            logoOrigin = CGPoint(
                x: margin,
                y: margin
            )
        }

        // Create composite image
        let renderer = UIGraphicsImageRenderer(size: flyerSize)

        return renderer.image { _ in
            // Draw flyer as base
            flyer.draw(at: .zero)

            // Draw logo (preserves transparency if PNG)
            logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        }
    }
}
