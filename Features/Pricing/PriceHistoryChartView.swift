import Charts
import SwiftData
import SwiftUI

struct PriceHistoryChartView: View {
    let productId: String
    @Environment(\.modelContext) private var context
    @State private var snapshots: [PriceSnapshot] = []

    private var points: [PriceSnapshot] {
        snapshots.filter { $0.cardmarketProductId == productId && $0.metric == .avg }
            .sorted { $0.fetchedAt < $1.fetchedAt }
    }

    var body: some View {
        Group {
            if points.isEmpty {
                ContentUnavailableView("Kein Verlauf", systemImage: "chart.line.downtrend.xyaxis", description: Text("Für diese Karte sind noch keine Preisstände gespeichert."))
            } else {
                Chart(points) { s in
                    LineMark(x: .value("Datum", s.fetchedAt), y: .value("Preis", NSDecimalNumber(decimal: s.amount).doubleValue))
                    PointMark(x: .value("Datum", s.fetchedAt), y: .value("Preis", NSDecimalNumber(decimal: s.amount).doubleValue))
                }
                .frame(height: 240)
                .padding()
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        let descriptor = FetchDescriptor<PriceSnapshot>(sortBy: [SortDescriptor(\PriceSnapshot.fetchedAt, order: .ascending)])
        if let all = try? context.fetch(descriptor) {
            snapshots = all
        }
    }
}
