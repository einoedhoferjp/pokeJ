import Foundation

enum LibrarySearchMode: String, CaseIterable, Identifiable {
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
        case .number: return "Kartennummer (z. B. 025)"
        case .text: return "Name"
        }
    }
}

