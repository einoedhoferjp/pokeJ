import SwiftUI
import UIKit

/// Zentrale Design-Tokens der App.
///
/// Ausrichtung: **modern, schlicht, glossy, kinderleicht bedienbar**.
/// Dunkles Midnight-Purple Basis-Design mit glänzenden Oberflächen,
/// sanften Verläufen, klarer Typografie und großen Touch-Zielen.
enum AppTheme {
    // MARK: - Markenfarben

    /// Primär: Midnight Purple für Aktionen/Hervorhebung.
    static let accent = Color(red: 0.38, green: 0.32, blue: 0.70)
    /// Sekundär: Pokémon-Gelb für Akzente/Badges.
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
    /// Hintergrund-Text, helles Lavendel-Weiß.
    static let ink = Color(red: 0.97, green: 0.95, blue: 1.0)
    /// Kartenoberfläche (glossy Base).
    static let surface = elevated

    // MARK: - Dunkle Palette

    /// Hintergrund ganz oben (tiefes Midnight-Purple).
    static let backgroundTop = Color(red: 0.04, green: 0.03, blue: 0.07)
    /// Hintergrund ganz unten (sanftes Violett-Schwarz).
    static let backgroundBottom = Color(red: 0.08, green: 0.06, blue: 0.12)
    /// Erhöhte Flächen (Karten, Chips, Panels).
    static let elevated = Color(red: 0.12, green: 0.10, blue: 0.18)
    /// Etwas hellere erhöhte Fläche für Sekundärebenen.
    static let elevatedAlt = Color(red: 0.16, green: 0.13, blue: 0.24)
    /// Feine Rahmenfarbe.
    static let stroke = Color.white.opacity(0.10)
    /// Glanz-Overlay für glossy Oberflächen.
    static let glossHighlight = Color.white.opacity(0.25)
    /// Primärer Text.
    static let textPrimary = Color(red: 0.97, green: 0.95, blue: 1.0)
    /// Sekundärer Text (gedämpftes Violett).
    static let textSecondary = Color(red: 0.68, green: 0.64, blue: 0.80)
    /// Platzhalter-Text.
    static let textTertiary = Color(red: 0.45, green: 0.42, blue: 0.58)

    // MARK: - Geometrie

    static let cardRadius: CGFloat = 22
    static let gridSpacing: CGFloat = 16
    static let controlRadius: CGFloat = 16
    static let smallCardRadius: CGFloat = 14
    /// Große Touch-Ziele für einfache Bedienung (mindestens 44 pt).
    static let minTouchTarget: CGFloat = 48

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
            colors: [accent, Color(red: 0.55, green: 0.45, blue: 0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [gold, Color(red: 1.0, green: 0.65, blue: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Glossy-Kartenverlauf: heller Glanz oben, sanft abdunkelnd unten.
    static var glossyCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.05),
                Color.black.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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

    static let midnightPurple = Color(red: 0.24, green: 0.19, blue: 0.44)
    static let screenGlow = Color(red: 0.50, green: 0.42, blue: 0.80)
    static let ledGreen = Color(red: 0.40, green: 0.82, blue: 0.50)
    static let ledGold = gold
    static let ledRed = Color(red: 0.95, green: 0.40, blue: 0.40)

    // MARK: - Bewegung

    enum Motion {
        static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.74)
        static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.88)
        static let bouncy = Animation.spring(response: 0.40, dampingFraction: 0.64)
        static let gentle = Animation.easeInOut(duration: 0.35)
    }

    // MARK: - Kamera

    static let cardRadiusSmall: CGFloat = 10
}