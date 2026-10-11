import XCTest
@testable import PokeJ

final class CardTextParserTests: XCTestCase {
    func testParsesNameHpAndNumber() {
        let fields = CardTextParser.parse(lines: ["Charizard", "HP 120", "4/102"])
        XCTAssertEqual(fields.nameCandidates.first, "Charizard")
        XCTAssertEqual(fields.number, "4")
        XCTAssertEqual(fields.printedTotal, "102")
        XCTAssertEqual(fields.hp, 120)
    }

    func testParsesNameAndHpOnSameLine() {
        let fields = CardTextParser.parse(lines: ["Pikachu HP60", "58/102"])
        XCTAssertEqual(fields.nameCandidates.first, "Pikachu")
        XCTAssertEqual(fields.hp, 60)
        XCTAssertEqual(fields.number, "58")
    }

    func testSkipsStageKeywordNoise() {
        let fields = CardTextParser.parse(lines: ["Stage 1", "Furret", "HP 110", "136/189"])
        XCTAssertEqual(fields.nameCandidates.first, "Furret")
        XCTAssertEqual(fields.number, "136")
        XCTAssertEqual(fields.printedTotal, "189")
    }

    func testHandlesPrefixedNumber() {
        let fields = CardTextParser.parse(lines: ["Charizard ex", "SV107/SV122"])
        XCTAssertEqual(fields.number, "SV107")
        XCTAssertEqual(fields.printedTotal, "SV122")
    }

    func testKeepsNameWhenNoNumberPresent() {
        let fields = CardTextParser.parse(lines: ["Charizard"])
        XCTAssertNil(fields.number)
        XCTAssertEqual(fields.nameCandidates, ["Charizard"])
    }

    func testEmptyInputProducesEmptyFields() {
        let fields = CardTextParser.parse(lines: [])
        XCTAssertTrue(fields.isEmpty)
    }

    func testNormalizesKindButKeepsOriginalOCRLine() {
        let fields = CardTextParser.parse(lines: ["Nidoran♀", "52/64"])
        XCTAssertEqual(fields.number, "52")
        XCTAssertFalse(fields.nameCandidates.isEmpty)
    }
}
