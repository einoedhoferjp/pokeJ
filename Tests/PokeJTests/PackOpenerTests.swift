import Foundation
@testable import PokeJ

final class PackOpenerTests: XCTestCase {
    func testGuaranteesHolo() {
        let pack = PackDefinition(id: "t", name: "T", cost: 10, cardCount: 3, holoGuarantee: 2, iconName: "x")
        var rng = DeterministicRNG(sequence: [0,1,2,3,4,5])
        let pulls = PackOpener.open(pack, from: [self.set], rng: &rng)
        XCTAssertEqual(pulls.count, 3)
        let holoCount = pulls.filter { $0.printing == .holo }.count
        XCTAssertGreaterThanOrEqual(holoCount, 2)
    }

    func testEmptyPoolReturnsEmpty() {
        let pack = PackDefinition.standard
        var rng = DeterministicRNG(sequence: [0,1,2])
        let pulls = PackOpener.open(pack, from: [], rng: &rng)
        XCTAssertTrue(pulls.isEmpty)
    }

    private var set: CatalogSet {
        CatalogSet(
            id: "test",
            name: "Test",
            cards: [
                CatalogCard(id: "1", localId: "001", name: "A", image: nil),
                CatalogCard(id: "2", localId: "002", name: "B", image: nil),
                CatalogCard(id: "3", localId: "003", name: "C", image: nil),
            ]
        )
    }
}

struct DeterministicRNG: RandomNumberGenerator {
    var sequence: [UInt64]
    mutating func next() -> UInt64 {
        if sequence.isEmpty { return 0 }
        let v = sequence.removeFirst()
        return v
    }
}