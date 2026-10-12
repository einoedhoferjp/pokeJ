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
    static let startingBalance = 100
    static let scanRewardPerCard = 50
    static let dailyBonus = 50

    @Published private(set) var balance: Int
    @Published private(set) var recentOpenings: [PackOpeningEvent]

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
        !Calendar.current.isDateInToday(lastDailyBonus)
    }

    @discardableResult
    func claimDailyBonus() -> Bool {
        guard canClaimDailyBonus else { return false }
        lastDailyBonus = .now
        balance += Self.dailyBonus
        persistBalance()
        return true
    }

    func awardScanReward() {
        balance += Self.scanRewardPerCard
        persistBalance()
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