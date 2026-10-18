import XCTest
@testable import PokeJ

final class SetArtworkCatalogTests: XCTestCase {
    func testLoadsBundledArtwork() {
        XCTAssertFalse(SetArtworkCatalog.all.isEmpty, "SetArtwork.json muss im Bundle liegen")
        XCTAssertGreaterThan(SetArtworkCatalog.all.count, 100)
    }

    func testSortedByReleaseDate() {
        let all = SetArtworkCatalog.all
        for (lhs, rhs) in zip(all, all.dropFirst()) {
            XCTAssertLessThanOrEqual(lhs.releaseDate, rhs.releaseDate, "\(lhs.id) steht vor \(rhs.id)")
        }
    }

    func testByIdRoundTrip() {
        for artwork in SetArtworkCatalog.all.prefix(10) {
            XCTAssertEqual(SetArtworkCatalog.artwork(for: artwork.id)?.id, artwork.id)
        }
        XCTAssertNil(SetArtworkCatalog.artwork(for: "gibt-es-nicht"))
    }

    func testLogoAndEnglishImageURLs() throws {
        let artwork = try XCTUnwrap(SetArtworkCatalog.all.first { $0.hasLogo })
        let logo = try XCTUnwrap(artwork.logoImageURL)
        XCTAssertEqual(logo.lastPathComponent, "logo.webp")

        let base = try XCTUnwrap(artwork.englishImageBase)
        XCTAssertFalse(base.absoluteString.hasSuffix("/logo"))

        let low = try XCTUnwrap(artwork.englishImageURL(localId: "1", highResolution: false))
        XCTAssertTrue(low.absoluteString.hasSuffix("/1/low.webp"))
        let high = try XCTUnwrap(artwork.englishImageURL(localId: "1", highResolution: true))
        XCTAssertTrue(high.absoluteString.hasSuffix("/1/high.webp"))
    }

    func testReleaseYearParses() throws {
        let artwork = try XCTUnwrap(SetArtworkCatalog.all.first)
        let year = try XCTUnwrap(artwork.releaseYear)
        XCTAssertGreaterThan(year, 1995)
        XCTAssertLessThanOrEqual(year, 2100)
    }

    func testArtworkWithoutLogoHasNoURLs() {
        let artwork = SetArtwork(id: "x", releaseDate: "2000-01-01", serieId: "base", logo: nil, enName: "X")
        XCTAssertFalse(artwork.hasLogo)
        XCTAssertNil(artwork.logoImageURL)
        XCTAssertNil(artwork.englishImageBase)
        XCTAssertNil(artwork.englishImageURL(localId: "1", highResolution: false))
    }

    // MARK: - CDN-Fallback (auch ohne Set-Logo)

    func testCardImageURLWorksWithoutLogo() throws {
        let artwork = try XCTUnwrap(SetArtworkCatalog.all.first { !$0.hasLogo })
        let low = try XCTUnwrap(artwork.cardImageURL(localId: "1", highResolution: false))
        XCTAssertEqual(
            low.absoluteString,
            "https://assets.tcgdex.net/en/\(artwork.serieId)/\(artwork.id)/1/low.webp"
        )
        let high = try XCTUnwrap(artwork.cardImageURL(localId: "1", highResolution: true))
        XCTAssertTrue(high.absoluteString.hasSuffix("/1/high.webp"))
    }

    func testCatalogCardFallsBackToEnglishCDN() throws {
        let artwork = try XCTUnwrap(SetArtworkCatalog.all.first { !$0.hasLogo })
        let card = CatalogCard(id: "\(artwork.id)-1", localId: "1", name: "Test", image: nil)
        XCTAssertEqual(card.setId, artwork.id)
        XCTAssertEqual(
            card.thumbnailURL?.absoluteString,
            "https://assets.tcgdex.net/en/\(artwork.serieId)/\(artwork.id)/1/low.webp"
        )
        XCTAssertTrue(try XCTUnwrap(card.highResURL).absoluteString.hasSuffix("/1/high.webp"))
    }

    func testCatalogCardPrefersGermanImage() {
        let card = CatalogCard(
            id: "base1-4",
            localId: "4",
            name: "Glurak",
            image: "https://assets.tcgdex.net/de/base/base1/4"
        )
        XCTAssertEqual(card.setId, "base1")
        XCTAssertEqual(card.thumbnailURL?.absoluteString, "https://assets.tcgdex.net/de/base/base1/4/low.webp")
        XCTAssertEqual(card.highResURL?.absoluteString, "https://assets.tcgdex.net/de/base/base1/4/high.webp")
    }

    func testCatalogCardUnknownSetHasNoFallback() {
        let card = CatalogCard(id: "gibt-es-nicht-1", localId: "1", name: "X", image: nil)
        XCTAssertNil(card.thumbnailURL)
        XCTAssertNil(card.highResURL)
    }

    func testDeadImageURLDetection() {
        XCTAssertTrue(Card.isDeadImageURL("https://images.tcgdex.net/de/cards/base1-4/high.webp"))
        XCTAssertFalse(Card.isDeadImageURL("https://assets.tcgdex.net/en/base/base1/4/high.webp"))
    }
}
