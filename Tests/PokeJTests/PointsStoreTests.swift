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
        XCTAssertTrue(store.canAfford(PackDefinition.standard))
        XCTAssertTrue(store.purchase(PackDefinition.standard))
        XCTAssertEqual(store.balance, PointsStore.startingBalance - PackDefinition.standard.cost)
    }

    func testCannotPurchaseIfTooExpensive() {
        let defaults = UserDefaults(suiteName: "test.poor")!
        defaults.removePersistentDomain(forName: "test.poor")
        let store = PointsStore(defaults: defaults)
        let expensive = PackDefinition(id: "x", name: "X", cost: 10_000, cardCount: 1, holoGuarantee: 0, iconName: "x")
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
}