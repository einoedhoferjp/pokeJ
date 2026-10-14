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

/// Ergebnis einer einzelnen gescannten Seite (eine Karte pro Aufnahmeseite).
struct ScanPageResult: Identifiable {
    let id = UUID()
    let image: UIImage
    let fields: OCRFields
    let outcome: IdentifyOutcome
    let record: ScanRecord?

    var status: ScanStatus { outcome.status }
    var topMatch: CardMatch? { outcome.matches.first }
}

/// Scanner-Flow: Bild(er) aufnehmen/wählen → OCR → Abgleich → Vorschau mit Bild
/// und Preis → nach Zustimmung direkt in die Bibliothek.
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.cardDataProvider) private var provider
    @Environment(\.priceProvider) private var priceProvider
    @EnvironmentObject private var points: PointsStore

    @State private var state: ScanState = .idle
    @State private var results: [ScanPageResult] = []
    @State private var selection: [UUID: CardMatch] = [:]
    @State private var priceStates: [UUID: ScanPriceState] = [:]
    @State private var savedResultIds: Set<UUID> = []
    @State private var scanLanguage: Language = .de

    @State private var isBatchMode = false
    @State private var batchCount = 0
    @State private var processedPages = 0
    @State private var totalPages = 0

    @State private var showCamera = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var formTarget: AddTarget?
    @State private var pendingAdd: PendingAdd?

    private struct PendingAdd {
        let match: CardMatch
        let pageId: UUID
    }

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

    private struct ScanPriceState {
        var isLoading = false
        var points: [PricePoint] = []

        func primary(printing: Printing) -> PricePoint? {
            PriceResolver.latest(points: points, printing: printing)
        }
    }

    private var cameraAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    private var pendingCount: Int {
        results.filter { !savedResultIds.contains($0.id) && effectiveMatch(for: $0) != nil }.count
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
                    Button("Beenden") { dismiss() }
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isBatchMode.toggle()
                    } label: {
                        Label(
                            isBatchMode ? "Stapelscan an: \(batchCount)" : "Stapelscan",
                            systemImage: "square.stack.3d.up.fill"
                        )
                    }
                    .disabled(state == .processing)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            DocumentScannerView(
                onComplete: { images in
                    showCamera = false
                    Task { await run(images: images) }
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
        .sheet(item: $formTarget) { target in
            AddEditCardView(mode: .add, preselected: target.brief, language: scanLanguage) {
                handleFormSave()
            }
        }
        .confirmationDialog(
            "Karte zur Bibliothek hinzufügen?",
            isPresented: Binding(
                get: { pendingAdd != nil },
                set: { if !$0 { pendingAdd = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingAdd
        ) { pending in
            Button("Hinzufügen") { addToLibrary(pending) }
            Button("Details bearbeiten …") { formTarget = .candidate(pending.match.brief) }
            Button("Abbrechen", role: .cancel) { pendingAdd = nil }
        } message: { pending in
            Text("\(pending.match.brief.name) · \(pending.match.brief.setName) #\(pending.match.brief.localId)")
        }
        .sensoryFeedback(.success, trigger: results.count)
        .rewardBanner(points: points)
    }

    // MARK: - Zustandsansichten

    private var idleView: some View {
        ContentUnavailableView {
            Label("Karten scannen", systemImage: "camera.viewfinder")
        } description: {
            Text(cameraAvailable
                 ? "Fotografiere eine oder mehrere Karten. Die Erkennung läuft vollständig auf dem Gerät."
                 : "Wähle ein Foto deiner Karte. Die Erkennung läuft vollständig auf dem Gerät.")
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
            if isBatchMode {
                Text("Stapelscan aktiv · \(batchCount) Karten übernommen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(totalPages > 1 ? "Karten werden erkannt … (\(processedPages)/\(totalPages))" : "Karte wird erkannt …")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var resultView: some View {
        List {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                Section {
                    pageResult(result)
                } header: {
                    HStack {
                        Text(results.count > 1 ? "Karte \(index + 1)" : "Ergebnis")
                        Spacer()
                        if savedResultIds.contains(result.id) {
                            Label("Gespeichert", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            if pendingCount > 1 {
                Section {
                    Button {
                        addAllPending()
                    } label: {
                        Label("Alle \(pendingCount) erkannten Karten übernehmen", systemImage: "square.stack.and.arrow.down.fill")
                    }
                }
            }

            if isBatchMode {
                Section {
                    LabeledContent("In dieser Runde", value: "\(batchCount) Karten")
                    Button {
                        presentCapture()
                    } label: {
                        Label("Nächste Karten scannen", systemImage: "camera.viewfinder")
                    }
                    Button {
                        dismiss()
                    } label: {
                        Label("Runde beenden", systemImage: "checkmark.circle")
                    }
                } footer: {
                    Text("Im Stapelscan erfasst du mehrere Karten nacheinander. Jede übernommene Karte bringt +\(PointsStore.scanRewardPerCard) Punkte.")
                }
            }

            Section {
                Button {
                    formTarget = .fresh
                } label: {
                    Label("Andere Karte manuell suchen", systemImage: "square.and.pencil")
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
            Button("Beenden") { dismiss() }
        }
    }

    // MARK: - Bausteine

    @ViewBuilder
    private func pageResult(_ result: ScanPageResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                scannedThumbnail(result.image)
                matchedThumbnail(result)
                VStack(alignment: .leading, spacing: 6) {
                    Label(result.status.displayName, systemImage: statusIcon(result.status))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor(result.status))
                    if let name = result.fields.nameCandidates.first {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                    }
                    if let number = result.fields.number {
                        Text("#\(number)" + (result.fields.printedTotal.map { "/\($0)" } ?? ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let hp = result.fields.hp {
                        Text("KP \(hp)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let match = effectiveMatch(for: result) {
                        Text("Treffer \(Int((match.score * 100).rounded())) %")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            priceRow(result)

            if !result.outcome.matches.isEmpty {
                if result.status == .multiple, selection[result.id] == nil {
                    Label("Mehrere plausible Treffer – bitte die richtige Karte antippen.", systemImage: "hand.tap.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                VStack(spacing: 6) {
                    ForEach(Array(result.outcome.matches.prefix(4))) { match in
                        Button {
                            select(match, for: result)
                        } label: {
                            matchRow(match, selected: effectiveMatch(for: result)?.id == match.brief.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("Keine sichere Zuordnung. Nutze die manuelle Suche, um die Karte hinzuzufügen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let match = effectiveMatch(for: result) {
                if savedResultIds.contains(result.id) {
                    Label("In der Bibliothek", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Button {
                        pendingAdd = PendingAdd(match: match, pageId: result.id)
                    } label: {
                        Label("Zur Bibliothek hinzufügen", systemImage: "tray.and.arrow.down.fill")
                    }
                    .buttonStyle(BrandButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func scannedThumbnail(_ image: UIImage) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 74, height: 103)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall, style: .continuous))
            Text("Scan")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func matchedThumbnail(_ result: ScanPageResult) -> some View {
        VStack(spacing: 4) {
            if let match = effectiveMatch(for: result), let url = match.brief.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        cardPlaceholder
                    case .empty:
                        ZStack { cardPlaceholder; ProgressView() }
                    @unknown default:
                        cardPlaceholder
                    }
                }
                .frame(width: 84, height: 117)
            } else {
                cardPlaceholder
                    .frame(width: 84, height: 117)
            }
            Text("Karte")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay {
                Image(systemName: "rectangle.stack")
                    .foregroundStyle(AppTheme.textSecondary)
            }
    }

    @ViewBuilder
    private func priceRow(_ result: ScanPageResult) -> some View {
        let priceState = priceStates[result.id]
        HStack(spacing: 8) {
            Image(systemName: "eurosign.circle")
            if let priceState, priceState.isLoading {
                ProgressView().controlSize(.small)
                Text("Preis wird geladen …")
                    .foregroundStyle(.secondary)
            } else if let point = priceState?.primary(printing: .normal) {
                Text(PriceFormatting.currency(point.amount, code: point.currency))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(point.metric.displayName)
                    .foregroundStyle(.secondary)
            } else {
                Text("Kein Preis verfügbar")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    private func matchRow(_ match: CardMatch, selected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? AppTheme.accent : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(match.brief.name)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text("\(match.brief.setName) · #\(match.brief.localId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("\(Int((match.score * 100).rounded())) %")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall, style: .continuous)
                .fill(selected ? AppTheme.accent.opacity(0.14) : Color.white.opacity(0.04))
        )
    }

    private func statusIcon(_ status: ScanStatus) -> String {
        switch status {
        case .recognized: return "checkmark.seal.fill"
        case .likely: return "checkmark.circle"
        case .multiple: return "square.stack.3d.up"
        case .noMatch: return "questionmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }

    private func statusColor(_ status: ScanStatus) -> Color {
        switch status {
        case .recognized: return .green
        case .likely: return AppTheme.gold
        case .multiple, .noMatch: return .orange
        case .error: return .red
        }
    }

    // MARK: - Aktionen

    private func effectiveMatch(for result: ScanPageResult) -> CardMatch? {
        if let selected = selection[result.id] { return selected }
        guard result.status != .multiple else { return nil }
        return result.topMatch
    }

    private func presentCapture() {
        guard state != .processing else { return }
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
        await run(images: [image])
    }

    @MainActor
    private func run(images: [UIImage]) async {
        guard !images.isEmpty else {
            state = .idle
            return
        }
        results = []
        selection = [:]
        priceStates = [:]
        savedResultIds = []
        totalPages = images.count
        processedPages = 0
        state = .processing

        var collected: [ScanPageResult] = []
        for image in images {
            if let page = await recognize(image: image) {
                collected.append(page)
            }
            processedPages += 1
        }

        results = collected
        if collected.isEmpty {
            state = .failed("Die Kartenerkennung ist fehlgeschlagen. Bitte erneut versuchen.")
            return
        }
        state = .result

        for result in collected {
            Task { await refreshPrice(for: result) }
        }
    }

    @MainActor
    private func recognize(image: UIImage) async -> ScanPageResult? {
        guard let normalized = CardImagePreprocessor.normalizedCGImage(from: image) else {
            return nil
        }
        let prepared = preprocess(normalized)
        let processor = ScanProcessor(provider: provider, language: scanLanguage)
        do {
            let result = try await processor.process(image: prepared, orientation: .up)
            let record = makeRecord(fields: result.fields, outcome: result.outcome)
            return ScanPageResult(image: image, fields: result.fields, outcome: result.outcome, record: record)
        } catch {
            return nil
        }
    }

    private func preprocess(_ cgImage: CGImage) -> CGImage {
        let ciImage = CIImage(cgImage: cgImage)
        let corrected = CardImagePreprocessor.rectify(ciImage, orientation: .up)
        let enhanced = CardImagePreprocessor.enhancedForOCR(corrected)
        return CardImagePreprocessor.cgImage(from: enhanced) ?? cgImage
    }

    @MainActor
    private func makeRecord(fields: OCRFields, outcome: IdentifyOutcome) -> ScanRecord {
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
        return record
    }

    @MainActor
    private func select(_ match: CardMatch, for result: ScanPageResult) {
        selection[result.id] = match
        result.record?.chosenExternalCardId = match.brief.id
        result.record?.confidence = match.score
        try? context.save()
        Task { await refreshPrice(for: result) }
    }

    @MainActor
    private func refreshPrice(for result: ScanPageResult) async {
        guard let match = effectiveMatch(for: result) else { return }
        priceStates[result.id] = ScanPriceState(isLoading: true, points: priceStates[result.id]?.points ?? [])
        let dtos = (try? await priceProvider.prices(externalCardId: match.brief.id, printing: .normal, language: scanLanguage)) ?? []
        let points = dtos.map {
            PricePoint(
                productId: $0.productId ?? match.brief.id,
                metric: $0.metric,
                amount: $0.amount,
                currency: $0.currency,
                fetchedAt: $0.fetchedAt,
                source: $0.source,
                matchQuality: $0.matchQuality
            )
        }
        priceStates[result.id] = ScanPriceState(isLoading: false, points: points)
    }

    @MainActor
    private func addToLibrary(_ pending: PendingAdd) {
        guard !savedResultIds.contains(pending.pageId) else { return }
        let repository = CollectionRepository(context: context)
        let card = repository.findOrCreateCard(from: pending.match.brief)
        if let existing = repository.existingItem(card: card, language: scanLanguage, printing: .normal, condition: .nearMint, notes: "") {
            existing.quantity += 1
        } else {
            let item = CollectionItem(quantity: 1, confirmedCondition: .nearMint)
            repository.addCollectionItem(card: card, language: scanLanguage, printing: .normal, item: item)
        }
        if let record = results.first(where: { $0.id == pending.pageId })?.record {
            record.chosenExternalCardId = pending.match.brief.id
            record.confidence = pending.match.score
        }
        try? context.save()

        savedResultIds.insert(pending.pageId)
        points.awardScanReward()
        batchCount += 1
        advanceBatchIfNeeded()
    }

    @MainActor
    private func addAllPending() {
        for result in results where !savedResultIds.contains(result.id) {
            guard let match = effectiveMatch(for: result) else { continue }
            addToLibrary(PendingAdd(match: match, pageId: result.id))
        }
    }

    @MainActor
    private func advanceBatchIfNeeded() {
        guard isBatchMode, !savedResultIds.isEmpty else { return }
        guard pendingCount == 0 else { return }
        state = .idle
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            if isBatchMode {
                presentCapture()
            }
        }
    }

    /// Wird nach dem Speichern über das Formular (manuelle Suche) aufgerufen.
    @MainActor
    private func handleFormSave() {
        points.awardScanReward()
        batchCount += 1
        if isBatchMode {
            state = .idle
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                if isBatchMode {
                    presentCapture()
                }
            }
        } else {
            dismiss()
        }
    }
}
