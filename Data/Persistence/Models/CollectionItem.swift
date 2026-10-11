import Foundation
import SwiftData

/// Ein physisches Kartenexemplar in der Sammlung.
///
/// Entscheidung: Jedes Exemplar erhält einen eigenen Datensatz, damit
/// unterschiedliche Zustände derselben Karte möglich sind. `quantity` > 1 wird
/// nur für echte identische Bündel genutzt.
@Model
final class CollectionItem {
    var quantity: Int
    var confirmedConditionRaw: String
    var estimatedConditionRaw: String?
    var purchasePrice: Decimal?
    var purchaseDate: Date?
    var notes: String
    var createdAt: Date

    var variant: CardVariant?

    @Relationship(deleteRule: .cascade, inverse: \ConditionAssessment.collectionItem)
    var assessments: [ConditionAssessment] = []

    init(
        quantity: Int = 1,
        confirmedCondition: CardCondition,
        estimatedCondition: CardCondition? = nil,
        purchasePrice: Decimal? = nil,
        purchaseDate: Date? = nil,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.quantity = quantity
        self.confirmedConditionRaw = confirmedCondition.rawValue
        self.estimatedConditionRaw = estimatedCondition?.rawValue
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.createdAt = createdAt
    }

    var confirmedCondition: CardCondition {
        get { CardCondition(rawValue: confirmedConditionRaw) ?? .nearMint }
        set { confirmedConditionRaw = newValue.rawValue }
    }

    var estimatedCondition: CardCondition? {
        get { estimatedConditionRaw.flatMap { CardCondition(rawValue: $0) } }
        set { estimatedConditionRaw = newValue?.rawValue }
    }
}
