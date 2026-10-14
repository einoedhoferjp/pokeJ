import SwiftUI
import UIKit

/// Zentrale Design-Tokens der App.
///
/// Ausrichtung: **dunkles Design** mit kräftiger Typografie, interaktiven
/// 3D-Elementen, Motion und klaren Grid-Layouts.
enum AppTheme {
    // MARK: - Markenfarben

    /// Midnight Purple für Aktionen/Hervorhebung.
    static let accent = Color(red: 0.35, green: 0.29, blue: 0.66)
    /// Pokémon-Gelb für Akzente/Badges.
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.16)
    /// Helle Schrift-/Icon-Farbe, midnight-purple getönt.
    static let ink = Color(red: 0.93, green: 0.91, blue: 0.99)
    /// Kartenfläche.
    static let surface = elevated

    // MARK: - Dunkle Palette

    /// Hintergrund ganz oben (fast schwarz, leicht violett).
    static let backgroundTop = Color(red: 0.07, green: 0.06, blue: 0.11)
    /// Hintergrund ganz unten (midnight purple).
    static let backgroundBottom = Color(red: 0.12, green: 0.09, blue: 0.19)
    /// Erhöhte Flächen (Karten, Chips).
    static let elevated = Color(red: 0.14, green: 0.12, blue: 0.23)
    /// Etwas hellere erhöhte Fläche.
    static let elevatedAlt = Color(red: 0.19, green: 0.16, blue: 0.30)
    /// Feine Rahmenfarbe.
    static let stroke = Color.white.opacity(0.08)
    /// Primärer Text (helles Lavendel).
    static let textPrimary = Color(red: 0.93, green: 0.92, blue: 0.99)
    /// Sekundärer Text (gedämpftes Violett).
    static let textSecondary = Color(red: 0.65, green: 0.61, blue: 0.78)

    // MARK: - Geometrie

    static let cardRadius: CGFloat = 18
    static let gridSpacing: CGFloat = 14
    static let controlRadius: CGFloat = 14

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

    /// Dezente Lichtkante für erhöhte Flächen.
    static var surfaceStroke: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)],
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
        static let snappy = Animation.spring(response: 0.30, dampingFraction: 0.72)
        /// Weiche Übergänge (Auftauchen, Layout).
        static let smooth = Animation.spring(response: 0.50, dampingFraction: 0.86)
        /// Federnd (Belohnungen, Highlights).
        static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.62)
    }

    // MARK: - Kamera

    static let cardRadiusSmall: CGFloat = 10
}
