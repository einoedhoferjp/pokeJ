import XCTest
@testable import PokeJ

final class MockProviderTests: XCTestCase {
    func testSearchMatchesPartialName() async throws {
        let provider = MockCardDataProvider()
        let results = try await provider.searchCards(CardQuery(text: "fur", language: .en))
        XCTAssertTrue(results.contains { $0.id == "swsh3-136" })
    }

    func testSearchByExactLocalId() async throws {
        let provider = MockCardDataProvider()
        let results = try await provider.searchCards(CardQuery(text: "136", language: .en))
        XCTAssertEqual(results.first?.id, "swsh3-136")
    }

    func testCardLookupThrowsWhenMissing() async {
        let provider = MockCardDataProvider()
        do {
            _ = try await provider.card(externalId: "does-not-exist", language: .de)
            XCTFail("Erwarteter Fehler wurde nicht geworfen.")
        } catch {
            XCTAssertTrue(error is CardDataError)
        }
    }

    func testSetsAreDeduplicated() async throws {
        let provider = MockCardDataProvider()
        let sets = try await provider.sets(language: .en)
        let ids = sets.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(ids.contains("base1"))
    }
}
