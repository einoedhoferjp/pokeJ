import SwiftUI

/// Wurzelansicht: zeigt den Login oder die Bibliothek, je nach Sitzung.
struct RootView: View {
    @StateObject private var auth = AuthStore()
    @StateObject private var points = PointsStore()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                TabView {
                    LibraryView()
                        .tabItem { Label("Sammlung", systemImage: "rectangle.stack.fill") }
                    PackShopView()
                        .tabItem { Label("Packs", systemImage: "gift.fill") }
                    SetBrowserView()
                        .tabItem { Label("Sets", systemImage: "square.grid.2x2.fill") }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                LoginView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .environmentObject(auth)
        .environmentObject(points)
        .rewardBanner(points: points)
        .background(AppTheme.appBackground.ignoresSafeArea())
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: auth.isAuthenticated)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
