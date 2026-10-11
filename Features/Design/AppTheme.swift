import SwiftUI
import UIKit

/// Zentrale Design-Tokens der App.
enum AppTheme {
    /// Pokémon-Rot für Aktionen/Hervorhebung.
    static let accent = Color(red: 0.92, green: 0.20, blue: 0.26)
    /// Pokémon-Gelb für Akzente/Badges.
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.16)
    /// Dunkle Schrift-/Icon-Farbe.
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.21)
    /// Ruhiger Hintergrundverlauf (hell/dunkel-tauglich).
    static let surface = Color(.secondarySystemBackground)

    static let cardRadius: CGFloat = 16

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(red: 0.99, green: 0.51, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [gold, Color(red: 1.0, green: 0.62, blue: 0.13)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
