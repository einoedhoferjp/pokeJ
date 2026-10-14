import Foundation

/// Persistiert die lokalen Benutzerkonten als JSON-Datei und legt beim ersten
/// Start die Demo-Konten als Startbestand an. Jedes Konto besitzt dadurch einen
/// eigenen Benutzernamen und ein eigenes Passwort (SHA-256 + Salt).
final class AccountStorage {
    static let shared = AccountStorage()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "pokej.accountstorage")
    private var cached: [AuthAccount]

    init(fileURL: URL = AccountStorage.defaultFileURL()) {
        self.fileURL = fileURL
        if let stored = try? Self.read(from: fileURL), !stored.isEmpty {
            cached = stored
        } else {
            cached = AuthService.seedAccounts
            try? Self.write(cached, to: fileURL)
        }
    }

    var accounts: [AuthAccount] {
        queue.sync { cached }
    }

    func account(named username: String) -> AuthAccount? {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return accounts.first { $0.username.lowercased() == name }
    }

    @discardableResult
    func register(username: String, password: String, displayName: String) -> AuthAccount? {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidUsername(name), password.count >= 6 else { return nil }
        guard account(named: name) == nil else { return nil }

        let salt = UUID().uuidString
        let account = AuthAccount(
            username: name,
            salt: salt,
            hash: AuthService.hash(password: password, salt: salt),
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? name
                : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        queue.sync {
            cached.append(account)
            try? Self.write(cached, to: fileURL)
        }
        return account
    }

    static func isValidUsername(_ name: String) -> Bool {
        guard (3...24).contains(name.count) else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == " " || $0 == "-" || $0 == "_" || $0 == "." }
    }

    /// Dateisystem-sicherer Schlüssel für Ordner- und UserDefaults-Namen.
    static func storageKey(for username: String) -> String {
        let key = username.lowercased().filter { $0.isLetter || $0.isNumber }
        return key.isEmpty ? "account" : key
    }

    private static func defaultFileURL() -> URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("PokeJ", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("accounts.json")
    }

    private static func read(from url: URL) throws -> [AuthAccount] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([AuthAccount].self, from: data)
    }

    private static func write(_ accounts: [AuthAccount], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(accounts).write(to: url, options: .atomic)
    }
}
