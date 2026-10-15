import Foundation
import SwiftData

/// Stammdaten einer Karte (aus der Kartendatenquelle).
@Model
final class Card {
    @Attribute(.unique) var externalId: String
    var name: String
    var setId: String
    var setName: String
    var localId: String
    var rarity: String?
    var illustrator: String?
    var imageURLString: String?
    var updatedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \CardVariant.card)
    var variants: [CardVariant] = []

    init(
        externalId: String,
        name: String,
        setId: String,
        setName: String,
        localId: String,
        rarity: String? = nil,
        illustrator: String? = nil,
        imageURLString: String? = nil,
        updatedAt: Date? = nil
    ) {
        self.externalId = externalId
        self.name = name
        self.setId = setId
        self.setName = setName
        self.localId = localId
        self.rarity = rarity
        self.illustrator = illustrator
        self.imageURLString = imageURLString
        self.updatedAt = updatedAt
    }

    /// Bild-URL mit mehreren Fallback-Stufen:
    /// 1. Gespeicherte imageURLString (TCGdex / Seed / Katalog)
    /// 2. Direkter TCGdex high.webp-Pfad über setId + localId
    var imageURL: URL? {
        if let stored = imageURLString, !stored.isEmpty,
           let url = URL(string: stored) {
            return url
        }
        // Fallback: TCGdex-Kartenbild über Set-ID und lokale Nummer
        return TCGdexCardImageFallback.url(for: setId, localId: localId)
    }
}

/// Fallback-Bild-URL für Karten, deren gespeicherte imageURLString fehlt.
/// Baut auf dem bekannten TCGdex-Bildmuster auf.
private enum TCGdexCardImageFallback {
    static func url(for setId: String, localId: String) -> URL? {
        // TCGdex speichert Bilder unter /cards/{setId}-{localId}/high.webp
        let base = "https://images.tcgdex.net/de"
        return URL(string: "\(base)/cards/\(setId)-\(localId)/high.webp")
    }
}
