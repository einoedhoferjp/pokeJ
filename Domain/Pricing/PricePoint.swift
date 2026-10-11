import Foundation

/// Leichtgewichtiger, SwiftData-freier Preispunkt für die Anzeige-Logik.
struct PricePoint: Equatable {
    let productId: String
    let metric: PriceMetric
    let amount: Decimal
    let currency: String
    let fetchedAt: Date
    let source: String
    let matchQuality: MatchQuality
}

/// Reine Auswahl-/Priorisierungslogik für Preispunkte.
enum PriceResolver {
    /// Bevorzugte Kennzahl für einen Druck: Foil nutzt den Holo-Preis.
    static func preferredMetric(for printing: Printing) -> PriceMetric {
        printing == .holo ? .avgHolo : .avg
    }

    /// Neuester Punkt zur bevorzugten Kennzahl; fehlt sie, wird auf die jeweils
    /// andere Preisfamilie zurückgegriffen (nie auf einen erfundenen Wert).
    static func latest(points: [PricePoint], printing: Printing) -> PricePoint? {
        let preferred = preferredMetric(for: printing)
        if let point = latest(points: points, metric: preferred) { return point }
        let fallback: PriceMetric = (printing == .holo) ? .avg : .avgHolo
        return latest(points: points, metric: fallback)
    }

    static func latest(points: [PricePoint], metric: PriceMetric) -> PricePoint? {
        points.filter { $0.metric == metric }.max { $0.fetchedAt < $1.fetchedAt }
    }

    /// Neuester Punkt je Kennzahl.
    static func latestPerMetric(points: [PricePoint]) -> [PriceMetric: PricePoint] {
        var result: [PriceMetric: PricePoint] = [:]
        for point in points {
            if let existing = result[point.metric], existing.fetchedAt >= point.fetchedAt { continue }
            result[point.metric] = point
        }
        return result
    }
}
