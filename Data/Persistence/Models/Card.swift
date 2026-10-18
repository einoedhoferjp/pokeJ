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
    ///
    /// Gespeicherte URLs des nicht mehr existierenden `images.tcgdex.net`-
    /// Musters (aus älteren App-Versionen) werden ignoriert, damit auch alte
    /// Exemplare wieder Bilder zeigen.
    var imageURL: URL? {
        if let stored = imageURLString, !stored.isEmpty,
           !Self.isDeadImageURL(stored),
           let url = URL(string: stored) {
            return url
        }
        // Fallback: TCGdex-Kartenbild über Set-ID und lokale Nummer
        return TCGdexCardImageFallback.url(for: setId, localId: localId)
    }

    /// `true` für Bild-URLs, die nicht mehr ausgeliefert werden.
    static func isDeadImageURL(_ string: String) -> Bool {
        string.contains("images.tcgdex.net")
    }
}

/// Fallback-Bild-URL für Karten, deren gespeicherte imageURLString fehlt.
/// Baut auf dem bekannten TCGdex-CDN-Muster auf (Serie/Set/Nummer); das alte
/// images.tcgdex.net-Muster existiert nicht mehr.
private enum TCGdexCardImageFallback {
    static func url(for setId: String, localId: String) -> URL? {
        SetArtworkCatalog.cardImageURL(setId: setId, localId: localId, highResolution: true)
    }
}
