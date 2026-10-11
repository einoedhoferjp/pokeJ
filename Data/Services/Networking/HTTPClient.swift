import Foundation

/// Minimale HTTP-Abstraktion, damit Provider in Tests ohne Netzwerk prüfbar sind.
protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, HTTPURLResponse)
}

/// Standard-Implementierung auf Basis von `URLSession`.
struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw CardDataError.network
        }
        return (data, http)
    }
}

extension HTTPClient {
    /// Lädt und dekodiert JSON. Überträgt HTTP-Fehler auf `CardDataError`.
    func get<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await data(from: url)
        switch response.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw CardDataError.decoding
            }
        case 404:
            throw CardDataError.notFound
        default:
            throw CardDataError.network
        }
    }
}
