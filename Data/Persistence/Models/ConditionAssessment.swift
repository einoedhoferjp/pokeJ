import Foundation
import SwiftData

/// Zustandsbewertung eines Exemplars (Phase 4). Getrennt von der manuell
/// bestätigten Bewertung am `CollectionItem`.
@Model
final class ConditionAssessment {
    var detectedDefects: String
    var estimatedConditionRaw: String
    var confirmedConditionRaw: String?
    var assessedAt: Date
    var imageReferences: String?

    var collectionItem: CollectionItem?

    init(
        detectedDefects: String = "",
        estimatedCondition: CardCondition,
        confirmedCondition: CardCondition? = nil,
        assessedAt: Date = .now,
        imageReferences: String? = nil
    ) {
        self.detectedDefects = detectedDefects
        self.estimatedConditionRaw = estimatedCondition.rawValue
        self.confirmedConditionRaw = confirmedCondition?.rawValue
        self.assessedAt = assessedAt
        self.imageReferences = imageReferences
    }

    var estimatedCondition: CardCondition {
        get { CardCondition(rawValue: estimatedConditionRaw) ?? .uncertain }
        set { estimatedConditionRaw = newValue.rawValue }
    }

    var confirmedCondition: CardCondition? {
        get { confirmedConditionRaw.flatMap { CardCondition(rawValue: $0) } }
        set { confirmedConditionRaw = newValue?.rawValue }
    }
}
