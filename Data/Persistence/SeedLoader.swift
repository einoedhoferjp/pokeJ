import Foundation
import SwiftData

/// Legt beim ersten Start einen kleinen Demo-Datensatz an, damit die App
/// offline sinnvoll nutzbar und testbar ist.
@MainActor
enum SeedLoader {
    /// Führt die einmalige Seeding-Logik und die Herkunfts-Migration aus.
    static func bootstrap(in context: ModelContext) {
        seedIfNeeded(in: context)
        migrateFictionalOrigins(in: context)
    }

    static func seedIfNeeded(in context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<Card>())) ?? 0
        guard existingCount == 0 else { return }

        let repository = CollectionRepository(context: context)

        for dto in SeedCatalog.cards {
            let card = Card(
                externalId: dto.id,
                name: dto.name,
                setId: dto.setId,
                setName: dto.setName,
                localId: dto.localId,
                rarity: dto.rarity,
                illustrator: dto.illustrator,
                imageURLString: dto.imageURL?.absoluteString,
                updatedAt: dto.updatedAt
            )
            context.insert(card)
        }

        if let charizard = try? repository.card(externalId: "base1-4") {
            let item = CollectionItem(
                quantity: 1,
                confirmedCondition: .excellent,
                purchasePrice: Decimal(120),
                purchaseDate: Date.now.addingTimeInterval(-86_400 * 30),
                notes: "Flohmarktfunde"
            )
            repository.addCollectionItem(card: charizard, language: .de, printing: .holo, item: item)
        }

        if let furret = try? repository.card(externalId: "swsh3-136") {
            let item = CollectionItem(
                quantity: 2,
                confirmedCondition: .nearMint,
                notes: "Aus Booster geöffnet",
                origin: .pack
            )
            repository.addCollectionItem(card: furret, language: .en, printing: .normal, item: item)
        }

        try? context.save()
    }

    /// Ordnet vor der Einführung der Herkunft gespeicherte Booster-Karten der
    /// fiktiven Sammlung zu (erkennbar an ihren Notizen).
    static func migrateFictionalOrigins(in context: ModelContext) {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { item in
                item.originRaw == "scanned"
                    && (item.notes == "Aus Pack geöffnet" || item.notes == "Aus Booster geöffnet")
            }
        )
        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return }
        for item in items {
            item.origin = .pack
        }
        try? context.save()
    }
}
