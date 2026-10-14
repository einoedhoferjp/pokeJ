import XCTest
@testable import PokeJ

final class AccountStorageTests: XCTestCase {
    private func makeStorage() -> AccountStorage {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("accounts-\(UUID().uuidString).json")
        return AccountStorage(fileURL: url)
    }

    func testSeedsDemoAccounts() {
        let storage = makeStorage()
        XCTAssertNotNil(storage.account(named: "berli"))
        XCTAssertNotNil(storage.account(named: "Berli"))
        XCTAssertEqual(storage.accounts.count, AuthService.seedAccounts.count)
    }

    func testRegisterAndVerify() {
        let storage = makeStorage()
        let account = storage.register(username: "Neuling", password: "geheim123", displayName: "Neu")
        XCTAssertEqual(account?.displayName, "Neu")
        XCTAssertNotNil(AuthService.verify(username: "neuling", password: "geheim123", in: storage.accounts))
        XCTAssertNil(AuthService.verify(username: "neuling", password: "falsch", in: storage.accounts))
    }

    func testRejectsDuplicateAndWeakCredentials() {
        let storage = makeStorage()
        XCTAssertNotNil(storage.register(username: "doppelt", password: "geheim123", displayName: ""))
        XCTAssertNil(storage.register(username: "Doppelt", password: "geheim123", displayName: ""))
        XCTAssertNil(storage.register(username: "ab", password: "geheim123", displayName: ""))
        XCTAssertNil(storage.register(username: "neu2", password: "kurz", displayName: ""))
    }

    func testStorageKeyIsFilesystemSafe() {
        XCTAssertEqual(AccountStorage.storageKey(for: "Ber lin!"), "berlin")
        XCTAssertEqual(AccountStorage.storageKey(for: "!!!"), "account")
    }
}
