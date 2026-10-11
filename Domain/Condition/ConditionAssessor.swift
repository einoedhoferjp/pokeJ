import CoreGraphics

struct ConditionAssessor {
    let analyzer: (CGImage) -> ConditionMetrics
    let estimator: (ConditionMetrics) -> (condition: CardCondition, confidence: Double)

    init(analyzer: @escaping (CGImage) -> ConditionMetrics = ConditionFeatureAnalyzer.metrics,
         estimator: @escaping (ConditionMetrics) -> (condition: CardCondition, confidence: Double) = { metrics in ConditionHeuristic.estimate(from: metrics) }) {
        self.analyzer = analyzer
        self.estimator = estimator
    }

    func assess(image: CGImage) -> ConditionAssessmentResult {
        let m = analyzer(image)
        let r = estimator(m)
        return ConditionAssessmentResult(
            metrics: m,
            estimatedCondition: r.condition,
            confidence: r.confidence,
            notes: notes(from: m, condition: r.condition)
        )
    }

    private func notes(from m: ConditionMetrics, condition: CardCondition) -> String {
        var n: [String] = []
        if m.quality.hasGlare { n.append("Reflexion erkannt") }
        if m.quality.sharpness < 0.3 { n.append("unschärftes Foto") }
        if m.centering.edgeUniformity < 0.7 { n.append("Rand ungleichmäßig") }
        if m.wear.cornerDamage > 0.15 { n.append("Ecken stärker beansprucht") }
        if n.isEmpty { n.append("Hinweis: Heuristik (keine ML-Schätzung)") }
        return n.joined(separator: "; ")
    }
}

struct ConditionAssessmentResult: Equatable, Sendable {
    let metrics: ConditionMetrics
    let estimatedCondition: CardCondition
    let confidence: Double
    let notes: String
}
