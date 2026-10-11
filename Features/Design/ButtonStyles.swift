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

/// Prominenter Aktionsbutton im App-Farbschema.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(configuration.isPressed ? 0.1 : 0.3), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
