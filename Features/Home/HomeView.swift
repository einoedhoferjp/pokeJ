import SwiftUI
import SwiftData

/// Startseite: Dashboard über die eigene Sammlung mit großer Scan-Aktion.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.priceProvider) private var priceProvider
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var points: PointsStore

    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @Query(sort: \PriceSnapshot.fetchedAt, order: .reverse) private var snapshots: [PriceSnapshot]
    @Query(sort: \ScanRecord.timestamp, order: .reverse) private var scans: [ScanRecord]

    @State private var showScanner = false
    @State private var showAdd = false
    @State private var isRefreshing = false
    @State private var refreshNote: String?

    private let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    brandHeader
                    scanCallToAction
                    valueCard
                    statsGrid
                    quickActions
                    if !items.isEmpty { recentCards }
                    recentScans
                }
                .padding()
            }
            .navigationTitle("Start")
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
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(points.balance) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .font(.caption)
                        .accessibilityLabel("Punktestand \(points.balance)")
                }
            }
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerView()
        }
        .sheet(isPresented: $showAdd) {
            AddEditCardView(mode: .add)
        }
        .onAppear {
            SeedLoader.seedIfNeeded(in: context)
        }
        .task { await autoRefreshIfDue() }
    }

    // MARK: - Bausteine

    private var brandHeader: some View {
        HStack(spacing: 12) {
            BrandLogo(size: 52)
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
    }

    private var scanCallToAction: some View {
        PokedexPanel(title: "Scanner", statusLED: AppTheme.ledGreen) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Erfasse deine Karten mit der Kamera – direkt in die Sammlung.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Button {
                    showScanner = true
                } label: {
                    Label("Karte scannen", systemImage: "camera.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(BrandButtonStyle())
            }
        }
    }

    private var valueCard: some View {
        let value = CollectionStats.value(items: items, snapshots: snapshots)
        return PokedexPanel(title: "Sammlung", statusLED: AppTheme.ledGold) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sammlungswert")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(PriceFormatting.currency(value.total, code: value.currency))
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                            .monospacedDigit()
                    }
                    Spacer()
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Button {
                            Task { await refreshPrices() }
                        } label: {
                            Label("Preise aktualisieren", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(GlassButtonStyle())
                        .font(.caption)
                    }
                }
                HStack(spacing: 12) {
                    if value.unpricedCount > 0 {
                        Label("\(value.unpricedCount) ohne Preis", systemImage: "questionmark.circle")
                    }
                    if value.staleCount > 0 {
                        Label("\(value.staleCount) veraltet", systemImage: "exclamationmark.triangle")
                    }
                    if value.unpricedCount == 0, value.staleCount == 0 {
                        Label("Alle Preise aktuell", systemImage: "checkmark.circle")
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                if let refreshNote {
                    Text(refreshNote)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                } else if let last = PriceRefreshLog().lastFullRefresh {
                    Text("Preise aktualisiert \(PriceFormatting.relative(last, now: Date()))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            PokedexSectionHeader(title: "Übersicht", systemImage: "chart.bar.fill")
            LazyVGrid(columns: statColumns, spacing: 12) {
                StatTile(icon: "shippingbox.fill", value: "\(CollectionStats.totalQuantity(items))", label: "Karten")
                StatTile(icon: "rectangle.stack.fill", value: "\(CollectionStats.uniqueCardCount(items))", label: "Verschiedene Karten")
                StatTile(icon: "square.grid.2x2.fill", value: "\(CollectionStats.setCount(items))", label: "Sets")
                StatTile(icon: "point.3.connected.trianglepath.dotted", value: "\(points.balance)", label: "Punkte")
            }
        }
    }

    private var quickActions: some View {
        Button {
            showAdd = true
        } label: {
            Label("Karte manuell hinzufügen", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private var recentCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            PokedexSectionHeader(title: "Letzte Zugänge", systemImage: "clock.arrow.circlepath")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items.prefix(8)) { item in
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

    @ViewBuilder
    private var recentScans: some View {
        VStack(alignment: .leading, spacing: 10) {
            PokedexSectionHeader(title: "Letzte Scans", systemImage: "viewfinder")
            if scans.isEmpty {
                Text("Noch keine Scans. Starte oben mit „Karte scannen\".")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(scans.prefix(5)) { scan in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: scanIcon(scan.status))
                                .foregroundStyle(scanColor(scan.status))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scan.status.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.ink)
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
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .surfaceCard()
            }
        }
    }

    private var greeting: String {
        if let name = auth.currentUser?.displayName, !name.isEmpty {
            return "Hallo, \(name)"
        }
        return "Willkommen"
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

    // MARK: - Preise

    @MainActor
    private func autoRefreshIfDue() async {
        guard !items.isEmpty, !isRefreshing else { return }
        guard PriceRefreshLog().isRefreshDue() else { return }
        await refreshPrices()
    }

    @MainActor
    private func refreshPrices() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshNote = nil
        let service = PriceService(provider: priceProvider, context: context)
        let summary = await service.refresh(items: items)
        isRefreshing = false

        if summary.failedTargets == 0 {
            PriceRefreshLog().markRefreshed()
        }

        var parts: [String] = []
        if summary.insertedSnapshots > 0 { parts.append("\(summary.insertedSnapshots) neue Preisstände") }
        if summary.updatedVariants > 0 { parts.append("\(summary.updatedVariants) Varianten aktualisiert") }
        if summary.failedTargets > 0 { parts.append("\(summary.failedTargets) fehlgeschlagen") }
        refreshNote = parts.isEmpty ? "Preise sind aktuell." : parts.joined(separator: " · ")
    }
}

private struct StatTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .surfaceCard(radius: AppTheme.cardRadiusSmall, padding: 12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthStore())
        .environmentObject(PointsStore())
        .modelContainer(PreviewData.container)
}
