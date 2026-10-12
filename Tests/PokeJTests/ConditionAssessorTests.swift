import XCTest
@testable import PokeJ
import UIKit

final class ConditionAssessorTests: XCTestCase {
    /// Erzeugt ein synthetisches Testbild (einfarbig hell) direkt im Speicher.
    /// Kein externes Fixture und kein Datei-Bundling nötig – dadurch ist der
    /// Test in jedem CI-Setup robust.
    @MainActor
    private func syntheticImage() -> CGImage? {
        let size = CGSize(width: 120, height: 168)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }

    @MainActor
    func testAssessorProducesResultFromImage() throws {
        let cg = try XCTUnwrap(syntheticImage(), "Synthetisches Testbild konnte nicht erzeugt werden.")
        let r = ConditionAssessor().assess(image: cg)
        XCTAssertGreaterThanOrEqual(r.confidence, 0)
    }
}