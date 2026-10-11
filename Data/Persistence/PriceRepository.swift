import Foundation
import SwiftData

/// Persistenz-Zugriff auf gespeicherte Preisstände.
@MainActor
struct PriceRepository {
    let context: ModelContext

    func snapshots(productId: String, metric: PriceMetric? = nil) throws -> [PriceSnapshot] {
        let fetch = FetchDescriptor<PriceSnapshot>(
            predicate: #Predicate { $0.cardmarketProductId == productId },
            sortBy: [SortDescriptor(\PriceSnapshot.fetchedAt, order: .reverse)]
        )
        let all = try context.fetch(fetch)
        guard let metric else { return all }
        return all.filter { $0.metric == metric }
    }

    func latestSnapshot(productId: String, metric: PriceMetric) throws -> PriceSnapshot? {
        let raw = metric.rawValue
        let fetch = FetchDescriptor<PriceSnapshot>(
            predicate: #Predicate { $0.cardmarketProductId == productId && $0.metricRaw == raw },
            sortBy: [SortDescriptor(\PriceSnapshot.fetchedAt, order: .reverse)]
        )
        return try context.fetch(fetch).first
    }

    /// Fügt nur dann neue Datensätze ein, wenn sich Wert oder Währung gegenüber
    /// dem letzten Stand geändert haben. Bewahrt echte Historie, vermeidet Bloat.
    @discardableResult
    func saveIfChanged(_ dtos: [PriceSnapshotDTO]) -> Int {
        var inserted = 0
        for dto in dtos {
            let productId = dto.productId ?? ""
            if let latest = try? latestSnapshot(productId: productId, metric: dto.metric),
               latest.amount == dto.amount,
               latest.currency == dto.currency {
                continue
            }
            let snapshot = PriceSnapshot(
                cardmarketProductId: productId,
                metric: dto.metric,
                amount: dto.amount,
                currency: dto.currency,
                fetchedAt: dto.fetchedAt,
                source: dto.source,
                matchQuality: dto.matchQuality
            )
            context.insert(snapshot)
            inserted += 1
        }
        if inserted > 0 { try? context.save() }
        return inserted
    }
}
