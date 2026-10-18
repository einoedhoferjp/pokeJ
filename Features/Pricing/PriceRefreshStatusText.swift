import SwiftUI

/// Zeigt an, wann die Preise zuletzt geholt wurden und wann die nächste
/// automatische Aktualisierung ansteht.
///
/// Macht die Aktualisierungslogik sichtbar: Vordergrund (App-Start/Öffnen) plus
/// iOS-Hintergrundlauf, Kadenz 24 Stunden.
struct PriceRefreshStatusText: View {
    let username: String?
    /// Meldung des letzten manuellen/automatischen Durchlaufs (optional).
    var note: String?

    private var log: PriceRefreshLog { PriceRefreshLog(username: username) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let note {
                Text(note)
            } else if let last = log.lastFullRefresh {
                Text("Preise aktualisiert \(PriceFormatting.relative(last, now: Date()))")
            } else {
                Text("Preise wurden noch nicht aktualisiert.")
            }

            if let next = log.nextAutomaticRefresh, next > Date() {
                Text("Nächste automatische Aktualisierung \(PriceFormatting.relative(next, now: Date())) – läuft auch im Hintergrund.")
            } else {
                Text("Automatische Aktualisierung läuft – auch im Hintergrund.")
            }
        }
        .font(.caption2)
        .foregroundStyle(AppTheme.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
