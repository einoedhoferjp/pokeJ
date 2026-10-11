import XCTest
@testable import PokeJ

final class TCGdexPriceProviderTests: XCTestCase {
    private static let json = """
    {"id":"swsh3-136","pricing":{"cardmarket":{"updated":"2026-10-11T09:52:39.684Z","unit":"EUR","idProduct":483559,"avg":0.07,"low":0.02,"trend":0.06,"avg1":0.08,"avg7":0.05,"avg30":0.07,"avg-holo":0.28,"low-holo":0.08,"trend-holo":0.24,"avg1-holo":0.25,"avg7-holo":0.25,"avg30-holo":0.27},"tcgplayer":{"unit":"USD"}}}
    """

    private func makeProvider() -> TCGdexPriceProvider {
        TCGdexPriceProvider(client: StubHTTPClient { _ in (200, Data(Self.json.utf8)) })
    }

    func testNonFoilMetricsMapped() async throws {
        let dtos = try await makeProvider().prices(externalCardId: "swsh3-136", printing: .normal, language: .en)
        let byMetric = Dictionary(uniqueKeysWithValues: dtos.map { ($0.metric, $0) })
        XCTAssertEqual(byMetric[.avg]?.amount, Decimal(string: "0.07"))
        XCTAssertEqual(byMetric[.low]?.amount, Decimal(string: "0.02"))
        XCTAssertEqual(byMetric[.trend]?.amount, Decimal(string: "0.06"))
        XCTAssertEqual(byMetric[.avg30]?.amount, Decimal(string: "0.07"))
        XCTAssertNil(byMetric[.avgHolo])
        XCTAssertEqual(dtos.first?.currency, "EUR")
        XCTAssertEqual(dtos.first?.productId, "483559")
        XCTAssertEqual(dtos.first?.matchQuality, .productOnly)
        XCTAssertNotNil(dtos.first?.fetchedAt)
    }

    func testHoloMetricsMappedForFoilPrinting() async throws {
        let dtos = try await makeProvider().prices(externalCardId: "swsh3-136", printing: .holo, language: .en)
        let byMetric = Dictionary(uniqueKeysWithValues: dtos.map { ($0.metric, $0) })
        XCTAssertEqual(byMetric[.avgHolo]?.amount, Decimal(string: "0.28"))
        XCTAssertEqual(byMetric[.trendHolo]?.amount, Decimal(string: "0.24"))
        XCTAssertNil(byMetric[.avg])
    }

    func testMissingPricingReturnsEmpty() async throws {
        let provider = TCGdexPriceProvider(client: StubHTTPClient { _ in (200, Data(#"{"id":"x"}"#.utf8)) })
        let dtos = try await provider.prices(externalCardId: "x", printing: .normal, language: .en)
        XCTAssertTrue(dtos.isEmpty)
    }

    func testDecimalParsesWithoutBinaryArtifacts() {
        XCTAssertEqual(TCGdexPriceProvider.decimal(from: 0.07), Decimal(string: "0.07"))
        XCTAssertEqual(TCGdexPriceProvider.decimal(from: 1.1), Decimal(string: "1.1"))
        XCTAssertEqual(TCGdexPriceProvider.decimal(from: 25), Decimal(string: "25"))
    }
}
