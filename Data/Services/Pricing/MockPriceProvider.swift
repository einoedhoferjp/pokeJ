import Foundation

/// Offline-Preisquelle für Previews/Tests. Liefert feste Beispielpreise für
/// bekannte Seed-Karten; für unbekannte IDs werden keine Werte erfunden.
struct MockPriceProvider: PriceProvider {
    let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    func prices(externalCardId: String, printing: Printing, language: Language) async throws -> [PriceSnapshotDTO] {
        guard let base = Self.basePrices[externalCardId] else { return [] }
        let amount = printing == .holo ? base * 3 : base
        return [
            PriceSnapshotDTO(productId: externalCardId, metric: .avg, amount: amount, currency: "EUR", fetchedAt: now, source: "Mock", matchQuality: .uncertain),
            PriceSnapshotDTO(productId: externalCardId, metric: .low, amount: amount * 0.7, currency: "EUR", fetchedAt: now, source: "Mock", matchQuality: .uncertain),
            PriceSnapshotDTO(productId: externalCardId, metric: .trend, amount: amount * 1.05, currency: "EUR", fetchedAt: now, source: "Mock", matchQuality: .uncertain)
        ]
    }

    private static let basePrices: [String: Decimal] = [
        "base1-4": 320,
        "base1-58": 25,
        "swsh3-136": 0.07,
        "swsh1-1": 4.5,
        "sm1-1": 0.4,
        "xy1-1": 0.3,
        "sv1-1": 0.15,
        "swsh12-1": 0.2
    ]
}
