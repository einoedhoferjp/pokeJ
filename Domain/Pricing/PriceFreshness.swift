import Foundation

/// Bewertet, ob ein gespeicherter Preis als veraltet gilt.
///
/// Cardmarket liefert Tageswerte; 36 Stunden tolerieren eine verpasste
/// Aktualisierung, ohne sofort „veraltet" zu melden.
enum PriceFreshness {
    static let defaultMaxAge: TimeInterval = 36 * 60 * 60

    static func isStale(fetchedAt: Date, now: Date, maxAge: TimeInterval = defaultMaxAge) -> Bool {
        now.timeIntervalSince(fetchedAt) > maxAge
    }
}
