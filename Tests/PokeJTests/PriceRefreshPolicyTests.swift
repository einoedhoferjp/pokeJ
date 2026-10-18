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

    // MARK: - Wiederholung fehlgeschlagener Karten

    func testFailedRefreshIsRetriedEarlierThanNextDay() {
        let now = Date()
        let tenMinutesAgo = now.addingTimeInterval(-10 * 60)

        // Kurz nach einem fehlerhaften Lauf: noch nicht erneut fällig.
        XCTAssertFalse(PriceRefreshPolicy.isRefreshDue(
            lastRefresh: tenMinutesAgo,
            lastAttempt: tenMinutesAgo,
            failedTargets: 2,
            now: now
        ))

        // Nach der Wiederholungsfrist: fällig.
        XCTAssertTrue(PriceRefreshPolicy.isRefreshDue(
            lastRefresh: tenMinutesAgo,
            lastAttempt: tenMinutesAgo,
            failedTargets: 2,
            now: tenMinutesAgo.addingTimeInterval(PriceRefreshPolicy.retryInterval)
        ))

        // Fehlerfreier Lauf: keine frühe Wiederholung.
        XCTAssertFalse(PriceRefreshPolicy.isRefreshDue(
            lastRefresh: tenMinutesAgo,
            lastAttempt: tenMinutesAgo,
            failedTargets: 0,
            now: now
        ))
    }

    func testRecordAttemptKeepsRefreshDueOnFailure() {
        let suite = "test.pricelog.retry"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let log = PriceRefreshLog(defaults: defaults)
        let stamp = Date()

        log.recordAttempt(failed: 3, at: stamp)
        XCTAssertNil(log.lastFullRefresh, "Fehlerhafter Lauf zählt nicht als Tagesaktualisierung")
        XCTAssertEqual(log.failedTargets, 3)
        XCTAssertEqual(log.nextAutomaticRefresh, stamp.addingTimeInterval(PriceRefreshPolicy.retryInterval))
        XCTAssertFalse(log.isRefreshDue(now: stamp.addingTimeInterval(60)))
        XCTAssertTrue(log.isRefreshDue(now: stamp.addingTimeInterval(PriceRefreshPolicy.retryInterval + 1)))

        log.recordAttempt(failed: 0, at: stamp)
        XCTAssertEqual(log.lastFullRefresh, stamp)
        XCTAssertEqual(log.failedTargets, 0)
        XCTAssertEqual(log.nextAutomaticRefresh, stamp.addingTimeInterval(PriceRefreshPolicy.interval))
        XCTAssertFalse(log.isRefreshDue(now: stamp.addingTimeInterval(23 * 60 * 60)))
        XCTAssertTrue(log.isRefreshDue(now: stamp.addingTimeInterval(25 * 60 * 60)))
    }
}
