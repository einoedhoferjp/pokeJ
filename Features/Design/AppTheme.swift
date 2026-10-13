import SwiftUI
import UIKit

/// Zentrale Design-Tokens der App.
///
/// Ausrichtung: **dunkles Design** mit kräftiger Typografie, interaktiven
/// 3D-Elementen, Motion und klaren Grid-Layouts.
enum AppTheme {
    // MARK: - Markenfarben

    /// Pokémon-Rot für Aktionen/Hervorhebung.
    static let accent = Color(red: 0.93, green: 0.24, blue: 0.30)
    /// Pokémon-Gelb für Akzente/Badges.
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.16)
    /// Helle Schrift-/Icon-Farbe (dunkles Design).
    static let ink = Color(red: 0.96, green: 0.97, blue: 1.0)
    /// Kartenfläche.
    static let surface = elevated

    // MARK: - Dunkle Palette

    /// Hintergrund ganz oben (fast schwarz, leicht blau).
    static let backgroundTop = Color(red: 0.06, green: 0.07, blue: 0.11)
    /// Hintergrund ganz unten (violettstichig).
    static let backgroundBottom = Color(red: 0.10, green: 0.09, blue: 0.17)
    /// Erhöhte Flächen (Karten, Chips).
    static let elevated = Color(red: 0.14, green: 0.15, blue: 0.21)
    /// Etwas hellere erhöhte Fläche.
    static let elevatedAlt = Color(red: 0.19, green: 0.20, blue: 0.27)
    /// Feine Rahmenfarbe.
    static let stroke = Color.white.opacity(0.08)
    /// Primärer Text.
    static let textPrimary = Color(red: 0.97, green: 0.98, blue: 1.0)
    /// Sekundärer Text.
    static let textSecondary = Color(red: 0.66, green: 0.69, blue: 0.79)

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

    /// Dezente Lichtkante für erhöhte Flächen.
    static var surfaceStroke: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
