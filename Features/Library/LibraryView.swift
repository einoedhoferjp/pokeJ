import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(PriceRefreshCoordinator.self) private var priceRefresher
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var points: PointsStore
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \PriceSnapshot.fetchedAt, order: .reverse) private var allSnapshots: [PriceSnapshot]

    @State private var filter = LibraryFilter()
    @State private var activeSheet: LibrarySheet?
    @State private var showingEmptyState = false

    private enum LibrarySheet: Identifiable {
        case scanner
        case add

        var id: String { rawValue }
        var rawValue: String {
            switch self {
            case .scanner: return "scanner"
            case .add: return "add"
            }
        }
    }

    private var realItems: [CollectionItem] {
        items.filter { $0.origin == .scanned }
    }

    private var visibleItems: [CollectionItem] {
        var effective = filter
        effective.marketPrices = CollectionStats.unitPrices(items: realItems, snapshots: allSnapshots)
        return effective.apply(to: realItems)
    }

    var body: some View {
        NavigationStack {
            Group {
                if realItems.isEmpty {
                    emptyLibraryState
                } else if visibleItems.isEmpty {
                    emptySearchState
                } else {
                    content
                }
            }
            .navigationTitle("Sammlung")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $filter.searchText, prompt: "Karte oder Set suchen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Suchmodus", selection: $filter.searchMode) {
                        ForEach(LibrarySearchMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let user = auth.currentUser {
                            Section(user.displayName) {
                                Label(user.username, systemImage: "person.crop.circle")
                            }
                        }
                        Button(role: .destructive) {
                            auth.logout()
                        } label: {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Section("Daten") {
                            NavigationLink {
                                DataExportView()
                            } label: {
                                Label("Export / Backup", systemImage: "square.and.arrow.up.on.square")
                            }
                        }
                        Section("Diagnose") {
                            NavigationLink {
                                DeviceDiagnosticsView()
                            } label: {
                                Label("Gerätetest", systemImage: "stethoscope")
                            }
                        }
                    } label: {
                        Label("Konto", systemImage: "person.crop.circle")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(points.balance) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .font(.caption)
                        .accessibilityLabel("Punktestand \(points.balance)")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .scanner
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: AppTheme.minTouchTarget, height: AppTheme.minTouchTarget)
                            .background(AppTheme.brandGradient, in: Circle())
                            .shadow(color: AppTheme.accent.opacity(0.5), radius: 12, y: 6)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: AppTheme.minTouchTarget, height: AppTheme.minTouchTarget)
                            .background(AppTheme.accent, in: Circle())
                            .shadow(color: AppTheme.accent.opacity(0.5), radius: 12, y: 6)
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { activeSheet == .scanner },
                set: { if !$0 { activeSheet = nil } }
            )) {
                ScannerView()
            }
            .sheet(isPresented: Binding(
                get: { activeSheet == .add },
                set: { if !$0 { activeSheet = nil } }
            )) {
                AddEditCardView(mode: .add)
            }
            .onAppear {
                SeedLoader.bootstrap(in: context)
            }
            .task(id: realItems.count) {
                await priceRefresher.autoRefreshIfDue(
                    items: realItems,
                    username: auth.currentUser?.username,
                    context: context
                )
            }
            .onChange(of: filter.searchText) { _, text in
                if text.isEmpty { filter.searchMode = .number }
            }
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
    }

    // MARK: - Leer-Zustände

    private var emptyLibraryState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.textTertiary)
            Text("Deine Sammlung ist noch leer")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text("Scanne oder füge deine erste Pokémon-Karte hinzu.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                Button {
                    activeSheet = .scanner
                } label: {
                    Label("Karte scannen", systemImage: "camera.viewfinder")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(BrandButtonStyle())

                Button {
                    activeSheet = .add
                } label: {
                    Label("Manuell hinzufügen", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textTertiary)
            Text("Keine Treffer")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text("Passe deine Suche oder Filter an.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    // MARK: - Inhalt

    private var content: some View {
        VStack(spacing: 0) {
            valueSummary
            filterBar
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: AppTheme.gridSpacing)], spacing: AppTheme.gridSpacing) {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            CardDetailView(item: item)
                        } label: {
                            CollectionItemCard(item: item)
                        }
                        .buttonStyle(PressableCardStyle())
                        .contextMenu {
                            Menu {
                                ForEach(CardCondition.allCases) { condition in
                                    Button {
                                        setCondition(item, to: condition)
                                    } label: {
                                        Label(condition.displayName, systemImage: item.confirmedCondition == condition ? "checkmark" : condition.systemImage)
                                    }
                                }
                            } label: {
                                Label("Zustand ändern", systemImage: "checkmark.shield")
                            }
                            Button {
                                duplicate(item)
                            } label: {
                                Label("Duplikat hinzufügen (+1)", systemImage: "plus.square.on.square")
                            }
                            Button {
                                item.purchaseDate = .now
                                try? context.save()
                            } label: {
                                Label("Kaufdatum auf heute setzen", systemImage: "calendar.badge.plus")
                            }
                            Button(role: .destructive) {
                                context.delete(item)
                                try? context.save()
                            } label: {
                                Label("Löschen", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .animation(AppTheme.Motion.smooth, value: visibleItems.count)
            }
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Menu {
                    Button("Alle Sprachen") { filter.language = nil }
                    ForEach(Language.allCases) { language in
                        Button(language.displayName) { filter.language = language }
                    }
                } label: {
                    filterChip(title: "Sprache", value: filter.language?.displayName ?? "Alle", icon: "globe")
                }

                Menu {
                    Button("Alle Zustände") { filter.condition = nil }
                    ForEach(CardCondition.allCases) { condition in
                        Button(condition.displayName) { filter.condition = condition }
                    }
                } label: {
                    filterChip(title: "Zustand", value: filter.condition?.displayName ?? "Alle", icon: "checkmark.shield")
                }

                Menu {
                    ForEach(LibrarySort.allCases) { sort in
                        Button(sort.displayName) { filter.sort = sort }
                    }
                } label: {
                    filterChip(title: "Sortierung", value: filter.sort.displayName, icon: "arrow.up.arrow.down")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(AppTheme.elevated.opacity(0.5))
    }

    /// Setzt den bestätigten Zustand direkt aus dem Kontextmenü heraus.
    private func setCondition(_ item: CollectionItem, to condition: CardCondition) {
        item.confirmedCondition = condition
        try? context.save()
    }

    /// Legt ein weiteres Exemplar derselben Karte an (QoL: Duplikat +1).
    private func duplicate(_ item: CollectionItem) {
        item.quantity += 1
        try? context.save()
    }

    private func filterChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().strokeBorder(AppTheme.stroke, lineWidth: 1))
    }

    // MARK: - Preise

    private var collectionValue: CollectionValue {
        CollectionStats.value(items: realItems, snapshots: allSnapshots)
    }

    @ViewBuilder
    private var priceStatus: some View {
        PriceRefreshStatusText(username: auth.currentUser?.username, note: priceRefresher.note)
    }

    private var valueSummary: some View {
        let value = collectionValue
        return PokedexPanel(title: "Sammlung", statusLED: AppTheme.ledGold) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sammlungswert")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(PriceFormatting.currency(value.total, code: value.currency))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                    }
                    Spacer()
                    if priceRefresher.isRefreshing {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                await priceRefresher.refresh(
                                    items: realItems,
                                    username: auth.currentUser?.username,
                                    context: context
                                )
                            }
                        } label: {
                            Label("Aktualisieren", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                HStack(spacing: 12) {
                    Label("\(totalQuantity) Karten", systemImage: "shippingbox")
                    if value.unpricedCount > 0 {
                        Label("\(value.unpricedCount) ohne Preis", systemImage: "questionmark.circle")
                    }
                    if value.staleCount > 0 {
                        Label("\(value.staleCount) veraltet", systemImage: "exclamationmark.triangle")
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                priceStatus
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var totalQuantity: Int {
        realItems.reduce(0) { $0 + $1.quantity }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AuthStore())
        .environmentObject(PointsStore())
        .environment(PriceRefreshCoordinator(provider: MockPriceProvider()))
        .modelContainer(PreviewData.container)
}

enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([Card.self, CardVariant.self, CollectionItem.self, PriceSnapshot.self, ScanRecord.self, ConditionAssessment.self, WishCard.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview-ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()
}