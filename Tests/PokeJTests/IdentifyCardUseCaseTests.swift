import XCTest
@testable import PokeJ

final class IdentifyCardUseCaseTests: XCTestCase {
    private func makeUseCase() -> IdentifyCardUseCase {
        IdentifyCardUseCase(provider: MockCardDataProvider())
    }

    func testIdentifiesFurretFromNumberAndName() async throws {
        let fields = CardTextParser.parse(lines: ["Furret", "HP 110", "136/189"])
        let outcome = try await makeUseCase().identify(fields: fields, language: .en)
        XCTAssertEqual(outcome.status, .recognized)
        XCTAssertEqual(outcome.matches.first?.brief.id, "swsh3-136")
        XCTAssertGreaterThanOrEqual(outcome.matches.first?.score ?? 0, IdentifyCardUseCase.recognizedThreshold)
    }

    func testEmptyFieldsReturnNoMatch() async throws {
        let outcome = try await makeUseCase().identify(fields: OCRFields(), language: .en)
        XCTAssertEqual(outcome.status, .noMatch)
        XCTAssertTrue(outcome.matches.isEmpty)
    }

    func testNameOnlyMatchIsLikely() async throws {
        let fields = OCRFields(nameCandidates: ["Furret"])
        let outcome = try await makeUseCase().identify(fields: fields, language: .en)
        XCTAssertFalse(outcome.matches.isEmpty)
        XCTAssertEqual(outcome.status, .likely)
        XCTAssertEqual(outcome.matches.first?.brief.id, "swsh3-136")
    }

    func testSearchLanguagesFallsBackToGermanAndEnglish() {
        XCTAssertEqual(IdentifyCardUseCase.searchLanguages(preferred: .de), [.de, .en])
        XCTAssertEqual(IdentifyCardUseCase.searchLanguages(preferred: .en), [.en, .de])
        XCTAssertEqual(IdentifyCardUseCase.searchLanguages(preferred: .fr), [.fr, .de, .en])
    }

    func testUnknownCardReturnsNoMatch() async throws {
        let fields = OCRFields(nameCandidates: ["Zzzunknownmon"], number: "9999")
        let outcome = try await makeUseCase().identify(fields: fields, language: .en)
        XCTAssertEqual(outcome.status, .noMatch)
        XCTAssertTrue(outcome.matches.isEmpty)
    }

    func testSearchQueriesPreferNameAndNumber() {
        let queries = IdentifyCardUseCase.searchQueries(names: ["Furret"], number: "136", language: .en)
        XCTAssertEqual(queries.first?.text, "Furret")
        XCTAssertEqual(queries.first?.localId, "136")
        XCTAssertTrue(queries.contains { $0.text.isEmpty && $0.localId == "136" })
        XCTAssertTrue(queries.contains { $0.text == "Furret" && $0.localId == nil })
    }

    func testSearchQueriesWithoutNumberOnlyUsesName() {
        let queries = IdentifyCardUseCase.searchQueries(names: ["Furret"], number: nil, language: .en)
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.text, "Furret")
        XCTAssertNil(queries.first?.localId)
    }

    func testStatusThresholds() {
        let strong = CardMatch(brief: sampleBrief(id: "a"), score: 0.95, reasons: [])
        let weak = CardMatch(brief: sampleBrief(id: "b"), score: 0.55, reasons: [])
        XCTAssertEqual(IdentifyCardUseCase.status(for: [strong]), .recognized)
        XCTAssertEqual(IdentifyCardUseCase.status(for: [weak]), .likely)

        let close = CardMatch(brief: sampleBrief(id: "c"), score: 0.9, reasons: [])
        XCTAssertEqual(IdentifyCardUseCase.status(for: [strong, close]), .multiple)

        let low = CardMatch(brief: sampleBrief(id: "d"), score: 0.2, reasons: [])
        XCTAssertEqual(IdentifyCardUseCase.status(for: [low]), .noMatch)
        XCTAssertEqual(IdentifyCardUseCase.status(for: []), .noMatch)
    }

    private func sampleBrief(id: String) -> CardBrief {
        CardBrief(id: id, name: "Sample", setId: "set", setName: "Set", localId: "1", rarity: nil, imageURL: nil)
    }
}
