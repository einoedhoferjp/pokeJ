import Foundation

/// Entscheidet, ob die Sammlungspreise automatisch neu geladen werden sollen.
///
/// Da die App ohne Server läuft, ist ein tägliches Aktualisieren nur möglich,
/// solange die App überhaupt läuft. Deshalb wird beim Start/vorder am
/// Vordergrund geprüft, ob seit der letzten vollständigen Aktualisierung ein
/// Intervall verstrichen ist.
enum PriceRefreshPolicy {
    /// Standardintervall zwischen zwei automatischen Aktualisierungen.
    static let interval: TimeInterval = 24 * 60 * 60

    /// `true`, wenn noch nie aktualisiert wurde oder das Intervall abgelaufen ist.
    static func isRefreshDue(
        lastRefresh: Date?,
        now: Date = .now,
        interval: TimeInterval = PriceRefreshPolicy.interval
    ) -> Bool {
        guard let lastRefresh else { return true }
        return now.timeIntervalSince(lastRefresh) >= interval
    }
}
