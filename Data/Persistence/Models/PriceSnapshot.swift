import Foundation
import SwiftData

/// Gespeicherter Preisstand zu einem Cardmarket-Produkt.
@Model
final class PriceSnapshot {
    var cardmarketProductId: String
    var metricRaw: String
    var amount: Decimal
    var currency: String
    var fetchedAt: Date
    var source: String
    var matchQualityRaw: String

    init(
        cardmarketProductId: String,
        metric: PriceMetric,
        amount: Decimal,
        currency: String,
        fetchedAt: Date,
        source: String,
        matchQuality: MatchQuality
    ) {
        self.cardmarketProductId = cardmarketProductId
        self.metricRaw = metric.rawValue
        self.amount = amount
        self.currency = currency
        self.fetchedAt = fetchedAt
        self.source = source
        self.matchQualityRaw = matchQuality.rawValue
    }

    var metric: PriceMetric {
        get { PriceMetric(rawValue: metricRaw) ?? .avg }
        set { metricRaw = newValue.rawValue }
    }

    var matchQuality: MatchQuality {
        get { MatchQuality(rawValue: matchQualityRaw) ?? .uncertain }
        set { matchQualityRaw = newValue.rawValue }
    }
}
