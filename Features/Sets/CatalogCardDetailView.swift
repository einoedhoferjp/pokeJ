import SwiftUI

/// Detailansicht einer Katalogkarte: Bild, Kennung, optionaler Live-Preis
/// (Cardmarket über TCGdex) und Übernahme in die Sammlung.
struct CatalogCardDetailView: View {
    let card: CatalogCard
    let set: CatalogSet

    @Environment(\.dismiss) private var dismiss
    @Environment(\.priceProvider) private var priceProvider

    @State private var points: [PricePoint] = []
    @State private var isLoadingPrice = false
    @State private var priceError: String?
    @State private var priceNote: String?
    @State private var showAdd = false

    private var brief: CardBrief {
        CardBrief(
            id: card.id,
            name: card.name,
            setId: set.id,
            setName: set.name,
            localId: card.localId,
            rarity: nil,
            imageURL: card.highResURL
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AsyncImage(url: card.highResURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            placeholder
                        case .empty:
                            ZStack { placeholder; ProgressView() }
                        @unknown default:
                            placeholder
                        }
                    }
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 6)

                    VStack(spacing: 4) {
                        Text(card.name).font(.title2.bold())
                        Text("\(set.name) · #\(card.localId)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    priceBox

                    Button {
                        showAdd = true
                    } label: {
                        Label("Zur Sammlung hinzufügen", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(BrandButtonStyle())
                }
                .padding()
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadPrices() }
                    } label: {
                        if isLoadingPrice {
                            ProgressView()
                        } else {
                            Label("Preise aktualisieren", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoadingPrice)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEditCardView(mode: .add, preselected: brief, language: .de)
            }
        }
    }

    @ViewBuilder
    private var priceBox: some View {
        if points.isEmpty {
            VStack(spacing: 10) {
                if let priceError {
                    Text(priceError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let priceNote {
                    Text(priceNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await loadPrices() }
                } label: {
                    if isLoadingPrice {
                        ProgressView()
                    } else {
                        Label("Cardmarket-Preis laden", systemImage: "eurosign.circle")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingPrice)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                if let priceError {
                    Text(priceError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                PriceSectionView(printing: .normal, points: points)
                if let priceNote {
                    Text(priceNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await loadPrices() }
                } label: {
                    if isLoadingPrice {
                        ProgressView()
                    } else {
                        Label("Preise aktualisieren", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingPrice)
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(AppTheme.surface)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
    }

    @MainActor
    private func loadPrices() async {
        guard !isLoadingPrice else { return }
        isLoadingPrice = true
        priceError = nil
        priceNote = nil
        do {
            let dtos = try await priceProvider.prices(externalCardId: card.id, printing: .normal, language: .de)
            if dtos.isEmpty {
                priceError = "Für diese Karte wurde kein Preis gefunden."
            } else {
                points = dtos.map {
                    PricePoint(
                        productId: $0.productId ?? card.id,
                        metric: $0.metric,
                        amount: $0.amount,
                        currency: $0.currency,
                        fetchedAt: $0.fetchedAt,
                        source: $0.source,
                        matchQuality: $0.matchQuality
                    )
                }
                priceNote = "Preise aktualisiert."
            }
        } catch {
            priceError = "Preis konnte nicht geladen werden (offline?)."
        }
        isLoadingPrice = false
    }
}
