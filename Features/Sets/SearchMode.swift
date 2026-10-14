import Foundation

enum SearchMode: String, CaseIterable, Identifiable {
    case number, text

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .number: return "Nummer"
        case .text: return "Text"
        }
    }

    var placeholder: String {
        switch self {
        case .number: return "Set-Nummer (z. B. sv3)"
        case .text: return "Name"
        }
    }
}

