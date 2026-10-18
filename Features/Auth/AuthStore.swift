import Foundation

/// Hält den Anmeldestatus und merkt sich die Sitzung über App-Starts hinweg.
@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var currentUser: AuthAccount?

    private let defaults: UserDefaults
    private let storageKey = "pokej.currentUser"

    /// Zuletzt angemeldeter Benutzername – auch ohne lebende `AuthStore`-Instanz
    /// lesbar (z. B. im Hintergrundlauf der Preisaktualisierung).
    static func storedUsername(defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: "pokej.currentUser")
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let username = defaults.string(forKey: storageKey),
           let account = AccountStorage.shared.account(named: username) {
            currentUser = account
        }
    }

    var isAuthenticated: Bool { currentUser != nil }

    @discardableResult
    func login(username: String, password: String) -> Bool {
        guard let account = AuthService.verify(username: username, password: password) else {
            return false
        }
        currentUser = account
        defaults.set(account.username, forKey: storageKey)
        return true
    }

    /// Legt ein neues lokales Konto an und meldet es direkt an.
    @discardableResult
    func register(username: String, password: String, displayName: String) -> Bool {
        guard let account = AuthService.register(username: username, password: password, displayName: displayName) else {
            return false
        }
        currentUser = account
        defaults.set(account.username, forKey: storageKey)
        return true
    }

    func logout() {
        currentUser = nil
        defaults.removeObject(forKey: storageKey)
    }
}
