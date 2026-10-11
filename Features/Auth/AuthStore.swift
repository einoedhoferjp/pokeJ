import Foundation

/// Hält den Anmeldestatus und merkt sich die Sitzung über App-Starts hinweg.
@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var currentUser: AuthAccount?

    private let defaults: UserDefaults
    private let storageKey = "pokej.currentUser"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let username = defaults.string(forKey: storageKey),
           let account = AuthService.accounts.first(where: { $0.username == username }) {
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

    func logout() {
        currentUser = nil
        defaults.removeObject(forKey: storageKey)
    }
}
