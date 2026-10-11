import XCTest
import SwiftData
@testable import PokeJ

final class DataModelTests: XCTestCase {
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
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }

    func testEnumRawRoundTrip() {
        XCTAssertEqual(CardCondition(rawValue: CardCondition.lightPlayed.rawValue), .lightPlayed)
        XCTAssertEqual(Language(rawValue: "ja"), .ja)
        XCTAssertEqual(Printing(rawValue: Printing.reverse.rawValue), .reverse)
        XCTAssertEqual(MatchQuality(rawValue: "productOnly"), .productOnly)
        XCTAssertEqual(ScanStatus(rawValue: "multiple")?.displayName, "Mehrere mögliche Treffer")
    }

    @MainActor
    func testCollectionItemUsesEnumAccessors() throws {
        let context = try makeContext()
        let item = CollectionItem(confirmedCondition: .excellent, estimatedCondition: .good)
        context.insert(item)
        try context.save()

        XCTAssertEqual(item.confirmedCondition, .excellent)
        XCTAssertEqual(item.estimatedCondition, .good)

        item.confirmedCondition = .poor
        item.estimatedCondition = nil
        XCTAssertEqual(item.confirmedConditionRaw, CardCondition.poor.rawValue)
        XCTAssertNil(item.estimatedCondition)
    }

    @MainActor
    func testFindOrCreateVariantReusesExisting() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)
        let brief = CardBrief(id: "base1-4", name: "Charizard", setId: "base1", setName: "Base Set", localId: "4", rarity: "Rare Holo", imageURL: nil)
        let card = repository.findOrCreateCard(from: brief)

        let first = repository.findOrCreateVariant(card: card, language: .de, printing: .holo)
        let second = repository.findOrCreateVariant(card: card, language: .de, printing: .holo)
        try context.save()

        XCTAssertEqual(first.persistentModelID, second.persistentModelID)
        XCTAssertEqual(card.variants.count, 1)
    }

    @MainActor
    func testSameCardAllowsDifferentConditions() throws {
        let context = try makeContext()
        let repository = CollectionRepository(context: context)
        let brief = CardBrief(id: "base1-4", name: "Charizard", setId: "base1", setName: "Base Set", localId: "4", rarity: "Rare Holo", imageURL: nil)
        let card = repository.findOrCreateCard(from: brief)

        let mint = CollectionItem(confirmedCondition: .nearMint)
        repository.addCollectionItem(card: card, language: .de, printing: .holo, item: mint)

        let played = CollectionItem(confirmedCondition: .played)
        repository.addCollectionItem(card: card, language: .de, printing: .holo, item: played)
        try context.save()

        let items = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(card.variants.count, 1)
        XCTAssertEqual(Set(items.map(\.confirmedCondition)), [.nearMint, .played])
    }

    @MainActor
    func testSeedLoaderIsIdempotent() throws {
        let context = try makeContext()
        SeedLoader.seedIfNeeded(in: context)
        let firstCards = try context.fetch(FetchDescriptor<Card>())
        let firstItems = try context.fetch(FetchDescriptor<CollectionItem>())

        XCTAssertFalse(firstCards.isEmpty)
        XCTAssertFalse(firstItems.isEmpty)

        SeedLoader.seedIfNeeded(in: context)
        let secondCards = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(firstCards.count, secondCards.count)
    }
}
