import SwiftUI

/// Shop für fiktive Booster: Punkte-Guthaben, Tagesbonus, Kauf & Öffnen.
/// Jeder Booster gehört zu einem echten Set (Base, Fossil, …) und zieht auch
/// nur Karten aus diesem Set.
struct PackShopView: View {
    @EnvironmentObject private var points: PointsStore

    @State private var opening: PackOpening?
    @State private var bonusNote: String?
    @State private var searchText = ""

    private var groups: [PackEraGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return PackDefinition.catalogPacksByEra.compactMap { group in
            guard !query.isEmpty else { return group }
            let packs = group.packs.filter { pack in
                pack.name.localizedCaseInsensitiveContains(query)
                    || group.era.name.localizedCaseInsensitiveContains(query)
            }
            return packs.isEmpty ? nil : PackEraGroup(era: group.era, packs: packs)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                explanationSection
                classicSection
                catalogSections
                if !points.recentOpenings.isEmpty {
                    historySection
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("Packs")
            .searchable(text: $searchText, prompt: "Set oder Serie")
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
            Text("Fiktive Booster aus dem Offline-Katalog. Ältere Sets sind günstiger, neuere teurer. Verdiene Punkte durch bestätigte Scans (+\(PointsStore.scanRewardPerCard) pro Karte) und den Tagesbonus. Gekauft ist geöffnet – Punkte werden sofort abgezogen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var classicSection: some View {
        Section("Booster") {
            ForEach(PackDefinition.all) { pack in
                Button {
                    open(pack)
                } label: {
                    packRow(pack, showsArt: false)
                }
                .buttonStyle(.plain)
                .disabled(!points.canAfford(pack))
            }
        }
    }

    @ViewBuilder
    private var catalogSections: some View {
        ForEach(groups) { group in
            Section {
                ForEach(group.packs) { pack in
                    Button {
                        open(pack)
                    } label: {
                        packRow(pack, showsArt: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(!points.canAfford(pack))
                }
            } header: {
                HStack(spacing: 8) {
                    Text(group.era.name)
                    Spacer()
                    Text("\(group.packs.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                if group.era.id == "base" {
                    Text("Klassische Sets – die günstigste Stufe.")
                }
            }
        }
    }

    private func packRow(_ pack: PackDefinition, showsArt: Bool) -> some View {
        HStack(spacing: 12) {
            if showsArt {
                BoosterPackArt(pack: pack, width: 52, showsDetails: false)
            } else {
                Image(systemName: pack.iconName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.name).font(.headline.weight(.bold)).foregroundStyle(AppTheme.ink).lineLimit(1)
                Text(pack.contentsText).font(.caption).foregroundStyle(AppTheme.textSecondary)
                if showsArt, let year = pack.releaseYearText {
                    Text("\(pack.eraName ?? "") · \(year)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
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
        let pulls = PackOpener.open(pack)
        opening = PackOpening(pack: pack, pulls: pulls)
    }
}

#Preview {
    PackShopView()
        .environmentObject(PointsStore(defaults: UserDefaults(suiteName: "preview.packs")!))
}
