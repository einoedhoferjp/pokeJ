import Foundation

/// Entscheidet, ob die Sammlungspreise automatisch neu geladen werden sollen.
///
/// Die App läuft ohne eigenen Server: Cardmarket liefert **Tageswerte** über
/// TCGdex. Eine Aktualisierung ist daher fällig, sobald
///
/// - noch nie vollständig aktualisiert wurde, oder
/// - die letzte **vollständige** Aktualisierung länger als `interval` (24 h)
///   zurückliegt, oder
/// - der letzte Durchlauf fehlgeschlagene Karten hatte und `retryInterval`
///   (1 h) vergangen ist (Wiederholung ohne Dauerfeuer).
///
/// Die tatsächliche Ausführung übernimmt der Vordergrund (App-Start/Vordergrund)
/// und zusätzlich der iOS-Hintergrundlauf (`PriceRefreshTask`).
enum PriceRefreshPolicy {
    /// Reguläres Intervall zwischen zwei automatischen Aktualisierungen.
    static let interval: TimeInterval = 24 * 60 * 60

    /// Wartezeit, bis fehlgeschlagene Karten erneut versucht werden.
    static let retryInterval: TimeInterval = 60 * 60

    /// `true`, wenn noch nie aktualisiert wurde oder das Intervall abgelaufen ist.
    static func isRefreshDue(
        lastRefresh: Date?,
        now: Date = .now,
        interval: TimeInterval = PriceRefreshPolicy.interval
    ) -> Bool {
        guard let lastRefresh else { return true }
        return now.timeIntervalSince(lastRefresh) >= interval
    }

    /// Vollständige Prüfung inklusive Wiederholung fehlgeschlagener Karten.
    ///
    /// `lastRefresh` ist der letzte **erfolgreiche** Durchlauf, `lastAttempt`
    /// der letzte Versuch (auch mit Fehlern).
    static func isRefreshDue(
        lastRefresh: Date?,
        lastAttempt: Date?,
        failedTargets: Int,
        now: Date = .now,
        interval: TimeInterval = PriceRefreshPolicy.interval,
        retryInterval: TimeInterval = PriceRefreshPolicy.retryInterval
    ) -> Bool {
        if isRefreshDue(lastRefresh: lastRefresh, now: now, interval: interval) {
            return true
        }
        guard failedTargets > 0, let lastAttempt else { return false }
        return now.timeIntervalSince(lastAttempt) >= retryInterval
    }
}
