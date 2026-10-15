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
            ScrollView {
                VStack(spacing: 20) {
                    balanceSection
                    explanationSection
                    classicSection
                    catalogSections
                    if !points.recentOpenings.isEmpty {
                        historySection
                    }
                }
                .padding()
                .padding(.bottom, 30)
            }
            .navigationTitle("Packs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Set oder Serie suchen")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Punkte", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(points.balance)")
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.gold)
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
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(!points.canClaimDailyBonus)
            .opacity(points.canClaimDailyBonus ? 1 : 0.6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 14, y: 7)

        if let bonusNote {
            Text(bonusNote)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal)
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fiktive Booster")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
            Text("Booster aus dem Offline-Katalog. Ältere Sets sind günstiger, neuere teurer. Verdiene Punkte durch bestätigte Scans (+\(PointsStore.scanRewardPerCard) pro Karte) und den Tagesbonus. Gekauft ist geöffnet – Punkte werden sofort abgezogen.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .fill(AppTheme.elevatedAlt)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
        )
    }

    private var classicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Klassische Booster", systemImage: "gift.fill")
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
            VStack(alignment: .leading, spacing: 12) {
                PokedexSectionHeader(title: group.era.name, systemImage: "gift.fill")
                ForEach(group.packs) { pack in
                    Button {
                        open(pack)
                    } label: {
                        packRow(pack, showsArt: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(!points.canAfford(pack))
                }
            }
        }
    }

    private func packRow(_ pack: PackDefinition, showsArt: Bool) -> some View {
        HStack(spacing: 14) {
            if showsArt {
                BoosterPackArt(pack: pack, width: 56, showsDetails: false)
            } else {
                Image(systemName: pack.iconName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        points.canAfford(pack)
                            ? AppTheme.accent.opacity(0.16)
                            : Color.secondary.opacity(0.12)
                    )
                )
                .foregroundStyle(points.canAfford(pack) ? AppTheme.accent : AppTheme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .fill(points.canAfford(pack) ? AppTheme.elevated : Color.white.opacity(0.04))
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(points.canAfford(pack) ? 0.3 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 1)
        )
        .opacity(points.canAfford(pack) ? 1 : 0.55)
        .scaleEffect(points.canAfford(pack) ? 1 : 0.98)
        .animation(AppTheme.Motion.snappy, value: points.canAfford(pack))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Zuletzt geöffnet", systemImage: "clock.arrow.circlepath")
            ForEach(points.recentOpenings) { event in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.packName).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(event.cardCount) Karten · \(event.holoCount) Holo")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.elevatedAlt, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
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