import Foundation
import SwiftData

/// Aktualisiert die Cardmarket-Preise im iOS-Hintergrund
/// („Background App Refresh").
///
/// Die App hat keinen eigenen Server und TCGdex liefert Cardmarket-Preise als
/// **Tageswerte**. Damit die Preise auch dann frisch bleiben, wenn die App
/// tagelang nicht geöffnet wird, registriert `PokeJApp` über
/// `.backgroundTask(.appRefresh(identifier))` diesen Lauf.
///
/// Wichtig: iOS entscheidet Zeitpunkt und Häufigkeit selbst (abhängig von
/// Nutzung, Ladezustand und Netz) – der Lauf ist also **Best-Effort**, üblich
/// ist etwa ein Lauf pro Tag. Deshalb prüft `run()` zusätzlich die
/// 24-Stunden-Kadenz und ist bei jedem weiteren Aufruf ein billiger No-Op.
enum PriceRefreshTask {
    /// Muss mit `BGTaskSchedulerPermittedIdentifiers` in der Info.plist
    /// übereinstimmen.
    static let identifier = "local.pokej.app.prices"

    @MainActor
    static func run() async {
        guard let username = AuthStore.storedUsername() else { return }
        guard let container = try? AccountDataStore.container(for: username) else { return }

        let context = container.mainContext
        let allItems = (try? context.fetch(FetchDescriptor<CollectionItem>())) ?? []
        let scanned = allItems.filter { $0.origin == .scanned }
        let log = PriceRefreshLog(username: username)

        guard !scanned.isEmpty, log.isRefreshDue() else { return }

        let service = PriceService(provider: TCGdexPriceProvider(), context: context)
        let summary = await service.refresh(items: scanned)
        log.recordAttempt(failed: summary.failedTargets)
    }
}
