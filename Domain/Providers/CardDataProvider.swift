import Foundation

/// Datenquelle für Kartendaten (Phase 1: Mock, Phase 2: TCGdex).
protocol CardDataProvider: Sendable {
    func searchCards(_ query: CardQuery) async throws -> [CardBrief]
    func card(externalId: String, language: Language) async throws -> CardDTO
    func sets(language: Language) async throws -> [SetBrief]
}

/// Datenquelle für Preise (Phase 3: TCGdex `pricing.cardmarket`).
protocol PriceProvider: Sendable {
    func price(externalCardId: String, printing: Printing, language: Language) async throws -> PriceSnapshotDTO?
}

enum CardDataError: Error, LocalizedError {
    case notFound
    case network
    case decoding

    var errorDescription: String? {
        switch self {
        case .notFound: return "Karte nicht gefunden."
        case .network: return "Netzwerkfehler. Bitte später erneut versuchen."
        case .decoding: return "Daten konnten nicht gelesen werden."
        }
    }
}
