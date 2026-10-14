import SwiftUI
import Vision
import VisionKit

/// Gerätetest-/Diagnoseansicht: prüft die nur auf dem echten Gerät verfügbaren
/// Funktionen (Kamera-Dokumentenscan, OCR) und die Live-Anbindung an TCGdex
/// (Katalogsuche und Preise).
///
/// Erfindet keine Ergebnisse: Jede Zeile nennt genau das, was tatsächlich
/// geprüft wurde – inklusive Fehlermeldung, falls eine Prüfung fehlschlägt.
struct DeviceDiagnosticsView: View {
    @Environment(\.cardDataProvider) private var cardDataProvider
    @Environment(\.priceProvider) private var priceProvider
    @EnvironmentObject private var points: PointsStore

    @State private var catalogProbe: Probe = .idle
    @State private var priceProbe: Probe = .idle

    private enum Probe: Equatable {
        case idle
        case running
        case success(String)
        case failure(String)
    }

    private var catalog: PokemonCatalogPayload { PokemonCatalog.shared }

    private var cameraAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    private var ocrLanguages: [String] {
        (try? VNRecognizeTextRequest.supportedRecognitionLanguages(
            for: .accurate,
            revision: VNRecognizeTextRequestRevision3
        )) ?? []
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            deviceSection
            catalogSection
            liveSection
            testSection
        }
        .navigationTitle("Gerätetest")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deviceSection: some View {
        Section("Gerät & Erkennung") {
            LabeledContent("Kamera-Scan", value: cameraAvailable ? "verfügbar" : "nicht verfügbar")
            LabeledContent("OCR-Sprachen", value: "\(ocrLanguages.count)")
            LabeledContent("App-Version", value: appVersion)
            Text("OCR läuft vollständig auf dem Gerät. Ohne Kamera (Simulator) ist nur die Fotoauswahl nutzbar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var catalogSection: some View {
        Section("Offline-Katalog") {
            LabeledContent("Sets", value: "\(catalog.sets.count)")
            LabeledContent("Karten", value: "\(catalog.cardCount)")
            if !catalog.source.isEmpty {
                LabeledContent("Quelle", value: catalog.source)
            }
            if !catalog.generatedAt.isEmpty {
                LabeledContent("Stand", value: catalog.generatedAt)
            }
        }
    }

    private var liveSection: some View {
        Section("Live-Anbindung (TCGdex)") {
            probeRow(title: "Katalogsuche", probe: catalogProbe) {
                Task { await runCatalogProbe() }
            }
            probeRow(title: "Preise", probe: priceProbe) {
                Task { await runPriceProbe() }
            }
        }
    }

    private var testSection: some View {
        Section("Test") {
            LabeledContent("Punkte", value: "\(points.balance)")
            Button {
                points.grantMaximumBalance()
            } label: {
                Label("Punkte auf Maximum setzen (\(PointsStore.maximumBalance))", systemImage: "arrow.up.to.line.circle")
            }
        }
    }

    @ViewBuilder
    private func probeRow(title: String, probe: Probe, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                if probe == .running {
                    ProgressView()
                } else {
                    Button("Testen") { action() }
                        .buttonStyle(.bordered)
                }
            }
            switch probe {
            case .idle:
                EmptyView()
            case .running:
                Text("Wird geprüft …")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .success(let message):
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .failure(let message):
                Label(message, systemImage: "xmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    @MainActor
    private func runCatalogProbe() async {
        catalogProbe = .running
        do {
            let sets = try await cardDataProvider.sets(language: .de)
            catalogProbe = .success("\(sets.count) Sets erreichbar.")
        } catch {
            catalogProbe = .failure(error.localizedDescription)
        }
    }

    @MainActor
    private func runPriceProbe() async {
        priceProbe = .running
        guard let cardId = catalog.sets.first?.cards.first?.id else {
            priceProbe = .failure("Kein Katalog geladen.")
            return
        }
        do {
            let prices = try await priceProvider.prices(externalCardId: cardId, printing: .normal, language: .de)
            priceProbe = prices.isEmpty
                ? .success("Erreichbar (kein Preis für \(cardId)).")
                : .success("\(prices.count) Kennzahlen für \(cardId).")
        } catch {
            priceProbe = .failure(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack { DeviceDiagnosticsView() }
        .environmentObject(PointsStore())
}
