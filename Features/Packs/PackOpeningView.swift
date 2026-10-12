import SwiftData
import SwiftUI

/// Eine gekaufte, noch nicht bestätigte Pack-Öffnung.
struct PackOpening: Identifiable {
    let id = UUID()
    let pack: PackDefinition
    let pulls: [PackPull]
}

/// Zeigt ein geöffnetes Pack und fügt die Ziehungen auf Wunsch der Sammlung hinzu.
struct PackOpeningView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var points: PointsStore

    let opening: PackOpening

    @State private var isRevealed = false
    @State private var hasAdded = false
    @State private var addSummary: String?
    @State private var showDiscardWarning = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if !isRevealed {
                        openButton
                    }
                    cardsGrid
                    if isRevealed && !hasAdded {
                        addButton
                    }
                    if let addSummary {
                        Label(addSummary, systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if hasAdded {
                        Button("Fertig") { dismiss() }
                            .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle(opening.pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        if hasAdded { dismiss() } else { showDiscardWarning = true }
                    }
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

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: opening.pack.iconName)
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accent)
            Text(opening.pack.contentsText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(opening.pack.cost) Punkte ausgegeben")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var openButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isRevealed = true
            }
        } label: {
            Label("Pack öffnen", systemImage: "sparkles")
        }
        .buttonStyle(BrandButtonStyle())
        .padding(.horizontal)
    }

    private var cardsGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(opening.pulls.enumerated()), id: \.element.id) { index, pull in
                if isRevealed {
                    PullCardView(pull: pull)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25).delay(Double(index) * 0.08), value: isRevealed)
                } else {
                    cardBack
                }
            }
        }
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.goldGradient)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: opening.pack.iconName)
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private var addButton: some View {
        Button {
            addAllToCollection()
        } label: {
            Label("Zur Sammlung hinzufügen", systemImage: "tray.and.arrow.down.fill")
        }
        .buttonStyle(BrandButtonStyle())
        .padding(.horizontal)
    }

    @MainActor
    private func addAllToCollection() {
        guard !hasAdded else { return }

        let repository = CollectionRepository(context: context)
        var added = 0
        var merged = 0
        let notes = "Aus Pack geöffnet"

        for pull in opening.pulls {
            let brief = CardBrief(
                id: pull.card.id,
                name: pull.card.name,
                setId: pull.set.id,
                setName: pull.set.name,
                localId: pull.card.localId,
                rarity: nil,
                imageURL: pull.card.highResURL
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
                let item = CollectionItem(quantity: 1, confirmedCondition: .nearMint, notes: notes)
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

        points.recordOpening(pack: opening.pack, pulls: opening.pulls)
        hasAdded = true
        let parts = [
            added > 0 ? "\(added) neue Karten" : nil,
            merged > 0 ? "\(merged) zusammengeführt" : nil
        ].compactMap { $0 }
        let base = parts.isEmpty ? "Bereits in der Sammlung" : parts.joined(separator: " · ")
        addSummary = "\(base) · \(points.balance) Punkte übrig"
    }
}

/// Einzelne Ziehung mit Kartenbild, Name und Holo-Badge.
private struct PullCardView: View {
    let pull: PackPull

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                AsyncImage(url: pull.card.thumbnailURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit()
                    }
                }
            }
            .aspectRatio(0.72, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                if pull.isHolo {
                    Text("Holo")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange, in: Capsule())
                        .padding(4)
                }
            }

            Text(pull.card.name)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("#\(pull.card.localId) · \(pull.set.id)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}