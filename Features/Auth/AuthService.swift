import CryptoKit
import Foundation

/// Ein lokaler Probe-Account. Passwörter werden nie im Klartext gespeichert,
/// sondern als mit einem Salt versehener SHA-256-Hash.
struct AuthAccount: Identifiable, Sendable, Equatable {
    let username: String
    let salt: String
    let hash: String
    let displayName: String

    var id: String { username }
}

/// Lokale Anmeldung ohne Server. Nur für die App-interne Demo gedacht.
enum AuthService {
    /// Probeaccounts. Zugangsdaten sind bewusst dokumentiert (Demo).
    static let accounts: [AuthAccount] = [
        AuthAccount(
            username: "admin",
            salt: "pqj-admin-2026",
            hash: "c49907f600bc19c4b5f140ef786593286a9b5182f948b312dda228fb4f32d2b0",
            displayName: "Administrator"
        ),
        AuthAccount(
            username: "pokefan",
            salt: "pqj-pokefan-2026",
            hash: "f93d4b303629c09339db014f33c6fa4553999dc88c7043361f00fb5a95fc146f",
            displayName: "Pokéfan"
        ),
        AuthAccount(
            username: "test",
            salt: "pqj-test-2026",
            hash: "137aa5191964541057c110817102ff653abfb8110b28afede44cbb71a5182db4",
            displayName: "Testkonto"
        ),
        AuthAccount(
            username: "sammler",
            salt: "pqj-sammler-2026",
            hash: "8183c81d7f6ac55c1205f68f5b060b86f39cbf8810e54615e4ee8eff35618699",
            displayName: "Sammler"
        ),
        AuthAccount(
            username: "berli",
            salt: "pqj-berli-2026",
            hash: "52854b93a30b17733606a79e3166d11917c48995e59ee46b7c37765f21b4a07a",
            displayName: "Berli"
        )
    ]

    /// Dokumentation der Probe-Zugangsdaten (nur Anzeige).
    static let demoHint: [(username: String, password: String)] = [
        ("admin", "admin"),
        ("pokefan", "pikachu"),
        ("test", "test"),
        ("sammler", "glueckspilz"),
        ("berli", "test123")
    ]

    static func hash(password: String, salt: String) -> String {
        let data = Data((salt + password).utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func verify(username: String, password: String) -> AuthAccount? {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let account = accounts.first(where: { $0.username.lowercased() == name }) else {
            return nil
        }
        let candidate = hash(password: password, salt: account.salt)
        return constantTimeEquals(candidate, account.hash) ? account : nil
    }

    private static func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(lhs.utf8)
        let b = Array(rhs.utf8)
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for index in a.indices {
            result |= a[index] ^ b[index]
        }
        return result == 0
    }
}
