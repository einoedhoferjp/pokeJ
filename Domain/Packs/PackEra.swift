import Foundation

/// Eine Sammlungs-Ära (Serie) im Booster-Shop.
struct PackEra: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let order: Int
}

/// Eine Ära mit ihren zugehörigen Booster-Packs (für die Shop-Gruppierung).
struct PackEraGroup: Identifiable, Hashable, Sendable {
    let era: PackEra
    let packs: [PackDefinition]

    var id: String { era.id }
}

/// Ordnet Serien deutschen Ära-Namen zu und leitet die Preisstufe ab.
enum PackEras {
    static let all: [PackEra] = [
        PackEra(id: "base", name: "Klassik (Base & Co.)", order: 0),
        PackEra(id: "neo", name: "Neo", order: 1),
        PackEra(id: "ecard", name: "E-Card", order: 2),
        PackEra(id: "ex", name: "EX", order: 3),
        PackEra(id: "dp", name: "Diamond & Pearl", order: 4),
        PackEra(id: "pl", name: "Platinum", order: 5),
        PackEra(id: "hgss", name: "HeartGold & SoulSilver", order: 6),
        PackEra(id: "col", name: "Call of Legends", order: 7),
        PackEra(id: "bw", name: "Schwarz & Weiß", order: 8),
        PackEra(id: "xy", name: "XY", order: 9),
        PackEra(id: "sm", name: "Sonne & Mond", order: 10),
        PackEra(id: "swsh", name: "Schwert & Schild", order: 11),
        PackEra(id: "sv", name: "Karmesin & Purpur", order: 12),
        PackEra(id: "me", name: "Mega-Entwicklung", order: 13),
        PackEra(id: "tcgp", name: "TCG Pocket", order: 14)
    ]

    static let fallback = PackEra(id: "misc", name: "Sonstige", order: 99)

    private static let byId: [String: PackEra] = Dictionary(
        all.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func era(for serieId: String) -> PackEra {
        byId[serieId] ?? fallback
    }

    /// Preis nach Erscheinungsjahr: ältere Sets sind günstiger, neue teurer.
    static func cost(releaseYear: Int?) -> Int {
        switch releaseYear ?? 2020 {
        case ..<2001: return 100
        case 2001...2003: return 120
        case 2004...2006: return 150
        case 2007...2009: return 180
        case 2010...2012: return 210
        case 2013...2016: return 260
        case 2017...2019: return 320
        case 2020...2022: return 400
        default: return 500
        }
    }
}
