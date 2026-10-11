import SwiftUI
import PhotosUI

struct ConditionPreviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let item: CollectionItem
    @State private var showingCapture = false
    @State private var latest: ConditionAssessment?

    var body: some View {
        Form {
            Section("Manueller Zustand") {
                Text(item.confirmedCondition.displayName)
                if let est = item.estimatedCondition { Text("Geschätzt: \(est.displayName)").font(.caption).foregroundStyle(.secondary) }
            }
            Section("Bewertungen") {
                if let a = latest {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(a.estimatedCondition.displayName).fontWeight(.semibold)
                        Text(a.detectedDefects).font(.caption)
                        Text(a.assessedAt.formatted()).font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Noch keine automatische Bewertung.").foregroundStyle(.secondary)
                }
            }
            Section {
                Button { showingCapture = true } label: { Label("Neue Zustandsbewertung", systemImage: "camera.metering.spot") }
            }
        }
        .navigationTitle("Zustand")
        .sheet(isPresented: $showingCapture) {
            ConditionCaptureView { _, _, res, mc in
                if let res = res {
                    let a = ConditionAssessment(detectedDefects: res.notes, estimatedCondition: res.estimatedCondition, confirmedCondition: mc, assessedAt: .now)
                    context.insert(a)
                    a.collectionItem = item
                    item.estimatedCondition = res.estimatedCondition
                    item.confirmedCondition = mc
                } else {
                    item.confirmedCondition = mc
                }
                try? context.save()
                latest = item.assessments.sorted(by: { $0.assessedAt > $1.assessedAt }).first
            }
        }
        .onAppear { latest = item.assessments.sorted(by: { $0.assessedAt > $1.assessedAt }).first }
    }
}
