import SwiftData
import SwiftUI

/// Wurzelansicht: zeigt den Login oder die Tabs, je nach Sitzung. Jedes Konto
/// erhält einen eigenen SwiftData-Speicher und einen eigenen Punkte-Stand.
struct RootView: View {
    @StateObject private var auth: AuthStore
    @StateObject private var points: PointsStore
    @State private var container: ModelContainer?
    @State private var priceRefresher = PriceRefreshCoordinator()
    @Environment(\.scenePhase) private var scenePhase

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
                        .tabItem { Label("PokeJ", systemImage: "sparkles") }
                    SetBrowserView()
                        .tabItem { Label("Sets", systemImage: "square.grid.2x2.fill") }
                }
                .modelContainer(container)
                .environment(priceRefresher)
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
        // Preise beim Start prüfen …
        .task(id: auth.currentUser?.username) {
            await autoRefreshPricesIfDue()
        }
        // … und bei jeder Rückkehr in den Vordergrund.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await autoRefreshPricesIfDue() }
            }
        }
    }

    /// Stößt die Tagesaktualisierung der Preise an (No-Op, wenn nicht fällig).
    ///
    /// Liegt hier statt in den einzelnen Tabs, damit die Preise unabhängig vom
    /// gerade geöffneten Tab frisch sind.
    @MainActor
    private func autoRefreshPricesIfDue() async {
        guard auth.isAuthenticated, let container else { return }
        let context = container.mainContext
        let allItems = (try? context.fetch(FetchDescriptor<CollectionItem>())) ?? []
        let scanned = allItems.filter { $0.origin == .scanned }
        await priceRefresher.autoRefreshIfDue(
            items: scanned,
            username: auth.currentUser?.username,
            context: context
        )
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
