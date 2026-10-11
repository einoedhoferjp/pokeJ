import CoreGraphics
import CoreImage
import ImageIO
import UIKit
import Vision

/// Bereitet Kamerabilder für die OCR auf: Drehung normalisieren und die
/// Kartenfläche per Perspektivkorrektur begradigen.
enum CardImagePreprocessor {
    /// Rendert ein UIImage aufrecht in ein CGImage (ohne EXIF-Drehung).
    static func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return normalized.cgImage
    }

    /// Begradigt die größte erkannte Kartenfläche. Ohne Fund bleibt das Bild
    /// unverändert.
    static func rectify(_ image: CIImage, orientation: CGImagePropertyOrientation = .up) -> CIImage {
        guard let rectangle = detectRectangle(in: image, orientation: orientation),
              let corrected = applyCorrection(to: image, rectangle: rectangle) else {
            return image
        }
        return corrected
    }

    static func detectRectangle(in image: CIImage, orientation: CGImagePropertyOrientation) -> VNRectangleObservation? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 0.95
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:])
        try? handler.perform([request])
        return request.results?.first
    }

    static func applyCorrection(to image: CIImage, rectangle: VNRectangleObservation) -> CIImage? {
        let extent = image.extent
        let filter = CIFilter(name: "CIPerspectiveCorrection")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgPoint: pixelPoint(normalized: rectangle.topLeft, in: extent)), forKey: "inputTopLeft")
        filter?.setValue(CIVector(cgPoint: pixelPoint(normalized: rectangle.topRight, in: extent)), forKey: "inputTopRight")
        filter?.setValue(CIVector(cgPoint: pixelPoint(normalized: rectangle.bottomLeft, in: extent)), forKey: "inputBottomLeft")
        filter?.setValue(CIVector(cgPoint: pixelPoint(normalized: rectangle.bottomRight, in: extent)), forKey: "inputBottomRight")
        return filter?.outputImage
    }

    /// Rechnet einen normalisierten Vision-Punkt (0…1) in Bildpixel um.
    static func pixelPoint(normalized: CGPoint, in extent: CGRect) -> CGPoint {
        CGPoint(
            x: extent.minX + normalized.x * extent.width,
            y: extent.minY + normalized.y * extent.height
        )
    }

    static func cgImage(from image: CIImage, context: CIContext = CIContext()) -> CGImage? {
        context.createCGImage(image, from: image.extent)
    }
}
