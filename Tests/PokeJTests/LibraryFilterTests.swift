import XCTest
import SwiftData
@testable import PokeJ

final class LibraryFilterTests: XCTestCase {
    private var container: ModelContainer!

    @MainActor
    private func makeItems() throws -> (ModelContext, [CollectionItem]) {
        let schema = Schema([Card.self, CardVariant.self, CollectionItem.self, PriceSnapshot.self, ScanRecord.self, ConditionAssessment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let repository = CollectionRepository(context: context)

        let charizard = CardBrief(id: "base1-4", name: "Charizard", setId: "base1", setName: "Base Set", localId: "4", rarity: "Rare Holo", imageURL: nil)
        let furret = CardBrief(id: "swsh3-136", name: "Furret", setId: "swsh3", setName: "Darkness Ablaze", localId: "136", rarity: "Uncommon", imageURL: nil)

        let charizardCard = repository.findOrCreateCard(from: charizard)
        let furretCard = repository.findOrCreateCard(from: furret)

        let mintDe = CollectionItem(confirmedCondition: .nearMint, purchasePrice: Decimal(50), createdAt: Date(timeIntervalSince1970: 100))
        repository.addCollectionItem(card: charizardCard, language: .de, printing: .holo, item: mintDe)

        let playedEn = CollectionItem(confirmedCondition: .played, purchasePrice: Decimal(5), createdAt: Date(timeIntervalSince1970: 200))
        repository.addCollectionItem(card: charizardCard, language: .en, printing: .holo, item: playedEn)

        let furretJa = CollectionItem(confirmedCondition: .excellent, purchasePrice: Decimal(1), createdAt: Date(timeIntervalSince1970: 300))
        repository.addCollectionItem(card: furretCard, language: .ja, printing: .normal, item: furretJa)

        try context.save()
        let items = try context.fetch(FetchDescriptor<CollectionItem>())
        return (context, items)
    }

    @MainActor
    func testSearchByName() throws {
        let (_, items) = try makeItems()
        var filter = LibraryFilter()
        filter.searchText = "chari"
        XCTAssertEqual(filter.apply(to: items).count, 2)
    }

    @MainActor
    func testSearchByLocalId() throws {
        let (_, items) = try makeItems()
        var filter = LibraryFilter()
        filter.searchText = "136"
        let result = filter.apply(to: items)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.variant?.card?.name, "Furret")
    }

    @MainActor
    func testFilterByLanguage() throws {
        let (_, items) = try makeItems()
        var filter = LibraryFilter()
        filter.language = .en
        let result = filter.apply(to: items)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.confirmedCondition, .played)
    }

    @MainActor
    func testFilterByCondition() throws {
        let (_, items) = try makeItems()
        var filter = LibraryFilter()
        filter.condition = .nearMint
        XCTAssertEqual(filter.apply(to: items).count, 1)
    }

    @MainActor
    func testSortByNameAndPriceAndDate() throws {
        let (_, items) = try makeItems()

        var byName = LibraryFilter()
        byName.sort = .name
        XCTAssertEqual(byName.apply(to: items).first?.variant?.card?.name, "Charizard")

        var byPrice = LibraryFilter()
        byPrice.sort = .price
        XCTAssertEqual(byPrice.apply(to: items).first?.purchasePrice, Decimal(50))

        var byDate = LibraryFilter()
        byDate.sort = .dateAdded
        XCTAssertEqual(byDate.apply(to: items).first?.variant?.language, .ja)
    }
}
