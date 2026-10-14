import SwiftUI

@main
struct PokeJApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
        }
    }
}
