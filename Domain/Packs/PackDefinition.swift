import Foundation

/// Booster, der gegen App-Punkte gekauft und geöffnet werden kann. Für fiktive
/// Booster ist er an ein konkretes Set gebunden (`setId`), aus dem gezogen wird.
struct PackDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let cost: Int
    let cardCount: Int
    let holoGuarantee: Int
    let iconName: String

    /// Angereicherte Set-Infos (nur für Katalog-Booster gesetzt).
    var setId: String? = nil
    var setName: String? = nil
    var serieId: String? = nil
    var eraName: String? = nil
    var releaseYear: Int? = nil
    var logoURL: URL? = nil
    var englishImageBase: URL? = nil

    static let standard = PackDefinition(
        id: "standard",
        name: "Standard-Pack",
        cost: 200,
        cardCount: 5,
        holoGuarantee: 0,
        iconName: "shippingbox"
    )
    static let holo = PackDefinition(
        id: "holo",
        name: "Holo-Pack",
        cost: 500,
        cardCount: 5,
        holoGuarantee: 1,
        iconName: "sparkles"
    )
    static let premium = PackDefinition(
        id: "premium",
        name: "Premium-Pack",
        cost: 1000,
        cardCount: 10,
        holoGuarantee: 3,
        iconName: "crown"
    )

    static let all: [PackDefinition] = [.standard, .holo, .premium]

    var contentsText: String {
        var parts = ["\(cardCount) Karten"]
        if holoGuarantee > 0 {
            parts.append("min. \(holoGuarantee) Holo")
        }
        return parts.joined(separator: " · ")
    }

    var isSetPack: Bool { setId != nil }

    /// Altersstufe als Text (z. B. „1999").
    var releaseYearText: String? {
        releaseYear.map { String($0) }
    }
}

// MARK: - Katalog-Booster

extension PackDefinition {
    /// Alle Sets des Offline-Katalogs als Booster, nach Erscheinungsdatum sortiert.
    static let catalogPacks: [PackDefinition] = buildCatalogPacks()

    /// Nach Ära gruppiert und in chronologischer Reihenfolge für den Shop.
    static var catalogPacksByEra: [PackEraGroup] {
        let grouped = Dictionary(grouping: catalogPacks) { $0.serieId ?? PackEras.fallback.id }
        return grouped
            .map { serieId, packs -> PackEraGroup in
                let era = PackEras.era(for: serieId)
                let sorted = packs.sorted { lhs, rhs in
                    let l = lhs.releaseYear ?? 0
                    let r = rhs.releaseYear ?? 0
                    if l == r { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                    return l < r
                }
                return PackEraGroup(era: era, packs: sorted)
            }
            .sorted { $0.era.order < $1.era.order }
    }

    private static func buildCatalogPacks() -> [PackDefinition] {
        let setsById = Dictionary(
            PokemonCatalog.sets.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return SetArtworkCatalog.all.compactMap { artwork -> PackDefinition? in
            guard let set = setsById[artwork.id], !set.cards.isEmpty else { return nil }
            let era = PackEras.era(for: artwork.serieId)
            return PackDefinition(
                id: set.id,
                name: set.name,
                cost: PackEras.cost(releaseYear: artwork.releaseYear),
                cardCount: 6,
                holoGuarantee: 1,
                iconName: "shippingbox",
                setId: set.id,
                setName: set.name,
                serieId: artwork.serieId,
                eraName: era.name,
                releaseYear: artwork.releaseYear,
                logoURL: artwork.logoImageURL,
                englishImageBase: artwork.englishImageBase
            )
        }
    }
}
