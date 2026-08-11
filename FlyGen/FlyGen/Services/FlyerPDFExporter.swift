import CoreGraphics
import Foundation

/// Standard print paper sizes, in PDF points (1pt = 1/72").
enum PDFPaper {
    case letter
    case a4

    var size: CGSize {
        switch self {
        case .letter: return CGSize(width: 612, height: 792)        // 8.5 x 11 in
        case .a4: return CGSize(width: 595.276, height: 841.89)     // 210 x 297 mm
        }
    }

    var aspectRatio: CGFloat { size.width / size.height }

    var displayName: String {
        switch self {
        case .letter: return "Letter"
        case .a4: return "A4"
        }
    }
}

/// Wraps a flyer image in a true-sized single-page PDF so print shops and print
/// dialogs get a document with real physical dimensions instead of a bare raster.
/// Pure CoreGraphics (no UIKit) so the logic is testable off-device.
enum FlyerPDFExporter {

    /// Relative ratio difference under which an image counts as "already paper-shaped"
    /// and is drawn full-bleed. Engine print output is padded to the exact paper ratio,
    /// so real matches land far inside this.
    private static let fullBleedTolerance: CGFloat = 0.01

    /// Regions that print on US Letter rather than A4.
    private static let letterRegions: Set<String> = ["US", "CA", "MX", "PH"]

    /// Best paper for an image: the paper whose ratio the image already matches
    /// (full-bleed case), else the locale's default paper (image centered with margins).
    static func paper(matching image: CGImage, localeRegion: String?) -> PDFPaper {
        let ratio = CGFloat(image.width) / CGFloat(image.height)
        for paper in [PDFPaper.letter, .a4] {
            if abs(ratio - paper.aspectRatio) / paper.aspectRatio <= fullBleedTolerance {
                return paper
            }
        }
        let region = localeRegion?.uppercased() ?? "US"
        return letterRegions.contains(region) ? .letter : .a4
    }

    /// Renders the image onto one page of `paper` size: full-bleed when the ratio
    /// matches the paper, otherwise centered aspect-fit on a white page.
    static func pdfData(for image: CGImage, paper: PDFPaper, title: String? = nil) -> Data? {
        let pageRect = CGRect(origin: .zero, size: paper.size)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return nil }

        var mediaBox = pageRect
        var info: [CFString: Any] = [kCGPDFContextCreator: "FlyGen"]
        if let title, !title.isEmpty {
            info[kCGPDFContextTitle] = title
        }
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox,
                                      info as CFDictionary) else { return nil }

        context.beginPDFPage(nil)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(pageRect)
        context.interpolationQuality = .high
        context.draw(image, in: drawRect(for: image, in: pageRect))
        context.endPDFPage()
        context.closePDF()

        return data as Data
    }

    /// Writes the PDF to a temporary file (named after the flyer) and returns its URL,
    /// ready for a share sheet.
    static func writeTemporaryPDF(image: CGImage, paper: PDFPaper, named name: String) -> URL? {
        guard let data = pdfData(for: image, paper: paper, title: name) else { return nil }
        let base = name.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: " ").prefix(60)
        let filename = (base.isEmpty ? "Flyer" : String(base)) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func drawRect(for image: CGImage, in pageRect: CGRect) -> CGRect {
        let imageRatio = CGFloat(image.width) / CGFloat(image.height)
        let pageRatio = pageRect.width / pageRect.height
        if abs(imageRatio - pageRatio) / pageRatio <= fullBleedTolerance {
            return pageRect
        }
        var size = pageRect.size
        if imageRatio > pageRatio {
            size.height = pageRect.width / imageRatio
        } else {
            size.width = pageRect.height * imageRatio
        }
        return CGRect(x: (pageRect.width - size.width) / 2,
                      y: (pageRect.height - size.height) / 2,
                      width: size.width, height: size.height)
    }
}
