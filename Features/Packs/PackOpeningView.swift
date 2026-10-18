import SwiftData
import SwiftUI
import UIKit

/// Eine gekaufte, noch nicht bestätigte Pack-Öffnung.
struct PackOpening: Identifiable {
    let id = UUID()
    let pack: PackDefinition
    let pulls: [PackPull]
}

/// Öffnet ein fiktives Booster wie ein echtes Pack: erst aufreißen (der
/// Reißstreifen fliegt weg), dann die Karten einzeln **aus dem Booster** ziehen
/// und schließlich der Sammlung hinzufügen.
struct PackOpeningView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var points: PointsStore

    let opening: PackOpening

    /// Echte Pack-Reihenfolge: gewöhnliche Karten zuerst, der Holo kommt –
    /// wie im echten Booster – ganz zum Schluss.
    private let pulls: [PackPull]

    @State private var isRipped = false
    @State private var ripProgress: CGFloat = 0
    @State private var revealedCount = 0
    @State private var isDrawing = false
    @State private var hasAdded = false
    @State private var addSummary: String?
    @State private var showDiscardWarning = false
    @State private var shine = false
    @State private var bob = false

    init(opening: PackOpening) {
        self.opening = opening
        self.pulls = opening.pulls.filter { !$0.isHolo } + opening.pulls.filter { $0.isHolo }
    }

    private var total: Int { pulls.count }
    private var allRevealed: Bool { total == 0 || revealedCount >= total }
    private var cardsLeft: Int { max(total - revealedCount, 0) }
    private var holoCount: Int { pulls.filter(\.isHolo).count }
    private var current: PackPull? {
        guard revealedCount > 0, revealedCount <= total else { return nil }
        return pulls[revealedCount - 1]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.appBackground.ignoresSafeArea()
                AmbientDots().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        if !isRipped {
                            sealedPack
                        } else {
                            boosterStage
                            revealArea
                            drawnRow
                            if allRevealed {
                                footerActions
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(opening.pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        if hasAdded || !isRipped { dismiss() } else { showDiscardWarning = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(opening.pack.cost) P", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .confirmationDialog(
                "Pack verwerfen?",
                isPresented: $showDiscardWarning,
                titleVisibility: .visible
            ) {
                Button("Verwerfen", role: .destructive) { dismiss() }
                Button("Behalten", role: .cancel) {}
            } message: {
                Text("Die gezogenen Karten werden verworfen; die Punkte sind bereits ausgegeben.")
            }
        }
    }

    // MARK: - Versiegeltes Pack

    private var sealedPack: some View {
        VStack(spacing: 20) {
            Text("POKEJ BOOSTER")
                .font(.caption.weight(.heavy))
                .tracking(2.0)
                .foregroundStyle(AppTheme.textSecondary)

            ZStack {
                BoosterPackArt(pack: opening.pack, width: 250)
                shineSweep
                ripOverlay
            }
            .scaleEffect(bob ? 1.012 : 0.988)
            .rotationEffect(.degrees(bob ? -0.7 : 0.7))
            .shadow(color: AppTheme.accent.opacity(0.35), radius: bob ? 26 : 16, y: 12)
            .onTapGesture { ripOpen() }
            .highPriorityGesture(ripGesture)
            .onAppear { startIdleMotion() }

            VStack(spacing: 4) {
                Text(opening.pack.contentsText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                if let era = opening.pack.eraName {
                    Text("\(era) · \(opening.pack.releaseYearText ?? "")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            ripHint

            if ripProgress <= 0.01 {
                Button {
                    ripOpen()
                } label: {
                    Label("Pack aufreißen", systemImage: "hand.draw")
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal)
            }
        }
    }

    /// Hinweis-Guide, der mit dem Reiß-Fortschritt an Intensität gewinnt.
    private var ripHint: some View {
        VStack(spacing: 8) {
            if ripProgress > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .rotationEffect(.degrees(90))
                    Text("Weiterziehen zum Aufreißen")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.gold)

                Capsule()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 180 * max(ripProgress, 0.06), height: 6)
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    .animation(AppTheme.Motion.snappy, value: ripProgress)
            } else {
                Text("Wischen oder tippen zum Aufreißen")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(height: 44)
    }

    /// Riss-Overlay: goldener Ring, Schere wandert über die Oberkante.
    private var ripOverlay: some View {
        let packWidth: CGFloat = 250
        let packHeight = packWidth / 0.70
        return ZStack {
            RoundedRectangle(cornerRadius: packWidth * 0.10, style: .continuous)
                .stroke(AppTheme.gold, lineWidth: 3)
                .opacity(ripProgress * 0.9)
                .scaleEffect(1.0 + ripProgress * 0.12, anchor: .center)

            if ripProgress > 0.05 {
                Image(systemName: "scissors")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
                    .shadow(color: AppTheme.gold.opacity(0.8), radius: 8)
                    .offset(
                        x: (ripProgress - 0.5) * packWidth * 0.9,
                        y: -packHeight * 0.40
                    )
            }
        }
        .allowsHitTesting(false)
        .animation(AppTheme.Motion.snappy, value: ripProgress)
    }

    private var shineSweep: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            LinearGradient(
                colors: [.clear, .white.opacity(0.38), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: w * 0.32, height: proxy.size.height * 1.6)
            .rotationEffect(.degrees(18))
            .offset(x: shine ? w * 1.0 : -w * 0.6)
            .blendMode(.softLight)
            .allowsHitTesting(false)
        }
        .frame(width: 250, height: 250 / 0.70)
        .mask(BoosterPackArt(pack: opening.pack, width: 250))
        .allowsHitTesting(false)
    }

    private var ripGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let distance = max(abs(value.translation.width), abs(value.translation.height))
                ripProgress = min(max(distance / 140, 0), 1)
            }
            .onEnded { _ in
                if ripProgress >= 0.55 {
                    ripOpen()
                } else {
                    withAnimation(AppTheme.Motion.smooth) { ripProgress = 0 }
                }
            }
    }

    // MARK: - Offener Booster (Karten werden einzeln gezogen)

    private var boosterStage: some View {
        let packWidth: CGFloat = 136
        let packHeight = packWidth / 0.70

        return VStack(spacing: 10) {
            ZStack {
                // Verbleibende Karten schauen aus der gerissenen Öffnung.
                DeckPeekView(count: cardsLeft)
                    .offset(y: -packHeight * 0.5 + (108 / 0.72) * 0.5 - 6)

                BoosterPackArt(pack: opening.pack, width: packWidth)
                    .mask { TornEdgeShape(depth: 11) }
                    .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
                    .overlay(alignment: .top) {
                        TornStrip(pack: opening.pack, width: packWidth)
                    }
            }
            .frame(width: packWidth + 60, height: packHeight + 24)
            .scaleEffect(cardsLeft == 0 ? 0.92 : 1)
            .opacity(cardsLeft == 0 ? 0.35 : 1)
            .animation(AppTheme.Motion.smooth, value: cardsLeft)
            .contentShape(Rectangle())
            .onTapGesture { drawNext() }
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        if value.translation.height < -30 { drawNext() }
                    }
            )

            if cardsLeft > 0 {
                Label(
                    cardsLeft == 1 ? "Letzte Karte ziehen" : "Ziehe die nächste Karte",
                    systemImage: "hand.tap.fill"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
            } else {
                Label("Booster geleert", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mint)
            }
        }
    }

    // MARK: - Karte für Karte

    @ViewBuilder
    private var revealArea: some View {
        VStack(spacing: 14) {
            if let current {
                RevealCardView(pull: current)
                    .id(revealedCount)
                    .transition(.identity)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(AppTheme.stroke, style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        )
                    Text("Noch nichts gezogen")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .aspectRatio(0.72, contentMode: .fit)
                .frame(maxWidth: 220)
            }

            progressBar

            HStack(spacing: 6) {
                Text("Karte \(min(revealedCount, total)) von \(total)")
                if holoCount > 0 {
                    Text("·")
                    Label("\(holoCount) Holo", systemImage: "sparkles")
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)

            if !allRevealed {
                HStack(spacing: 10) {
                    Button {
                        drawNext()
                    } label: {
                        Label(
                            current == nil ? "Karte ziehen" : "Nächste Karte ziehen",
                            systemImage: "arrow.up.to.line.compact"
                        )
                    }
                    .buttonStyle(BrandButtonStyle())
                    .disabled(isDrawing)

                    Button {
                        revealAll()
                    } label: {
                        Label("Alle", systemImage: "forward.fill")
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.horizontal)
            }
        }
    }

    /// Segmentierter Fortschrittsbalken – Holo-Segmente leuchten golden.
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                let isRevealed = index < revealedCount
                let isHoloSlot = index < total && pulls[index].isHolo

                Capsule()
                    .fill(
                        isRevealed
                            ? AnyShapeStyle(isHoloSlot ? AppTheme.goldGradient : AppTheme.brandGradient)
                            : AnyShapeStyle(Color.white.opacity(0.12))
                    )
                    .frame(height: 7)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isRevealed && isHoloSlot ? Color.white.opacity(0.5) : .clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isRevealed && isHoloSlot ? AppTheme.gold.opacity(0.7) : .clear,
                        radius: 5
                    )
            }
        }
        .padding(.horizontal, 4)
        .animation(AppTheme.Motion.smooth, value: revealedCount)
    }

    private var drawnRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            PokedexSectionHeader(title: "Gezogen", systemImage: "rectangle.stack.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(pulls.enumerated()), id: \.element.id) { index, pull in
                        Group {
                            if index < revealedCount {
                                PullThumb(pull: pull)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                CardBackArt()
                                    .aspectRatio(0.72, contentMode: .fit)
                                    .opacity(0.55)
                            }
                        }
                        .frame(width: 58)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .animation(AppTheme.Motion.bouncy, value: revealedCount)
    }

    // MARK: - Abschluss

    private var footerActions: some View {
        VStack(spacing: 14) {
            summaryPanel

            if !hasAdded {
                Button {
                    addAllToCollection()
                } label: {
                    Label("Zur PokeJ-Sammlung hinzufügen", systemImage: "tray.and.arrow.down.fill")
                }
                .buttonStyle(BrandButtonStyle())
            }
            if let addSummary {
                Label(addSummary, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mint)
                    .transition(.scale.combined(with: .opacity))
            }
            if hasAdded {
                Button("Fertig") { dismiss() }
                    .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    /// Verspielte Auswertung des Zugs: Karten, Holo-Treffer und kleine Sticker.
    private var summaryPanel: some View {
        HStack(spacing: 10) {
            SummaryChip(
                value: "\(total)",
                label: total == 1 ? "Karte" : "Karten",
                systemImage: "rectangle.stack.fill",
                tint: AppTheme.accent
            )
            SummaryChip(
                value: "\(holoCount)",
                label: "Holo",
                systemImage: "sparkles",
                tint: AppTheme.gold
            )
            SummaryChip(
                value: opening.pack.name,
                label: opening.pack.eraName ?? "Set",
                systemImage: "gift.fill",
                tint: AppTheme.mint,
                isText: true
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
    }

    // MARK: - Aktionen

    private func ripOpen() {
        guard !isRipped else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(AppTheme.Motion.bouncy) {
            isRipped = true
            ripProgress = 0
        }
    }

    private func drawNext() {
        guard !allRevealed, !isDrawing else { return }
        let next = pulls[revealedCount]

        isDrawing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(AppTheme.Motion.smooth) {
            revealedCount += 1
        }
        if next.isHolo {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 340_000_000)
            isDrawing = false
        }
    }

    private func revealAll() {
        guard !allRevealed else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let hasHoloAhead = pulls[revealedCount...].contains(where: \.isHolo)
        withAnimation(AppTheme.Motion.smooth) {
            revealedCount = total
        }
        if hasHoloAhead {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func startIdleMotion() {
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            bob = true
        }
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
            shine = true
        }
    }

    @MainActor
    private func addAllToCollection() {
        guard !hasAdded else { return }

        let repository = CollectionRepository(context: context)
        var added = 0
        var merged = 0
        let notes = "Aus Pack geöffnet"

        for pull in pulls {
            let brief = CardBrief(
                id: pull.card.id,
                name: pull.card.name,
                setId: pull.set.id,
                setName: pull.set.name,
                localId: pull.card.localId,
                rarity: nil,
                imageURL: pull.highResURL
            )
            let card = repository.findOrCreateCard(from: brief)
            if let existing = repository.existingItem(
                card: card,
                language: .de,
                printing: pull.printing,
                condition: .nearMint,
                notes: notes
            ) {
                existing.quantity += 1
                merged += 1
            } else {
                let item = CollectionItem(
                    quantity: 1,
                    confirmedCondition: .nearMint,
                    notes: notes,
                    origin: .pack
                )
                repository.addCollectionItem(card: card, language: .de, printing: pull.printing, item: item)
                added += 1
            }
        }

        do {
            try context.save()
        } catch {
            addSummary = "Speichern fehlgeschlagen: \(error.localizedDescription)"
            return
        }

        points.recordOpening(pack: opening.pack, pulls: pulls)
        hasAdded = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let parts = [
            added > 0 ? "\(added) neue Karten" : nil,
            merged > 0 ? "\(merged) zusammengeführt" : nil
        ].compactMap { $0 }
        let base = parts.isEmpty ? "Bereits in der Sammlung" : parts.joined(separator: " · ")
        withAnimation(AppTheme.Motion.bouncy) {
            addSummary = "\(base) · \(points.balance) Punkte übrig"
        }
    }
}

// MARK: - Aufdeck-Phase

/// Große Karte, die sichtbar aus dem Booster herausgezogen wird:
/// gleitet von unten (aus der Pack-Öffnung) herein und klappert um.
private struct RevealCardView: View {
    let pull: PackPull

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                cardImage
                if pull.isHolo {
                    holoSheen
                    sparkleBurst
                }
            }
            .rotation3DEffect(.degrees(appeared ? 0 : -78), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
            .scaleEffect(appeared ? 1 : 0.55)
            .offset(y: appeared ? 0 : -70)
            .opacity(appeared ? 1 : 0)
            .shadow(
                color: pull.isHolo ? AppTheme.gold.opacity(0.55) : .black.opacity(0.45),
                radius: 20,
                y: 12
            )
            .overlay(alignment: .topTrailing) {
                if pull.isHolo {
                    Text("HOLO")
                        .font(.caption2.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.goldGradient, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 1))
                        .padding(8)
                        .scaleEffect(appeared ? 1 : 0.4)
                }
            }

            VStack(spacing: 2) {
                Text(pull.card.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text("#\(pull.card.localId) · \(pull.set.name)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private var cardImage: some View {
        Group {
            if let url = pull.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            placeholder
                            ProgressView()
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Streifender Regenbogen-Glanz über der Holofläche.
    private var holoSheen: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.6, blue: 0.8).opacity(0.35),
                Color(red: 0.5, green: 0.85, blue: 1.0).opacity(0.30),
                Color(red: 1.0, green: 0.9, blue: 0.5).opacity(0.30)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.screen)
        .opacity(appeared ? 1 : 0)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: appeared)
        .allowsHitTesting(false)
    }

    /// Kleine Funkel-Burst-Animation beim Aufdecken eines Holos.
    private var sparkleBurst: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) / 8 * 2 * .pi
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "sparkles")
                    .font(.system(size: index.isMultiple(of: 2) ? 12 : 16, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
                    .offset(
                        x: cos(angle) * (appeared ? 88 : 12),
                        y: sin(angle) * (appeared ? 118 : 12)
                    )
                    .opacity(appeared ? 0 : 1)
                    .scaleEffect(appeared ? 0.3 : 1)
            }
        }
        .allowsHitTesting(false)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
            Image(systemName: "rectangle.portrait.slash")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

// MARK: - Booster-Detailansichten

/// Aufgeschichtete Kartenrücken, die aus der gerissenen Booster-Öffnung
/// herausgucken. Wird pro gezogener Karte dünner.
private struct DeckPeekView: View {
    let count: Int

    var body: some View {
        let visible = Swift.min(count, 4)

        ZStack {
            ForEach(0..<visible, id: \.self) { index in
                CardBackArt()
                    .frame(width: 108, height: 150)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -1.8 : 2.2))
                    .offset(y: CGFloat(-index * 6))
                    .opacity(1 - Double(index) * 0.14)
            }
        }
        .animation(AppTheme.Motion.smooth, value: count)
    }
}

