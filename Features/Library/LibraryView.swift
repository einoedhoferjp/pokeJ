import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.priceProvider) private var priceProvider
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var points: PointsStore
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \PriceSnapshot.fetchedAt, order: .reverse) private var allSnapshots: [PriceSnapshot]

    @State private var filter = LibraryFilter()
    @State private var activeSheet: LibrarySheet?
    @State private var isRefreshing = false
    @State private var refreshNote: String?

    private enum LibrarySheet: Identifiable {
        case scanner
        case add

        var id: String {
            switch self {
            case .scanner: return "scanner"
            case .add: return "add"
            }
        }
    }

    private var visibleItems: [CollectionItem] {
        filter.apply(to: items)
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Keine Karten",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Füge deine erste Karte über das Plus-Symbol hinzu.")
                    )
                } else if visibleItems.isEmpty {
                    ContentUnavailableView(
                        "Keine Treffer",
                        systemImage: "magnifyingglass",
                        description: Text("Passe Suche oder Filter an.")
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Sammlung")
            .searchable(text: $filter.searchText, prompt: filter.searchMode.placeholder)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Suchmodus", selection: $filter.searchMode) {
                        ForEach(SearchMode.allCases) { mode in
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
                    } label: {
                        Label("Konto", systemImage: "person.crop.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Label("\(points.balance) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .font(.caption)
                        .accessibilityLabel("Punktestand \(points.balance)")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .scanner
                    } label: {
                        Label("Scannen", systemImage: "camera.viewfinder")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .scanner:
                    ScannerView()
                case .add:
                    AddEditCardView(mode: .add)
                }
            }
            .onAppear {
                SeedLoader.seedIfNeeded(in: context)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            valueSummary
            filterBar
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            CardDetailView(item: item)
                        } label: {
                            CollectionItemCard(item: item)
                        }
                        .buttonStyle(PressableCardStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                context.delete(item)
                                try? context.save()
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("Alle Sprachen") { filter.language = nil }
                    ForEach(Language.allCases) { language in
                        Button(language.displayName) { filter.language = language }
                    }
                } label: {
                    filterChip(title: "Sprache", value: filter.language?.displayName ?? "Alle")
                }

                Menu {
                    Button("Alle Zustände") { filter.condition = nil }
                    ForEach(CardCondition.allCases) { condition in
                        Button(condition.displayName) { filter.condition = condition }
                    }
                } label: {
                    filterChip(title: "Zustand", value: filter.condition?.displayName ?? "Alle")
                }

                Menu {
                    ForEach(LibrarySort.allCases) { sort in
                        Button(sort.displayName) { filter.sort = sort }
                    }
                } label: {
                    filterChip(title: "Sortierung", value: filter.sort.displayName)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15), in: Capsule())
    }

    // MARK: - Preise

    private var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    private var valueSummary: some View {
        let value = collectionValue
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sammlungswert")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(PriceFormatting.currency(value.total, code: value.currency))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                if isRefreshing {
                    ProgressView()
                } else {
                    Button {
                        Task { await refreshPrices() }
                    } label: {
                        Label("Preise aktualisieren", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
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
            .foregroundStyle(.secondary)
            if let refreshNote {
                Text(refreshNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var pointsByProduct: [String: [PricePoint]] {
        Dictionary(grouping: allSnapshots, by: { $0.cardmarketProductId }).mapValues { snapshots in
            snapshots.map {
                PricePoint(
                    productId: $0.cardmarketProductId,
                    metric: $0.metric,
                    amount: $0.amount,
                    currency: $0.currency,
                    fetchedAt: $0.fetchedAt,
                    source: $0.source,
                    matchQuality: $0.matchQuality
                )
            }
        }
    }

    private var collectionValue: CollectionValue {
        let now = Date()
        let valued = items.map { item -> ValuedItem in
            let printing = item.variant?.printing ?? .normal
            let points = item.variant?.cardmarketProductId.flatMap { pointsByProduct[$0] } ?? []
            let latest = PriceResolver.latest(points: points, printing: printing)
            let stale = latest.map { PriceFreshness.isStale(fetchedAt: $0.fetchedAt, now: now) } ?? false
            return ValuedItem(
                unitPrice: latest?.amount,
                quantity: item.quantity,
                isStale: stale,
                currency: latest?.currency ?? "EUR"
            )
        }
        return CollectionValueCalculator.compute(items: valued)
    }

    @MainActor
    private func refreshPrices() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshNote = nil
        let service = PriceService(provider: priceProvider, context: context)
        let summary = await service.refresh(items: items)
        isRefreshing = false

        var parts: [String] = []
        if summary.insertedSnapshots > 0 { parts.append("\(summary.insertedSnapshots) neue Preisstände") }
        if summary.updatedVariants > 0 { parts.append("\(summary.updatedVariants) Varianten aktualisiert") }
        if summary.failedTargets > 0 { parts.append("\(summary.failedTargets) fehlgeschlagen") }
        refreshNote = parts.isEmpty ? "Preise sind aktuell." : parts.joined(separator: " · ")
    }
}

#Preview {
    LibraryView()
        .environmentObject(AuthStore())
        .modelContainer(PreviewData.container)
}

enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([Card.self, CardVariant.self, CollectionItem.self, PriceSnapshot.self, ScanRecord.self, ConditionAssessment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview-ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()
}
