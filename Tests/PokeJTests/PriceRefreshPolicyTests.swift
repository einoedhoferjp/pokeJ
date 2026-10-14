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

    func testLogIsIsolatedPerAccount() {
        let suite = "test.pricelog.perAccount"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let alice = PriceRefreshLog(defaults: defaults, username: "alice")
        let bob = PriceRefreshLog(defaults: defaults, username: "bob")
        let stamp = Date()
        alice.markRefreshed(at: stamp)

        XCTAssertEqual(alice.lastFullRefresh, stamp)
        XCTAssertNil(bob.lastFullRefresh)
        XCTAssertTrue(bob.isRefreshDue(now: stamp))
    }
}
