import Foundation
import SwiftData

/// Stammdaten einer Karte (aus der Kartendatenquelle).
@Model
final class Card {
    @Attribute(.unique) var externalId: String
    var name: String
    var setId: String
    var setName: String
    var localId: String
    var rarity: String?
    var illustrator: String?
    var imageURLString: String?
    var updatedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \CardVariant.card)
    var variants: [CardVariant] = []

    init(
        externalId: String,
        name: String,
        setId: String,
        setName: String,
        localId: String,
        rarity: String? = nil,
        illustrator: String? = nil,
        imageURLString: String? = nil,
        updatedAt: Date? = nil
    ) {
        self.externalId = externalId
        self.name = name
        self.setId = setId
        self.setName = setName
        self.localId = localId
        self.rarity = rarity
        self.illustrator = illustrator
        self.imageURLString = imageURLString
        self.updatedAt = updatedAt
    }

    var imageURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }
}
