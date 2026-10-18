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

/// Scanner-Flow: Bild aufnehmen → OCR → Abgleich → Vorschau → Speichern.
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
    /// Letzte Scan-Sprache; wird über den App-Launch hinweg gemerkt.
    @AppStorage("pokej.scanLanguage") private var scanLanguageRaw: String = Language.de.rawValue
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var collectionItems: [CollectionItem]

    @State private var isBatchMode = false
    @State private var batchCount = 0
    @State private var processedPages = 0
    @State private var totalPages = 0

    @State private var showCamera = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var formTarget: AddTarget?
    @State private var pendingAdd: PendingAdd?

    // QoL: Blitz / Taschenlampe
    @State private var torchIsOn = false

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

    /// Zuletzt gewählte Scan-Sprache (wird gemerkt).
    private var scanLanguage: Language {
        get { Language(rawValue: scanLanguageRaw) ?? .de }
        nonmutating set { scanLanguageRaw = newValue.rawValue }
    }

    /// Binding für den Sprach-Picker, das die Auswahl direkt persistiert.
    private var scanLanguageBinding: Binding<Language> {
        Binding(
            get: { scanLanguage },
            set: { scanLanguage = $0 }
        )
    }

    /// Anzahl der Exemplare dieser Karte, die bereits in der Sammlung stecken
    /// (Duplikat-Check beim Scannen).
    private func ownedCount(for externalId: String) -> Int {
        collectionItems
            .filter { $0.variant?.card?.externalId == externalId }
            .reduce(0) { $0 + $1.quantity }
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
                    Button("Fertig") { dismiss() }
                        .font(.headline)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sprache", selection: scanLanguageBinding) {
                            ForEach(Language.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                    } label: {
                        Label("Sprache: \(scanLanguage.displayName)", systemImage: "globe")
                            .font(.headline)
                    }
                    .disabled(state == .processing)
                }
                if cameraAvailable {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            torchIsOn.toggle()
                        } label: {
                            Image(systemName: torchIsOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.headline)
                                .foregroundStyle(torchIsOn ? AppTheme.gold : .primary)
                        }
                        .disabled(state == .processing)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentCapture()
                    } label: {
                        Label("Neu scannen", systemImage: "camera.viewfinder")
                            .font(.headline)
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

    // MARK: - Leer-Zustand

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.textSecondary)

            Text(cameraAvailable ? "Karte scannen" : "Foto auswählen")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.ink)

            Text(cameraAvailable
                 ? "Halte deine Pokémon-Karte in den Sucher. Die Erkennung läuft automatisch auf dem Gerät."
                 : "Wähle ein Foto aus deiner Mediathek. Die Erkennung läuft auf dem Gerät.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button {
                    presentCapture()
                } label: {
                    Label(cameraAvailable ? "Kamera öffnen" : "Foto auswählen", systemImage: cameraAvailable ? "camera" : "photo.on.rectangle")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(BrandButtonStyle())

                if cameraAvailable {
                    Button("Foto aus der Mediathek") { showPicker = true }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.horizontal, 40)

            if isBatchMode {
                Text("Stapelscan aktiv · \(batchCount) Karten erfasst")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.accent)
            Text(totalPages > 1 ? "Karten werden erkannt … (\(processedPages)/\(totalPages))" : "Karte wird erkannt …")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    pageResult(result, index: index)
                }

                if pendingCount > 1 {
                    Button {
                        addAllPending()
                    } label: {
                        Label("Alle \(pendingCount) erkannten Karten übernehmen", systemImage: "square.stack.and.arrow.down.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(BrandButtonStyle())
                    .padding(.horizontal)
                }

                if isBatchMode {
                    VStack(spacing: 10) {
                        LabeledContent("In dieser Runde", value: "\(batchCount) Karten")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Button {
                            presentCapture()
                        } label: {
                            Label("Nächste Karten scannen", systemImage: "camera.viewfinder")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(BrandButtonStyle())
                        Button {
                            dismiss()
                        } label: {
                            Label("Runde beenden", systemImage: "checkmark.circle")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    .padding(.horizontal)
                }

                SectionHeader(title: "Oder", icon: "minus")

                Button {
                    formTarget = .fresh
                } label: {
                    Label("Andere Karte manuell suchen", systemImage: "square.and.pencil")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("Scan fehlgeschlagen")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Erneut versuchen") { presentCapture() }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal, 40)
            Spacer()
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    // MARK: - Scan-Ergebnis-Karte

    @ViewBuilder
    private func pageResult(_ result: ScanPageResult, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(2)
                    }
                    if let number = result.fields.number {
                        Text("#\(number)" + (result.fields.printedTotal.map { "/\($0)" } ?? ""))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    if let hp = result.fields.hp {
                        Text("KP \(hp)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    if let match = effectiveMatch(for: result) {
                        Text("Treffer \(Int((match.score * 100).rounded())) %")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
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
                VStack(spacing: 8) {
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
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let match = effectiveMatch(for: result) {
                if savedResultIds.contains(result.id) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("In der Bibliothek")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                } else {
                    let existing = ownedCount(for: match.brief.id)
                    if existing > 0 {
                        Label(
                            "Bereits \(existing)× in deiner Sammlung – wird als Duplikat ergänzt.",
                            systemImage: "square.on.square.badge.person.crop"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.gold.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.gold.opacity(0.3), lineWidth: 1))
                    }
                    Button {
                        pendingAdd = PendingAdd(match: match, pageId: result.id)
                    } label: {
                        Label("Zur Sammlung hinzufügen", systemImage: "tray.and.arrow.down.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(BrandButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
                .overlay(AppTheme.glossyCardGradient
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .blendMode(.overlay)
                    .opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal)
    }

    private func scannedThumbnail(_ image: UIImage) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 98)
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
                .frame(width: 80, height: 112)
            } else {
                cardPlaceholder
                    .frame(width: 80, height: 112)
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
            Image(systemName: "eurosign.circle.fill")
                .foregroundStyle(AppTheme.gold)
            if let priceState, priceState.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(AppTheme.accent)
                Text("Preis wird geladen …")
                    .foregroundStyle(.secondary)
            } else if let point = priceState?.primary(printing: .normal) {
                Text(PriceFormatting.currency(point.amount, code: point.currency))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.ink)
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
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text("\(Int((match.score * 100).rounded())) %")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
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

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    ScannerView()
        .environmentObject(PointsStore())
        .modelContainer(for: [Card.self, CardVariant.self, CollectionItem.self], inMemory: true)
}