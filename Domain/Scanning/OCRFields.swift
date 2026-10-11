import Foundation

/// Aus OCR-Text extrahierte Kartenfelder.
///
/// Alle Felder sind optional bzw. Listen, weil OCR nie garantiert vollständig
/// ist. Es wird nichts erfunden: fehlt ein Feld, bleibt es leer.
struct OCRFields: Sendable, Equatable {
    /// Mögliche Kartennamen, in Reihenfolge abnehmender Wahrscheinlichkeit.
    var nameCandidates: [String] = []
    /// Gedruckte Kartennummer, z. B. `136` oder `SV107`.
    var number: String?
    /// Gesamtzahl nach dem Schrägstrich, z. B. `189`.
    var printedTotal: String?
    /// KP-Wert, falls erkannt.
    var hp: Int?
    /// Unveränderte OCR-Zeilen (für Anzeige/Diagnose).
    var rawLines: [String] = []

    var isEmpty: Bool {
        nameCandidates.isEmpty && number == nil && hp == nil
    }
}

/// Ein bewerteter Kandidat für eine gescannte Karte.
struct CardMatch: Identifiable, Sendable, Equatable {
    let brief: CardBrief
    let score: Double
    let reasons: [String]

    var id: String { brief.id }
}

/// Ergebnis der Kartenerkennung.
struct IdentifyOutcome: Sendable {
    let status: ScanStatus
    let matches: [CardMatch]
}
