import SwiftUI

/// Sanfter Druck-Effekt für kartenartige Buttons (Grid-Einträge).
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Prominenter Aktionsbutton mit glossy Verlauf und großer Touch-Zone.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: AppTheme.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(AppTheme.brandGradient)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .blendMode(.overlay)
                        .opacity(0.5)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: AppTheme.accent.opacity(configuration.isPressed ? 0.20 : 0.50),
                    radius: configuration.isPressed ? 4 : 16, y: configuration.isPressed ? 2 : 12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Flacher, glossy „Glass"-Button für sekundäre Aktionen.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: AppTheme.minTouchTarget)
            .background(
                Capsule()
                    .fill(AppTheme.elevatedAlt)
                    .overlay(AppTheme.glossyCardGradient
                        .clipShape(Capsule())
                        .blendMode(.overlay)
                        .opacity(0.4))
            )
            .overlay(Capsule().strokeBorder(AppTheme.surfaceStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

/// Kleiner Erfolgs-Haken mit Feder-Animation.
struct SuccessCheckmark: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 48))
            .foregroundStyle(AppTheme.brandGradient)
            .symbolEffect(.bounce, value: 1)
    }
}