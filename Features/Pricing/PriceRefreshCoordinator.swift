import Foundation
import Observation
import SwiftData

/// Führt die automatische Aktualisierung der Cardmarket-Preise an **einer**
/// Stelle aus und hält den Status für die Oberfläche.
///
/// Ohne diese Bündelung würden Startansicht, Sammlung und App-Start denselben
/// Durchlauf mehrfach anstoßen. Der Koordinator entscheidet anhand von
/// `PriceRefreshPolicy` (24-Stunden-Kadenz, Wiederholung nach Fehlern), ob
/// wirklich geladen wird.
@MainActor
@Observable
final class PriceRefreshCoordinator {
    /// `true`, solange ein Durchlauf läuft (steuert Spinner und Buttons).
    private(set) var isRefreshing = false

    /// Kurze Rückmeldung nach dem letzten Durchlauf (z. B. „3 neue Preisstände").
    private(set) var note: String?

    private let provider: PriceProvider

    init(provider: PriceProvider = TCGdexPriceProvider()) {
        self.provider = provider
    }

    /// Lädt nur, wenn die Tagesaktualisierung fällig ist. Wird beim App-Start,
    /// beim Wechsel in den Vordergrund und beim Öffnen der Preisansichten
    /// aufgerufen und ist dadurch mehrfach sicher auslösbar.
    func autoRefreshIfDue(items: [CollectionItem], username: String?, context: ModelContext) async {
        guard !items.isEmpty, !isRefreshing else { return }
        guard PriceRefreshLog(username: username).isRefreshDue() else { return }
        await refresh(items: items, username: username, context: context, announce: false)
    }

    /// Aktualisiert alle übergebenen Karten.
    ///
    /// `announce` steuert, ob die bisherige Statusmeldung vorher geleert wird
    /// (bei manueller Auslösung) oder sichtbar bleibt (Automatik).
    func refresh(
        items: [CollectionItem],
        username: String?,
        context: ModelContext,
        announce: Bool = true
    ) async {
        guard !items.isEmpty, !isRefreshing else { return }
        isRefreshing = true
        if announce { note = nil }

        let service = PriceService(provider: provider, context: context)
        let summary = await service.refresh(items: items)

        // Fehlgeschlagene Karten halten die Aktualisierung „fällig"; nur ein
        // fehlerfreier Lauf zählt als abgeschlossene Tagesaktualisierung.
        PriceRefreshLog(username: username).recordAttempt(failed: summary.failedTargets)
        isRefreshing = false

        var parts: [String] = []
        if summary.insertedSnapshots > 0 { parts.append("\(summary.insertedSnapshots) neue Preisstände") }
        if summary.updatedVariants > 0 { parts.append("\(summary.updatedVariants) Varianten aktualisiert") }
        if summary.failedTargets > 0 { parts.append("\(summary.failedTargets) fehlgeschlagen – neuer Versuch folgt") }
        note = parts.isEmpty ? "Preise sind aktuell." : parts.joined(separator: " · ")
    }
}
