import Foundation

/// Kurze Set-Information.
struct SetBrief: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}

/// Leichtgewichtige Karteninformation für Suchergebnisse/Listen.
struct CardBrief: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let setId: String
    let setName: String
    let localId: String
    let rarity: String?
    let imageURL: URL?
}

/// Vollständige Karteninformation aus der Datenquelle.
struct CardDTO: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let setId: String
    let setName: String
    let localId: String
    let rarity: String?
    let illustrator: String?
    let imageURL: URL?
    let availablePrintings: [Printing]
    let updatedAt: Date?
}

/// Suchanfrage an die Kartendatenquelle.
struct CardQuery: Sendable {
    var text: String = ""
    var setId: String?
    var language: Language = .de
}

/// Von der Preisdatenquelle gelieferter Momentaufnahme-Datensatz.
struct PriceSnapshotDTO: Sendable {
    let metric: PriceMetric
    let amount: Decimal
    let currency: String
    let fetchedAt: Date
    let source: String
    let matchQuality: MatchQuality
}
