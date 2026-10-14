import XCTest
import SwiftData
@testable import PokeJ

final class CollectionImportTests: XCTestCase {
    private var containers: [ModelContainer] = []

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
        containers.append(container)
        return container.mainContext
    }

    private func dto(
        cardId: String = "swsh3-136",
        language: String = "de",
        printing: String = "normal",
        condition: String = "nearMint",
        quantity: Int = 1,
        notes: String = "",
        origin: String? = nil
    ) -> CollectionExport.ItemDTO {
        CollectionExport.ItemDTO(
            cardId: cardId,
            cardName: "Furret",
            setId: "swsh3",
            setName: "Darkness Ablaze",
            localId: "136",
            language: language,
            printing: printing,
            condition: condition,
            quantity: quantity,
            notes: notes,
            purchasePrice: nil,
            purchaseDate: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            origin: origin
        )
    }

    private func encode(_ dtos: [CollectionExport.ItemDTO]) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dtos)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    @MainActor
    func testRoundTripRestoresCollection() throws {
        let source = try makeContext()
        let repository = CollectionRepository(context: source)
        let brief = CardBrief(id: "swsh3-136", name: "Furret", setId: "swsh3", setName: "Darkness Ablaze", localId: "136", rarity: "Rare", imageURL: nil)
        let card = repository.findOrCreateCard(from: brief)
        let item = CollectionItem(quantity: 2, confirmedCondition: .excellent, notes: "Booster")
        repository.addCollectionItem(card: card, language: .en, printing: .holo, item: item)
        try source.save()
        let json = CollectionExport.json(items: [item])

        let destination = try makeContext()
        let summary = CollectionImport.apply(try CollectionImport.decode(json), context: destination)
        XCTAssertEqual(summary.imported, 1)
        XCTAssertEqual(summary.merged, 0)
        XCTAssertEqual(summary.skipped, 0)

        let fetched = try destination.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.quantity, 2)
        XCTAssertEqual(fetched.first?.confirmedCondition, .excellent)
        XCTAssertEqual(fetched.first?.notes, "Booster")
        XCTAssertEqual(fetched.first?.variant?.card?.externalId, "swsh3-136")
        XCTAssertEqual(fetched.first?.variant?.language, .en)
        XCTAssertEqual(fetched.first?.variant?.printing, .holo)
    }

    @MainActor
    func testImportMergesIdenticalItems() throws {
        let json = try encode([dto(quantity: 1), dto(quantity: 2)])
        let context = try makeContext()
        let summary = CollectionImport.apply(try CollectionImport.decode(json), context: context)

        XCTAssertEqual(summary.imported, 1)
        XCTAssertEqual(summary.merged, 1)

        let fetched = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.quantity, 3)
    }

    @MainActor
    func testImportSkipsUnknownValues() throws {
        let json = try encode([dto(language: "xx")])
        let context = try makeContext()
        let summary = CollectionImport.apply(try CollectionImport.decode(json), context: context)

        XCTAssertEqual(summary.imported, 0)
        XCTAssertEqual(summary.skipped, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CollectionItem>()), 0)
    }

    @MainActor
    func testImportRestoresPackOrigin() throws {
        let json = try encode([dto(notes: "Aus Pack geöffnet", origin: "pack")])
        let context = try makeContext()
        _ = CollectionImport.apply(try CollectionImport.decode(json), context: context)

        let fetched = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.first?.origin, .pack)
    }

    @MainActor
    func testImportDefaultsOriginToScanned() throws {
        let json = try encode([dto()])
        let context = try makeContext()
        _ = CollectionImport.apply(try CollectionImport.decode(json), context: context)

        let fetched = try context.fetch(FetchDescriptor<CollectionItem>())
        XCTAssertEqual(fetched.first?.origin, .scanned)
    }

    func testDecodeRejectsInvalidJSON() {
        XCTAssertThrowsError(try CollectionImport.decode("kein-json"))
    }
}
