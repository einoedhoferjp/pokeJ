import XCTest
@testable import PokeJ

private final class URLCapture: @unchecked Sendable {
    var url: URL?
}

final class TCGdexProviderTests: XCTestCase {
    private static let searchJSON = """
    [
      {"id":"swsh3-136","localId":"136","name":"Furret","image":"https://assets.tcgdex.net/en/swsh/swsh3/136"},
      {"id":"base1-4","localId":"4","name":"Charizard","image":"https://assets.tcgdex.net/en/base/base1/4"}
    ]
    """

    private static let setsJSON = """
    [
      {"id":"swsh3","name":"Darkness Ablaze","logo":"https://assets.tcgdex.net/en/swsh/swsh3/logo"},
      {"id":"base1","name":"Base Set"}
    ]
    """

    private static let cardJSON = """
    {
      "id":"swsh3-136","localId":"136","name":"Furret",
      "image":"https://assets.tcgdex.net/en/swsh/swsh3/136",
      "rarity":"Uncommon","illustrator":"tetsuya koizumi","hp":110,
      "updated":"2026-07-01T21:27:44+01:00",
      "set":{"id":"swsh3","name":"Darkness Ablaze"},
      "variants":{"firstEdition":false,"holo":false,"normal":true,"reverse":true,"wPromo":false}
    }
    """

    private func makeClient() -> StubHTTPClient {
        StubHTTPClient { url in
            if url.path.hasSuffix("/en/cards") { return (200, Data(Self.searchJSON.utf8)) }
            if url.path.hasSuffix("/en/sets") { return (200, Data(Self.setsJSON.utf8)) }
            if url.path.contains("/en/cards/swsh3-136") { return (200, Data(Self.cardJSON.utf8)) }
            return (404, Data())
        }
    }

    func testSearchIncludesLocalIdFilter() async throws {
        let capture = URLCapture()
        let client = StubHTTPClient { url in
            capture.url = url
            return (200, Data(Self.searchJSON.utf8))
        }
        let provider = TCGdexProvider(client: client)
        _ = try await provider.searchCards(CardQuery(text: "furret", localId: "136", language: .en))

        let url = try XCTUnwrap(capture.url)
        let query = try XCTUnwrap(url.query)
        XCTAssertTrue(query.contains("name=furret"))
        XCTAssertTrue(query.contains("localId=136"))
    }

    func testSearchByIdOnlyDoesNotRequireName() async throws {
        let capture = URLCapture()
        let client = StubHTTPClient { url in
            capture.url = url
            return (200, Data(Self.searchJSON.utf8))
        }
        let provider = TCGdexProvider(client: client)
        _ = try await provider.searchCards(CardQuery(text: "", localId: "136", language: .en))

        let url = try XCTUnwrap(capture.url)
        let query = try XCTUnwrap(url.query)
        XCTAssertFalse(query.contains("name="))
        XCTAssertTrue(query.contains("localId=136"))
    }

    func testSearchMapsBriefWithSetName() async throws {
        let provider = TCGdexProvider(client: makeClient())
        let results = try await provider.searchCards(CardQuery(text: "furret", language: .en))
        let furret = try XCTUnwrap(results.first { $0.id == "swsh3-136" })
        XCTAssertEqual(furret.setId, "swsh3")
        XCTAssertEqual(furret.setName, "Darkness Ablaze")
        XCTAssertEqual(furret.localId, "136")
        XCTAssertEqual(furret.imageURL?.absoluteString, "https://assets.tcgdex.net/en/swsh/swsh3/136/high.webp")
    }

    func testSearchEmptyQueryReturnsEmptyWithoutRequest() async throws {
        let client = StubHTTPClient { _ in
            XCTFail("Für eine leere Suche darf keine Anfrage gesendet werden.")
            return (500, Data())
        }
        let provider = TCGdexProvider(client: client)
        let results = try await provider.searchCards(CardQuery(text: "   ", language: .en))
        XCTAssertTrue(results.isEmpty)
    }

    func testCardMapsPrintingsImageAndDate() async throws {
        let provider = TCGdexProvider(client: makeClient())
        let card = try await provider.card(externalId: "swsh3-136", language: .en)
        XCTAssertEqual(card.name, "Furret")
        XCTAssertEqual(card.setName, "Darkness Ablaze")
        XCTAssertTrue(card.availablePrintings.contains(.normal))
        XCTAssertTrue(card.availablePrintings.contains(.reverse))
        XCTAssertFalse(card.availablePrintings.contains(.holo))
        XCTAssertEqual(card.imageURL?.absoluteString, "https://assets.tcgdex.net/en/swsh/swsh3/136/high.webp")
        XCTAssertNotNil(card.updatedAt)
    }

    func testCardNotFoundThrowsTypedError() async {
        let provider = TCGdexProvider(client: StubHTTPClient { _ in (404, Data()) })
        do {
            _ = try await provider.card(externalId: "does-not-exist", language: .en)
            XCTFail("Erwarteter Fehler wurde nicht geworfen.")
        } catch {
            XCTAssertTrue(error is CardDataError)
        }
    }

    func testSetsAreMappedAndSorted() async throws {
        let provider = TCGdexProvider(client: makeClient())
        let sets = try await provider.sets(language: .en)
        XCTAssertEqual(sets.map(\.id), ["base1", "swsh3"])
        XCTAssertEqual(sets.first?.name, "Base Set")
    }

    func testSetIdDerivation() {
        XCTAssertEqual(TCGdexProvider.setId(from: "swsh3-136", localId: "136"), "swsh3")
        XCTAssertEqual(TCGdexProvider.setId(from: "sv03.5-183", localId: "183"), "sv03.5")
        XCTAssertEqual(TCGdexProvider.setId(from: "base1-4", localId: "4"), "base1")
    }

    func testImageURLDoesNotDoubleAppend() {
        XCTAssertNil(TCGdexProvider.imageURL(from: nil))
        XCTAssertNil(TCGdexProvider.imageURL(from: ""))
        XCTAssertEqual(
            TCGdexProvider.imageURL(from: "https://assets.tcgdex.net/en/base/base1/4")?.absoluteString,
            "https://assets.tcgdex.net/en/base/base1/4/high.webp"
        )
    }

    func testPrintingsFallBackToNormal() {
        XCTAssertEqual(TCGdexProvider.printings(from: nil), [.normal])
        let none = TCGdexVariants(firstEdition: false, holo: false, normal: false, reverse: false, wPromo: false)
        XCTAssertEqual(TCGdexProvider.printings(from: none), [.normal])
    }
}
