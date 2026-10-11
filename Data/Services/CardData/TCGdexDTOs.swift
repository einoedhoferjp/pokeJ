import Foundation

/// Kurzes Kartenobjekt aus `GET /v2/{lang}/cards`.
struct TCGdexCardBrief: Decodable {
    let id: String
    let localId: String
    let name: String
    let image: String?
}

/// Kurzes Set-Objekt aus `GET /v2/{lang}/sets`.
struct TCGdexSetBrief: Decodable {
    let id: String
    let name: String
    let logo: String?
}

/// Vollständiges Kartenobjekt aus `GET /v2/{lang}/cards/{id}`.
struct TCGdexCard: Decodable {
    let id: String
    let localId: String
    let name: String
    let image: String?
    let rarity: String?
    let illustrator: String?
    let hp: Int?
    let updated: String?
    let set: TCGdexSet
    let variants: TCGdexVariants?
}

struct TCGdexSet: Decodable {
    let id: String
    let name: String
}

/// Enthält nur die Felder, die für die Ableitung der Druckvarianten nötig sind.
struct TCGdexVariants: Decodable {
    let firstEdition: Bool?
    let holo: Bool?
    let normal: Bool?
    let reverse: Bool?
    let wPromo: Bool?
}
