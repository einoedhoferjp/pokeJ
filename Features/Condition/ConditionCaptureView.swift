import SwiftUI
import PhotosUI
import UIKit

struct ConditionCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var frontItem: PhotosPickerItem?
    @State private var backItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var result: ConditionAssessmentResult?
    @State private var isAssessing = false
    @State private var manualCondition: CardCondition = .uncertain

    var onAssess: ((UIImage?, UIImage?, ConditionAssessmentResult?, CardCondition) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Vorderseite") {
                    PhotosPicker(selection: $frontItem, matching: .images) {
                        Label(frontImage == nil ? "Foto auswählen" : "Foto wechseln", systemImage: "photo")
                    }
                    if let img = frontImage { Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 240) }
                }
                Section("Rückseite") {
                    PhotosPicker(selection: $backItem, matching: .images) {
                        Label(backImage == nil ? "Foto auswählen" : "Foto wechseln", systemImage: "photo")
                    }
                    if let img = backImage { Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 240) }
                }
                if let r = result {
                    Section("Schätzung") {
                        HStack { Text("Geschätzter Zustand"); Spacer(); Text(r.estimatedCondition.displayName).fontWeight(.semibold) }
                        HStack { Text("Konfidenz"); Spacer(); Text("\(Int(r.confidence*100))%") }
                        Text(r.notes).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Manuell korrigieren") {
                    Picker("Bestätigter Zustand", selection: $manualCondition) {
                        ForEach(CardCondition.allCases) { Text($0.displayName).tag($0) }
                    }
                }
                Section {
                    Button {
                        Task { await assess() }
                    } label: {
                        if isAssessing { ProgressView() } else { Label("Zustand schätzen", systemImage: "sparkles") }
                    }.disabled(frontImage == nil && backImage == nil)
                    Button {
                        let mc = (manualCondition == .uncertain && result != nil) ? result!.estimatedCondition : manualCondition
                        onAssess?(frontImage, backImage, result, mc)
                        dismiss()
                    } label: { Label("Übernehmen", systemImage: "checkmark.circle.fill") }.buttonStyle(BrandButtonStyle())
                }
            }
            .navigationTitle("Zustandsbewertung")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } } }
            .onChange(of: frontItem) { _, v in Task { if let v = v { frontImage = try? await v.loadTransferable(type: Data.self).flatMap(UIImage.init(data:)) } } }
            .onChange(of: backItem) { _, v in Task { if let v = v { backImage = try? await v.loadTransferable(type: Data.self).flatMap(UIImage.init(data:)) } } }
        }
    }
    @MainActor private func assess() async {
        guard let cg = frontImage?.cgImage ?? backImage?.cgImage else { return }
        isAssessing = true
        result = ConditionAssessor().assess(image: cg)
        if manualCondition == .uncertain { manualCondition = result?.estimatedCondition ?? .uncertain }
        isAssessing = false
    }
}
