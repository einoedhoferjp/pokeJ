import SwiftUI
import SwiftData

/// Startseite: Dashboard mit großer Scan-Aktion im Mittelpunkt.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(PriceRefreshCoordinator.self) private var priceRefresher
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var points: PointsStore

    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \PriceSnapshot.fetchedAt, order: .reverse) private var snapshots: [PriceSnapshot]
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var scans: [ScanRecord]

    private var realItems: [CollectionItem] {
        items.filter { $0.origin == .scanned }
    }

    private var fictionalQuantity: Int {
        CollectionStats.totalQuantity(items.filter { $0.origin == .pack })
    }

    @State private var showScanner = false
    @State private var showAdd = false
    @State private var animateScanButton = false

    private let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    brandHeader
                    scanCallToAction
                    valueCard
                    statsGrid
                    quickActions
                    if !realItems.isEmpty { recentCards }
                    recentScans
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(AppTheme.appBackground.ignoresSafeArea())
            .navigationTitle("Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let user = auth.currentUser {
                            Section(user.displayName) {
                                Label(user.username, systemImage: "person.crop.circle")
                            }
                        }
                        Button(role: .destructive) {
                            auth.logout()
                        } label: {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Section("Daten") {
                            NavigationLink {
                                WishlistView()
                            } label: {
                                Label("Wunschliste", systemImage: "heart")
                            }
                            NavigationLink {
                                DataExportView()
                            } label: {
                                Label("Export / Backup", systemImage: "square.and.arrow.up.on.square")
                            }
                        }
                        Section("Diagnose") {
                            NavigationLink {
                                DeviceDiagnosticsView()
                            } label: {
                                Label("Gerätetest", systemImage: "stethoscope")
                            }
                        }
                    } label: {
                        Label("Konto", systemImage: "person.crop.circle")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(points.balance) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .font(.caption)
                        .accessibilityLabel("Punktestand \(points.balance)")
                }
            }
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView()
            }
            .sheet(isPresented: $showAdd) {
                AddEditCardView(mode: .add)
            }
            .onAppear {
                SeedLoader.bootstrap(in: context)
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animateScanButton = true
                }
            }
            .task {
                await priceRefresher.autoRefreshIfDue(
                    items: realItems,
                    username: auth.currentUser?.username,
                    context: context
                )
            }
        }
    }

    // MARK: - Bausteine

    private var brandHeader: some View {
        HStack(spacing: 14) {
            BrandLogo(size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("PokéJ")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(AppTheme.ink)
                Text(greeting)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    /// Großer Scan-Button als zentrales Element – immer gut erreichbar.
    private var scanCallToAction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Karte scannen")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("Fotografiere deine Pokémon-Karte – PokéJ erkennt sie automatisch.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            Button {
                showScanner = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2.weight(.semibold))
                    Text("Jetzt scannen")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .fill(AppTheme.brandGradient)
                        .overlay(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                            .blendMode(.overlay)
                            .opacity(0.5)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: AppTheme.accent.opacity(0.5), radius: 16, y: 8)
                .scaleEffect(animateScanButton ? 1.02 : 1)
                .animation(AppTheme.Motion.gentle, value: animateScanButton)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }

    private var valueCard: some View {
        let value = CollectionStats.value(items: realItems, snapshots: snapshots)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sammlungswert")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(PriceFormatting.currency(value.total, code: value.currency))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                        .monospacedDigit()
                }
                Spacer()
                if priceRefresher.isRefreshing {
                    ProgressView()
                        .tint(AppTheme.gold)
                } else {
                    Button {
                        Task {
                            await priceRefresher.refresh(
                                items: realItems,
                                username: auth.currentUser?.username,
                                context: context
                            )
                        }
                    } label: {
                        Label("Aktualisieren", systemImage: "arrow.clockwise.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            HStack(spacing: 14) {
                if value.unpricedCount > 0 {
                    statChip("\(value.unpricedCount) ohne Preis", icon: "questionmark.circle")
                }
                if value.staleCount > 0 {
                    statChip("\(value.staleCount) veraltet", icon: "exclamationmark.triangle")
                }
                if value.unpricedCount == 0, value.staleCount == 0 {
                    statChip("Alle Preise aktuell", icon: "checkmark.circle.fill", color: .green)
                }
            }
            .font(.caption2)
            PriceRefreshStatusText(
                username: auth.currentUser?.username,
                note: priceRefresher.note
            )
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
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    private func statChip(_ text: String, icon: String, color: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color ?? AppTheme.gold)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((color ?? AppTheme.accent).opacity(0.15), in: Capsule())
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Übersicht", systemImage: "chart.bar.fill")
            LazyVGrid(columns: statColumns, spacing: 12) {
                StatTile(icon: "shippingbox.fill", value: "\(CollectionStats.totalQuantity(realItems))", label: "Karten", color: AppTheme.accent)
                StatTile(icon: "rectangle.stack.fill", value: "\(CollectionStats.uniqueCardCount(realItems))", label: "Verschiedene", color: AppTheme.gold)
                StatTile(icon: "square.grid.2x2.fill", value: "\(CollectionStats.setCount(realItems))", label: "Sets", color: AppTheme.ledGreen)
                StatTile(icon: "sparkles", value: "\(fictionalQuantity)", label: "PokeJ-Karten", color: AppTheme.ledGold)
                StatTile(icon: "point.3.connected.trianglepath.dotted", value: "\(points.balance)", label: "Punkte", color: AppTheme.accent)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Schnellaktionen", systemImage: "bolt.fill")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                QuickActionButton(
                    title: "Karte hinzufügen",
                    subtitle: "Manuell suchen",
                    icon: "plus.circle.fill",
                    color: AppTheme.accent
                ) {
                    showAdd = true
                }
                QuickActionButton(
                    title: "Packs öffnen",
                    subtitle: "Fiktive Booster",
                    icon: "gift.fill",
                    color: AppTheme.gold
                ) {
                    // Packs-Tab wird über TabView gewechselt – hier nur Hinweis
                }
                .disabled(true)
                .opacity(0.5)
            }
        }
    }

    private var recentCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Letzte Zugänge", systemImage: "clock.arrow.circlepath")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(realItems.prefix(8)) { item in
                        NavigationLink {
                            CardDetailView(item: item)
                        } label: {
                            CollectionItemCard(item: item)
                                .frame(width: 150)
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
            }
        }
    }

    private var recentScans: some View {
        VStack(alignment: .leading, spacing: 12) {
            PokedexSectionHeader(title: "Letzte Scans", systemImage: "viewfinder")
            if scans.isEmpty {
                emptyState(
                    icon: "viewfinder",
                    title: "Noch keine Scans",
                    subtitle: "Scanne deine erste Karte, um sie der Sammlung hinzuzufügen."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(scans.prefix(5)) { scan in
                        ScanHistoryRow(scan: scan)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .fill(AppTheme.elevatedAlt)
                        .overlay(AppTheme.glossyCardGradient
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                            .blendMode(.overlay)
                            .opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            }
        }
    }

    private var greeting: String {
        if let name = auth.currentUser?.displayName, !name.isEmpty {
            return "Hallo, \(name)"
        }
        return "Willkommen"
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevatedAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 1)
        )
    }

    // MARK: - Preise
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(AppTheme.elevated)
                    .overlay(AppTheme.glossyCardGradient
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .blendMode(.overlay)
                        .opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ScanHistoryRow: View {
    let scan: ScanRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: scanIcon(scan.status))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scanColor(scan.status))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.status.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                if !scan.candidateSummary.isEmpty {
                    Text(scan.candidateSummary)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(PriceFormatting.relative(scan.timestamp, now: Date()))
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.vertical, 4)
    }

    private func scanIcon(_ status: ScanStatus) -> String {
        switch status {
        case .recognized: return "checkmark.seal.fill"
        case .likely: return "checkmark.circle"
        case .multiple: return "square.stack.3d.up"
        case .noMatch: return "questionmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    private func scanColor(_ status: ScanStatus) -> Color {
        switch status {
        case .recognized: return .green
        case .likely: return AppTheme.gold
        case .multiple, .noMatch: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthStore())
        .environmentObject(PointsStore())
        .environment(PriceRefreshCoordinator(provider: MockPriceProvider()))
        .modelContainer(PreviewData.container)
}