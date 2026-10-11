import XCTest
@testable import PokeJ
import UIKit

final class ConditionAssessorTests: XCTestCase {
    func testAssessorProducesResultFromImage() {
        let url = Bundle(for: Self.self).url(forResource: "card_nm", withExtension: "png")
        let img = url.flatMap { UIImage(contentsOfFile: $0.path) }
        let cg = img?.cgImage
        XCTAssertNotNil(cg, "Fixture card_nm.png konnte nicht geladen werden.")
        let r = ConditionAssessor().assess(image: cg!)
        XCTAssertGreaterThanOrEqual(r.confidence, 0)
    }
}

