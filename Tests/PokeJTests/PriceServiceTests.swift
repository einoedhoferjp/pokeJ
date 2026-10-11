import XCTest
import SwiftData
@testable import PokeJ

final class PriceServiceTests: XCTestCase {
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

    private static func dto(amount: String) -> PriceSnapshotDTO {
        PriceSnapshotDTO(
            productId: "483559",
            metric: .avg,
            amount: Decimal(string: amount)!,
            currency: "EUR",
            fetchedAt: Date(timeIntervalSince1970: 1_000),
            source: "test",
            matchQuality: .productOnly
        )
    }

    @MainActor
    private func makeItem(in context: ModelContext) throws -> CollectionItem {
        let card = Card(externalId: "swsh3-136", name: "Furret", setId: "swsh3", setName: "Darkness Ablaze", localId: "136")
        context.insert(card)
        let variant = CardVariant(language: .en, printing: .normal)
        variant.card = card
        context.insert(variant)
        let item = CollectionItem(confirmedCondition: .nearMint)
        item.variant = variant
        context.insert(item)
        try context.save()
        return item
    }

    @MainActor
    func testRefreshInsertsSnapshotAndSetsProductId() async throws {
        let context = try makeContext()
        let item = try makeItem(in: context)
        let service = PriceService(provider: StubPriceProvider { _, _, _ in [Self.dto(amount: "0.07")] }, context: context)

        let summary = await service.refresh(items: [item])
        XCTAssertEqual(summary.insertedSnapshots, 1)
        XCTAssertEqual(summary.updatedVariants, 1)
        XCTAssertEqual(item.variant?.cardmarketProductId, "483559")

        let snapshots = try PriceRepository(context: context).snapshots(productId: "483559")
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.amount, Decimal(string: "0.07"))
    }

    @MainActor
    func testRefreshSkipsUnchangedPrice() async throws {
        let context = try makeContext()
        let item = try makeItem(in: context)
        let service = PriceService(provider: StubPriceProvider { _, _, _ in [Self.dto(amount: "0.07")] }, context: context)

        _ = await service.refresh(items: [item])
        let second = await service.refresh(items: [item])
        XCTAssertEqual(second.insertedSnapshots, 0)
        XCTAssertEqual(try PriceRepository(context: context).snapshots(productId: "483559").count, 1)
    }

    @MainActor
    func testRefreshCountsFailedTargets() async throws {
        let context = try makeContext()
        let item = try makeItem(in: context)
        let service = PriceService(provider: StubPriceProvider { _, _, _ -> [PriceSnapshotDTO] in throw CardDataError.network }, context: context)
        let summary = await service.refresh(items: [item])
        XCTAssertEqual(summary.failedTargets, 1)
        XCTAssertEqual(summary.insertedSnapshots, 0)
    }
}
