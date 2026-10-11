import CoreGraphics
import ImageIO
import UIKit

/// Texterkennung auf einem Bild. Abstrahiert, damit die Scan-Logik ohne
/// echte Vision-Ausführung getestet werden kann.
protocol TextRecognizing: Sendable {
    /// Liefert die erkannten Textzeilen, grob von oben nach unten sortiert.
    func recognizeText(in image: CGImage, orientation: CGImagePropertyOrientation) async throws -> [String]
}

extension CGImagePropertyOrientation {
    /// Bildet die UIImage-Orientierung auf die Vision/ImageIO-Orientierung ab.
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}
