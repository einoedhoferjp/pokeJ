import Foundation

/// Berechnet den Sammlungswert aus gespeicherten Exemplaren und Preisen.
///
/// Bündelt die in der Bibliothek und auf der Startseite benötigte Logik an einer
/// Stelle, damit beide Ansichten exakt dieselbe Zahl zeigen.
enum CollectionStats {
    static func value(items: [CollectionItem], snapshots: [PriceSnapshot], now: Date = .now) -> CollectionValue {
        let byProduct = Dictionary(grouping: snapshots, by: { $0.cardmarketProductId })
        let valued = items.map { item -> ValuedItem in
            let printing = item.variant?.printing ?? .normal
            let stored = item.variant?.cardmarketProductId.flatMap { byProduct[$0] } ?? []
            let points = stored.map {
                PricePoint(
                    productId: $0.cardmarketProductId,
                    metric: $0.metric,
                    amount: $0.amount,
                    currency: $0.currency,
                    fetchedAt: $0.fetchedAt,
                    source: $0.source,
                    matchQuality: $0.matchQuality
                )
            }
            let latest = PriceResolver.latest(points: points, printing: printing)
            let stale = latest.map { PriceFreshness.isStale(fetchedAt: $0.fetchedAt, now: now) } ?? false
            return ValuedItem(
                unitPrice: latest?.amount,
                quantity: item.quantity,
                isStale: stale,
                currency: latest?.currency ?? "EUR"
            )
        }
        return CollectionValueCalculator.compute(items: valued)
    }

    static func totalQuantity(_ items: [CollectionItem]) -> Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    static func uniqueCardCount(_ items: [CollectionItem]) -> Int {
        Set(items.compactMap { $0.variant?.card?.externalId }).count
    }

    static func setCount(_ items: [CollectionItem]) -> Int {
        Set(items.compactMap { $0.variant?.card?.setId }).count
    }
}
