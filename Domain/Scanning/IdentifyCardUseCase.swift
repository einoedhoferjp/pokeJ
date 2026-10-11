import Foundation

/// Führt Kandidatensuche und Bewertung zu einem Erkennungsergebnis zusammen.
///
/// Es wird bewusst nie ein Treffer ohne Mindestpunktzahl vorgeschlagen; die UI
/// muss das Ergebnis immer bestätigen.
struct IdentifyCardUseCase {
    let provider: CardDataProvider

    static let recognizedThreshold = 0.8
    static let likelyThreshold = 0.5
    static let closeCallGap = 0.1

    func identify(fields: OCRFields, language: Language) async throws -> IdentifyOutcome {
        guard !fields.isEmpty else {
            return IdentifyOutcome(status: .noMatch, matches: [])
        }

        var candidates: [CardBrief] = []
        var seen = Set<String>()

        for query in searchQueries(for: fields) {
            let results = (try? await provider.searchCards(CardQuery(text: query, language: language))) ?? []
            for brief in results where seen.insert(brief.id).inserted {
                candidates.append(brief)
            }
        }

        let matches = CardMatcher.match(fields: fields, candidates: candidates)
        return IdentifyOutcome(status: Self.status(for: matches), matches: matches)
    }

    private func searchQueries(for fields: OCRFields) -> [String] {
        var queries: [String] = []
        for name in fields.nameCandidates.prefix(2) where !name.isEmpty {
            queries.append(name)
        }
        if let number = fields.number, !number.isEmpty {
            queries.append(number)
        }
        return queries
    }

    static func status(for matches: [CardMatch]) -> ScanStatus {
        guard let best = matches.first else { return .noMatch }
        let second = matches.dropFirst().first

        if best.score < likelyThreshold { return .noMatch }
        if let second, best.score - second.score < closeCallGap { return .multiple }
        if best.score >= recognizedThreshold { return .recognized }
        return .likely
    }
}
