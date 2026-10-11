import SwiftUI
import SwiftData

@main
struct PokeJApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Card.self,
            CardVariant.self,
            CollectionItem.self,
            PriceSnapshot.self,
            ScanRecord.self,
            ConditionAssessment.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
        .modelContainer(container)
    }
}
