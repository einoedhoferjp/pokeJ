import SwiftUI
import UIKit

/// Zentrale Design-Tokens der App.
///
/// Ausrichtung: **modern, schlicht, glossy**. Dunkles Midnight-Purple Basis-
/// Design mit glänzenden Kartenoberflächen, sanften Verläufen und klaren
/// Grid-Elementen.
enum AppTheme {
    // MARK: - Markenfarben

    /// Midnight Purple für Aktionen/Hervorhebung.
    static let accent = Color(red: 0.35, green: 0.29, blue: 0.66)
    /// Pokémon-Gelb für Akzente/Badges.
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.16)
    /// Helle Schrift-/Icon-Farbe, midnight-purple getönt.
    static let ink = Color(red: 0.96, green: 0.94, blue: 1.0)
    /// Kartenoberfläche (glossy Base).
    static let surface = elevated

    // MARK: - Dunkle Palette

    /// Hintergrund ganz oben (tiefes Midnight-Purple).
    static let backgroundTop = Color(red: 0.05, green: 0.04, blue: 0.08)
    /// Hintergrund ganz unten (sanftes Violett-Schwarz).
    static let backgroundBottom = Color(red: 0.09, green: 0.07, blue: 0.14)
    /// Erhöhte Flächen (Karten, Chips).
    static let elevated = Color(red: 0.13, green: 0.11, blue: 0.20)
    /// Etwas hellere erhöhte Fläche für Sekundärebenen.
    static let elevatedAlt = Color(red: 0.17, green: 0.14, blue: 0.26)
    /// Feine Rahmenfarbe.
    static let stroke = Color.white.opacity(0.10)
    /// Glanz-Overlay für glossy Kartenoberflächen.
    static let glossHighlight = Color.white.opacity(0.18)
    /// Primärer Text (helles Lavendel-Weiß).
    static let textPrimary = Color(red: 0.96, green: 0.94, blue: 1.0)
    /// Sekundärer Text (gedämpftes Violett).
    static let textSecondary = Color(red: 0.65, green: 0.61, blue: 0.78)

    // MARK: - Geometrie

    static let cardRadius: CGFloat = 20
    static let gridSpacing: CGFloat = 16
    static let controlRadius: CGFloat = 16
    static let smallCardRadius: CGFloat = 12

    // MARK: - Verläufe

    /// Grundverlauf über den gesamten App-Hintergrund.
    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(red: 0.52, green: 0.42, blue: 0.85)],
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

    /// Glossy-Kartenverlauf: heller Glanz oben, sanft abdunkelnd unten.
    static var glossyCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.20),
                Color.white.opacity(0.05),
                Color.black.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Dezente Lichtkante für erhöhte Flächen.
    static var surfaceStroke: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.16), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Pokedex-Elemente

    /// Reines Midnight Purple als Referenzfarbe.
    static let midnightPurple = Color(red: 0.24, green: 0.19, blue: 0.44)
    /// Helles Violett für Screen-Inhalte/Rahmen.
    static let screenGlow = Color(red: 0.45, green: 0.38, blue: 0.75)
    /// Status-LEDs im Pokedex-Panel.
    static let ledGreen = Color(red: 0.36, green: 0.78, blue: 0.46)
    static let ledGold = gold
    static let ledRed = Color(red: 0.92, green: 0.38, blue: 0.38)

    // MARK: - Bewegung

    /// Wiederverwendbare Animationskurven für konsistentes Motion-Design.
    enum Motion {
        /// Schnelle Reaktion (Press, Auswahl).
        static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.74)
        /// Weiche Übergänge (Auftauchen, Layout).
        static let smooth = Animation.spring(response: 0.48, dampingFraction: 0.88)
        /// Federnd (Belohnungen, Highlights).
        static let bouncy = Animation.spring(response: 0.40, dampingFraction: 0.64)
    }

    // MARK: - Kamera

    static let cardRadiusSmall: CGFloat = 10
}
