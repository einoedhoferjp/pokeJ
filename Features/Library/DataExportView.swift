import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct DataExportView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]
    @State private var jsonText = ""
    @State private var csvText = ""
    @State private var showShareJSON = false
    @State private var showShareCSV = false

    @State private var importText = ""
    @State private var importMessage: String?
    @State private var showImportAlert = false

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
            Section("JSON (Backup wiederherstellen)") {
                Text("Füge den Inhalt eines JSON-Backups ein. Der Import ergänzt deine Sammlung und löscht nichts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $importText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 120)
                Button("Backup prüfen & importieren") {
                    runImport()
                }
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Export/Backup")
        .sheet(isPresented: $showShareJSON) {
            ShareSheet(activityItems: [jsonText])
        }
        .sheet(isPresented: $showShareCSV) {
            ShareSheet(activityItems: [csvText])
        }
        .alert("Import", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func runImport() {
        do {
            let dtos = try CollectionImport.decode(importText)
            guard !dtos.isEmpty else {
                importMessage = "Das Backup enthält keine Einträge."
                showImportAlert = true
                return
            }
            let summary = CollectionImport.apply(dtos, context: context)
            importText = ""
            importMessage = "\(summary.total) Einträge verarbeitet: \(summary.message)."
            showImportAlert = true
        } catch {
            importMessage = error.localizedDescription
            showImportAlert = true
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
