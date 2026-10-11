import Charts
import SwiftData
import SwiftUI

struct PriceHistoryChartView: View {
    let productId: String
    @Query(sort: \PriceSnapshot.fetchedAt, order: .ascending) private var snapshots: [PriceSnapshot]

    private var points: [PriceSnapshot] {
        snapshots.filter { $0.cardmarketProductId == productId && $0.metric == .avg }
    }

    var body: some View {
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
}
