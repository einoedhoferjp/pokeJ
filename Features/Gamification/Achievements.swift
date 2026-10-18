import SwiftData
import SwiftUI

/// Ein abgeleitetes Abzeichen: wird direkt aus den vorhandenen Daten berechnet
/// (Punkte-Statistik, Sammlung, Scans) und benötigt daher keine zusätzliche
/// Persistenz.
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isUnlocked: Bool
    /// Fortschritt 0…1 bis zur Freischaltung; `nil`, wenn es keine Zwischen-
    /// stufen gibt.
    let progress: Double?

    /// Aktueller Zählerstand für die Anzeige (z. B. „37/100").
    let current: Int?
    let target: Int?
}

/// Erzeugt alle Abzeichen aus dem aktuellen Spielstand.
@MainActor
enum Achievements {
    static func all(
        points: PointsStore,
        cardCount: Int,
        scanCount: Int
    ) -> [Achievement] {
        [
            make(
                id: "firstScan", title: "Erster Scan",
                subtitle: "Scanne deine erste Karte.", icon: "camera.viewfinder",
                tint: AppTheme.accent, current: scanCount, target: 1
            ),
            make(
                id: "scan10", title: "Scanner-Profi",
                subtitle: "10 Karten scannen.", icon: "doc.text.magnifyingglass",
                tint: AppTheme.accent, current: scanCount, target: 10
            ),
            make(
                id: "scan100", title: "Vollautomatik",
                subtitle: "100 Karten scannen.", icon: "bolt.fill",
                tint: AppTheme.gold, current: scanCount, target: 100
            ),
            make(
                id: "card1", title: "Erste Karte",
                subtitle: "Nimm deine erste Karte auf.", icon: "tray.and.arrow.down.fill",
                tint: AppTheme.mint, current: cardCount, target: 1
            ),
            make(
                id: "card25", title: "Regal gefüllt",
                subtitle: "25 Karten sammeln.", icon: "books.vertical.fill",
                tint: AppTheme.mint, current: cardCount, target: 25
            ),
            make(
                id: "card100", title: "Sammler:in",
                subtitle: "100 Karten sammeln.", icon: "crown.fill",
                tint: AppTheme.gold, current: cardCount, target: 100
            ),
            make(
                id: "pack1", title: "Erster Booster",
                subtitle: "Öffne deinen ersten Booster.", icon: "gift.fill",
                tint: AppTheme.coral, current: points.totalOpenings, target: 1
            ),
            make(
                id: "pack25", title: "Booster-Junkie",
                subtitle: "Öffne 25 Booster.", icon: "flame.fill",
                tint: AppTheme.coral, current: points.totalOpenings, target: 25
            ),
            make(
                id: "holo25", title: "Regenbogenjäger:in",
                subtitle: "Ziehe 25 Holo-Karten.", icon: "sparkles",
                tint: AppTheme.gold, current: points.totalHolosPulled, target: 25
            ),
            make(
                id: "streak7", title: "Sieben-Tage-Serie",
                subtitle: "Hole 7 Tage hintereinander den Tagesbonus.", icon: "calendar.badge.checkmark",
                tint: AppTheme.coral, current: points.streak, target: 7
            ),
            make(
                id: "streak30", title: "Monatsritual",
                subtitle: "30 Tage Tagesbonus-Serie.", icon: "calendar.badge.infinity",
                tint: AppTheme.gold, current: points.streak, target: 30
            )
        ]
    }

    private static func make(
        id: String,
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        current: Int,
        target: Int
    ) -> Achievement {
        let safeTarget = max(target, 1)
        let capped = min(current, safeTarget)
        return Achievement(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: icon,
            tint: tint,
            isUnlocked: current >= safeTarget,
            progress: Double(capped) / Double(safeTarget),
            current: capped,
            target: safeTarget
        )
    }
}

// MARK: - Views

/// Kompakte Badge-Kachel für die Shop-Vorschau und die Detail-Übersicht.
struct AchievementBadge: View {
    let achievement: Achievement
    var compact: Bool = false

    var body: some View {
        if compact {
            VStack(spacing: 6) {
                iconCircle
                    .frame(width: 46, height: 46)
                Text(achievement.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(achievement.isUnlocked ? AppTheme.ink : AppTheme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 96)
            .opacity(achievement.isUnlocked ? 1 : 0.5)
        } else {
            HStack(spacing: 12) {
                iconCircle
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(achievement.isUnlocked ? AppTheme.ink : AppTheme.textTertiary)
                    Text(achievement.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                    if !achievement.isUnlocked,
                       let current = achievement.current,
                       let target = achievement.target {
                        HStack(spacing: 6) {
                            ProgressView(value: achievement.progress ?? 0)
                                .tint(achievement.tint)
                            Text("\(current)/\(target)")
                                .font(.system(size: 10, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(achievement.tint)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(achievement.isUnlocked ? AppTheme.elevated : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(
                        achievement.isUnlocked ? achievement.tint.opacity(0.35) : AppTheme.stroke,
                        lineWidth: 1
                    )
            )
            .opacity(achievement.isUnlocked ? 1 : 0.75)
        }
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(achievement.isUnlocked ? achievement.tint.opacity(0.18) : Color.white.opacity(0.06))
            Circle()
                .strokeBorder(
                    achievement.isUnlocked ? achievement.tint.opacity(0.6) : AppTheme.stroke,
                    lineWidth: 1
                )
            Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(achievement.isUnlocked ? achievement.tint : AppTheme.textTertiary)
        }
        .shadow(
            color: achievement.isUnlocked ? achievement.tint.opacity(0.5) : .clear,
            radius: 6
        )
        .animation(AppTheme.Motion.celebratory, value: achievement.isUnlocked)
    }
}

/// Vollständige Abzeichen-Übersicht mit Fortschritt.
struct AchievementsView: View {
    @EnvironmentObject private var points: PointsStore
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var scans: [ScanRecord]

    private var cardCount: Int {
        CollectionStats.totalQuantity(items.filter { $0.origin == .scanned })
    }

    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    private var achievements: [Achievement] {
        Achievements.all(points: points, cardCount: cardCount, scanCount: scans.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryHeader
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
            .padding()
            .padding(.bottom, 30)
        }
        .navigationTitle("Abzeichen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.gold)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 2) {
                Text("Freigeschaltet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("\(unlockedCount) von \(achievements.count)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private var progress: Double {
        guard !achievements.isEmpty else { return 0 }
        let total = achievements.compactMap { $0.progress }.reduce(0, +)
        return total / Double(achievements.count)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .environmentObject(PointsStore(defaults: UserDefaults(suiteName: "preview.ach")!))
    .modelContainer(PreviewData.container)
}
