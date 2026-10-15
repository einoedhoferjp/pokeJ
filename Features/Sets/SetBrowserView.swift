import SwiftUI

/// Browser für den gebündelten Gesamtkatalog (alle Sets/Karten der Quelle).
struct SetBrowserView: View {
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number

    private let allSets = PokemonCatalog.sets
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

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
                    emptyState(
                        icon: "square.grid.2x2",
                        title: "Kein Katalog",
                        subtitle: "Der Offline-Katalog wurde nicht gefunden."
                    )
                } else if visibleSets.isEmpty {
                    emptyState(
                        icon: "magnifyingglass",
                        title: "Keine Treffer",
                        subtitle: "Passe deine Suche an."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
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
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Set suchen")
            .onChange(of: searchText) { _, text in
                if text.isEmpty { searchMode = .number }
            }
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
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textTertiary)
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct SetGridCell: View {
    let set: CatalogSet

    private var thumbnailURL: URL? {
        return set.cards.first(where: { $0.image != nil })?.thumbnailURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack { placeholder; ProgressView() }
                    @unknown default:
                        placeholder
                    }
                }
                .aspectRatio(0.72, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous))

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(set.cards.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                    .padding(8)
                }
            }

            Text(set.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSecondary)
            }
    }
}

/// Kartenraster eines Sets.
struct SetDetailView: View {
    let set: CatalogSet
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number
    @State private var selected: CatalogCard?

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: AppTheme.gridSpacing)]

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
        .searchable(text: $searchText, prompt: "Karte suchen")
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
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AsyncImage(url: card.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack { placeholder; ProgressView() }
                    @unknown default:
                        placeholder
                    }
                }
                .aspectRatio(0.72, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous))

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("#\(card.localId)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                    .padding(6)
                }
            }

            Text(card.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(AppTheme.textSecondary)
            }
    }
}