import SwiftUI

@main
struct PokeJApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
                // Hält die Cardmarket-Preise frisch, auch wenn die App nicht
                // geöffnet wird. iOS bestimmt den Zeitpunkt (Best-Effort).
                .backgroundTask(.appRefresh(PriceRefreshTask.identifier)) {
                    await PriceRefreshTask.run()
                }
        }
    }
}
