import Foundation

/// Merkt sich (per `UserDefaults`), wann die Sammlungspreise zuletzt vollständig
/// aktualisiert wurden. Grundlage für die tägliche Auto-Aktualisierung.
struct PriceRefreshLog {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, username: String? = nil) {
        self.defaults = defaults
        self.key = username.map { "pokej.prices.\(AccountStorage.storageKey(for: $0)).lastFullRefresh" }
            ?? "pokej.prices.lastFullRefresh"
    }

    var lastFullRefresh: Date? {
        get { defaults.object(forKey: key) as? Date }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    func isRefreshDue(now: Date = .now) -> Bool {
        PriceRefreshPolicy.isRefreshDue(lastRefresh: lastFullRefresh, now: now)
    }

    func markRefreshed(at date: Date = .now) {
        lastFullRefresh = date
    }
}
