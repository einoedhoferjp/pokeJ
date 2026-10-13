import XCTest
@testable import PokeJ

final class PriceRefreshPolicyTests: XCTestCase {
    func testNeverRefreshedIsDue() {
        XCTAssertTrue(PriceRefreshPolicy.isRefreshDue(lastRefresh: nil))
    }

    func testFreshRefreshIsNotDue() {
        let now = Date()
        let twentyThreeHoursAgo = now.addingTimeInterval(-23 * 60 * 60)
        XCTAssertFalse(PriceRefreshPolicy.isRefreshDue(lastRefresh: twentyThreeHoursAgo, now: now))
    }

    func testStaleRefreshIsDue() {
        let now = Date()
        let twentyFiveHoursAgo = now.addingTimeInterval(-25 * 60 * 60)
        XCTAssertTrue(PriceRefreshPolicy.isRefreshDue(lastRefresh: twentyFiveHoursAgo, now: now))
    }

    func testExactlyAtIntervalIsDue() {
        let now = Date()
        let exactlyADayAgo = now.addingTimeInterval(-PriceRefreshPolicy.interval)
        XCTAssertTrue(PriceRefreshPolicy.isRefreshDue(lastRefresh: exactlyADayAgo, now: now))
    }

    func testLogPersistsPerDefaultsSuite() {
        let defaults = UserDefaults(suiteName: "test.pricelog")!
        defaults.removePersistentDomain(forName: "test.pricelog")
        let log = PriceRefreshLog(defaults: defaults)
        XCTAssertNil(log.lastFullRefresh)
        XCTAssertTrue(log.isRefreshDue())

        let stamp = Date()
        log.markRefreshed(at: stamp)
        XCTAssertEqual(PriceRefreshLog(defaults: defaults).lastFullRefresh, stamp)
        XCTAssertFalse(PriceRefreshLog(defaults: defaults).isRefreshDue(now: stamp.addingTimeInterval(60)))
    }
}
