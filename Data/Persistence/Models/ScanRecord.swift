import Foundation
import SwiftData

/// Protokolldatensatz eines Scanvorgangs (Phase 2).
@Model
final class ScanRecord {
    var timestamp: Date
    var rawText: String
    var candidateSummary: String
    var chosenExternalCardId: String?
    var confidence: Double?
    var statusRaw: String

    init(
        timestamp: Date = .now,
        rawText: String = "",
        candidateSummary: String = "",
        chosenExternalCardId: String? = nil,
        confidence: Double? = nil,
        status: ScanStatus
    ) {
        self.timestamp = timestamp
        self.rawText = rawText
        self.candidateSummary = candidateSummary
        self.chosenExternalCardId = chosenExternalCardId
        self.confidence = confidence
        self.statusRaw = status.rawValue
    }

    var status: ScanStatus {
        get { ScanStatus(rawValue: statusRaw) ?? .error }
        set { statusRaw = newValue.rawValue }
    }
}
