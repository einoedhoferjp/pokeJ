import SwiftUI
import SwiftData

struct AddEditCardView: View {
    enum Mode {
        case add
        case edit(CollectionItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.cardDataProvider) private var provider

    let mode: Mode
    private let preselected: CardBrief?
    private let preselectedLanguage: Language?
    private let onSaved: (() -> Void)?

    init(
        mode: Mode,
        preselected: CardBrief? = nil,
        language: Language? = nil,
        onSaved: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.preselected = preselected
        self.preselectedLanguage = language
        self.onSaved = onSaved
    }

    @State private var query = ""
    @State private var results: [CardBrief] = []
    @State private var selectedCard: CardBrief?
    @State private var saveError: String?
    @State private var didSave = false

    @State private var language: Language = .de
    @State private var printing: Printing = .normal
    @State private var condition: CardCondition = .nearMint
    @State private var quantity = 1
    @State private var mergeDuplicates = true
    @State private var purchasePriceText = ""
    @State private var hasPurchaseDate = false
    @State private var purchaseDate = Date()
    @State private var notes = ""

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        if isEdit { return true }
        return selectedCard != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isEdit {
                        editedCardSummary
                    } else {
                        searchSection
                    }

                    exemplarSection
                    purchaseSection
                    notesSection

                    saveButton
                }
                .padding(20)
            }
            .navigationTitle(isEdit ? "Karte bearbeiten" : "Karte hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .onAppear(perform: onAppear)
            .task(id: query) { await runSearch() }
            .sensoryFeedback(.success, trigger: didSave)
            .alert("Speichern fehlgeschlagen", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
    }

    // MARK: - Suche

    @ViewBuilder
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Karte suchen")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Name oder Kartennummer (z. B. \"Pikachu\" oder \"4\")", text: $query)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))

                if !results.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(results) { brief in
                            Button {
                                selectedCard = brief
                                query = ""
                                results = []
                            } label: {
                                HStack(spacing: 12) {
                                    if let url = brief.imageURL {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let image) = phase {
                                                image.resizable().scaledToFill()
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.08))
                                            }
                                        }
                                        .frame(width: 44, height: 62)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.08))
                                            .frame(width: 44, height: 62)
                                            .overlay {
                                                Image(systemName: "photo")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.textSecondary)
                                            }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(brief.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.ink)
                                            .lineLimit(1)
                                        Text("\(brief.setName) · #\(brief.localId)")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if selectedCard?.id == brief.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    selectedCard?.id == brief.id
                                        ? AppTheme.accent.opacity(0.15)
                                        : Color.white.opacity(0.03),
                                    in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let selectedCard {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ausgewählt: \(selectedCard.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text("\(selectedCard.setName) #\(selectedCard.localId)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private var editedCardSummary: some View {
        if case .edit(let item) = mode, let card = item.variant?.card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Karte bearbeiten")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .tracking(0.5)
                HStack(spacing: 12) {
                    if let url = card.imageURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                placeholderImage
                            }
                        }
                        .frame(width: 56, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        placeholderImage
                            .frame(width: 56, height: 78)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(card.setName) · #\(card.localId)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
            }
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
    }

    // MARK: - Exemplar

    private var exemplarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exemplar")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                PickerRow(title: "Sprache", selection: $language, options: Language.allCases.map { $0.displayName })
                PickerRow(title: "Variante", selection: $printing, options: Printing.allCases.map { $0.displayName })
                PickerRow(title: "Zustand", selection: $condition, options: CardCondition.allCases.map { $0.displayName })

                HStack(spacing: 12) {
                    Text("Anzahl")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Stepper("", value: $quantity, in: 1...999)
                        .labelsHidden()
                    Text("\(quantity)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))

                if !isEdit {
                    Toggle("Gleiche Karte zusammenfassen", isOn: $mergeDuplicates)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink)
                        .toggleStyle(ModernToggleStyle())
                }
            }
        }
    }

    // MARK: - Kauf

    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kauf (optional)")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                TextField("Kaufpreis in €", text: $purchasePriceText)
                    .font(.body)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))

                Toggle("Kaufdatum angeben", isOn: $hasPurchaseDate)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink)
                    .toggleStyle(ModernToggleStyle())

                if hasPurchaseDate {
                    DatePicker("Kaufdatum", selection: $purchaseDate, displayedComponents: .date)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Notizen

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notizen")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)

            TextField("Notizen (z. B. Woher, Zustand, Besonderheiten)", text: $notes, axis: .vertical)
                .font(.body)
                .lineLimit(2...5)
                .padding(14)
                .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
        }
    }

    // MARK: - Speichern

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack {
                Image(systemName: isEdit ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                Text(isEdit ? "Änderungen speichern" : "Zur Sammlung hinzufügen")
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(canSave ? AppTheme.brandGradient : Color.secondary.opacity(0.3))
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .blendMode(.overlay)
                        .opacity(canSave ? 0.5 : 0)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: AppTheme.accent.opacity(canSave ? 0.5 : 0.1), radius: 14, y: 8)
        }
        .disabled(!canSave)
        .buttonStyle(.plain)
    }

    // MARK: - Logik

    @MainActor
    private func runSearch() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            return
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        if Task.isCancelled { return }

        let looksLikeNumber = text.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
            && text.rangeOfCharacter(from: CharacterSet.letters) == nil

        let request: CardQuery
        if looksLikeNumber {
            request = CardQuery(text: "", localId: text, language: language)
        } else {
            request = CardQuery(text: text, language: language)
        }
        results = (try? await provider.searchCards(request)) ?? []
    }

    private func onAppear() {
        if case .add = mode {
            if let preselected { selectedCard = preselected }
            if let preselectedLanguage { language = preselectedLanguage }
        }
        loadForEdit()
    }

    private func loadForEdit() {
        guard case .edit(let item) = mode else { return }
        language = item.variant?.language ?? .de
        printing = item.variant?.printing ?? .normal
        condition = item.confirmedCondition
        quantity = item.quantity
        notes = item.notes
        hasPurchaseDate = item.purchaseDate != nil
        purchaseDate = item.purchaseDate ?? Date()
        if let price = item.purchasePrice {
            purchasePriceText = NSDecimalNumber(decimal: price).stringValue
        }
    }

    private func save() {
        let repository = CollectionRepository(context: context)
        let price = parsedPrice()

        switch mode {
        case .add:
            guard let brief = selectedCard else {
                saveError = "Bitte zuerst eine Karte auswählen."
                return
            }
            let card = repository.findOrCreateCard(from: brief)
            if mergeDuplicates,
               let existing = repository.existingItem(
                   card: card,
                   language: language,
                   printing: printing,
                   condition: condition,
                   notes: notes
               ) {
                existing.quantity += quantity
            } else {
                let item = CollectionItem(
                    quantity: quantity,
                    confirmedCondition: condition,
                    purchasePrice: price,
                    purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                    notes: notes
                )
                repository.addCollectionItem(card: card, language: language, printing: printing, item: item)
            }

        case .edit(let item):
            item.quantity = quantity
            item.confirmedCondition = condition
            item.notes = notes
            item.purchasePrice = price
            item.purchaseDate = hasPurchaseDate ? purchaseDate : nil

            let currentLanguage = item.variant?.language
            let currentPrinting = item.variant?.printing
            if let card = item.variant?.card,
               currentLanguage != language || currentPrinting != printing {
                let variant = repository.findOrCreateVariant(card: card, language: language, printing: printing)
                item.variant = variant
            }
        }

        do {
            try context.save()
        } catch {
            saveError = error.localizedDescription
            return
        }

        didSave = true
        let completion = onSaved
        dismiss()
        if let completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: completion)
        }
    }

    private func parsedPrice() -> Decimal? {
        let normalized = purchasePriceText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }
}

/// Moderne Picker-Zeile mit Segmented-Control-Stil.
struct PickerRow: View {
    let title: String
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Picker(title, selection: $selection) {
                ForEach(0..<options.count, id: \.self) { index in
                    Text(options[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous).strokeBorder(AppTheme.stroke, lineWidth: 1))
    }
}

/// Moderner Toggle-Stil.
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isOn ? AppTheme.accent : Color.white.opacity(0.12))
                    .frame(width: 48, height: 28)
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            }
            .animation(AppTheme.Motion.snappy, value: configuration.isOn)
        }
    }
}

#Preview {
    AddEditCardView(mode: .add)
        .environmentObject(AuthStore())
        .environmentObject(PointsStore())
        .modelContainer(PreviewData.container)
}