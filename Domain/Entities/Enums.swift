import Foundation

/// Sprache einer Kartenvariante. Teilmenge der von TCGdex unterstützten Sprachen.
enum Language: String, Codable, CaseIterable, Identifiable, Sendable {
    case de, en, fr, it, es, ja

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .de: return "Deutsch"
        case .en: return "Englisch"
        case .fr: return "Französisch"
        case .it: return "Italienisch"
        case .es: return "Spanisch"
        case .ja: return "Japanisch"
        }
    }
}

/// Druck-/Holo-Variante einer Karte.
enum Printing: String, Codable, CaseIterable, Identifiable, Sendable {
    case normal, reverse, holo, firstEdition, promo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .reverse: return "Reverse Holo"
        case .holo: return "Holo"
        case .firstEdition: return "1. Edition"
        case .promo: return "Promo"
        }
    }
}

/// Zustandsklassen. `uncertain` kennzeichnet eine unsichere Schätzung.
enum CardCondition: String, Codable, CaseIterable, Identifiable, Sendable {
    case nearMint, excellent, good, lightPlayed, played, poor, uncertain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nearMint: return "Near Mint"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .lightPlayed: return "Light Played"
        case .played: return "Played"
        case .poor: return "Poor"
        case .uncertain: return "Unsichere Schätzung"
        }
    }
}

/// Herkunft eines Exemplars: real erfasst (gescannt/eingetragen) oder aus
/// einem fiktiven Booster gezogen. Trennt echte von fiktiven Sammlungen.
enum CollectionOrigin: String, Codable, CaseIterable, Identifiable, Sendable {
    case scanned, pack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scanned: return "Gescannt"
        case .pack: return "Aus Packs"
        }
    }

    var systemImage: String {
        switch self {
        case .scanned: return "camera.viewfinder"
        case .pack: return "sparkles"
        }
    }
}

/// Kennzahl eines Preisdatensatzes (Cardmarket über TCGdex).
enum PriceMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case avg, low, trend, avg1, avg7, avg30
    case avgHolo, lowHolo, trendHolo, avg1Holo, avg7Holo, avg30Holo

    var id: String { rawValue }

    /// `true`, wenn die Kennzahl den Foil-/Holo-Preis beschreibt.
    var isHolo: Bool {
        switch self {
        case .avg, .low, .trend, .avg1, .avg7, .avg30: return false
        case .avgHolo, .lowHolo, .trendHolo, .avg1Holo, .avg7Holo, .avg30Holo: return true
        }
    }

    var displayName: String {
        switch self {
        case .avg: return "Durchschnitt"
        case .low: return "Günstigstes Angebot"
        case .trend: return "Trend"
        case .avg1: return "Ø 1 Tag"
        case .avg7: return "Ø 7 Tage"
        case .avg30: return "Ø 30 Tage"
        case .avgHolo: return "Ø (Holo)"
        case .lowHolo: return "Günstigstes (Holo)"
        case .trendHolo: return "Trend (Holo)"
        case .avg1Holo: return "Ø 1 Tag (Holo)"
        case .avg7Holo: return "Ø 7 Tage (Holo)"
        case .avg30Holo: return "Ø 30 Tage (Holo)"
        }
    }
}

/// Sicherheit der Zuordnung eines Preises zur Karte.
enum MatchQuality: String, Codable, CaseIterable, Identifiable, Sendable {
    case exact, productOnly, uncertain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .exact: return "Exakte Zuordnung"
        case .productOnly: return "Produktgenau"
        case .uncertain: return "Unsichere Zuordnung"
        }
    }
}

/// Ergebnisstatus eines Scans.
enum ScanStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case recognized, likely, multiple, noMatch, error

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recognized: return "Karte erkannt"
        case .likely: return "Wahrscheinlicher Treffer"
        case .multiple: return "Mehrere mögliche Treffer"
        case .noMatch: return "Keine sichere Zuordnung"
        case .error: return "Fehler"
        }
    }
}
