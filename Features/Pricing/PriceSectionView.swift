import SwiftUI

/// Zeigt gespeicherte Cardmarket-Preise zu einer Variante.
///
/// Kennzeichnet immer Quelle, Kennzahl, Zeitstempel und Unsicherheit; erfindet
/// nie einen Preis.
struct PriceSectionView: View {
    let printing: Printing
    let points: [PricePoint]

    private let now = Date()

    var body: some View {
        GroupBox("Preis") {
            if points.isEmpty {
                unavailable
            } else {
                available
            }
        }
        if !points.isEmpty, let pid = points.first?.productId {
            PriceHistoryChartView(productId: pid)
                .frame(maxWidth: .infinity)
        }
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Kein Preis verfügbar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Preise stammen von Cardmarket, geliefert über TCGdex. Sie sind produktbezogen – nicht sprach-, zustands- oder exemplargenau.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var available: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let primary = PriceResolver.latest(points: points, printing: printing) {
                primaryRow(primary)
            }

            let metrics = PriceResolver.latestPerMetric(points: points)
            let ordered = metrics.values.sorted { $0.metric.displayName < $1.metric.displayName }
            if ordered.count > 1 {
                Divider()
                ForEach(ordered, id: \.metric) { point in
                    metricRow(point)
                }
            }

            Divider()
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primaryRow(_ point: PricePoint) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PriceFormatting.currency(point.amount, code: point.currency))
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(point.metric.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if PriceFreshness.isStale(fetchedAt: point.fetchedAt, now: now) {
                staleBadge
            }
        }
    }

    private func metricRow(_ point: PricePoint) -> some View {
        HStack {
            Text(point.metric.displayName)
                .foregroundStyle(.secondary)
            Spacer()
            Text(PriceFormatting.currency(point.amount, code: point.currency))
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Quelle: \(points.first?.source ?? "Cardmarket über TCGdex")")
            if let fetchedAt = points.map(\.fetchedAt).max() {
                Text("Stand: \(PriceFormatting.timestamp(fetchedAt)) (\(PriceFormatting.relative(fetchedAt, now: now)))")
            }
            Text(matchQualityText)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var matchQualityText: String {
        guard let quality = points.first?.matchQuality else { return "" }
        return "Zuordnung: \(quality.displayName)"
    }

    private var staleBadge: some View {
        Label("veraltet", systemImage: "exclamationmark.triangle.fill")
            .font(.caption2)
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15), in: Capsule())
    }
}
