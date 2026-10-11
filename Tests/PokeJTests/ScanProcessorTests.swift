import CoreGraphics
import ImageIO
import XCTest
@testable import PokeJ

private struct StubRecognizer: TextRecognizing {
    let lines: [String]

    func recognizeText(in image: CGImage, orientation: CGImagePropertyOrientation) async throws -> [String] {
        lines
    }
}

final class ScanProcessorTests: XCTestCase {
    private func makeImage() -> CGImage {
        let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        return context!.makeImage()!
    }

    func testProcessesOCRIntoRecognizedOutcome() async throws {
        let processor = ScanProcessor(
            provider: MockCardDataProvider(),
            recognizer: StubRecognizer(lines: ["Furret", "HP 110", "136/189"]),
            language: .en
        )
        let result = try await processor.process(image: makeImage())
        XCTAssertEqual(result.fields.number, "136")
        XCTAssertEqual(result.fields.hp, 110)
        XCTAssertEqual(result.outcome.status, .recognized)
        XCTAssertEqual(result.outcome.matches.first?.brief.id, "swsh3-136")
    }

    func testProcessesEmptyOCRIntoNoMatch() async throws {
        let processor = ScanProcessor(
            provider: MockCardDataProvider(),
            recognizer: StubRecognizer(lines: []),
            language: .en
        )
        let result = try await processor.process(image: makeImage())
        XCTAssertTrue(result.fields.isEmpty)
        XCTAssertEqual(result.outcome.status, .noMatch)
    }
}
