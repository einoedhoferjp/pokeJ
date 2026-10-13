import SwiftUI

/// Interaktiver 3D-Neigungseffekt.
///
/// Die Karte kippt unter der Fingerbewegung, hebt sich an und bekommt einen
/// dynamischen Schatten. Die Geste ist `simultaneous`, damit umliegende
/// Buttons/NavigationLinks weiterhin auslösen.
struct Card3DModifier: ViewModifier {
    var maxTilt: Double = 12
    var pressedScale: Double = 1.03

    @State private var tilt: CGSize = .zero
    @State private var isInteracting = false

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(Double(tilt.height) * maxTilt),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.55
            )
            .rotation3DEffect(
                .degrees(Double(-tilt.width) * maxTilt),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.55
            )
            .scaleEffect(isInteracting ? pressedScale : 1)
            .shadow(
                color: .black.opacity(isInteracting ? 0.42 : 0.25),
                radius: isInteracting ? 20 : 10,
                y: isInteracting ? 14 : 6
            )
            .animation(AppTheme.Motion.snappy, value: isInteracting)
            .animation(AppTheme.Motion.smooth, value: tilt)
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        isInteracting = true
                        tilt = CGSize(
                            width: clamp(value.translation.width / 120),
                            height: clamp(value.translation.height / 120)
                        )
                    }
                    .onEnded { _ in
                        tilt = .zero
                        isInteracting = false
                    }
            )
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, -1), 1)
    }
}

/// Erhöhte Kartenoberfläche im dunklen Design: gerundet, mit Lichtkante und
/// weichem Schatten.
struct SurfaceCardModifier: ViewModifier {
    var radius: CGFloat = AppTheme.cardRadius
    var padding: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
    }
}

extension View {
    /// Fügt den interaktiven 3D-Neigungseffekt hinzu.
    func card3D(maxTilt: Double = 12, pressedScale: Double = 1.03) -> some View {
        modifier(Card3DModifier(maxTilt: maxTilt, pressedScale: pressedScale))
    }

    /// Legt die Karte auf eine erhöhte, abgerundete Fläche.
    func surfaceCard(radius: CGFloat = AppTheme.cardRadius, padding: CGFloat = 10) -> some View {
        modifier(SurfaceCardModifier(radius: radius, padding: padding))
    }
}
