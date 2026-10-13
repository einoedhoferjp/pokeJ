import SwiftUI

/// Sanfter Druck-Effekt für kartenartige Buttons (Grid-Einträge).
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Prominenter Aktionsbutton im App-Farbschema mit 3D-Druckeffekt.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: AppTheme.accent.opacity(configuration.isPressed ? 0.15 : 0.45), radius: configuration.isPressed ? 3 : 12, y: configuration.isPressed ? 1 : 7)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Flacher, tiefenglätter „Glass"-Button für sekundäre Aktionen.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(AppTheme.surfaceStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Kleiner Erfolgs-Haken mit Feder-Animation.
struct SuccessCheckmark: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 44))
            .foregroundStyle(AppTheme.brandGradient)
            .symbolEffect(.bounce, value: 1)
    }
}
