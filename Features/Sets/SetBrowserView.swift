import SwiftUI

/// Browser für den gebündelten Gesamtkatalog (alle Sets/Karten der Quelle).
struct SetBrowserView: View {
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number

    private let allSets = PokemonCatalog.sets
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var visibleSets: [CatalogSet] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return allSets }
        return allSets.filter {
            let name = $0.name.lowercased()
            let id = $0.id.lowercased()
            switch searchMode {
            case .number:
                return id.contains(trimmed) || name == trimmed
            case .text:
                return name.contains(trimmed) || id.contains(trimmed)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allSets.isEmpty {
                    ContentUnavailableView(
                        "Kein Katalog",
                        systemImage: "square.grid.2x2",
                        description: Text("Der Offline-Katalog wurde nicht gefunden.")
                    )
                } else if visibleSets.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(visibleSets) { set in
                                NavigationLink {
                                    SetDetailView(set: set)
                                } label: {
                                    SetGridCell(set: set)
                                }
                                .buttonStyle(PressableCardStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Alle Sets")
            .searchable(text: $searchText, prompt: searchMode.placeholder)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Suchmodus", selection: $searchMode) {
                        ForEach(SearchMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(allSets.count) Sets · \(PokemonCatalog.shared.cardCount) Karten")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct SetGridCell: View {
    let set: CatalogSet

    private var thumbnailURL: URL? {
        return set.cards.first(where: { $0.image != nil })?.thumbnailURL
    }

    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    placeholder
                case .empty:
                    ZStack { placeholder; ProgressView() }
                @unknown default:
                    placeholder
                }
            }
            .aspectRatio(0.72, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(set.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity)

            Text("\(set.cards.count)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .surfaceCard(radius: AppTheme.cardRadiusSmall, padding: 6)
        .card3D(maxTilt: 8)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppTheme.goldGradient)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
    }
}

/// Kartenraster eines Sets.
struct SetDetailView: View {
    let set: CatalogSet
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number
    @State private var selected: CatalogCard?

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 10)]

    private var visibleCards: [CatalogCard] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return set.cards }
        return set.cards.filter {
            let name = $0.name.lowercased()
            let localId = $0.localId.lowercased()
            let id = $0.id.lowercased()
            switch searchMode {
            case .number:
                let t = trimmed.replacingOccurrences(of: "/", with: "")
                let lid = localId.replacingOccurrences(of: "/", with: "")
                return lid.contains(t) || localId == trimmed || id.contains(trimmed)
            case .text:
                return name.contains(trimmed) || localId.contains(trimmed) || id.contains(trimmed)
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                ForEach(visibleCards) { card in
                    Button {
                        selected = card
                    } label: {
                        CatalogCardCell(card: card)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding()
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
        .navigationTitle(set.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: searchMode.placeholder)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Suchmodus", selection: $searchMode) {
                    ForEach(SearchMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selected) { card in
            CatalogCardDetailView(card: card, set: set)
        }
    }
}

private struct CatalogCardCell: View {
    let card: CatalogCard

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: card.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    placeholder
                case .empty:
                    ZStack { placeholder; ProgressView() }
                @unknown default:
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(card.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(AppTheme.ink)
            Text("#\(card.localId)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .surfaceCard(radius: AppTheme.cardRadiusSmall, padding: 6)
        .card3D(maxTilt: 10)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
    }
}
