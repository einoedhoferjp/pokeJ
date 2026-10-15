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

    /// Verbessert die OCR-Trefferquote: skaliert kleine Aufnahmen hoch, hebt den
    /// Kontrast leicht an und schärft Kanten. Die Parameter werden adaptiv an die
    /// Bildhelligkeit angepasst, damit sowohl dunkle als auch überbelichtete
    /// Aufnahmen gut erkannt werden.
    static func enhancedForOCR(_ image: CIImage, minimumWidth: CGFloat = 1400) -> CIImage {
        var result = image

        let width = image.extent.width
        if width > 0, width < minimumWidth {
            let scale = minimumWidth / width
            let filter = CIFilter(name: "CILanczosScaleTransform")
            filter?.setValue(image, forKey: kCIInputImageKey)
            filter?.setValue(scale, forKey: kCIInputScaleKey)
            filter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
            if let output = filter?.outputImage { result = output }
        }

        // Durchschnittliche Helligkeit ermitteln (0 = dunkel, 1 = hell)
        let brightness = averageBrightness(of: result)

        // Adaptive Kontrast- und Helligkeitswerte je nach Lichtverhältnissen
        let contrast: CGFloat
        let brightnessAdjust: CGFloat
        if brightness < 0.30 {
            // Dunkles Bild: stärker aufhellen, mehr Kontrast
            contrast = 1.35
            brightnessAdjust = 0.10
        } else if brightness > 0.75 {
            // Überbelichtetes Bild: Kontrast reduzieren, leicht abdunkeln
            contrast = 1.15
            brightnessAdjust = -0.05
        } else {
            // Normale Lichtverhältnisse
            contrast = 1.20
            brightnessAdjust = 0.02
        }

        let controls = CIFilter(name: "CIColorControls")
        controls?.setValue(result, forKey: kCIInputImageKey)
        controls?.setValue(contrast, forKey: kCIInputContrastKey)
        controls?.setValue(brightnessAdjust, forKey: kCIInputBrightnessKey)
        if let output = controls?.outputImage { result = output }

        let sharpen = CIFilter(name: "CIUnsharpMask")
        sharpen?.setValue(result, forKey: kCIInputImageKey)
        sharpen?.setValue(1.5, forKey: kCIInputRadiusKey)
        sharpen?.setValue(0.55, forKey: kCIInputIntensityKey)
        if let output = sharpen?.outputImage { result = output }

        return result
    }

    /// Berechnet die durchschnittliche Helligkeit eines CIImage (0…1).
    ///
    /// Nutzt eine kleinformatige Downsample-Version des Bildes für schnelle
    /// Auswertung, damit der Scan-Flow nicht verzögert wird.
    private static func averageBrightness(of image: CIImage) -> CGFloat {
        let small = image.transformed(by: CGAffineTransform(scaleX: 0.05, y: 0.05))
        guard let cg = cgImage(from: small, context: CIContext(options: [.useSoftwareRenderer: true])) else {
            return 0.5
        }

        let width = cg.width
        let height = cg.height
        guard width > 0, height > 0,
              let data = cg.dataProvider?.data as Data? else { return 0.5 }

        let bytesPerRow = cg.bytesPerRow
        let bitsPerPixel = cg.bitsPerPixel
        let bytesPerPixel = bitsPerPixel / 8
        var totalBrightness: CGFloat = 0
        var sampleCount = 0

        data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in stride(from: 0, to: height, by: 4) {
                for x in stride(from: 0, to: width, by: 4) {
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    guard offset + 2 < buffer.count else { continue }
                    let r = CGFloat(ptr[offset]) / 255.0
                    let g = CGFloat(ptr[offset + 1]) / 255.0
                    let b = CGFloat(ptr[offset + 2]) / 255.0
                    totalBrightness += (r + g + b) / 3.0
                    sampleCount += 1
                }
            }
        }

        guard sampleCount > 0 else { return 0.5 }
        return totalBrightness / CGFloat(sampleCount)
    }
}
