import Foundation

/// Sortieroptionen der Bibliothek.
enum LibrarySort: String, CaseIterable, Identifiable {
    case dateAdded, name, price, set

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dateAdded: return "Zuletzt hinzugefügt"
        case .name: return "Name"
        case .price: return "Preis"
        case .set: return "Set"
        }
    }
}

/// Reine, testbare Filter-/Sortierlogik für die Bibliothek.
struct LibraryFilter: Equatable {
    var searchText: String = ""
    var language: Language?
    var condition: CardCondition?
    var sort: LibrarySort = .dateAdded

    func apply(to items: [CollectionItem]) -> [CollectionItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var result = items.filter { item in
            let cardName = item.variant?.card?.name.lowercased() ?? ""
            let localId = item.variant?.card?.localId.lowercased() ?? ""
            let matchesText = trimmed.isEmpty || cardName.contains(trimmed) || localId == trimmed
            let matchesLanguage = language == nil || item.variant?.language == language
            let matchesCondition = condition == nil || item.confirmedCondition == condition
            return matchesText && matchesLanguage && matchesCondition
        }

        switch sort {
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .name:
            result.sort {
                ($0.variant?.card?.name ?? "").localizedCaseInsensitiveCompare($1.variant?.card?.name ?? "") == .orderedAscending
            }
        case .set:
            result.sort {
                ($0.variant?.card?.setName ?? "").localizedCaseInsensitiveCompare($1.variant?.card?.setName ?? "") == .orderedAscending
            }
        case .price:
            result.sort { ($0.purchasePrice ?? 0) > ($1.purchasePrice ?? 0) }
        }

        return result
    }
}
