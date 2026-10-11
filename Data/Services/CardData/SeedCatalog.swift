import Foundation

/// Demo-Datensatz für Phase 1.
///
/// Hinweis: IDs und Bildpfade werden in Phase 2 gegen die Live-TCGdex-API
/// validiert. `swsh3-136` (Furret) stammt aus der offiziellen TCGdex-Doku.
enum SeedCatalog {
    static let cards: [CardDTO] = [
        CardDTO(
            id: "base1-4",
            name: "Charizard",
            setId: "base1",
            setName: "Base Set",
            localId: "4",
            rarity: "Rare Holo",
            illustrator: "Mitsuhiro Arita",
            imageURL: url("en/base/base1/4"),
            availablePrintings: [.holo, .firstEdition],
            updatedAt: nil
        ),
        CardDTO(
            id: "base1-58",
            name: "Pikachu",
            setId: "base1",
            setName: "Base Set",
            localId: "58",
            rarity: "Common",
            illustrator: "Mitsuhiro Arita",
            imageURL: url("en/base/base1/58"),
            availablePrintings: [.normal, .firstEdition],
            updatedAt: nil
        ),
        CardDTO(
            id: "swsh3-136",
            name: "Furret",
            setId: "swsh3",
            setName: "Darkness Ablaze",
            localId: "136",
            rarity: "Uncommon",
            illustrator: "tetsuya koizumi",
            imageURL: url("en/swsh/swsh3/136"),
            availablePrintings: [.normal, .reverse],
            updatedAt: nil
        ),
        CardDTO(
            id: "swsh1-1",
            name: "Celebi & Venusaur-GX",
            setId: "swsh1",
            setName: "Sword & Shield",
            localId: "1",
            rarity: "Rare Holo GX",
            illustrator: nil,
            imageURL: url("en/swsh/swsh1/1"),
            availablePrintings: [.holo],
            updatedAt: nil
        ),
        CardDTO(
            id: "sm1-1",
            name: "Caterpie",
            setId: "sm1",
            setName: "Sun & Moon",
            localId: "1",
            rarity: "Common",
            illustrator: nil,
            imageURL: url("en/sm/sm1/1"),
            availablePrintings: [.normal, .reverse],
            updatedAt: nil
        ),
        CardDTO(
            id: "xy1-1",
            name: "Weedle",
            setId: "xy1",
            setName: "XY",
            localId: "1",
            rarity: "Common",
            illustrator: nil,
            imageURL: url("en/xy/xy1/1"),
            availablePrintings: [.normal, .reverse],
            updatedAt: nil
        ),
        CardDTO(
            id: "sv1-1",
            name: "Pineco",
            setId: "sv1",
            setName: "Scarlet & Violet",
            localId: "1",
            rarity: "Common",
            illustrator: nil,
            imageURL: url("en/sv/sv1/1"),
            availablePrintings: [.normal, .reverse],
            updatedAt: nil
        ),
        CardDTO(
            id: "swsh12-1",
            name: "Oddish",
            setId: "swsh12",
            setName: "Silver Tempest",
            localId: "1",
            rarity: "Common",
            illustrator: nil,
            imageURL: url("en/swsh/swsh12/1"),
            availablePrintings: [.normal, .reverse],
            updatedAt: nil
        )
    ]

    static func url(_ path: String) -> URL? {
        URL(string: "https://assets.tcgdex.net/\(path)/high.webp")
    }
}
