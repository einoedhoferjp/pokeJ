import Foundation

/// Eine gezogene Karte aus einem fiktiven Booster.
struct PackPull: Identifiable, Hashable, Sendable {
    let id = UUID()
    let card: CatalogCard
    let set: CatalogSet
    let printing: Printing

    var isHolo: Bool { printing == .holo }
}

/// Öffnet fiktive Booster zufällig aus dem gebündelten Offline-Katalog.
enum PackOpener {
    /// Wahrscheinlichkeit, dass eine nicht garantierte Karte als Holo fällt.
    static let baseHoloChance = 0.15

    static func open(_ pack: PackDefinition, from sets: [CatalogSet]) -> [PackPull] {
        var rng = SystemRandomNumberGenerator()
        return open(pack, from: sets, rng: &rng)
    }

    /// Zieht `cardCount` unterschiedliche Karten aus dem Katalog und verteilt
    /// die Druckvarianten. Tests injizieren eine seedbare Zufallsquelle.
    static func open(
        _ pack: PackDefinition,
        from sets: [CatalogSet],
        rng: inout some RandomNumberGenerator
    ) -> [PackPull] {
        let pool = sets.flatMap { set in
            set.cards.map { card in (card: card, set: set) }
        }
        guard !pool.isEmpty else { return [] }

        let count = Swift.min(pack.cardCount, pool.count)
        var indices = Set<Int>()
        while indices.count < count {
            indices.insert(Int.random(in: 0..<pool.count, using: &rng))
        }

        var pulls = indices.map { PackPull(card: pool[$0].card, set: pool[$0].set, printing: .normal) }

        if pack.holoGuarantee > 0 {
            var order = Array(pulls.indices)
            order.shuffle(using: &rng)
            for index in 0..<Swift.min(pack.holoGuarantee, order.count) {
                let target = order[index]
                pulls[target] = PackPull(card: pulls[target].card, set: pulls[target].set, printing: .holo)
            }
        }

        for index in pulls.indices
        where pulls[index].printing == .normal
            && Double.random(in: 0..<1, using: &rng) < baseHoloChance {
            pulls[index] = PackPull(card: pulls[index].card, set: pulls[index].set, printing: .holo)
        }

        return pulls.shuffled(using: &rng)
    }
}