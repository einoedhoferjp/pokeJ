import Foundation

/// Bewertet Suchkandidaten anhand der OCR-Felder.
///
/// Die Gewichtung ist bewusst erklärbar: Die Kartennummer ist das
/// zuverlässigste Merkmal, der Name das zweitwichtigste. Es gibt nie einen
/// stillen Treffer ohne Mindestpunktzahl.
enum CardMatcher {
    static func match(fields: OCRFields, candidates: [CardBrief]) -> [CardMatch] {
        candidates
            .map { brief -> CardMatch in
                let (score, reasons) = score(fields: fields, brief: brief)
                return CardMatch(brief: brief, score: score, reasons: reasons)
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.brief.name.localizedCaseInsensitiveCompare(rhs.brief.name) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
    }

    static func score(fields: OCRFields, brief: CardBrief) -> (Double, [String]) {
        var score = 0.0
        var reasons: [String] = []

        if let number = fields.number, !number.isEmpty {
            if normalize(number) == normalize(brief.localId) {
                score += 0.6
                reasons.append("Kartennummer stimmt überein")
            } else if digitsOnly(number) == digitsOnly(brief.localId), !digitsOnly(number).isEmpty {
                score += 0.4
                reasons.append("Nummer stimmt (ohne Präfix)")
            }
        }

        if let similarity = bestNameSimilarity(fields.nameCandidates, brief.name) {
            score += 0.4 * similarity
            if similarity >= 0.85 {
                reasons.append("Name sehr ähnlich")
            } else if similarity >= 0.5 {
                reasons.append("Name teilweise ähnlich")
            }
        }

        return (min(max(score, 0.0), 1.0), reasons)
    }

    // MARK: - Namensähnlichkeit

    static func bestNameSimilarity(_ candidates: [String], _ target: String) -> Double? {
        guard !candidates.isEmpty else { return nil }
        return candidates.map { similarity($0, target) }.max()
    }

    static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let a = normalizeName(lhs)
        let b = normalizeName(rhs)
        if a.isEmpty || b.isEmpty { return 0 }
        if a == b { return 1 }
        if a.contains(b) || b.contains(a) {
            let shorter = min(a.count, b.count)
            let longer = max(a.count, b.count)
            return 0.7 + 0.3 * (Double(shorter) / Double(longer))
        }
        let distance = levenshtein(a, b)
        let maxLength = max(a.count, b.count)
        return max(0, 1 - Double(distance) / Double(maxLength))
    }

    private static func normalizeName(_ value: String) -> String {
        let lowered = value.lowercased()
        let filtered = lowered.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || $0 == " "
        }
        return String(String.UnicodeScalarView(filtered))
            .split(separator: " ")
            .joined(separator: " ")
    }

    private static func normalize(_ value: String) -> String {
        let stripped = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let pattern = #"^([A-Z]*)(0*)(\d+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let result = regex.firstMatch(in: stripped, options: [], range: NSRange(stripped.startIndex..<stripped.endIndex, in: stripped)),
           let prefixRange = Range(result.range(at: 1), in: stripped),
           let digitRange = Range(result.range(at: 3), in: stripped) {
            return String(stripped[prefixRange]) + String(stripped[digitRange])
        }
        return stripped
    }

    private static func digitsOnly(_ value: String) -> String {
        value.filter { $0.isNumber }
    }

    private static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}
