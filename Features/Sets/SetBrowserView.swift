import SwiftData
import SwiftUI

/// Browser für den gebündelten Gesamtkatalog (alle Sets/Karten der Quelle).
struct SetBrowserView: View {
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \WishCard.createdAt, order: .reverse) private var wishes: [WishCard]

    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number
    @State private var showsOwnedOnly = false

    private let allSets = PokemonCatalog.sets
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    /// Lokale Kartennummern je Set, die in der Sammlung vorkommen.
    private var ownedPerSet: [String: Set<String>] {
        var map: [String: Set<String>] = [:]
        for item in items {
            guard let card = item.variant?.card else { continue }
            map[card.setId, default: []].insert(card.localId)
        }
        return map
    }

    /// Gewünschte Karten je Set (Wunschliste).
    private var wishesPerSet: [String: Int] {
        Dictionary(grouping: wishes, by: \.setId).mapValues(\.count)
    }

    private var visibleSets: [CatalogSet] {
        let owned = ownedPerSet
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allSets.filter { set in
            if showsOwnedOnly, (owned[set.id]?.isEmpty ?? true) { return false }
            guard !trimmed.isEmpty else { return true }
            let name = set.name.lowercased()
            let id = set.id.lowercased()
            switch searchMode {
            case .number:
                return id.contains(trimmed) || name == trimmed
            case .text:
                return name.contains(trimmed) || id.contains(trimmed)
            }
        }
    }

    private var totalOwnedCards: Int {
        ownedPerSet.values.reduce(0) { $0 + $1.count }
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
                        if totalOwnedCards > 0 {
                            progressSummary
                        }
                        LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                            ForEach(visibleSets) { set in
                                NavigationLink {
                                    SetDetailView(set: set)
                                } label: {
                                    SetGridCell(
                                        set: set,
                                        ownedCount: ownedPerSet[set.id]?.count ?? 0,
                                        wishedCount: wishesPerSet[set.id] ?? 0
                                    )
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
                    Toggle(isOn: $showsOwnedOnly) {
                        Label("Fortschritt", systemImage: "chart.pie.fill")
                    }
                    .toggleStyle(.button)
                    .tint(showsOwnedOnly ? AppTheme.mint : nil)
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

    /// Kopfzeile mit gesammeltem Set-Fortschritt.
    private var progressSummary: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.pie.fill")
                .foregroundStyle(AppTheme.mint)
            Text("\(totalOwnedCards) von \(PokemonCatalog.shared.cardCount) Katalogkarten gesammelt")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.mint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(AppTheme.mint.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
        .padding(.top, 8)
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
    var ownedCount: Int = 0
    var wishedCount: Int = 0

    private var thumbnailURL: URL? {
        return set.cards.first(where: { $0.image != nil })?.thumbnailURL
    }

    private var fraction: Double {
        guard set.cards.count > 0 else { return 0 }
        return Double(min(ownedCount, set.cards.count)) / Double(set.cards.count)
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
                        if ownedCount > 0 {
                            completionBadge
                        } else {
                            Text("\(set.cards.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.5), in: Capsule())
                        }
                    }
                    .padding(8)
                }

                if ownedCount == 0, wishedCount > 0 {
                    VStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(AppTheme.coral, in: Circle())
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }

            Text(set.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)

            if ownedCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: fraction)
                        .tint(AppTheme.mint)
                    Text("\(ownedCount)/\(set.cards.count) gesammelt")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
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
                .strokeBorder(ownedCount > 0 ? AppTheme.mint.opacity(0.30) : AppTheme.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .animation(AppTheme.Motion.smooth, value: ownedCount)
    }

    /// Kleiner Fortschritts-Ring als Sticker auf der Kachel.
    private var completionBadge: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(AppTheme.mint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((fraction * 100).rounded()))")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 30, height: 30)
        .background(Circle().fill(.black.opacity(0.55)))
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
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \WishCard.createdAt, order: .reverse) private var wishes: [WishCard]
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .number
    @State private var selected: CatalogCard?

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: AppTheme.gridSpacing)]

    /// Externe IDs der Set-Karten, die bereits in der Sammlung sind.
    private var ownedCardIds: Set<String> {
        Set(
            items.compactMap { item -> String? in
                guard let card = item.variant?.card, card.setId == set.id else { return nil }
                return card.externalId
            }
        )
    }

    private var wishedCardIds: Set<String> {
        Set(wishes.filter { $0.setId == set.id }.map(\.externalId))
    }

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
            completionHeader
            LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                ForEach(visibleCards) { card in
                    Button {
                        selected = card
                    } label: {
                        CatalogCardCell(
                            card: card,
                            isOwned: ownedCardIds.contains(card.id),
                            isWished: wishedCardIds.contains(card.id)
                        )
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

    /// Fortschritts-Header: wie viele Karten des Sets besitzt du bereits?
    @ViewBuilder
    private var completionHeader: some View {
        let owned = ownedCardIds.count
        if owned > 0 || !wishedCardIds.isEmpty {
            let fraction = set.cards.isEmpty
                ? 0.0
                : Double(min(owned, set.cards.count)) / Double(set.cards.count)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(AppTheme.mint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int((fraction * 100).rounded()))%")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(AppTheme.mint)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(owned) von \(set.cards.count) Karten")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    if !wishedCardIds.isEmpty {
                        Label("\(wishedCardIds.count) auf deiner Wunschliste", systemImage: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.coral)
                    } else {
                        Text("Tippe auf eine Karte für Details und Preise.")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(AppTheme.elevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(owned > 0 ? AppTheme.mint.opacity(0.3) : AppTheme.stroke, lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

private struct CatalogCardCell: View {
    let card: CatalogCard
    var isOwned: Bool = false
    var isWished: Bool = false

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

                if isOwned {
                    Color.black.opacity(0.25)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous))
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.mint)
                        .shadow(color: AppTheme.mint.opacity(0.8), radius: 6)
                }

                VStack {
                    HStack {
                        if isWished {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(AppTheme.coral, in: Circle())
                        }
                        Spacer()
                    }
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
                .padding(6)
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