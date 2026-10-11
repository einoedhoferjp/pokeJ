import XCTest
@testable import PokeJ
import UIKit

final class ConditionAssessorTests: XCTestCase {
    func testAssessorProducesResultFromImage() {
        let img = UIImage(contentsOfFile: Bundle.module.path(forResource: "card_nm", ofType: "png") ?? "")
        let cg = img?.cgImage ?? UIImage(systemName: "photo")?.cgImage
        let r = ConditionAssessor().assess(image: cg!)
        XCTAssertNotNil(r)
        XCTAssertGreaterThanOrEqual(r.confidence, 0)
    }
}
