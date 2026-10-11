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

    var thumbnailURL: URL? {
        guard let image else { return nil }
        return URL(string: image + "/low.webp")
    }

    var highResURL: URL? {
        guard let image else { return nil }
        return URL(string: image + "/high.webp")
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
