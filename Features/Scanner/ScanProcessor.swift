import CoreGraphics
import ImageIO

/// Führt OCR, Parsing und Kartenabgleich zu einem Scanergebnis zusammen.
///
/// Reiner Orchestrator ohne UI und ohne Persistenz: dadurch mit einem
/// Stub-Recognizer vollständig testbar.
struct ScanProcessor {
    let recognizer: TextRecognizing
    let identify: IdentifyCardUseCase
    let language: Language

    init(
        provider: CardDataProvider,
        recognizer: TextRecognizing = VisionTextRecognizer(),
        language: Language = .en
    ) {
        self.recognizer = recognizer
        self.identify = IdentifyCardUseCase(provider: provider)
        self.language = language
    }

    func process(
        image: CGImage,
        orientation: CGImagePropertyOrientation = .up
    ) async throws -> (fields: OCRFields, outcome: IdentifyOutcome) {
        let lines = try await recognizer.recognizeText(in: image, orientation: orientation)
        let fields = CardTextParser.parse(lines: lines)
        let outcome = try await identify.identify(fields: fields, language: language)
        return (fields, outcome)
    }
}
