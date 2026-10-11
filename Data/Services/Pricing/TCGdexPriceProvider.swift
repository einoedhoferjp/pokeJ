import Foundation

/// Nur die für Preise relevanten Felder des TCGdex-Card-Objekts.
///
/// Bewusst getrennt von `TCGdexCard`, um das Namens-Mapping der
/// Bindestrich-Felder (`avg-holo`) isoliert zu halten.
struct TCGdexPriceCard: Decodable {
    let id: String
    let pricing: TCGdexPricing?
}

struct TCGdexPricing: Decodable {
    let cardmarket: TCGdexCardmarket?
}

/// Cardmarket-Preisdaten, wie sie TCGdex eingebettet liefert.
struct TCGdexCardmarket: Decodable {
    let updated: String?
    let unit: String?
    let idProduct: Int?
    let avg: Double?
    let low: Double?
    let trend: Double?
    let avg1: Double?
    let avg7: Double?
    let avg30: Double?
    let avgHolo: Double?
    let lowHolo: Double?
    let trendHolo: Double?
    let avg1Holo: Double?
    let avg7Holo: Double?
    let avg30Holo: Double?

    enum CodingKeys: String, CodingKey {
        case updated, unit, idProduct, avg, low, trend, avg1, avg7, avg30
        case avgHolo = "avg-holo"
        case lowHolo = "low-holo"
        case trendHolo = "trend-holo"
        case avg1Holo = "avg1-holo"
        case avg7Holo = "avg7-holo"
        case avg30Holo = "avg30-holo"
    }
}

/// Live-Preisquelle: liest `pricing.cardmarket` aus dem TCGdex-Card-Objekt.
///
/// Wichtig: Der Preis ist **produktbezogen** (nicht sprach-, zustands- oder
/// exemplargenau). Das wird über `matchQuality = .productOnly` ausgewiesen.
struct TCGdexPriceProvider: PriceProvider {
    static let sourceName = "Cardmarket über TCGdex"

    private let client: HTTPClient
    private let baseURL: URL

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        baseURL: URL = URL(string: "https://api.tcgdex.net/v2")!
    ) {
        self.client = client
        self.baseURL = baseURL
    }

    func prices(externalCardId: String, printing: Printing, language: Language) async throws -> [PriceSnapshotDTO] {
        guard let url = TCGdexProvider.makeURL(base: baseURL, language: language, path: "cards/\(externalCardId)") else {
            throw CardDataError.network
        }
        let card: TCGdexPriceCard = try await client.get(TCGdexPriceCard.self, from: url)
        return Self.snapshots(from: card.pricing?.cardmarket, printing: printing)
    }

    /// Wandelt die Cardmarket-Felder in Kennzahl-Datensätze um.
    ///
    /// Bei Foil-Druck (`holo`) werden die Holo-Kennzahlen verwendet, sonst die
    /// regulären. Fehlende Werte werden ausgelassen.
    static func snapshots(from cardmarket: TCGdexCardmarket?, printing: Printing) -> [PriceSnapshotDTO] {
        guard let cardmarket else { return [] }

        let currency = cardmarket.unit ?? "EUR"
        let productId = cardmarket.idProduct.map(String.init)
        let fetchedAt = TCGdexProvider.date(from: cardmarket.updated) ?? Date()

        func make(_ metric: PriceMetric, _ value: Double?) -> PriceSnapshotDTO? {
            guard let value else { return nil }
            return PriceSnapshotDTO(
                productId: productId,
                metric: metric,
                amount: decimal(from: value),
                currency: currency,
                fetchedAt: fetchedAt,
                source: sourceName,
                matchQuality: .productOnly
            )
        }

        let pairs: [(PriceMetric, Double?)]
        if printing == .holo {
            pairs = [
                (.avgHolo, cardmarket.avgHolo),
                (.lowHolo, cardmarket.lowHolo),
                (.trendHolo, cardmarket.trendHolo),
                (.avg1Holo, cardmarket.avg1Holo),
                (.avg7Holo, cardmarket.avg7Holo),
                (.avg30Holo, cardmarket.avg30Holo)
            ]
        } else {
            pairs = [
                (.avg, cardmarket.avg),
                (.low, cardmarket.low),
                (.trend, cardmarket.trend),
                (.avg1, cardmarket.avg1),
                (.avg7, cardmarket.avg7),
                (.avg30, cardmarket.avg30)
            ]
        }

        return pairs.compactMap(make)
    }

    /// Wandelt einen Double in ein Decimal ohne Binärartefakte
    /// (z. B. `0.07` bleibt `0.07`).
    static func decimal(from value: Double) -> Decimal {
        Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(value)
    }
}
