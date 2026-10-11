import XCTest
@testable import PokeJ

final class PriceResolverTests: XCTestCase {
    private func point(_ metric: PriceMetric, _ amount: String, at offset: TimeInterval) -> PricePoint {
        PricePoint(
            productId: "p",
            metric: metric,
            amount: Decimal(string: amount)!,
            currency: "EUR",
            fetchedAt: Date(timeIntervalSince1970: offset),
            source: "test",
            matchQuality: .productOnly
        )
    }

    func testPreferredMetricByPrinting() {
        XCTAssertEqual(PriceResolver.preferredMetric(for: .normal), .avg)
        XCTAssertEqual(PriceResolver.preferredMetric(for: .reverse), .avg)
        XCTAssertEqual(PriceResolver.preferredMetric(for: .holo), .avgHolo)
    }

    func testLatestReturnsNewestForPreferredMetric() {
        let points = [point(.avg, "1", at: 100), point(.avg, "2", at: 200)]
        XCTAssertEqual(PriceResolver.latest(points: points, printing: .normal)?.amount, Decimal(string: "2"))
    }

    func testFallsBackToOtherFamilyWhenPreferredMissing() {
        let points = [point(.avgHolo, "5", at: 100)]
        let resolved = PriceResolver.latest(points: points, printing: .normal)
        XCTAssertEqual(resolved?.metric, .avgHolo)
        XCTAssertEqual(resolved?.amount, Decimal(string: "5"))
    }

    func testNilWhenNoPoints() {
        XCTAssertNil(PriceResolver.latest(points: [], printing: .normal))
    }

    func testLatestPerMetricKeepsNewestPerMetric() {
        let points = [point(.avg, "1", at: 100), point(.avg, "2", at: 200), point(.low, "0.5", at: 100)]
        let map = PriceResolver.latestPerMetric(points: points)
        XCTAssertEqual(map[.avg]?.amount, Decimal(string: "2"))
        XCTAssertEqual(map[.low]?.amount, Decimal(string: "0.5"))
        XCTAssertEqual(map.count, 2)
    }
}
