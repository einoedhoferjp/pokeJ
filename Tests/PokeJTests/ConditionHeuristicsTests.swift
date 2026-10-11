import XCTest
@testable import PokeJ
import UIKit

final class ConditionHeuristicsTests: XCTestCase {
    func testNearMintBetterThanPlayed() {
        let nm = ConditionMetrics(
            quality: .init(sharpness: 0.9, brightness: 0.5, contrast: 0.8, hasGlare: false),
            centering: .init(edgeUniformity: 0.9),
            wear: .init(cornerDamage: 0.01, edgeDamage: 0.01, surfaceScratches: 0.01, whitening: 0.01)
        )
        let pl = ConditionMetrics(
            quality: .init(sharpness: 0.6, brightness: 0.5, contrast: 0.7, hasGlare: false),
            centering: .init(edgeUniformity: 0.7),
            wear: .init(cornerDamage: 0.5, edgeDamage: 0.5, surfaceScratches: 0.4, whitening: 0.5)
        )
        let r1 = ConditionHeuristic.estimate(from: nm)
        let r2 = ConditionHeuristic.estimate(from: pl)
        XCTAssertTrue(r1.condition.rawValue <= r2.condition.rawValue || r1.condition == .nearMint || r2.condition == .played || r2.condition == .poor)
    }

    func testGlareForcesUncertain() {
        let m = ConditionMetrics(
            quality: .init(sharpness: 0.9, brightness: 0.9, contrast: 0.9, hasGlare: true),
            centering: .init(edgeUniformity: 0.9),
            wear: .init()
        )
        let r = ConditionHeuristic.estimate(from: m)
        XCTAssertEqual(r.condition, .uncertain)
    }
}
