import SwiftData
import SwiftUI

/// Eine gekaufte, noch nicht bestätigte Pack-Öffnung.
struct PackOpening: Identifiable {
    let id = UUID()
    let pack: PackDefinition
    let pulls: [PackPull]
}

/// Öffnet ein fiktives Booster wie ein echtes Pack: erst aufreißen, dann die
/// Karten einzeln nacheinander ziehen und schließlich der Sammlung hinzufügen.
struct PackOpeningView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var points: PointsStore

    let opening: PackOpening

    @State private var isRipped = false
    @State private var ripProgress: CGFloat = 0
    @State private var revealedCount = 0
    @State private var hasAdded = false
    @State private var addSummary: String?
    @State private var showDiscardWarning = false
    @State private var shine = false

    private var pulls: [PackPull] { opening.pulls }
    private var total: Int { pulls.count }
    private var allRevealed: Bool { total == 0 || revealedCount >= total }
    private var current: PackPull? {
        guard revealedCount > 0, revealedCount <= total else { return nil }
        return pulls[revealedCount - 1]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if !isRipped {
                            sealedPack
                        } else {
                            revealArea
                            drawnRow
                            if allRevealed {
                                footerActions
                            }
                        }
                    }
                    .padding()
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
        VStack(spacing: 18) {
            Text("PokeJ Booster")
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.textSecondary)

            ZStack {
                BoosterPackArt(pack: opening.pack, width: 260)
                shineSweep
                ripOverlay
            }
            .scaleEffect(shine ? 1.02 : 1.0)
            .animation(AppTheme.Motion.bouncy, value: shine)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let progress = min(max(value.translation.height / 120, 0), 1)
                        ripProgress = progress
                    }
                    .onEnded { value in
                        if ripProgress >= 0.55 {
                            ripOpen()
                        } else {
                            withAnimation(AppTheme.Motion.smooth) {
                                ripProgress = 0
                            }
                        }
                    }
            )

            VStack(spacing: 4) {
                Text(opening.pack.contentsText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                if let era = opening.pack.eraName {
                    Text("\(era) · \(opening.pack.releaseYearText ?? "")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if ripProgress > 0 {
                Text("Nach unten wischen, um aufzureißen")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                Button {
                    ripOpen()
                } label: {
                    Label("Pack aufreißen", systemImage: "hand.draw")
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                shine = true
            }
        }
    }

    /// Riss-Overlay über dem Pack, wächst mit der Wisch-Geste.
    private var ripOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 260 * 0.10, style: .continuous)
                .stroke(AppTheme.gold, lineWidth: 3)
                .opacity(ripProgress)
                .scaleEffect(1.0 + ripProgress * 0.15, anchor: .center)
            if ripProgress > 0.3 {
                Text("✂")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.gold)
                    .offset(y: 260 * 0.35 * ripProgress)
            }
        }
        .allowsHitTesting(false)
        .animation(AppTheme.Motion.snappy, value: ripProgress)
    }

    private var shineSweep: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            LinearGradient(
                colors: [.clear, .white.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: w * 0.35, height: proxy.size.height * 1.6)
            .rotationEffect(.degrees(18))
            .offset(x: shine ? w * 1.0 : -w * 0.6)
            .blendMode(.softLight)
            .allowsHitTesting(false)
        }
        .frame(width: 260, height: 260 / 0.70)
        .mask(BoosterPackArt(pack: opening.pack, width: 260))
    }

    // MARK: - Karte für Karte

    private var revealArea: some View {
        VStack(spacing: 14) {
            if let current {
                RevealCardView(pull: current)
                    .id(revealedCount)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < revealedCount ? AppTheme.accent : Color.white.opacity(0.18))
                        .frame(width: 7, height: 7)
                }
            }

            Text("Karte \(revealedCount) von \(total)")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            if !allRevealed {
                HStack(spacing: 10) {
                    Button {
                        drawNext()
                    } label: {
                        Label("Nächste Karte", systemImage: "hand.tap.fill")
                    }
                    .buttonStyle(BrandButtonStyle())

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
                                LockedThumb(pack: opening.pack)
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
        VStack(spacing: 12) {
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
                    .foregroundStyle(AppTheme.textSecondary)
            }
            if hasAdded {
                Button("Fertig") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Aktionen

    private func ripOpen() {
        withAnimation(AppTheme.Motion.bouncy) {
            isRipped = true
            revealedCount = min(1, total)
        }
    }

    private func drawNext() {
        guard !allRevealed else { return }
        withAnimation(AppTheme.Motion.smooth) {
            revealedCount += 1
        }
    }

    private func revealAll() {
        withAnimation(AppTheme.Motion.smooth) {
            revealedCount = total
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
        let parts = [
            added > 0 ? "\(added) neue Karten" : nil,
            merged > 0 ? "\(merged) zusammengeführt" : nil
        ].compactMap { $0 }
        let base = parts.isEmpty ? "Bereits in der Sammlung" : parts.joined(separator: " · ")
        addSummary = "\(base) · \(points.balance) Punkte übrig"
    }
}

/// Große Karte in der Aufdeck-Phase mit Klapp-/Glanzanimation.
private struct RevealCardView: View {
    let pull: PackPull

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
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
            .frame(maxWidth: 280)
            .overlay(alignment: .topTrailing) {
                if pull.isHolo {
                    Text("HOLO")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.goldGradient, in: Capsule())
                        .padding(8)
                }
            }
            .shadow(color: pull.isHolo ? AppTheme.gold.opacity(0.5) : .black.opacity(0.4), radius: 18, y: 10)
            .rotation3DEffect(.degrees(appeared ? 0 : 75), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 2) {
                Text(pull.card.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text("#\(pull.card.localId) · \(pull.set.name)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
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

/// Kleine aufgedeckte Karte in der Ziehungsleiste.
private struct PullThumb: View {
    let pull: PackPull

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: pull.imageURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                }
            }
            .aspectRatio(0.72, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topTrailing) {
                if pull.isHolo {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(AppTheme.goldGradient, in: Circle())
                        .padding(2)
                }
            }
            Text("#\(pull.card.localId)")
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }
}

/// Noch nicht gezogene, verdeckte Karte.
private struct LockedThumb: View {
    let pack: PackDefinition

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(AppTheme.gold.opacity(0.35))
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "questionmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
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
