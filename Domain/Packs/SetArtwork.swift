import Foundation

/// Angereicherte Set-Metadaten (Epoche, Veröffentlichung, Logo), gebündelt in
/// `Resources/SetArtwork.json`. Treibt Pack-Design, Preisstufe und Reihenfolge.
struct SetArtwork: Identifiable, Decodable, Sendable, Hashable {
    let id: String
    let releaseDate: String
    let serieId: String
    let logo: String?
    let enName: String

    /// `true`, wenn ein echtes Set-Logo vorhanden ist.
    var hasLogo: Bool { logo?.isEmpty == false }

    /// Logo als WebP für `AsyncImage` (`…/logo` → `…/logo.webp`).
    var logoImageURL: URL? {
        guard let logo, !logo.isEmpty else { return nil }
        return URL(string: logo + ".webp")
    }

    /// Basis der englischen Kartenbilder (`…/base1/logo` → `…/base1`).
    var englishImageBase: URL? {
        guard let logo, let range = logo.range(of: "/logo", options: .backwards) else { return nil }
        return URL(string: String(logo[..<range.lowerBound]))
    }

    /// Englisches Kartenbild als Ausweichquelle, wenn das deutsche Bild fehlt.
    func englishImageURL(localId: String, highResolution: Bool) -> URL? {
        guard let base = englishImageBase else { return nil }
        let suffix = highResolution ? "/high.webp" : "/low.webp"
        return URL(string: base.absoluteString + "/" + localId + suffix)
    }

    var releaseYear: Int? {
        Int(releaseDate.prefix(4))
    }

    /// Kartenbild auf dem TCGdex-CDN, aufgebaut aus Serie- und Set-ID.
    ///
    /// Funktioniert auch dann, wenn kein Set-Logo hinterlegt ist und wenn das
    /// deutsche Kartenbild fehlt (u. a. ältere Sets wie Base Set) – der
    /// englische Pfad existiert für alle 155 Sets.
    func cardImageURL(localId: String, highResolution: Bool) -> URL? {
        let suffix = highResolution ? "/high.webp" : "/low.webp"
        return URL(string: "https://assets.tcgdex.net/en/\(serieId)/\(id)/\(localId)\(suffix)")
    }

    var releaseDateValue: Date? {
        Self.dateFormatter.date(from: releaseDate)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct SetArtworkPayload: Decodable, Sendable {
    let generatedAt: String
    let source: String
    let sets: [SetArtwork]
}

/// Lädt die gebündelten Set-Metadaten (`Resources/SetArtwork.json`).
enum SetArtworkCatalog {
    static let all: [SetArtwork] = load()
    static let byId: [String: SetArtwork] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    static func artwork(for setId: String) -> SetArtwork? {
        byId[setId]
    }

    /// Zentraler Kartenbild-Fallback (englisches CDN), wenn das deutsche Bild
    /// im Katalog fehlt. Liefert `nil`, wenn das Set unbekannt ist.
    static func cardImageURL(setId: String, localId: String, highResolution: Bool = false) -> URL? {
        artwork(for: setId)?.cardImageURL(localId: localId, highResolution: highResolution)
    }

    private static func load() -> [SetArtwork] {
        guard let url = Bundle.main.url(forResource: "SetArtwork", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(SetArtworkPayload.self, from: data) else {
            return []
        }
        return payload.sets.sorted { lhs, rhs in
            if lhs.releaseDate == rhs.releaseDate { return lhs.id < rhs.id }
            return lhs.releaseDate < rhs.releaseDate
        }
    }
}
