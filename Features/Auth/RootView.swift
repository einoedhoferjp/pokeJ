import SwiftData
import SwiftUI

/// Wurzelansicht: zeigt den Login oder die Tabs, je nach Sitzung. Jedes Konto
/// erhält einen eigenen SwiftData-Speicher und einen eigenen Punkte-Stand.
struct RootView: View {
    @StateObject private var auth: AuthStore
    @StateObject private var points: PointsStore
    @State private var container: ModelContainer?

    init() {
        let authStore = AuthStore()
        _auth = StateObject(wrappedValue: authStore)
        _points = StateObject(wrappedValue: PointsStore(username: authStore.currentUser?.username))
        _container = State(initialValue: authStore.currentUser.flatMap { account in
            try? AccountDataStore.container(for: account.username)
        })
    }

    var body: some View {
        Group {
            if auth.isAuthenticated, let container {
                TabView {
                    HomeView()
                        .tabItem { Label("Start", systemImage: "house.fill") }
                    LibraryView()
                        .tabItem { Label("Sammlung", systemImage: "rectangle.stack.fill") }
                    PackShopView()
                        .tabItem { Label("Packs", systemImage: "gift.fill") }
                    FictionalCollectionView()
                        .tabItem { Label("Fiktiv", systemImage: "sparkles") }
                    SetBrowserView()
                        .tabItem { Label("Sets", systemImage: "square.grid.2x2.fill") }
                }
                .modelContainer(container)
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
        .onChange(of: auth.currentUser?.username) { _, username in
            switchAccount(to: username)
        }
    }

    private func switchAccount(to username: String?) {
        points.configure(for: username)
        container = username.flatMap { try? AccountDataStore.container(for: $0) }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
