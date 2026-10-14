import XCTest
@testable import PokeJ

final class AuthServiceTests: XCTestCase {
    func testHashMatchesExpectedVector() {
        let hash = AuthService.hash(password: "admin", salt: "pqj-admin-2026")
        XCTAssertEqual(hash, "c49907f600bc19c4b5f140ef786593286a9b5182f948b312dda228fb4f32d2b0")
    }

    func testVerifyAcceptsProbeAccounts() {
        XCTAssertNotNil(AuthService.verify(username: "admin", password: "admin"))
        XCTAssertNotNil(AuthService.verify(username: "Pokefan", password: "pikachu"))
        XCTAssertNotNil(AuthService.verify(username: " test ", password: "test"))
        XCTAssertNotNil(AuthService.verify(username: "sammler", password: "glueckspilz"))
        XCTAssertNotNil(AuthService.verify(username: "berli", password: "test123"))
    }

    func testVerifyRejectsWrongPasswordForBerli() {
        XCTAssertNil(AuthService.verify(username: "berli", password: "falsch"))
    }

    func testVerifyRejectsWrongPasswordAndUnknownUser() {
        XCTAssertNil(AuthService.verify(username: "admin", password: "falsch"))
        XCTAssertNil(AuthService.verify(username: "unbekannt", password: "egal"))
    }

    @MainActor
    func testAuthStorePersistsSession() {
        let suiteName = "pokej.tests.auth.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AuthStore(defaults: defaults)
        XCTAssertFalse(store.isAuthenticated)
        XCTAssertTrue(store.login(username: "admin", password: "admin"))
        XCTAssertTrue(store.isAuthenticated)
        XCTAssertEqual(store.currentUser?.username, "admin")

        let reloaded = AuthStore(defaults: defaults)
        XCTAssertTrue(reloaded.isAuthenticated)

        store.logout()
        XCTAssertFalse(store.isAuthenticated)
    }
}