/// Der abgerissene Reißstreifen, der beim Öffnen wegfliegt.
private struct TornStrip: View {
    let pack: PackDefinition
    var width: CGFloat

    @State private var flown = false

    private var height: CGFloat { width * 0.14 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: BoosterPalette.colors(for: pack.serieId),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.white.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
        }
        .frame(width: width, height: height)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(height: Swift.max(width * 0.025, 2))
        }
        .clipShape(TornEdgeShape(atTop: false, depth: height * 0.45))
        .overlay(
            TornEdgeShape(atTop: false, depth: height * 0.45)
                .stroke(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .rotationEffect(.degrees(flown ? 42 : 0))
        .offset(x: flown ? width * 0.8 : 0, y: flown ? -height * 3.4 : 0)
        .opacity(flown ? 0 : 1)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.6).delay(0.06)) {
                flown = true
            }
        }
    }
}

/// Kartenrückseite im App-Farbschema (verspielt: Poké-Ball + Goldrand).
struct CardBackArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accent,
                            Color(red: 0.20, green: 0.15, blue: 0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .blendMode(.softLight)
            PokeballMark()
                .frame(width: 44, height: 44)
                .opacity(0.5)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.gold.opacity(0.75), lineWidth: 2)
                .padding(2.5)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
    }
}

