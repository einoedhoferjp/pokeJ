import SwiftUI
import SwiftData

struct CardDetailView: View {
    let item: CollectionItem
    @State private var showingEdit = false

    private var card: Card? { item.variant?.card }
    private var variant: CardVariant? { item.variant }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cardImage
                detailsSection
                priceSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(card?.name ?? "Karte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(mode: .edit(item))
        }
    }

    private var cardImage: some View {
        AsyncImage(url: card?.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                imagePlaceholder(systemName: "photo.badge.exclamationmark")
            case .empty:
                ZStack {
                    imagePlaceholder(systemName: "photo")
                    ProgressView()
                }
            @unknown default:
                imagePlaceholder(systemName: "photo")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 420)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func imagePlaceholder(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1))
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    private var detailsSection: some View {
        GroupBox("Karte") {
            VStack(alignment: .leading, spacing: 8) {
                detailRow("Set", "\(card?.setName ?? "–") (\(card?.setId ?? "–"))")
                detailRow("Nummer", "#\(card?.localId ?? "–")")
                detailRow("Seltenheit", card?.rarity ?? "–")
                detailRow("Illustrator", card?.illustrator ?? "–")
                detailRow("Sprache", variant?.language.displayName ?? "–")
                detailRow("Variante", variant?.printing.displayName ?? "–")
                detailRow("Zustand", item.confirmedCondition.displayName)
                detailRow("Anzahl", "\(item.quantity)")
                if let purchasePrice = item.purchasePrice {
                    detailRow("Kaufpreis", formatCurrency(purchasePrice))
                }
                if let purchaseDate = item.purchaseDate {
                    detailRow("Kaufdatum", purchaseDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var priceSection: some View {
        GroupBox("Preis") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keine Preisdaten verfügbar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Cardmarket-Preise werden in Phase 3 über TCGdex geladen. Sie sind produktbezogen und nicht zustands- oder exemplargenau.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notesSection: some View {
        GroupBox("Notizen") {
            Text(item.notes.isEmpty ? "Keine Notizen." : item.notes)
                .font(.body)
                .foregroundStyle(item.notes.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
