import Foundation
@testable import PokeJ
import XCTest

@MainActor
final class PointsStoreTests: XCTestCase {
    func testInitialBalance() {
        let store = PointsStore(defaults: UserDefaults(suiteName: "test.initial")!)
        XCTAssertEqual(store.balance, PointsStore.startingBalance)
    }

    func testScanReward() {
        let defaults = UserDefaults(suiteName: "test.reward")!
        defaults.removePersistentDomain(forName: "test.reward")
        let store = PointsStore(defaults: defaults)
        let before = store.balance
        store.awardScanReward()
        XCTAssertEqual(store.balance, before + PointsStore.scanRewardPerCard)
    }

    func testPurchase() {
        let defaults = UserDefaults(suiteName: "test.purchase")!
        defaults.removePersistentDomain(forName: "test.purchase")
        let store = PointsStore(defaults: defaults)
        while !store.canAfford(PackDefinition.standard) {
            store.awardScanReward()
        }
        let before = store.balance
        XCTAssertTrue(store.canAfford(PackDefinition.standard))
        XCTAssertTrue(store.purchase(PackDefinition.standard))
        XCTAssertEqual(store.balance, before - PackDefinition.standard.cost)
    }

    func testCannotPurchaseIfTooExpensive() {
        let defaults = UserDefaults(suiteName: "test.poor")!
        defaults.removePersistentDomain(forName: "test.poor")
        let store = PointsStore(defaults: defaults)
        let expensive = PackDefinition(id: "x", name: "X", cost: PointsStore.startingBalance + 1, cardCount: 1, holoGuarantee: 0, iconName: "x")
        XCTAssertFalse(store.canAfford(expensive))
        XCTAssertFalse(store.purchase(expensive))
    }

    func testDailyBonusOncePerDay() {
        let defaults = UserDefaults(suiteName: "test.daily")!
        defaults.removePersistentDomain(forName: "test.daily")
        let store = PointsStore(defaults: defaults)
        XCTAssertTrue(store.canClaimDailyBonus)
        let before = store.balance
        XCTAssertTrue(store.claimDailyBonus())
        XCTAssertEqual(store.balance, before + PointsStore.dailyBonus)
        XCTAssertFalse(store.canClaimDailyBonus)
        XCTAssertFalse(store.claimDailyBonus())
    }

    func testPointsAreIsolatedPerAccount() {
        let suite = "test.points.perAccount"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let alice = PointsStore(defaults: defaults, username: "alice")
        alice.awardScanReward()
        XCTAssertEqual(alice.balance, PointsStore.startingBalance + PointsStore.scanRewardPerCard)

        let bob = PointsStore(defaults: defaults, username: "bob")
        XCTAssertEqual(bob.balance, PointsStore.startingBalance)
    }

    func testConfigureSwitchesAccounts() {
        let suite = "test.points.configure"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = PointsStore(defaults: defaults, username: "alice")
        store.awardScanReward()
        let aliceBalance = store.balance

        store.configure(for: "bob")
        XCTAssertEqual(store.balance, PointsStore.startingBalance)

        store.configure(for: "alice")
        XCTAssertEqual(store.balance, aliceBalance)
    }
}