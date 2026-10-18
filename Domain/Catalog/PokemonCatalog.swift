import Foundation

/// Ein Pokémon-Set aus dem gebündelten Offline-Katalog.
struct CatalogSet: Identifiable, Decodable, Sendable, Hashable {
    let id: String
    let name: String
    let cards: [CatalogCard]
}

/// Eine Karte im Offline-Katalog (nur Anzeige-/Suchdaten, keine Preise).
struct CatalogCard: Identifiable, Decodable, Sendable, Hashable {
    let id: String
    let localId: String
    let name: String
    let image: String?

    /// Set-ID, aus der Kartenkennung abgeleitet (Format „{setId}-{localId}").
    var setId: String {
        guard id.hasSuffix(localId), id.count > localId.count + 1 else { return "" }
        return String(id.dropLast(localId.count + 1))
    }

    /// Thumbnail-URL: deutsches Kartenbild, sonst englisches CDN-Bild des Sets.
    ///
    /// Fehlende deutsche Bilder (62 Sets, z. B. Base Set) werden so über den
    /// Fallback des Set-Artwork-Katalogs abgedeckt.
    var thumbnailURL: URL? {
        if let image, let url = URL(string: image + "/low.webp") {
            return url
        }
        return SetArtworkCatalog.cardImageURL(setId: setId, localId: localId, highResolution: false)
    }

    /// Große Bild-URL mit demselben Fallback wie `thumbnailURL`.
    var highResURL: URL? {
        if let image, let url = URL(string: image + "/high.webp") {
            return url
        }
        return SetArtworkCatalog.cardImageURL(setId: setId, localId: localId, highResolution: true)
    }
}

struct PokemonCatalogPayload: Decodable, Sendable {
    let generatedAt: String
    let language: String
    let source: String
    let sets: [CatalogSet]

    static let empty = PokemonCatalogPayload(generatedAt: "", language: "de", source: "", sets: [])

    var cardCount: Int {
        sets.reduce(0) { $0 + $1.cards.count }
    }
}

/// Lädt den gebündelten Gesamtkatalog (`Resources/PokemonCatalog.json`).
///
/// Enthält nach Möglichkeit **alle** jemals veröffentlichten Sets/Karten der
/// Datenquelle. Preise sind bewusst **nicht** enthalten (sie würden veralten)
/// und werden zur Anzeige live geladen.
enum PokemonCatalog {
    static let shared: PokemonCatalogPayload = load()
    static let sets: [CatalogSet] = shared.sets

    private static func load() -> PokemonCatalogPayload {
        guard let url = Bundle.main.url(forResource: "PokemonCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(PokemonCatalogPayload.self, from: data) else {
            return .empty
        }
        return payload
    }
}
