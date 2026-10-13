import Foundation

/// Offline-Kartenquelle für Phase 1. Sucht im lokalen Seed-Katalog.
struct MockCardDataProvider: CardDataProvider {
    let catalog: [CardDTO]

    init(catalog: [CardDTO] = SeedCatalog.cards) {
        self.catalog = catalog
    }

    func searchCards(_ query: CardQuery) async throws -> [CardBrief] {
        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let localId = query.localId?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return catalog
            .filter { query.setId == nil || $0.setId == query.setId }
            .filter { card in
                if let localId, !localId.isEmpty, card.localId.lowercased() != localId {
                    return false
                }
                guard !text.isEmpty else { return true }
                return card.name.lowercased().contains(text) || card.localId.lowercased() == text
            }
            .map { card in
                CardBrief(
                    id: card.id,
                    name: card.name,
                    setId: card.setId,
                    setName: card.setName,
                    localId: card.localId,
                    rarity: card.rarity,
                    imageURL: card.imageURL
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func card(externalId: String, language: Language) async throws -> CardDTO {
        guard let card = catalog.first(where: { $0.id == externalId }) else {
            throw CardDataError.notFound
        }
        return card
    }

    func sets(language: Language) async throws -> [SetBrief] {
        let grouped = Dictionary(grouping: catalog, by: { $0.setId })
        return grouped
            .map { SetBrief(id: $0.key, name: $0.value.first?.setName ?? $0.key) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
