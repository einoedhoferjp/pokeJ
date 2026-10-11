import Foundation

/// Bildqualitäts-Metriken (unscharf, beleuchtet, Reflexion).
struct ImageQualityMetrics: Equatable, Sendable {
    var sharpness: Double = 0.5
    var brightness: Double = 0.5
    var contrast: Double = 0.5
    var hasGlare: Bool = false
    var glareAreaRatio: Double = 0
}

/// Zentrierung und Perspektive.
struct CenteringMetrics: Equatable, Sendable {
    var isCentered: Bool = true
    var horizontalOffset: Double = 0
    var verticalOffset: Double = 0
    var edgeUniformity: Double = 0.8
}

/// Verschleiß-Erkennungs-Ergebnis.
struct WearMetrics: Equatable, Sendable {
    var cornerDamage: Double = 0
    var edgeDamage: Double = 0
    var surfaceScratches: Double = 0
    var whitening: Double = 0
    var isBent: Bool = false
}

/// Gesamte Zustandsmetrik.
struct ConditionMetrics: Equatable, Sendable {
    var quality: ImageQualityMetrics = .init()
    var centering: CenteringMetrics = .init()
    var wear: WearMetrics = .init()
    var confidence: Double = 0
}

/// Schwellen für eine konservative Schätzung.
struct ConditionThresholds: Sendable {
    var nmSharpness: Double = 0.60
    var nmEdgeUniformity: Double = 0.80
    var nmWear: Double = 0.05
    var exWear: Double = 0.12
    var gdWear: Double = 0.25
    var lpWear: Double = 0.40
    var plWear: Double = 0.60
    var prWear: Double = 0.80
}

enum ConditionHeuristic {
    static func estimate(from metrics: ConditionMetrics,
                         thresholds: ConditionThresholds = .init()) -> (condition: CardCondition, confidence: Double) {
        let wear = (metrics.wear.cornerDamage + metrics.wear.edgeDamage + metrics.wear.surfaceScratches + metrics.wear.whitening) / 4.0
        let qualityFactor = max(0, metrics.quality.sharpness) * max(0, metrics.centering.edgeUniformity)
        var cond: CardCondition = .uncertain
        if wear <= thresholds.nmWear && metrics.centering.edgeUniformity >= thresholds.nmEdgeUniformity && metrics.quality.sharpness >= thresholds.nmSharpness {
            cond = .nearMint
        } else if wear <= thresholds.exWear {
            cond = .excellent
        } else if wear <= thresholds.gdWear {
            cond = .good
        } else if wear <= thresholds.lpWear {
            cond = .lightPlayed
        } else if wear <= thresholds.plWear {
            cond = .played
        } else {
            cond = .poor
        }
        let conf = clamp((qualityFactor + (1.0 - min(1, wear))) / 2.0, 0, 1)
        if metrics.quality.hasGlare || metrics.quality.sharpness < 0.25 { cond = .uncertain }
        return (cond == .uncertain ? .uncertain : cond, conf)
    }

    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }
}
