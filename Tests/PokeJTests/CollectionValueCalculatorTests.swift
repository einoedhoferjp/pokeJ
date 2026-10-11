import XCTest
@testable import PokeJ

final class CollectionValueCalculatorTests: XCTestCase {
    func testSumsQuantityTimesUnitPrice() {
        let items = [
            ValuedItem(unitPrice: 10, quantity: 2, isStale: false, currency: "EUR"),
            ValuedItem(unitPrice: Decimal(string: "0.07"), quantity: 1, isStale: false, currency: "EUR")
        ]
        let value = CollectionValueCalculator.compute(items: items)
        XCTAssertEqual(value.total, Decimal(string: "20.07"))
        XCTAssertEqual(value.pricedCount, 2)
        XCTAssertEqual(value.unpricedCount, 0)
        XCTAssertEqual(value.currency, "EUR")
    }

    func testMissingPriceIsCountedNotInvented() {
        let items = [
            ValuedItem(unitPrice: nil, quantity: 3, isStale: false, currency: "EUR"),
            ValuedItem(unitPrice: 5, quantity: 1, isStale: false, currency: "EUR")
        ]
        let value = CollectionValueCalculator.compute(items: items)
        XCTAssertEqual(value.total, 5)
        XCTAssertEqual(value.pricedCount, 1)
        XCTAssertEqual(value.unpricedCount, 1)
    }

    func testStaleItemsAreCounted() {
        let items = [
            ValuedItem(unitPrice: 5, quantity: 1, isStale: true, currency: "EUR"),
            ValuedItem(unitPrice: 5, quantity: 1, isStale: false, currency: "EUR")
        ]
        let value = CollectionValueCalculator.compute(items: items)
        XCTAssertEqual(value.staleCount, 1)
    }

    func testMixedCurrencyFlagged() {
        let items = [
            ValuedItem(unitPrice: 5, quantity: 1, isStale: false, currency: "EUR"),
            ValuedItem(unitPrice: 5, quantity: 1, isStale: false, currency: "USD")
        ]
        let value = CollectionValueCalculator.compute(items: items)
        XCTAssertTrue(value.hasMixedCurrency)
    }

    func testEmptyIsZeroWithoutCurrencyAssumption() {
        let value = CollectionValueCalculator.compute(items: [])
        XCTAssertEqual(value.total, 0)
        XCTAssertEqual(value.currency, "EUR")
        XCTAssertFalse(value.hasMixedCurrency)
    }
}
