import Foundation

/// Live-Datenquelle gegen die TCGdex-REST-API (v2).
///
/// Nur `GET`. Endpunkte:
/// - `GET /v2/{lang}/cards?name=...`   Kandidatensuche
/// - `GET /v2/{lang}/cards/{id}`       vollständige Karte
/// - `GET /v2/{lang}/sets`             Set-Liste (für Anzeigenamen)
///
/// Hinweis: Japanische Karten haben eigene IDs; die Suche liefert dort ggf.
/// keine Treffer zu englischen IDs. Das ist eine Eigenschaft der Quelle.
struct TCGdexProvider: CardDataProvider {
    private let client: HTTPClient
    private let baseURL: URL
    private let setStore: TCGdexSetNameStore

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://api.tcgdex.net/v2")!
    ) {
        self.client = client
        self.baseURL = baseURL
        self.setStore = TCGdexSetNameStore(client: client, baseURL: baseURL)
    }

    func searchCards(_ query: CardQuery) async throws -> [CardBrief] {
        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || query.setId != nil else { return [] }

        var items: [URLQueryItem] = []
        if !text.isEmpty { items.append(URLQueryItem(name: "name", value: text)) }

        guard let url = Self.makeURL(base: baseURL, language: query.language, path: "cards", queryItems: items) else {
            throw CardDataError.network
        }

        let briefs: [TCGdexCardBrief] = try await client.get([TCGdexCardBrief].self, from: url)
        let setNames = await setStore.names(for: query.language)

        var result = briefs.map { brief -> CardBrief in
            let setId = Self.setId(from: brief.id, localId: brief.localId)
            return CardBrief(
                id: brief.id,
                name: brief.name,
                setId: setId,
                setName: setNames[setId] ?? setId,
                localId: brief.localId,
                rarity: nil,
                imageURL: Self.imageURL(from: brief.image)
            )
        }

        if let wantedSet = query.setId {
            result = result.filter { $0.setId == wantedSet }
        }
        return result
    }

    func card(externalId: String, language: Language) async throws -> CardDTO {
        guard let url = Self.makeURL(base: baseURL, language: language, path: "cards/\(externalId)") else {
            throw CardDataError.network
        }
        let dto: TCGdexCard = try await client.get(TCGdexCard.self, from: url)
        return CardDTO(
            id: dto.id,
            name: dto.name,
            setId: dto.set.id,
            setName: dto.set.name,
            localId: dto.localId,
            rarity: dto.rarity,
            illustrator: dto.illustrator,
            imageURL: Self.imageURL(from: dto.image),
            availablePrintings: Self.printings(from: dto.variants),
            updatedAt: Self.date(from: dto.updated)
        )
    }

    func sets(language: Language) async throws -> [SetBrief] {
        guard let url = Self.makeURL(base: baseURL, language: language, path: "sets") else {
            throw CardDataError.network
        }
        let dtos: [TCGdexSetBrief] = try await client.get([TCGdexSetBrief].self, from: url)
        return dtos
            .map { SetBrief(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Reine Hilfsfunktionen (testbar)

extension TCGdexProvider {
    static func makeURL(
        base: URL,
        language: Language,
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) -> URL? {
        var url = base.appendingPathComponent(language.rawValue)
        for component in path.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }

    /// Leitet die Set-ID aus `{setId}-{localId}` ab.
    static func setId(from cardId: String, localId: String) -> String {
        let suffix = "-" + localId
        if cardId.hasSuffix(suffix) {
            return String(cardId.dropLast(suffix.count))
        }
        if let index = cardId.lastIndex(of: "-") {
            return String(cardId[..<index])
        }
        return cardId
    }

    /// Baut aus dem TCGdex-Basispfad eine hochauflösende Bild-URL.
    static func imageURL(from base: String?) -> URL? {
        guard let base, !base.isEmpty else { return nil }
        return URL(string: base + "/high.webp")
    }

    static func printings(from variants: TCGdexVariants?) -> [Printing] {
        guard let variants else { return [.normal] }
        var result: [Printing] = []
        if variants.normal == true { result.append(.normal) }
        if variants.holo == true { result.append(.holo) }
        if variants.reverse == true { result.append(.reverse) }
        if variants.firstEdition == true { result.append(.firstEdition) }
        if variants.wPromo == true { result.append(.promo) }
        return result.isEmpty ? [.normal] : result
    }

    static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}

// MARK: - Set-Namen-Cache

/// Lädt die Set-Namen je Sprache einmalig und hält sie im Speicher.
actor TCGdexSetNameStore {
    private var cache: [String: [String: String]] = [:]
    private let client: HTTPClient
    private let baseURL: URL

    init(client: HTTPClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    func names(for language: Language) async -> [String: String] {
        if let cached = cache[language.rawValue] { return cached }
        guard let url = TCGdexProvider.makeURL(base: baseURL, language: language, path: "sets") else {
            return [:]
        }
        let dtos: [TCGdexSetBrief] = (try? await client.get([TCGdexSetBrief].self, from: url)) ?? []
        let map = Dictionary(dtos.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        cache[language.rawValue] = map
        return map
    }
}
