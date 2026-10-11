import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]

    @State private var filter = LibraryFilter()
    @State private var activeSheet: LibrarySheet?

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
            .searchable(text: $filter.searchText, prompt: "Name oder Kartennummer")
            .toolbar {
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
            filterBar
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            CardDetailView(item: item)
                        } label: {
                            CollectionItemCard(item: item)
                        }
                        .buttonStyle(.plain)
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
}

#Preview {
    LibraryView()
        .modelContainer(PreviewData.container)
}

enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([Card.self, CardVariant.self, CollectionItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Preview-ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()
}
