import CoreGraphics
import UIKit
import XCTest
@testable import PokeJ

final class CardImagePreprocessorTests: XCTestCase {
    func testPixelPointMapsNormalizedToExtent() {
        let extent = CGRect(x: 0, y: 0, width: 100, height: 200)
        XCTAssertEqual(CardImagePreprocessor.pixelPoint(normalized: CGPoint(x: 0.5, y: 0.5), in: extent), CGPoint(x: 50, y: 100))
        XCTAssertEqual(CardImagePreprocessor.pixelPoint(normalized: CGPoint(x: 0, y: 0), in: extent), CGPoint(x: 0, y: 0))
        XCTAssertEqual(CardImagePreprocessor.pixelPoint(normalized: CGPoint(x: 1, y: 1), in: extent), CGPoint(x: 100, y: 200))
    }

    func testPixelPointRespectsExtentOrigin() {
        let extent = CGRect(x: 10, y: 20, width: 100, height: 40)
        XCTAssertEqual(CardImagePreprocessor.pixelPoint(normalized: CGPoint(x: 0.5, y: 0.25), in: extent), CGPoint(x: 60, y: 30))
    }

    func testNormalizedCGImageReturnsImage() {
        let context = CGContext(
            data: nil,
            width: 4,
            height: 4,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        let cgImage = context!.makeImage()!
        let image = UIImage(cgImage: cgImage)
        XCTAssertNotNil(CardImagePreprocessor.normalizedCGImage(from: image))
    }
}
