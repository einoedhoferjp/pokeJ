import XCTest
import SwiftData
@testable import PokeJ

final class CollectionRepositoryTests: XCTestCase {
    private var container: ModelContainer!

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            Card.self,
            CardVariant.self,
            CollectionItem.self,
            PriceSnapshot.self,
            ScanRecord.self,
            ConditionAssessment.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }

    private func brief(id: String = "swsh3-136") -> CardBrief {
        CardBrief(
            id: id,
            name: "Furret",
            setId: "swsh3",
            setName: "Darkness Ablaze",
            localId: "136",
            rarity: "Rare",
            imageURL: nil
        )
    }

    @MainActor
    func testAddCollectionItemPersistsAndIsFetchable() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)

        let card = repository.findOrCreateCard(from: brief())
        let item = CollectionItem(quantity: 1, confirmedCondition: .nearMint)
        repository.addCollectionItem(card: card, language: .de, printing: .normal, item: item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.variant?.card?.externalId, "swsh3-136")
        XCTAssertEqual(fetched.first?.variant?.language, .de)
        XCTAssertEqual(fetched.first?.variant?.card?.name, "Furret")
    }

    @MainActor
    func testFindOrCreateCardIsIdempotent() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)

        let first = repository.findOrCreateCard(from: brief())
        let second = repository.findOrCreateCard(from: brief())
        try context.save()

        XCTAssertTrue(first === second)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Card>()), 1)
    }

    @MainActor
    func testFindOrCreateVariantReusesMatchingVariant() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)
        let card = repository.findOrCreateCard(from: brief())

        let first = repository.findOrCreateVariant(card: card, language: .en, printing: .holo)
        let second = repository.findOrCreateVariant(card: card, language: .en, printing: .holo)
        let different = repository.findOrCreateVariant(card: card, language: .de, printing: .holo)
        try context.save()

        XCTAssertTrue(first === second)
        XCTAssertFalse(first === different)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CardVariant>()), 2)
    }

    @MainActor
    func testExistingItemMatchesVariantConditionAndNotes() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)
        let card = repository.findOrCreateCard(from: brief())
        let item = CollectionItem(quantity: 2, confirmedCondition: .nearMint, notes: "Booster")
        repository.addCollectionItem(card: card, language: .de, printing: .normal, item: item)
        try context.save()

        let match = repository.existingItem(card: card, language: .de, printing: .normal, condition: .nearMint, notes: "Booster")
        XCTAssertTrue(match === item)

        let differentCondition = repository.existingItem(card: card, language: .de, printing: .normal, condition: .excellent, notes: "Booster")
        XCTAssertNil(differentCondition)

        let differentLanguage = repository.existingItem(card: card, language: .en, printing: .normal, condition: .nearMint, notes: "Booster")
        XCTAssertNil(differentLanguage)
    }
}
