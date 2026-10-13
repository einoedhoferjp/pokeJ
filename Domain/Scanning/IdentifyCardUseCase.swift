import Foundation

/// Führt Kandidatensuche und Bewertung zu einem Erkennungsergebnis zusammen.
///
/// Es wird bewusst nie ein Treffer ohne Mindestpunktzahl vorgeschlagen; die UI
/// muss das Ergebnis immer bestätigen.
struct IdentifyCardUseCase {
    let provider: CardDataProvider

    static let recognizedThreshold = 0.8
    static let likelyThreshold = 0.4
    static let closeCallGap = 0.1
    static let maxMatches = 25

    func identify(fields: OCRFields, language: Language) async throws -> IdentifyOutcome {
        guard !fields.isEmpty else {
            return IdentifyOutcome(status: .noMatch, matches: [])
        }

        var candidates: [CardBrief] = []
        var seen = Set<String>()

        let names = fields.nameCandidates.prefix(2).filter { !$0.isEmpty }
        let number = fields.number?.trimmingCharacters(in: .whitespacesAndNewlines)

        for lang in Self.searchLanguages(preferred: language) {
            for query in Self.searchQueries(names: Array(names), number: number, language: lang) {
                let results = (try? await provider.searchCards(query)) ?? []
                for brief in results where seen.insert(brief.id).inserted {
                    candidates.append(brief)
                }
            }
        }

        let matches = Array(CardMatcher.match(fields: fields, candidates: candidates).prefix(Self.maxMatches))
        return IdentifyOutcome(status: Self.status(for: matches), matches: matches)
    }

    /// Baut die Suchanfragen in abnehmender Präzision:
    /// 1. Name **und** Nummer (genaueste Suche),
    /// 2. nur Nummer (findet Karten mit unklarem Namen),
    /// 3. nur Name (Fallback).
    static func searchQueries(names: [String], number: String?, language: Language) -> [CardQuery] {
        var queries: [CardQuery] = []
        if let number, !number.isEmpty {
            for name in names {
                queries.append(CardQuery(text: name, localId: number, language: language))
            }
            queries.append(CardQuery(text: "", localId: number, language: language))
        }
        for name in names {
            queries.append(CardQuery(text: name, language: language))
        }
        return queries
    }

    /// Sucht bevorzugt in der gewählten Sprache und zusätzlich in den
    /// Hauptsprachen der Datenquelle. Kartennamen unterscheiden sich je
    /// Sprache (z. B. „Glurak" vs. „Charizard"), daher reicht eine Sprache
    /// nicht aus.
    static func searchLanguages(preferred: Language) -> [Language] {
        var languages: [Language] = [preferred]
        for language in [Language.de, .en] where language != preferred {
            languages.append(language)
        }
        return languages
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
