import CoreImage
import ImageIO
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import VisionKit

/// Ablaufzustand des Scanners.
enum ScanState: Equatable {
    case idle
    case processing
    case result
    case failed(String)
}

/// Scanner-Flow: Bild aufnehmen/wählen → OCR → Abgleich → Kandidat bestätigen
/// → vorausgefüllter Hinzufügen-Dialog.
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.cardDataProvider) private var provider

    @State private var state: ScanState = .idle
    @State private var fields: OCRFields?
    @State private var outcome: IdentifyOutcome?
    @State private var scanRecord: ScanRecord?
    @State private var scanLanguage: Language = .de

    @State private var showCamera = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var addTarget: AddTarget?

    private enum AddTarget: Identifiable {
        case fresh
        case candidate(CardBrief)

        var id: String {
            switch self {
            case .fresh: return "fresh"
            case .candidate(let brief): return brief.id
            }
        }

        var brief: CardBrief? {
            if case .candidate(let brief) = self { return brief }
            return nil
        }
    }

    private var cameraAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle: idleView
                case .processing: processingView
                case .result: resultView
                case .failed(let message): failedView(message)
                }
            }
            .navigationTitle("Karte scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sprache", selection: $scanLanguage) {
                            ForEach(Language.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                    } label: {
                        Label("Sprache: \(scanLanguage.displayName)", systemImage: "globe")
                    }
                    .disabled(state == .processing)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentCapture()
                    } label: {
                        Label("Neu scannen", systemImage: "viewfinder")
                    }
                    .disabled(state == .processing)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            DocumentScannerView(
                onComplete: { image in
                    showCamera = false
                    Task { await run(image: image) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPicked(item) }
        }
        .sheet(item: $addTarget) { target in
            AddEditCardView(mode: .add, preselected: target.brief, language: scanLanguage)
        }
    }

    // MARK: - Zustandsansichten

    private var idleView: some View {
        ContentUnavailableView {
            Label("Karte scannen", systemImage: "camera.viewfinder")
        } description: {
            Text("Fotografiere die Karte. Die Erkennung läuft vollständig auf dem Gerät.")
        } actions: {
            Button {
                presentCapture()
            } label: {
                Label(cameraAvailable ? "Kamera öffnen" : "Foto auswählen", systemImage: cameraAvailable ? "camera" : "photo.on.rectangle")
            }
            .buttonStyle(.borderedProminent)
            if cameraAvailable {
                Button("Foto aus der Mediathek") { showPicker = true }
            }
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Karte wird erkannt …")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var resultView: some View {
        List {
            if let fields {
                Section("Erkannt") {
                    if fields.isEmpty {
                        Text("Keine verwertbaren Felder erkannt.")
                            .foregroundStyle(.secondary)
                    } else {
                        if let name = fields.nameCandidates.first {
                            row("Name", name)
                        }
                        if let number = fields.number {
                            row("Nummer", number + (fields.printedTotal.map { "/\($0)" } ?? ""))
                        }
                        if let hp = fields.hp {
                            row("KP", "\(hp)")
                        }
                    }
                }
            }

            Section("Mögliche Treffer") {
                if let outcome, !outcome.matches.isEmpty {
                    Text(outcome.status.displayName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ForEach(Array(outcome.matches.prefix(6))) { match in
                        Button {
                            select(match)
                        } label: {
                            matchRow(match)
                        }
                    }
                } else {
                    Text("Keine sichere Zuordnung. Du kannst die Karte manuell hinzufügen.")
                        .foregroundStyle(.secondary)
                }
            }

            if let fields, !fields.rawLines.isEmpty {
                Section("Diagnose") {
                    DisclosureGroup("Erkannter Text (OCR)") {
                        ForEach(Array(fields.rawLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                    row("Suchsprache", scanLanguage.displayName)
                    row("Kandidaten", "\(outcome?.matches.count ?? 0)")
                }
            }

            Section {
                Button {
                    addTarget = .fresh
                } label: {
                    Label("Karte manuell hinzufügen", systemImage: "square.and.pencil")
                }
            }
        }
    }

    private func failedView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Scan fehlgeschlagen", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") { presentCapture() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    private func matchRow(_ match: CardMatch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.brief.name).foregroundStyle(.primary)
                Text("\(match.brief.setName) · #\(match.brief.localId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int((match.score * 100).rounded())) %")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Aktionen

    private func presentCapture() {
        if cameraAvailable {
            showCamera = true
        } else {
            showPicker = true
        }
    }

    @MainActor
    private func loadPicked(_ item: PhotosPickerItem) async {
        pickerItem = nil
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            state = .failed("Das Bild konnte nicht geladen werden.")
            return
        }
        await run(image: image)
    }

    @MainActor
    private func run(image: UIImage) async {
        guard let normalized = CardImagePreprocessor.normalizedCGImage(from: image) else {
            state = .failed("Das Bild konnte nicht verarbeitet werden.")
            return
        }
        state = .processing
        let prepared = preprocess(normalized)
        let processor = ScanProcessor(provider: provider, language: scanLanguage)
        do {
            let result = try await processor.process(image: prepared, orientation: .up)
            fields = result.fields
            outcome = result.outcome
            record(fields: result.fields, outcome: result.outcome)
            state = .result
        } catch {
            state = .failed("Die Kartenerkennung ist fehlgeschlagen. Bitte erneut versuchen.")
        }
    }

    private func preprocess(_ cgImage: CGImage) -> CGImage {
        let ciImage = CIImage(cgImage: cgImage)
        let corrected = CardImagePreprocessor.rectify(ciImage, orientation: .up)
        return CardImagePreprocessor.cgImage(from: corrected) ?? cgImage
    }

    @MainActor
    private func record(fields: OCRFields, outcome: IdentifyOutcome) {
        let summary = outcome.matches.prefix(3)
            .map { "\($0.brief.name) #\($0.brief.localId) (\(Int(($0.score * 100).rounded()))%)" }
            .joined(separator: "; ")
        let record = ScanRecord(
            rawText: fields.rawLines.joined(separator: "\n"),
            candidateSummary: summary,
            chosenExternalCardId: nil,
            confidence: outcome.matches.first?.score,
            status: outcome.status
        )
        context.insert(record)
        try? context.save()
        scanRecord = record
    }

    @MainActor
    private func select(_ match: CardMatch) {
        scanRecord?.chosenExternalCardId = match.brief.id
        scanRecord?.confidence = match.score
        try? context.save()
        addTarget = .candidate(match.brief)
    }
}