/// Zackige Kante, die die gerissene Öffnung des Booster-Beutels darstellt.
struct TornEdgeShape: Shape {
    var atTop: Bool = true
    var depth: CGFloat = 10
    var teeth: Int = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let d = Swift.min(depth, rect.height * 0.3)
        let width = rect.width / CGFloat(teeth)
        let start = CGPoint(x: rect.minX, y: atTop ? rect.minY + d : rect.maxY - d)

        path.move(to: start)

        for index in 0..<teeth {
            let midX = rect.minX + width * (CGFloat(index) + 0.5)
            let endX = rect.minX + width * CGFloat(index + 1)
            let highY = atTop ? rect.minY : rect.maxY - d
            let lowY = atTop ? rect.minY + d : rect.maxY
            let tipY = index.isMultiple(of: 2) ? highY : lowY
            let endY = index.isMultiple(of: 2) ? lowY : highY

            path.addLine(to: CGPoint(x: midX, y: tipY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }

        if atTop {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

/// Kleine Statistik-Würfel für die Pack-Auswertung.
private struct SummaryChip: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color
    var isText: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            if isText {
                Text(value)
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(value)
                    .font(.title3.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
            Label(label, systemImage: systemImage)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
    }
}

/// Dezente schwebende Punkte im Hintergrund – verspielte Atmosphäre.
private struct AmbientDots: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let hue = index % 3
                Circle()
                    .fill(
                        hue == 0
                            ? AppTheme.gold.opacity(0.10)
                            : (hue == 1 ? AppTheme.mint.opacity(0.08) : Color.white.opacity(0.05))
                    )
                    .frame(width: CGFloat(3 + (index * 5) % 8))
                    .offset(
                        x: CGFloat((index * 97) % 300) - 150,
                        y: CGFloat((index * 173) % 620) - 310
                    )
                    .offset(y: drift ? -10 : 6)
                    .animation(
                        .easeInOut(duration: 3.5 + Double(index % 4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.25),
                        value: drift
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { drift = true }
    }
}

#Preview {
    PackOpeningView(
        opening: PackOpening(
            pack: PackDefinition(
                id: "base1",
                name: "Grundset",
                cost: 100,
                cardCount: 6,
                holoGuarantee: 1,
                iconName: "shippingbox",
                setId: "base1",
                setName: "Grundset",
                serieId: "base",
                eraName: "Klassik (Base & Co.)",
                releaseYear: 1999,
                logoURL: URL(string: "https://assets.tcgdex.net/en/base/base1/logo.webp")
            ),
            pulls: []
        )
    )
    .environmentObject(PointsStore(defaults: UserDefaults(suiteName: "preview.opening")!))
    .modelContainer(for: [Card.self, CardVariant.self, CollectionItem.self], inMemory: true)
}
