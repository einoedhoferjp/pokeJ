import Foundation

/// Fiktiver Booster, der gegen App-Punkte gekauft und geöffnet werden kann.
struct PackDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let cost: Int
    let cardCount: Int
    let holoGuarantee: Int
    let iconName: String

    static let standard = PackDefinition(
        id: "standard",
        name: "Standard-Pack",
        cost: 200,
        cardCount: 5,
        holoGuarantee: 0,
        iconName: "shippingbox"
    )
    static let holo = PackDefinition(
        id: "holo",
        name: "Holo-Pack",
        cost: 500,
        cardCount: 5,
        holoGuarantee: 1,
        iconName: "sparkles"
    )
    static let premium = PackDefinition(
        id: "premium",
        name: "Premium-Pack",
        cost: 1000,
        cardCount: 10,
        holoGuarantee: 3,
        iconName: "crown"
    )

    static let all: [PackDefinition] = [.standard, .holo, .premium]

    var contentsText: String {
        var parts = ["\(cardCount) Karten"]
        if holoGuarantee > 0 {
            parts.append("min. \(holoGuarantee) Holo")
        }
        return parts.joined(separator: " · ")
    }
}