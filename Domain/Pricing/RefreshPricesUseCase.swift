import Foundation

/// Ein eindeutiges Preis-Abrufziel: Karte + Druckvariante + Sprache.
struct PriceRefreshTarget: Hashable {
    let externalCardId: String
    let printing: Printing
    let language: Language
}

/// Ergebnis eines Abrufs pro Ziel.
struct PriceRefreshResult: Equatable {
    let target: PriceRefreshTarget
    let snapshots: [PriceSnapshotDTO]
    let failed: Bool
}

/// Ruft Preise für eine Menge von Zielen ab. Dedupliziert identische Ziele und
/// verschluckt einzelne Fehler, damit ein Ausfall nie die ganze Sammlung
/// blockiert.
///
/// Die Abrufe laufen mit **begrenzter Parallelität**: bei großen Sammlungen
/// dauert ein vollständiger Durchlauf so wenige Sekunden statt vieler Minuten,
/// ohne TCGdex mit hunderten gleichzeitigen Requests zu belasten.
struct RefreshPricesUseCase {
    let provider: PriceProvider
    let maxConcurrent: Int

    init(provider: PriceProvider, maxConcurrent: Int = 6) {
        self.provider = provider
        self.maxConcurrent = maxConcurrent
    }

    func fetch(targets: [PriceRefreshTarget]) async -> [PriceRefreshResult] {
        var unique: [PriceRefreshTarget] = []
        var seen = Set<PriceRefreshTarget>()
        for target in targets where seen.insert(target).inserted {
            unique.append(target)
        }
        guard !unique.isEmpty else { return [] }

        let width = max(1, min(maxConcurrent, unique.count))
        var collected = [PriceRefreshResult?](repeating: nil, count: unique.count)

        await withTaskGroup(of: (Int, PriceRefreshResult).self) { group in
            var next = 0
            while next < width {
                let index = next
                group.addTask { (index, await Self.fetchOne(unique[index], using: provider)) }
                next += 1
            }
            while let (index, result) = await group.next() {
                collected[index] = result
                if next < unique.count {
                    let later = next
                    group.addTask { (later, await Self.fetchOne(unique[later], using: provider)) }
                    next += 1
                }
            }
        }

        return collected.compactMap { $0 }
    }

    private static func fetchOne(_ target: PriceRefreshTarget, using provider: PriceProvider) async -> PriceRefreshResult {
        do {
            let snapshots = try await provider.prices(
                externalCardId: target.externalCardId,
                printing: target.printing,
                language: target.language
            )
            return PriceRefreshResult(target: target, snapshots: snapshots, failed: false)
        } catch {
            return PriceRefreshResult(target: target, snapshots: [], failed: true)
        }
    }
}
