import SwiftUI

/// Stellt die aktive Kartendatenquelle (Phase 2: TCGdex) der UI bereit.
///
/// Der Standard ist die Live-Quelle; Previews/Tests können eine andere
/// Implementierung einspeisen.
private struct CardDataProviderKey: EnvironmentKey {
    static let defaultValue: CardDataProvider = TCGdexProvider()
}

private struct PriceProviderKey: EnvironmentKey {
    static let defaultValue: PriceProvider = TCGdexPriceProvider()
}

extension EnvironmentValues {
    var cardDataProvider: CardDataProvider {
        get { self[CardDataProviderKey.self] }
        set { self[CardDataProviderKey.self] = newValue }
    }

    var priceProvider: PriceProvider {
        get { self[PriceProviderKey.self] }
        set { self[PriceProviderKey.self] = newValue }
    }
}
