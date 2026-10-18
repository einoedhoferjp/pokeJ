import SwiftUI

@main
struct PokeJApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
        }
        // Hält die Cardmarket-Preise frisch, auch wenn die App nicht geöffnet
        // wird. iOS bestimmt Zeitpunkt und Häufigkeit (Best-Effort, üblich ist
        // etwa ein Lauf pro Tag); der Lauf prüft selbst die 24-Stunden-Kadenz.
        .backgroundTask(.appRefresh(PriceRefreshTask.identifier)) {
            await PriceRefreshTask.run()
        }
    }
}
