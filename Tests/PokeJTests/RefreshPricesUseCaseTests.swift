import XCTest
@testable import PokeJ

final class RefreshPricesUseCaseTests: XCTestCase {
    private static func sample(metric: PriceMetric = .avg) -> PriceSnapshotDTO {
        PriceSnapshotDTO(
            productId: "p",
            metric: metric,
            amount: 1,
            currency: "EUR",
            fetchedAt: Date(timeIntervalSince1970: 0),
            source: "test",
            matchQuality: .productOnly
        )
    }

    func testDeduplicatesIdenticalTargets() async {
        let provider = StubPriceProvider { _, _, _ in [Self.sample()] }
        let targetA = PriceRefreshTarget(externalCardId: "a", printing: .normal, language: .en)
        let targetB = PriceRefreshTarget(externalCardId: "b", printing: .normal, language: .en)

        let results = await RefreshPricesUseCase(provider: provider).fetch(targets: [targetA, targetA, targetB])
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(Set(results.map(\.target)), [targetA, targetB])
    }

    func testFailureIsIsolatedPerTarget() async {
        let provider = StubPriceProvider { id, _, _ in
            if id == "bad" { throw CardDataError.network }
            return [Self.sample()]
        }
        let good = PriceRefreshTarget(externalCardId: "good", printing: .normal, language: .en)
        let bad = PriceRefreshTarget(externalCardId: "bad", printing: .normal, language: .en)

        let results = await RefreshPricesUseCase(provider: provider).fetch(targets: [good, bad])
        let byId = Dictionary(uniqueKeysWithValues: results.map { ($0.target.externalCardId, $0) })
        XCTAssertEqual(byId["good"]?.failed, false)
        XCTAssertEqual(byId["good"]?.snapshots.count, 1)
        XCTAssertEqual(byId["bad"]?.failed, true)
        XCTAssertEqual(byId["bad"]?.snapshots.count, 0)
    }

    func testBoundedConcurrencyFetchesAllTargetsInOrder() async {
        let provider = StubPriceProvider { _, _, _ in [Self.sample()] }
        let targets = (0..<25).map {
            PriceRefreshTarget(externalCardId: "card-\($0)", printing: .normal, language: .en)
        }

        let results = await RefreshPricesUseCase(provider: provider, maxConcurrent: 4).fetch(targets: targets)

        XCTAssertEqual(results.count, 25)
        XCTAssertEqual(results.map(\.target), targets, "Reihenfolge bleibt stabil")
        XCTAssertTrue(results.allSatisfy { !$0.failed })
    }
}
