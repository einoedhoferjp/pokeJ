import Foundation
import SwiftData

/// Ergebnis eines Imports (additiv, nie zerstörend).
struct CollectionImportSummary: Equatable {
    var imported: Int = 0
    var merged: Int = 0
    var skipped: Int = 0

    var total: Int { imported + merged + skipped }

    var message: String {
        var parts: [String] = []
        parts.append("\(imported) neu")
        parts.append("\(merged) zusammengeführt")
        if skipped > 0 { parts.append("\(skipped) übersprungen") }
        return parts.joined(separator: " · ")
    }
}

/// Stellt eine Sammlung aus einem JSON-Backup wieder her (Gegenstück zu
/// `CollectionExport`).
///
/// Bewusst **additiv**: Vorhandene Exemplare werden über Variante, Zustand und
/// Notiz erkannt und in der Anzahl erhöht; es wird nie etwas gelöscht. Unbekannte
/// Sprach-/Druck-/Zustandswerte werden gezählt und übersprungen statt zu raten.
enum CollectionImport {
    enum ImportError: Error, LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Das Backup konnte nicht gelesen werden. Erwartet wird das JSON-Format aus dem Export."
            }
        }
    }

    static func decode(_ json: String) throws -> [CollectionExport.ItemDTO] {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([CollectionExport.ItemDTO].self, from: data)
        } catch {
            throw ImportError.invalidFormat
        }
    }

    @MainActor
    static func apply(_ dtos: [CollectionExport.ItemDTO], context: ModelContext) -> CollectionImportSummary {
        let repository = CollectionRepository(context: context)
        var summary = CollectionImportSummary()

        for dto in dtos {
            guard let language = Language(rawValue: dto.language),
                  let printing = Printing(rawValue: dto.printing),
                  let condition = CardCondition(rawValue: dto.condition) else {
                summary.skipped += 1
                continue
            }

            let brief = CardBrief(
                id: dto.cardId,
                name: dto.cardName,
                setId: dto.setId,
                setName: dto.setName,
                localId: dto.localId,
                rarity: nil,
                imageURL: nil
            )
            let card = repository.findOrCreateCard(from: brief)
            let quantity = max(1, dto.quantity)

            if let existing = repository.existingItem(
                card: card,
                language: language,
                printing: printing,
                condition: condition,
                notes: dto.notes
            ) {
                existing.quantity += quantity
                summary.merged += 1
            } else {
                let item = CollectionItem(
                    quantity: quantity,
                    confirmedCondition: condition,
                    purchasePrice: dto.purchasePrice,
                    purchaseDate: dto.purchaseDate,
                    notes: dto.notes,
                    createdAt: dto.createdAt
                )
                repository.addCollectionItem(card: card, language: language, printing: printing, item: item)
                summary.imported += 1
            }
        }

        try? context.save()
        return summary
    }
}
