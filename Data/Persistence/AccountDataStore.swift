import Foundation
import SwiftData

/// Baut je Benutzerkonto einen eigenen SwiftData-Speicher, damit jede Sammlung
/// (Karten, Scans, Preise) getrennt gespeichert wird.
enum AccountDataStore {
    /// Inhaber des bisherigen, gemeinsamen Speichers. Dessen Daten werden bei
    /// Bedarf einmalig in den kontogebundenen Speicher übernommen.
    static let legacyOwnerKey = "berli"

    static var schema: Schema {
        Schema([
            Card.self,
            CardVariant.self,
            CollectionItem.self,
            PriceSnapshot.self,
            ScanRecord.self,
            ConditionAssessment.self
        ])
    }

    static func container(for username: String) throws -> ModelContainer {
        migrateLegacyStoreIfNeeded(for: username)
        let url = try storeURL(for: username)
        let configuration = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func storeURL(for username: String) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base
            .appendingPathComponent("PokeJ", isDirectory: true)
            .appendingPathComponent("Accounts", isDirectory: true)
            .appendingPathComponent(AccountStorage.storageKey(for: username), isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("store.sqlite")
    }

    private static func migrateLegacyStoreIfNeeded(for username: String) {
        guard username.lowercased() == legacyOwnerKey,
              let legacy = findLegacyStore(),
              let target = try? storeURL(for: username),
              !FileManager.default.fileExists(atPath: target.path) else { return }

        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacy.path + suffix)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            try? FileManager.default.moveItem(at: source, to: URL(fileURLWithPath: target.path + suffix))
        }
    }

    private static func findLegacyStore() -> URL? {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        let folder = support.appendingPathComponent(Bundle.main.bundleIdentifier ?? "PokeJ", isDirectory: true)
        let contents = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return contents.first { $0.pathExtension == "store" }
    }
}
