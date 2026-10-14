import XCTest
@testable import PokeJ

final class PackCatalogTests: XCTestCase {
    func testCatalogPacksAreSetBound() {
        let packs = PackDefinition.catalogPacks
        XCTAssertFalse(packs.isEmpty, "Katalog-Booster müssen aus dem Bundle geladen werden")
        for pack in packs {
            XCTAssertNotNil(pack.setId, "\(pack.name) ohne Set")
            XCTAssertNotNil(pack.setName)
            XCTAssertNotNil(pack.serieId)
            XCTAssertNotNil(pack.eraName)
            XCTAssertTrue(pack.isSetPack)
        }
    }

    func testCatalogPackIdsAreUnique() {
        let ids = PackDefinition.catalogPacks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testCatalogPacksMatchLoadedSets() {
        let catalogSetIds = Set(PokemonCatalog.sets.map(\.id))
        for pack in PackDefinition.catalogPacks {
            XCTAssertTrue(catalogSetIds.contains(pack.setId ?? ""), "\(pack.id) hat kein Katalog-Set")
        }
    }

    func testCostsIncreaseWithReleaseYear() {
        let packs = PackDefinition.catalogPacks
        let oldest = packs.min { ($0.releaseYear ?? 0) < ($1.releaseYear ?? 0) }
        let newest = packs.max { ($0.releaseYear ?? 0) < ($1.releaseYear ?? 0) }
        XCTAssertNotNil(oldest)
        XCTAssertNotNil(newest)
        XCTAssertLessThanOrEqual(oldest!.cost, newest!.cost)
        XCTAssertGreaterThanOrEqual(oldest!.cost, 100)
    }

    func testEraCostBands() {
        XCTAssertEqual(PackEras.cost(releaseYear: 1999), 100)
        XCTAssertEqual(PackEras.cost(releaseYear: 2005), 150)
        XCTAssertEqual(PackEras.cost(releaseYear: 2015), 260)
        XCTAssertEqual(PackEras.cost(releaseYear: 2023), 500)
    }

    func testEraNames() {
        XCTAssertEqual(PackEras.era(for: "base").name, "Klassik (Base & Co.)")
        XCTAssertEqual(PackEras.era(for: "swsh").name, "Schwert & Schild")
        XCTAssertEqual(PackEras.era(for: "unbekannt"), PackEras.fallback)
    }

    func testGroupsSortedByEraThenRelease() {
        for group in PackDefinition.catalogPacksByEra {
            for (lhs, rhs) in zip(group.packs, group.packs.dropFirst()) {
                XCTAssertLessThanOrEqual(lhs.releaseYear ?? 0, rhs.releaseYear ?? 0)
            }
        }
        let orders = PackDefinition.catalogPacksByEra.map(\.era.order)
        XCTAssertEqual(orders, orders.sorted())
        XCTAssertFalse(orders.isEmpty)
    }

    func testStandardPacksUnaffected() {
        XCTAssertEqual(PackDefinition.all, [.standard, .holo, .premium])
        XCTAssertFalse(PackDefinition.standard.isSetPack)
        XCTAssertEqual(PackDefinition.standard.contentsText, "5 Karten")
        XCTAssertEqual(PackDefinition.holo.contentsText, "5 Karten · min. 1 Holo")
    }

    func testOpeningSetPackOnlyDrawsFromItsSet() throws {
        let pack = try XCTUnwrap(PackDefinition.catalogPacks.first)
        let pulls = PackOpener.open(pack)
        XCTAssertEqual(pulls.count, pack.cardCount)
        for pull in pulls {
            XCTAssertEqual(pull.set.id, pack.setId ?? "")
        }
    }
}
