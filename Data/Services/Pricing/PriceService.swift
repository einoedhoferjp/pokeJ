import Foundation
import SwiftData

/// Orchestriert das Aktualisieren der Preise für eine Sammlung: Ziele ableiten,
/// abrufen, speichern und die Cardmarket-Produkt-ID an der Variante setzen.
@MainActor
struct PriceService {
    let provider: PriceProvider
    let context: ModelContext

    struct Summary: Equatable {
        let insertedSnapshots: Int
        let updatedVariants: Int
        let failedTargets: Int
    }

    func refresh(items: [CollectionItem], now: Date = .now) async -> Summary {
        let repository = PriceRepository(context: context)

        var variantsByTarget: [PriceRefreshTarget: [CardVariant]] = [:]
        for item in items {
            guard let variant = item.variant, let card = variant.card else { continue }
            let target = PriceRefreshTarget(
                externalCardId: card.externalId,
                printing: variant.printing,
                language: variant.language
            )
            variantsByTarget[target, default: []].append(variant)
        }

        let results = await RefreshPricesUseCase(provider: provider).fetch(targets: Array(variantsByTarget.keys))

        var inserted = 0
        var updated = 0
        var failed = 0
        for result in results {
            if result.failed {
                failed += 1
                continue
            }
            inserted += repository.saveIfChanged(result.snapshots)
            if let productId = result.snapshots.compactMap({ $0.productId }).first {
                for variant in variantsByTarget[result.target] ?? [] where variant.cardmarketProductId != productId {
                    variant.cardmarketProductId = productId
                    updated += 1
                }
            }
        }

        if updated > 0 { try? context.save() }
        return Summary(insertedSnapshots: inserted, updatedVariants: updated, failedTargets: failed)
    }
}
