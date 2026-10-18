import Foundation

/// Sortieroptionen der Bibliothek.
enum LibrarySort: String, CaseIterable, Identifiable {
    case dateAdded, name, price, set

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dateAdded: return "Zuletzt hinzugefügt"
        case .name: return "Name"
        case .price: return "Wert (Markt/Kauf)"
        case .set: return "Set"
        }
    }
}

/// Reine, testbare Filter-/Sortierlogik für die Bibliothek.


struct LibraryFilter: Equatable {
    var searchText: String = ""
    var searchMode: LibrarySearchMode = .number
    var language: Language?
    var condition: CardCondition?
    var sort: LibrarySort = .dateAdded
    /// Marktwerte je Karte (externId → Preis), um nach Marktwert sortieren zu
    /// können, ohne die Logik an SwiftData zu koppeln.
    var marketPrices: [String: Decimal] = [:]

    func apply(to items: [CollectionItem]) -> [CollectionItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var result = items.filter { item in
            matches(item: item, query: trimmed)
                && matchesLanguage(item: item)
                && matchesCondition(item: item)
        }

        switch sort {
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .name:
            result.sort { cardName(of: $0).localizedCaseInsensitiveCompare(cardName(of: $1)) == .orderedAscending }
        case .set:
            result.sort { setName(of: $0).localizedCaseInsensitiveCompare(setName(of: $1)) == .orderedAscending }
        case .price:
            result.sort { value(of: $0) > value(of: $1) }
        }

        return result
    }

    /// Marktwert der Karte; fallback auf den Kaufpreis, wenn kein Marktpreis
    /// vorliegt (dann ohne Sortiergewicht).
    private func value(of item: CollectionItem) -> Decimal {
        if let externalId = item.variant?.card?.externalId, let market = marketPrices[externalId] {
            return market
        }
        return item.purchasePrice ?? 0
    }

    private func cardName(of item: CollectionItem) -> String {
        item.variant?.card?.name ?? ""
    }

    private func setName(of item: CollectionItem) -> String {
        item.variant?.card?.setName ?? ""
    }

    private func matchesLanguage(item: CollectionItem) -> Bool {
        language == nil || item.variant?.language == language
    }

    private func matchesCondition(item: CollectionItem) -> Bool {
        condition == nil || item.confirmedCondition == condition
    }

    private func matches(item: CollectionItem, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let cardName = (item.variant?.card?.name ?? "").lowercased()
        let localId = (item.variant?.card?.localId ?? "").lowercased()
        let externalId = (item.variant?.card?.externalId ?? "").lowercased()
        switch searchMode {
        case .number:
            let compactQuery = query.replacingOccurrences(of: "/", with: "")
            let compactLocal = localId.replacingOccurrences(of: "/", with: "")
            return localId == query
                || compactLocal.contains(compactQuery)
                || externalId.contains(query)
                || cardName == query
        case .text:
            return cardName.contains(query) || localId.contains(query)
        }
    }
}
