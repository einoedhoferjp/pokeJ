import Foundation
import SwiftData

/// Sprache + Druckvariante einer Karte. Träger der optionalen Cardmarket-Produkt-ID.
@Model
final class CardVariant {
    var languageRaw: String
    var printingRaw: String
    var cardmarketProductId: String?

    var card: Card?

    @Relationship(deleteRule: .cascade, inverse: \CollectionItem.variant)
    var collectionItems: [CollectionItem] = []

    init(language: Language, printing: Printing, cardmarketProductId: String? = nil) {
        self.languageRaw = language.rawValue
        self.printingRaw = printing.rawValue
        self.cardmarketProductId = cardmarketProductId
    }

    var language: Language {
        get { Language(rawValue: languageRaw) ?? .de }
        set { languageRaw = newValue.rawValue }
    }

    var printing: Printing {
        get { Printing(rawValue: printingRaw) ?? .normal }
        set { printingRaw = newValue.rawValue }
    }
}
