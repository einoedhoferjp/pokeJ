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

    static let startingBalance = 100
    static let scanRewardPerCard = 50
    static let dailyBonus = 50
    /// Anzeigedauer der Belohnungs-Snackbar in Sekundenbruchteilen.
    static let rewardDurationNanoseconds: UInt64 = 2_500_000_000

    @Published private(set) var balance: Int
    @Published private(set) var recentOpenings: [PackOpeningEvent]
    /// Zuletzt gewährte Belohnung; `nil`, wenn keine Snackbar angezeigt wird.
    @Published private(set) var reward: RewardEvent?

    private let defaults: UserDefaults

    private static let initializedKey = "pokej.points.initialized"
    private static let balanceKey = "pokej.points.balance"
    private static let dailyKey = "pokej.points.dailyBonus"
    private static let recentKey = "pokej.points.recentOpenings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.bool(forKey: Self.initializedKey) {
            self.balance = defaults.integer(forKey: Self.balanceKey)
        } else {
            self.balance = Self.startingBalance
            defaults.set(true, forKey: Self.initializedKey)
            defaults.set(Self.startingBalance, forKey: Self.balanceKey)
        }
        if let data = defaults.data(forKey: Self.recentKey),
           let events = try? JSONDecoder().decode([PackOpeningEvent].self, from: data) {
            self.recentOpenings = events
        } else {
            self.recentOpenings = []
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
        get { defaults.object(forKey: Self.dailyKey) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Self.dailyKey)
            } else {
                defaults.removeObject(forKey: Self.dailyKey)
            }
        }
    }

    private func persistBalance() {
        defaults.set(balance, forKey: Self.balanceKey)
    }

    private func persistRecent() {
        guard let data = try? JSONEncoder().encode(recentOpenings) else { return }
        defaults.set(data, forKey: Self.recentKey)
    }
}