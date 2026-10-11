import Foundation

/// Ein bewertbares Exemplar für die Sammlungswert-Berechnung.
struct ValuedItem: Equatable {
    let unitPrice: Decimal?
    let quantity: Int
    let isStale: Bool
    let currency: String
}

/// Ergebnis der Sammlungswert-Berechnung. Weist fehlende Daten ehrlich aus.
struct CollectionValue: Equatable {
    let total: Decimal
    let currency: String
    let pricedCount: Int
    let unpricedCount: Int
    let staleCount: Int
    let hasMixedCurrency: Bool
}

/// Reine Berechnung des Sammlungswerts aus bewertbaren Exemplaren.
enum CollectionValueCalculator {
    static func compute(items: [ValuedItem]) -> CollectionValue {
        var total: Decimal = 0
        var currencies = Set<String>()
        var priced = 0
        var unpriced = 0
        var stale = 0

        for item in items {
            currencies.insert(item.currency)
            if let unitPrice = item.unitPrice {
                priced += 1
                total += unitPrice * Decimal(item.quantity)
            } else {
                unpriced += 1
            }
            if item.isStale { stale += 1 }
        }

        let currency = currencies.count == 1 ? (currencies.first ?? "EUR") : "EUR"
        return CollectionValue(
            total: total,
            currency: currency,
            pricedCount: priced,
            unpricedCount: unpriced,
            staleCount: stale,
            hasMixedCurrency: currencies.count > 1
        )
    }
}
