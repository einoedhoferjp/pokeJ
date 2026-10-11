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

    init(mode: Mode, preselected: CardBrief? = nil) {
        self.mode = mode
        self.preselected = preselected
    }

    @State private var query = ""
    @State private var results: [CardBrief] = []
    @State private var selectedCard: CardBrief?

    @State private var language: Language = .de
    @State private var printing: Printing = .normal
    @State private var condition: CardCondition = .nearMint
    @State private var quantity = 1
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
            Form {
                if isEdit {
                    Section("Karte") { editedCardSummary }
                } else {
                    Section("Karte") { searchSection }
                }

                Section("Exemplar") {
                    Picker("Sprache", selection: $language) {
                        ForEach(Language.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("Variante", selection: $printing) {
                        ForEach(Printing.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("Zustand", selection: $condition) {
                        ForEach(CardCondition.allCases) { Text($0.displayName).tag($0) }
                    }
                    Stepper("Anzahl: \(quantity)", value: $quantity, in: 1...999)
                }

                Section("Kauf (optional)") {
                    TextField("Kaufpreis in €", text: $purchasePriceText)
                        .keyboardType(.decimalPad)
                    Toggle("Kaufdatum angeben", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Kaufdatum", selection: $purchaseDate, displayedComponents: .date)
                    }
                }

                Section("Notizen") {
                    TextField("Notizen", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEdit ? "Karte bearbeiten" : "Karte hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: onAppear)
            .task(id: query) { await runSearch() }
        }
    }

    @ViewBuilder
    private var searchSection: some View {
        TextField("Name oder Kartennummer", text: $query)
        ForEach(results) { brief in
            Button {
                selectedCard = brief
                query = ""
                results = []
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(brief.name).foregroundStyle(.primary)
                        Text("\(brief.setName) · #\(brief.localId)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedCard?.id == brief.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        if let selectedCard {
            Label("\(selectedCard.name) · \(selectedCard.setName) #\(selectedCard.localId)", systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var editedCardSummary: some View {
        if case .edit(let item) = mode, let card = item.variant?.card {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name).font(.headline)
                Text("\(card.setName) · #\(card.localId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func runSearch() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            return
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        if Task.isCancelled { return }
        let request = CardQuery(text: text, language: language)
        results = (try? await provider.searchCards(request)) ?? []
    }

    private func onAppear() {
        if case .add = mode, let preselected {
            selectedCard = preselected
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
            guard let brief = selectedCard else { return }
            let card = repository.findOrCreateCard(from: brief)
            let item = CollectionItem(
                quantity: quantity,
                confirmedCondition: condition,
                purchasePrice: price,
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                notes: notes
            )
            repository.addCollectionItem(card: card, language: language, printing: printing, item: item)

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

        try? context.save()
        dismiss()
    }

    private func parsedPrice() -> Decimal? {
        let normalized = purchasePriceText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }
}
