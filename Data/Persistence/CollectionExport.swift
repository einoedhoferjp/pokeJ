import Foundation
import SwiftData

struct CollectionExport {
    struct ItemDTO: Codable {
        let cardId: String
        let cardName: String
        let setId: String
        let setName: String
        let localId: String
        let language: String
        let printing: String
        let condition: String
        let quantity: Int
        let notes: String
        let purchasePrice: Decimal?
        let purchaseDate: Date?
        let createdAt: Date
        /// Herkunft; optional, damit ältere Backups ohne dieses Feld lesbar bleiben.
        let origin: String?
    }

    static func json(items: [CollectionItem]) -> String {
        let dtos = items.compactMap { item -> ItemDTO? in
            guard let v = item.variant, let c = v.card else { return nil }
            return ItemDTO(
                cardId: c.externalId,
                cardName: c.name,
                setId: c.setId,
                setName: c.setName,
                localId: c.localId,
                language: v.language.rawValue,
                printing: v.printing.rawValue,
                condition: item.confirmedCondition.rawValue,
                quantity: item.quantity,
                notes: item.notes,
                purchasePrice: item.purchasePrice,
                purchaseDate: item.purchaseDate,
                createdAt: item.createdAt,
                origin: item.origin.rawValue
            )
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys, .prettyPrinted]
        enc.dateEncodingStrategy = .iso8601
        enc.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+Inf", negativeInfinity: "-Inf", nan: "NaN")
        do {
            let d = try enc.encode(dtos)
            return String(data: d, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }

    static func csv(items: [CollectionItem]) -> String {
        let header = "cardId,cardName,setId,setName,localId,language,printing,condition,quantity,notes,purchasePriceEUR,purchaseDate,createdAt"
        let rows = items.compactMap { item -> String? in
            guard let v = item.variant, let c = v.card else { return nil }
            let q = String(item.quantity)
            let price = item.purchasePrice.map { String(describing: $0) } ?? ""
            let pd = item.purchaseDate?.ISO8601Format() ?? ""
            let ca = item.createdAt.ISO8601Format()
            func esc(_ s: String) -> String {
                if s.contains(",") || s.contains("\"") || s.contains("\n") {
                    return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                }
                return s
            }
            return [c.externalId, c.name, c.setId, c.setName, c.localId, v.language.rawValue, v.printing.rawValue, item.confirmedCondition.rawValue, q, item.notes, price, pd, ca].map(esc).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
