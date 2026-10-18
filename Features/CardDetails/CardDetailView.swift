import SwiftUI
import SwiftData

struct CardDetailView: View {
    let item: CollectionItem
    @State private var showingEdit = false
    @Query(sort: \PriceSnapshot.fetchedAt, order: .reverse) private var allSnapshots: [PriceSnapshot]

    private var card: Card? { item.variant?.card }
    private var variant: CardVariant? { item.variant }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cardImage
                detailsSection
                priceSection
                notesSection
                conditionTimelineSection
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
        .navigationTitle(card?.name ?? "Karte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { showingEdit = true }
                    .font(.headline.weight(.semibold))
            }
            ToolbarItem(placement: .secondaryAction) {
                NavigationLink("Zustand") { ConditionPreviewView(item: item) }
                    .font(.headline.weight(.semibold))
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(mode: .edit(item))
        }
    }

    private var cardImage: some View {
        ZStack {
            if let url = card?.imageURL {
                AsyncImage(url: url) { phase in
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
            } else {
                imagePlaceholder(systemName: "photo")
            }
            glossOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 420)
        .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var glossOverlay: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.05),
                Color.black.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }

    private func imagePlaceholder(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(Color.white.opacity(0.08))
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .strokeBorder(AppTheme.stroke, lineWidth: 1)
            Image(systemName: systemName)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Karte")
            VStack(alignment: .leading, spacing: 12) {
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
            .padding(16)
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
    }

    /// Verlauf aller Zustandsbewertungen dieses Exemplars (neueste zuerst).
    @ViewBuilder
    private var conditionTimelineSection: some View {
        let assessments = item.assessments.sorted { $0.assessedAt > $1.assessedAt }
        if !assessments.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Zustands-Verlauf")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(assessments.enumerated()), id: \.element.id) { index, assessment in
                        ConditionTimelineRow(
                            assessment: assessment,
                            isLast: index == assessments.count - 1
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .fill(AppTheme.elevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
                )
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Preise")
            PriceSectionView(printing: variant?.printing ?? .normal, points: pricePoints)
        }
        .padding(16)
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

    private var pricePoints: [PricePoint] {
        guard let productId = variant?.cardmarketProductId else { return [] }
        return allSnapshots
            .filter { $0.cardmarketProductId == productId }
            .map {
                PricePoint(
                    productId: $0.cardmarketProductId,
                    metric: $0.metric,
                    amount: $0.amount,
                    currency: $0.currency,
                    fetchedAt: $0.fetchedAt,
                    source: $0.source,
                    matchQuality: $0.matchQuality
                )
            }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notizen")
            Text(item.notes.isEmpty ? "Keine Notizen." : item.notes)
                .font(.body)
                .foregroundStyle(item.notes.isEmpty ? AppTheme.textSecondary : AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.ink)
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

/// Eine Zeile in der Zustands-Verlaufstimeline.
private struct ConditionTimelineRow: View {
    let assessment: ConditionAssessment
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.surfaceStroke)
                        .frame(width: 2)
                    Spacer(minLength: 0)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(assessment.assessedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    if assessment.confirmedCondition != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.mint)
                    }
                }
                HStack(spacing: 6) {
                    Text(assessment.estimatedCondition.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    if let confirmed = assessment.confirmedCondition {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(confirmed.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.mint)
                    }
                }
                if !assessment.detectedDefects.isEmpty {
                    Text("Mängel: \(assessment.detectedDefects)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    private var dotColor: Color {
        assessment.confirmedCondition == nil ? AppTheme.gold : AppTheme.mint
    }
}

#Preview {
    CardDetailView(item: CollectionItem(quantity: 1, confirmedCondition: .nearMint))
        .modelContainer(for: [Card.self, CardVariant.self, CollectionItem.self, PriceSnapshot.self, ScanRecord.self, ConditionAssessment.self], inMemory: true)
}