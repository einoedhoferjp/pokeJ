import Foundation
@testable import PokeJ

/// Gemeinsamer HTTP-Stub für Provider-Tests.
struct StubHTTPClient: HTTPClient {
    let handler: @Sendable (URL) throws -> (Int, Data)

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (status, body) = try handler(url)
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw CardDataError.network
        }
        return (body, response)
    }
}

/// Gemeinsamer Preis-Stub für Tests ohne Netzwerk.
struct StubPriceProvider: PriceProvider {
    let snapshots: @Sendable (String, Printing, Language) throws -> [PriceSnapshotDTO]

    func prices(externalCardId: String, printing: Printing, language: Language) async throws -> [PriceSnapshotDTO] {
        try snapshots(externalCardId, printing, language)
    }
}
