import Foundation

/// Wandelt OCR-Zeilen in strukturierte Kartenfelder um.
///
/// Bewusst heuristisch und konservativ: Es werden nur Muster akzeptiert, die
/// für Pokémon-Karten typisch sind. Die Eingabe wird als grob von oben nach
/// unten sortiert angenommen (der OCR-Service sortiert nach Bounding-Box).
enum CardTextParser {
    static func parse(lines: [String]) -> OCRFields {
        var fields = OCRFields()
        fields.rawLines = lines

        let joined = lines.joined(separator: "\n")

        if let match = firstMatch(in: joined, pattern: #"([A-Za-z]{0,4}\d{1,4})\s*/\s*([A-Za-z]{0,4}\d{1,4})"#) {
            fields.number = match[0]
            fields.printedTotal = match[1]
        }

        if let hp = firstMatch(in: joined, pattern: #"\b(\d{1,3})\s*(?:HP|KP)\b"#, caseInsensitive: true)?[0],
           let value = Int(hp) {
            fields.hp = value
        } else if let hp = firstMatch(in: joined, pattern: #"\b(?:HP|KP)\s*(\d{1,3})\b"#, caseInsensitive: true)?[0],
                  let value = Int(hp) {
            fields.hp = value
        }

        fields.nameCandidates = nameCandidates(from: lines, number: fields.number)
        return fields
    }

    // MARK: - Namenserkennung

    private static func nameCandidates(from lines: [String], number: String?) -> [String] {
        var candidates: [String] = []
        for line in lines {
            let cleaned = cleanName(line)
            guard !cleaned.isEmpty else { continue }
            if isNoise(cleaned, number: number) { continue }
            if !candidates.contains(where: { $0.caseInsensitiveCompare(cleaned) == .orderedSame }) {
                candidates.append(cleaned)
            }
            if candidates.count >= 3 { break }
        }
        return candidates
    }

    /// Entfernt KP-Angaben und Energiesymbole aus einer potenziellen Namenszeile.
    private static func cleanName(_ line: String) -> String {
        var text = line
        text = text.replacingOccurrences(
            of: #"(?:HP|KP)\s*\d{1,3}"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(
            of: #"\b\d{1,3}\s*(?:HP|KP)\b"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(
            of: #"\b(?:LV|Lv|Nv)\.?\s*\d{1,3}\b"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "★", with: "")
        text = text.replacingOccurrences(of: "◇", with: "")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let noiseKeywords: Set<String> = [
        "basic", "stage 1", "stage 2", "stage1", "stage2",
        "phase 1", "phase 2", "basis",
        "trainer", "energy", "item", "supporter", "stadium",
        "ability", "pokemon", "pokémon", "ex", "gx", "v", "vmax", "vstar",
        "fähigkeit", "attacke", "attacken", "schwäche", "resistenz",
        "rückzug", "flucht", "regel", "tausch", "unterstützer", "stadion",
        "energie", "entwickelt sich", "entwickelt sich aus"
    ]

    private static func isNoise(_ line: String, number: String?) -> Bool {
        let lower = line.lowercased()
        if noiseKeywords.contains(lower) { return true }

        if let number, !number.isEmpty {
            if normalizeNumber(line) == normalizeNumber(number) { return true }
        }

        let scalars = line.unicodeScalars
        let letterCount = scalars.filter { CharacterSet.letters.contains($0) }.count
        let digitCount = scalars.filter { CharacterSet.decimalDigits.contains($0) }.count
        if letterCount == 0 { return true }

        // Überwiegend numerische Zeilen sind keine Kartennamen.
        if digitCount > 0 && digitCount >= letterCount { return true }

        // Zeilen, die nur eine Kartennummer enthalten (z. B. "136" oder "TG03").
        if line.range(of: #"^[A-Za-z]{0,4}\d{1,4}$"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }

    // MARK: - Regex-Helfer

    private static func firstMatch(
        in text: String,
        pattern: String,
        caseInsensitive: Bool = false
    ) -> [String]? {
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let result = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        var groups: [String] = []
        for index in 1..<result.numberOfRanges {
            if let groupRange = Range(result.range(at: index), in: text) {
                groups.append(String(text[groupRange]))
            } else {
                groups.append("")
            }
        }
        return groups
    }

    private static func normalizeNumber(_ value: String) -> String {
        let stripped = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // Führende Nullen entfernen, aber mindestens eine Ziffer behalten.
        let pattern = #"^([A-Z]*)(0*)(\d+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let result = regex.firstMatch(in: stripped, options: [], range: NSRange(stripped.startIndex..<stripped.endIndex, in: stripped)),
           let prefixRange = Range(result.range(at: 1), in: stripped),
           let digitRange = Range(result.range(at: 3), in: stripped) {
            return String(stripped[prefixRange]) + String(stripped[digitRange])
        }
        return stripped
    }
}
