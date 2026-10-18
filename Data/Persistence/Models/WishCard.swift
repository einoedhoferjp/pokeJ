import Foundation
import SwiftData

/// Eine gewünschte Karte (Wunschliste).
///
/// Bewusst eigenständig und nicht als Beziehung an `Card` gebunden: Wünsche
/// können Karten betreffen, die noch gar nicht Teil der Sammlung (und damit
/// nicht als eigenes `Card`-Objekt angelegt) sind.
@Model
final class WishCard {
    @Attribute(.unique) var externalId: String
    var name: String
    var setId: String
    var setName: String
    var localId: String
    var imageURLString: String?
    var createdAt: Date

    init(
        externalId: String,
        name: String,
        setId: String,
        setName: String,
        localId: String,
        imageURLString: String? = nil,
        createdAt: Date = .now
    ) {
        self.externalId = externalId
        self.name = name
        self.setId = setId
        self.setName = setName
        self.localId = localId
        self.imageURLString = imageURLString
        self.createdAt = createdAt
    }

    /// Bild-URL mit TCGdex-Fallback über Set-ID und lokale Nummer.
    var imageURL: URL? {
        if let stored = imageURLString, !stored.isEmpty, let url = URL(string: stored) {
            return url
        }
        return URL(string: "https://images.tcgdex.net/de/cards/\(setId)-\(localId)/low.webp")
    }
}

// MARK: - Wunschlisten-Operationen

/// Kapselt das Anlegen/Entfernen von Wunsch-Karten.
@MainActor
enum WishlistStore {
    static func contains(externalId: String, context: ModelContext) -> Bool {
        let id = externalId
        let descriptor = FetchDescriptor<WishCard>(
            predicate: #Predicate { $0.externalId == id }
        )
        return ((try? context.fetch(descriptor)) ?? []).isEmpty == false
    }

    static func add(brief: CardBrief, context: ModelContext) {
        guard !contains(externalId: brief.id, context: context) else { return }
        context.insert(
            WishCard(
                externalId: brief.id,
                name: brief.name,
                setId: brief.setId,
                setName: brief.setName,
                localId: brief.localId,
                imageURLString: brief.imageURL?.absoluteString
            )
        )
        try? context.save()
    }

    static func add(set: CatalogSet, card: CatalogCard, context: ModelContext) {
        add(
            brief: CardBrief(
                id: card.id,
                name: card.name,
                setId: set.id,
                setName: set.name,
                localId: card.localId,
                rarity: nil,
                imageURL: card.thumbnailURL
            ),
            context: context
        )
    }

    static func remove(externalId: String, context: ModelContext) {
        let id = externalId
        let descriptor = FetchDescriptor<WishCard>(
            predicate: #Predicate { $0.externalId == id }
        )
        for wish in (try? context.fetch(descriptor)) ?? [] {
            context.delete(wish)
        }
        try? context.save()
    }

    /// Schaltet einen Wunsch um und liefert den neuen Zustand.
    @discardableResult
    static func toggle(brief: CardBrief, context: ModelContext) -> Bool {
        if contains(externalId: brief.id, context: context) {
            remove(externalId: brief.id, context: context)
            return false
        }
        add(brief: brief, context: context)
        return true
    }
}
