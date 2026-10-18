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
    /// Zusatzpunkte pro Folgetag der Tagesbonus-Serie (max. 6 Stapel).
    static let dailyBonusStreakStep = 10
    /// Maximale Anzahl gestapelter Serien-Boni.
    static let maxDailyBonusStreakStacks = 6
    /// Obergrenze für Testguthaben im Diagnose-Menü.
    static let maximumBalance = 999_999
    /// Anzeigedauer der Belohnungs-Snackbar in Sekundenbruchteilen.
    static let rewardDurationNanoseconds: UInt64 = 2_500_000_000

    @Published private(set) var balance: Int
    @Published private(set) var recentOpenings: [PackOpeningEvent]
    /// Aktuelle Tagesbonus-Serie (aufeinanderfolgende Tage ohne Lücke).
    @Published private(set) var streak: Int
    /// Gesamtzahl geöffneter Packs (auch jenseits des kurzen Verlaufs).
    @Published private(set) var totalOpenings: Int
    /// Gesamtzahl gezogener Karten aus Packs.
    @Published private(set) var totalCardsPulled: Int
    /// Gesamtzahl gezogener Holo-Karten aus Packs.
    @Published private(set) var totalHolosPulled: Int
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
        self.streak = defaults.integer(forKey: prefix + "streak")
        self.totalOpenings = defaults.integer(forKey: prefix + "totalOpenings")
        self.totalCardsPulled = defaults.integer(forKey: prefix + "totalCardsPulled")
        self.totalHolosPulled = defaults.integer(forKey: prefix + "totalHolosPulled")
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
        streak = defaults.integer(forKey: prefix + "streak")
        totalOpenings = defaults.integer(forKey: prefix + "totalOpenings")
        totalCardsPulled = defaults.integer(forKey: prefix + "totalCardsPulled")
        totalHolosPulled = defaults.integer(forKey: prefix + "totalHolosPulled")
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

    /// Bonus für die nächste Abholung: Grundbonus plus Serien-Aufstockung.
    var nextDailyBonus: Int {
        let nextStreak = projectedStreak(afterClaiming: .now)
        let stacks = min(max(nextStreak - 1, 0), Self.maxDailyBonusStreakStacks)
        return Self.dailyBonus + stacks * Self.dailyBonusStreakStep
    }

    /// Projektion der Serie nach einer Abholung heute (für die Anzeige).
    private func projectedStreak(afterClaiming now: Date) -> Int {
        guard let last = lastDailyBonus else { return 1 }
        let calendar = Calendar.current
        if calendar.isDateInYesterday(last) { return streak + 1 }
        if calendar.isDateInToday(last) { return streak }
        return 1
    }

    @discardableResult
    func claimDailyBonus() -> Bool {
        guard canClaimDailyBonus else { return false }
        let newStreak = projectedStreak(afterClaiming: .now)
        streak = newStreak
        defaults.set(newStreak, forKey: key("streak"))
        lastDailyBonus = .now

        let amount = nextDailyBonus
        balance += amount
        persistBalance()
        showReward(amount: amount, reason: newStreak > 1 ? "Tagesbonus · Serie \(newStreak) Tage" : "Tagesbonus")
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

        totalOpenings += 1
        totalCardsPulled += pulls.count
        totalHolosPulled += pulls.filter(\.isHolo).count
        defaults.set(totalOpenings, forKey: key("totalOpenings"))
        defaults.set(totalCardsPulled, forKey: key("totalCardsPulled"))
        defaults.set(totalHolosPulled, forKey: key("totalHolosPulled"))
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