import SwiftUI

/// Browser für den gebündelten Gesamtkatalog (alle Sets/Karten der Quelle).
struct SetBrowserView: View {
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number

    private let allSets = PokemonCatalog.sets

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
                        LazyVStack(spacing: 12) {
                            ForEach(visibleSets) { set in
                                NavigationLink {
                                    SetDetailView(set: set)
                                } label: {
                                    SetSummaryRow(set: set)
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
                    Text("\(allSets.count) Sets �� \(PokemonCatalog.shared.cardCount) Karten")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SetSummaryRow: View {
    let set: CatalogSet

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.goldGradient)
                    .frame(width: 54, height: 54)
                if let url = set.cards.first(where: { $0.image != nil })?.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(set.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(set.cards.count) Karten · \(set.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
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
            LazyVGrid(columns: columns, spacing: 10) {
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
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.primary)
            Text("#\(card.localId)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppTheme.surface)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
    }
}
