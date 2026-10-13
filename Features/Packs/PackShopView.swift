import SwiftUI

/// Shop für fiktive Booster: Punkte-Guthaben, Tagesbonus, Kauf & Öffnen.
struct PackShopView: View {
    @EnvironmentObject private var points: PointsStore

    @State private var opening: PackOpening?
    @State private var bonusNote: String?

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                explanationSection
                boosterSection
                if !points.recentOpenings.isEmpty {
                    historySection
                }
            }
            .navigationTitle("Packs")
            .scrollContentBackground(.hidden)
            .background(AppTheme.appBackground.ignoresSafeArea())
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $opening) { item in
                PackOpeningView(opening: item)
            }
        }
    }

    private var balanceSection: some View {
        Section {
            HStack {
                Label("Punkte", systemImage: "point.3.connected.trianglepath.dotted")
                Spacer()
                Text("\(points.balance)")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
            Button {
                if points.claimDailyBonus() {
                    bonusNote = "Tagesbonus eingelöst: +\(PointsStore.dailyBonus) Punkte."
                }
            } label: {
                Label(
                    points.canClaimDailyBonus
                        ? "Tagesbonus abholen (+\(PointsStore.dailyBonus))"
                        : "Tagesbonus heute schon abgeholt",
                    systemImage: "sun.max.fill"
                )
            }
            .disabled(!points.canClaimDailyBonus)
        } footer: {
            if let bonusNote {
                Text(bonusNote)
            }
        }
    }

    private var explanationSection: some View {
        Section {
            Text("Fiktive Booster aus dem Offline-Katalog. Verdiene Punkte durch bestätigte Scans (+\(PointsStore.scanRewardPerCard) pro Karte) und den Tagesbonus. Gekauft ist geöffnet – Punkte werden sofort abgezogen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var boosterSection: some View {
        Section("Booster") {
            ForEach(PackDefinition.all) { pack in
                Button {
                    open(pack)
                } label: {
                    packRow(pack)
                }
                .buttonStyle(.plain)
                .disabled(!points.canAfford(pack))
            }
        }
    }

    private func packRow(_ pack: PackDefinition) -> some View {
        HStack(spacing: 12) {
            Image(systemName: pack.iconName)
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.name).font(.headline.weight(.bold)).foregroundStyle(AppTheme.ink)
                Text(pack.contentsText).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Text("\(pack.cost) P")
                .font(.subheadline.bold())
                .monospacedDigit()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        points.canAfford(pack)
                            ? AppTheme.accent.opacity(0.16)
                            : Color.secondary.opacity(0.12)
                    )
                )
        }
        .opacity(points.canAfford(pack) ? 1 : 0.6)
    }

    private var historySection: some View {
        Section("Zuletzt geöffnet") {
            ForEach(points.recentOpenings) { event in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.packName).font(.subheadline)
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(event.cardCount) Karten · \(event.holoCount) Holo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func open(_ pack: PackDefinition) {
        guard points.purchase(pack) else { return }
        let pulls = PackOpener.open(pack, from: PokemonCatalog.sets)
        opening = PackOpening(pack: pack, pulls: pulls)
    }
}

#Preview {
    PackShopView()
        .environmentObject(PointsStore(defaults: UserDefaults(suiteName: "preview.packs")!))
}