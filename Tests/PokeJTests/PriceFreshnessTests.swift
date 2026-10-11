import XCTest
@testable import PokeJ

final class PriceFreshnessTests: XCTestCase {
    func testFreshWithinWindow() {
        let now = Date()
        XCTAssertFalse(PriceFreshness.isStale(fetchedAt: now.addingTimeInterval(-3600), now: now))
    }

    func testStaleBeyondWindow() {
        let now = Date()
        XCTAssertTrue(PriceFreshness.isStale(fetchedAt: now.addingTimeInterval(-37 * 3600), now: now))
    }

    func testBoundaryIsInclusive() {
        let now = Date()
        XCTAssertFalse(PriceFreshness.isStale(fetchedAt: now.addingTimeInterval(-36 * 3600), now: now))
        XCTAssertTrue(PriceFreshness.isStale(fetchedAt: now.addingTimeInterval(-36 * 3600 - 1), now: now))
    }
}
