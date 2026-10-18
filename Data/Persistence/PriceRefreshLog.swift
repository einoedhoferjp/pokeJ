import Foundation

/// Merkt sich (per `UserDefaults`, je Konto), wann die Sammlungspreise zuletzt
/// aktualisiert wurden. Grundlage für die tägliche Auto-Aktualisierung – im
/// Vordergrund wie im iOS-Hintergrundlauf.
struct PriceRefreshLog {
    private let defaults: UserDefaults
    private let lastRefreshKey: String
    private let lastAttemptKey: String
    private let failedKey: String

    init(defaults: UserDefaults = .standard, username: String? = nil) {
        self.defaults = defaults
        let scope = username.map { "pokej.prices.\(AccountStorage.storageKey(for: $0))" } ?? "pokej.prices"
        self.lastRefreshKey = "\(scope).lastFullRefresh"
        self.lastAttemptKey = "\(scope).lastAttempt"
        self.failedKey = "\(scope).failedTargets"
    }

    /// Zeitpunkt der letzten **vollständigen** Aktualisierung (alle Karten ok).
    var lastFullRefresh: Date? {
        get { defaults.object(forKey: lastRefreshKey) as? Date }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: lastRefreshKey)
            } else {
                defaults.removeObject(forKey: lastRefreshKey)
            }
        }
    }

    /// Zeitpunkt des letzten Versuchs – auch wenn dabei Karten fehlschlugen.
    var lastAttempt: Date? {
        get { defaults.object(forKey: lastAttemptKey) as? Date }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: lastAttemptKey)
            } else {
                defaults.removeObject(forKey: lastAttemptKey)
            }
        }
    }

    /// Anzahl der beim letzten Versuch fehlgeschlagenen Karten.
    var failedTargets: Int {
        get { defaults.integer(forKey: failedKey) }
        nonmutating set { defaults.set(newValue, forKey: failedKey) }
    }

    func isRefreshDue(now: Date = .now) -> Bool {
        PriceRefreshPolicy.isRefreshDue(
            lastRefresh: lastFullRefresh,
            lastAttempt: lastAttempt,
            failedTargets: failedTargets,
            now: now
        )
    }

    /// Voraussichtlicher Zeitpunkt der nächsten automatischen Aktualisierung.
    ///
    /// Fehlgeschlagene Karten werden früher erneut versucht, sonst gilt das
    /// 24-Stunden-Intervall.
    var nextAutomaticRefresh: Date? {
        if failedTargets > 0, let lastAttempt {
            return lastAttempt.addingTimeInterval(PriceRefreshPolicy.retryInterval)
        }
        guard let lastFullRefresh else { return nil }
        return lastFullRefresh.addingTimeInterval(PriceRefreshPolicy.interval)
    }

    /// Merkt einen vollständig erfolgreichen Durchlauf.
    func markRefreshed(at date: Date = .now) {
        lastFullRefresh = date
        lastAttempt = date
        failedTargets = 0
    }

    /// Merkt einen Durchlauf, auch wenn einzelne Karten fehlschlugen.
    ///
    /// Nur ein fehlerfreier Lauf zählt als abgeschlossene Tagesaktualisierung;
    /// bei Fehlern bleibt die Aktualisierung fällig (Wiederholung nach
    /// `PriceRefreshPolicy.retryInterval`).
    func recordAttempt(failed: Int, at date: Date = .now) {
        lastAttempt = date
        failedTargets = failed
        if failed == 0 {
            lastFullRefresh = date
        }
    }
}
