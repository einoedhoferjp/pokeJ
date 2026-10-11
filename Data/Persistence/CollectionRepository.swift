import Foundation
import SwiftData

/// Kapselt das Anlegen/Auffinden von Karten, Varianten und Exemplaren.
@MainActor
struct CollectionRepository {
    let context: ModelContext

    func card(externalId: String) throws -> Card? {
        let id = externalId
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.externalId == id }
        )
        return try context.fetch(descriptor).first
    }

    func findOrCreateCard(from brief: CardBrief) -> Card {
        if let existing = try? card(externalId: brief.id) {
            return existing
        }
        let card = Card(
            externalId: brief.id,
            name: brief.name,
            setId: brief.setId,
            setName: brief.setName,
            localId: brief.localId,
            rarity: brief.rarity,
            imageURLString: brief.imageURL?.absoluteString
        )
        context.insert(card)
        return card
    }

    func variant(matching card: Card, language: Language, printing: Printing) -> CardVariant? {
        card.variants.first { $0.language == language && $0.printing == printing }
    }

    @discardableResult
    func findOrCreateVariant(card: Card, language: Language, printing: Printing) -> CardVariant {
        if let existing = variant(matching: card, language: language, printing: printing) {
            return existing
        }
        let variant = CardVariant(language: language, printing: printing)
        variant.card = card
        context.insert(variant)
        return variant
    }

    func addCollectionItem(card: Card, language: Language, printing: Printing, item: CollectionItem) {
        let variant = findOrCreateVariant(card: card, language: language, printing: printing)
        item.variant = variant
        context.insert(item)
    }
}
