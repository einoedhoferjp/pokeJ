import Foundation
import SwiftUI

/// Ein einzelnes geöffnetes Pack für den Verlaufsabschnitt im Shop.
struct PackOpeningEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let packName: String
    let cost: Int
    let cardCount: Int
    let holoCount: Int
    let date: Date
}

/// App-interne Punkte-Wirtschaft (rein fiktiv, kein Echtgeld):
/// Startguthaben, Punkte pro bestätigtem Scan und ein täglicher Bonus.
///
/// Persistenz über `UserDefaults`; bewusst kein SwiftData-Modell, damit keine
/// Schema-/Migrationsfragen entstehen.
@MainActor
final class PointsStore: ObservableObject {
    /// Eine soeben erhaltene Punkte-Belohnung, die als Snackbar angezeigt wird.
    struct RewardEvent: Identifiable, Equatable, Sendable {
        let id: UUID
        let amount: Int
        let reason: String
    }

    static let startingBalance = 999_999
    static let scanRewardPerCard = 50
    static let dailyBonus = 50
    /// Obergrenze für Testguthaben im Diagnose-Menü.
    static let maximumBalance = 999_999
    /// Anzeigedauer der Belohnungs-Snackbar in Sekundenbruchteilen.
    static let rewardDurationNanoseconds: UInt64 = 2_500_000_000

    @Published private(set) var balance: Int
    @Published private(set) var recentOpenings: [PackOpeningEvent]
    /// Zuletzt gewährte Belohnung; `nil`, wenn keine Snackbar angezeigt wird.
    @Published private(set) var reward: RewardEvent?

    private let defaults: UserDefaults
    private var username: String?

    /// Inhaber der bisherigen, nicht kontogebundenen Daten.
    private static let legacyOwnerKey = "berli"

    init(defaults: UserDefaults = .standard, username: String? = nil) {
        self.defaults = defaults
        self.username = username
        let prefix = Self.keyPrefix(for: username)
        Self.migrateLegacyIfNeeded(defaults: defaults, prefix: prefix, username: username)

        if defaults.bool(forKey: prefix + "initialized") {
            self.balance = defaults.integer(forKey: prefix + "balance")
        } else {
            self.balance = Self.startingBalance
            defaults.set(true, forKey: prefix + "initialized")
            defaults.set(Self.startingBalance, forKey: prefix + "balance")
        }
        if let data = defaults.data(forKey: prefix + "recentOpenings"),
           let events = try? JSONDecoder().decode([PackOpeningEvent].self, from: data) {
            self.recentOpenings = events
        } else {
            self.recentOpenings = []
        }
    }

    /// Wechselt auf das Konto `username` (oder `nil` beim Abmelden) und lädt
    /// dessen Punkte, Tagesbonus und Öffnungsverlauf.
    func configure(for username: String?) {
        guard username != self.username else { return }
        self.username = username
        let prefix = Self.keyPrefix(for: username)
        Self.migrateLegacyIfNeeded(defaults: defaults, prefix: prefix, username: username)

        if defaults.bool(forKey: prefix + "initialized") {
            balance = defaults.integer(forKey: prefix + "balance")
        } else {
            balance = Self.startingBalance
            defaults.set(true, forKey: prefix + "initialized")
            defaults.set(Self.startingBalance, forKey: prefix + "balance")
        }
        if let data = defaults.data(forKey: prefix + "recentOpenings"),
           let events = try? JSONDecoder().decode([PackOpeningEvent].self, from: data) {
            recentOpenings = events
        } else {
            recentOpenings = []
        }
        reward = nil
    }

    private static func keyPrefix(for username: String?) -> String {
        guard let username else { return "pokej.points." }
        return "pokej.points.\(AccountStorage.storageKey(for: username))."
    }

    private func key(_ suffix: String) -> String {
        Self.keyPrefix(for: username) + suffix
    }

    /// Übernimmt die früher global gespeicherten Punkte einmalig in das Konto
    /// des bisherigen Besitzers.
    private static func migrateLegacyIfNeeded(defaults: UserDefaults, prefix: String, username: String?) {
        guard let username, username.lowercased() == legacyOwnerKey else { return }
        guard !defaults.bool(forKey: prefix + "initialized"),
              defaults.bool(forKey: "pokej.points.initialized") else { return }

        defaults.set(true, forKey: prefix + "initialized")
        defaults.set(defaults.integer(forKey: "pokej.points.balance"), forKey: prefix + "balance")
        if let date = defaults.object(forKey: "pokej.points.dailyBonus") as? Date {
            defaults.set(date, forKey: prefix + "dailyBonus")
        }
        if let data = defaults.data(forKey: "pokej.points.recentOpenings") {
            defaults.set(data, forKey: prefix + "recentOpenings")
        }
    }

    var canClaimDailyBonus: Bool {
        guard let lastDailyBonus else { return true }
        return !Calendar.current.isDateInToday(lastDailyBonus)
    }

    @discardableResult
    func claimDailyBonus() -> Bool {
        guard canClaimDailyBonus else { return false }
        lastDailyBonus = .now
        balance += Self.dailyBonus
        persistBalance()
        showReward(amount: Self.dailyBonus, reason: "Tagesbonus")
        return true
    }

    func awardScanReward() {
        balance += Self.scanRewardPerCard
        persistBalance()
        showReward(amount: Self.scanRewardPerCard, reason: "Karte gescannt")
    }

    /// Blendet das Belohnungs-Banner sofort aus (z. B. beim Verlassen der Ansicht).
    func clearReward() {
        reward = nil
    }

    /// Setzt das Guthaben auf das Maximum (Test-/Diagnosefunktion).
    func grantMaximumBalance() {
        balance = Self.maximumBalance
        persistBalance()
        showReward(amount: Self.maximumBalance, reason: "Testguthaben")
    }

    private func showReward(amount: Int, reason: String) {
        let event = RewardEvent(id: UUID(), amount: amount, reason: reason)
        reward = event
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.rewardDurationNanoseconds)
            if reward?.id == event.id {
                reward = nil
            }
        }
    }

    func canAfford(_ pack: PackDefinition) -> Bool {
        balance >= pack.cost
    }

    @discardableResult
    func purchase(_ pack: PackDefinition) -> Bool {
        guard canAfford(pack) else { return false }
        balance -= pack.cost
        persistBalance()
        return true
    }

    func recordOpening(pack: PackDefinition, pulls: [PackPull]) {
        let event = PackOpeningEvent(
            id: UUID(),
            packName: pack.name,
            cost: pack.cost,
            cardCount: pulls.count,
            holoCount: pulls.filter(\.isHolo).count,
            date: .now
        )
        recentOpenings.insert(event, at: 0)
        recentOpenings = Array(recentOpenings.prefix(10))
        persistRecent()
    }

    private var lastDailyBonus: Date? {
        get { defaults.object(forKey: key("dailyBonus")) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: key("dailyBonus"))
            } else {
                defaults.removeObject(forKey: key("dailyBonus"))
            }
        }
    }

    private func persistBalance() {
        defaults.set(balance, forKey: key("balance"))
    }

    private func persistRecent() {
        guard let data = try? JSONEncoder().encode(recentOpenings) else { return }
        defaults.set(data, forKey: key("recentOpenings"))
    }
}