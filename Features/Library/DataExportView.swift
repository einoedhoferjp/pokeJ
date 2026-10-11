import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataExportView: View {
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @State private var jsonText = ""
    @State private var csvText = ""
    @State private var showShareJSON = false
    @State private var showShareCSV = false

    var body: some View {
        Form {
            Section("JSON (Backup)") {
                TextEditor(text: .constant(jsonText))
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 120)
                Button("Anzeigen & Exportieren") {
                    jsonText = CollectionExport.json(items: items)
                    showShareJSON = true
                }
            }
            Section("CSV (Export)") {
                TextEditor(text: .constant(csvText))
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 120)
                Button("Anzeigen & Exportieren") {
                    csvText = CollectionExport.csv(items: items)
                    showShareCSV = true
                }
            }
        }
        .navigationTitle("Export/Backup")
        .sheet(isPresented: $showShareJSON) {
            ShareSheet(activityItems: [jsonText])
        }
        .sheet(isPresented: $showShareCSV) {
            ShareSheet(activityItems: [csvText])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
