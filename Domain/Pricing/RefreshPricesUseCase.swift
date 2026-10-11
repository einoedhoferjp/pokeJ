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
struct RefreshPricesUseCase {
    let provider: PriceProvider

    func fetch(targets: [PriceRefreshTarget]) async -> [PriceRefreshResult] {
        var results: [PriceRefreshResult] = []
        var seen = Set<PriceRefreshTarget>()

        for target in targets where seen.insert(target).inserted {
            do {
                let snapshots = try await provider.prices(
                    externalCardId: target.externalCardId,
                    printing: target.printing,
                    language: target.language
                )
                results.append(PriceRefreshResult(target: target, snapshots: snapshots, failed: false))
            } catch {
                results.append(PriceRefreshResult(target: target, snapshots: [], failed: true))
            }
        }

        return results
    }
}
