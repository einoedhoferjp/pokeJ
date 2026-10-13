import XCTest
@testable import PokeJ

final class CardMatcherTests: XCTestCase {
    private let furret = CardBrief(
        id: "swsh3-136",
        name: "Furret",
        setId: "swsh3",
        setName: "Darkness Ablaze",
        localId: "136",
        rarity: "Uncommon",
        imageURL: nil
    )

    private let charizard = CardBrief(
        id: "base1-4",
        name: "Charizard",
        setId: "base1",
        setName: "Base Set",
        localId: "4",
        rarity: "Rare Holo",
        imageURL: nil
    )

    func testExactNumberAndNameScoresFull() {
        let fields = OCRFields(nameCandidates: ["Furret"], number: "136")
        let (score, reasons) = CardMatcher.score(fields: fields, brief: furret)
        XCTAssertEqual(score, 1.0, accuracy: 0.0001)
        XCTAssertTrue(reasons.contains("Kartennummer stimmt überein"))
        XCTAssertTrue(reasons.contains("Name sehr ähnlich"))
    }

    func testNameOnlyScoresWithoutNumber() {
        let fields = OCRFields(nameCandidates: ["Charizard"])
        let (score, _) = CardMatcher.score(fields: fields, brief: charizard)
        XCTAssertEqual(score, 0.4, accuracy: 0.0001)
    }

    func testWrongNumberDoesNotAddNumberPoints() {
        let fields = OCRFields(nameCandidates: ["Charizard"], number: "999")
        let (score, reasons) = CardMatcher.score(fields: fields, brief: charizard)
        XCTAssertFalse(reasons.contains("Kartennummer stimmt überein"))
        XCTAssertLessThan(score, 0.5)
    }

    func testLeadingZeroNumberStillMatches() {
        let brief = CardBrief(id: "sv03.5-006", name: "Charizard ex", setId: "sv03.5", setName: "Paldean Fates", localId: "006", rarity: nil, imageURL: nil)
        let fields = OCRFields(nameCandidates: ["Charizard ex"], number: "6")
        let (score, reasons) = CardMatcher.score(fields: fields, brief: brief)
        XCTAssertTrue(reasons.contains("Kartennummer stimmt überein"))
        XCTAssertEqual(score, 1.0, accuracy: 0.0001)
    }

    func testOcrConfusedNumberStillMatches() {
        let fields = OCRFields(nameCandidates: ["Furret"], number: "l36")
        let (score, reasons) = CardMatcher.score(fields: fields, brief: furret)
        XCTAssertTrue(reasons.contains("Kartennummer stimmt überein"))
        XCTAssertEqual(score, 1.0, accuracy: 0.0001)
    }

    func testMatchSortsByNameAndNumberMatch() {
        let fields = OCRFields(nameCandidates: ["Furret"], number: "136")
        let matches = CardMatcher.match(fields: fields, candidates: [charizard, furret])
        XCTAssertEqual(matches.first?.brief.id, "swsh3-136")
    }

    func testSimilarityHandlesTypos() {
        XCTAssertGreaterThan(CardMatcher.similarity("Chrizard", "Charizard"), 0.8)
        XCTAssertLessThan(CardMatcher.similarity("Furret", "Charizard"), 0.4)
    }
}
