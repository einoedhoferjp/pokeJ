import SwiftData
import SwiftUI

/// Eigener Bereich für Karten aus fiktiven Boostern – getrennt von der echten,
/// gescannten Sammlung. Preise spielen hier keine Rolle.
struct FictionalCollectionView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var points: PointsStore

    @Query(
        filter: #Predicate<CollectionItem> { $0.originRaw == "pack" },
        sort: \CollectionItem.createdAt,
        order: .reverse
    )
    private var items: [CollectionItem]

    @State private var searchText = ""

    private var visibleItems: [CollectionItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter { item in
            let card = item.variant?.card
            let name = card?.name ?? ""
            let set = card?.setName ?? ""
            return name.localizedCaseInsensitiveContains(query)
                || set.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Noch keine PokeJ-Karten",
                        systemImage: "sparkles",
                        description: Text("Öffne Booster im Packs-Tab, um deine PokeJ-Sammlung zu füllen.")
                    )
                } else if visibleItems.isEmpty {
                    ContentUnavailableView(
                        "Keine Treffer",
                        systemImage: "magnifyingglass",
                        description: Text("Passe deine Suche an.")
                    )
                } else {
                    content
                }
            }
            .navigationTitle("PokeJ")
            .searchable(text: $searchText, prompt: "Name oder Set")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(points.balance) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .font(.caption)
                        .accessibilityLabel("Punktestand \(points.balance)")
                }
            }
            .onAppear {
                SeedLoader.bootstrap(in: context)
            }
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statsGrid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: AppTheme.gridSpacing)],
                    spacing: AppTheme.gridSpacing
                ) {
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
                .animation(AppTheme.Motion.smooth, value: visibleItems.count)
            }
            .padding()
        }
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            PokedexSectionHeader(title: "PokeJ-Sammlung", systemImage: "sparkles")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                StatTile(icon: "shippingbox.fill", value: "\(CollectionStats.totalQuantity(items))", label: "Karten")
                StatTile(icon: "rectangle.stack.fill", value: "\(CollectionStats.uniqueCardCount(items))", label: "Verschiedene")
                StatTile(icon: "square.grid.2x2.fill", value: "\(CollectionStats.setCount(items))", label: "Sets")
                StatTile(icon: "sparkles", value: "\(holoCount)", label: "Holo")
            }
        }
    }

    private var holoCount: Int {
        items.reduce(0) { count, item in
            item.variant?.printing == .holo ? count + item.quantity : count
        }
    }
}

#Preview {
    FictionalCollectionView()
        .environmentObject(PointsStore(defaults: UserDefaults(suiteName: "preview.fictional")!))
        .modelContainer(PreviewData.container)
}
