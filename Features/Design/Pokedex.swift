import SwiftUI

/// Pokédex-artiges Panel: Rahmen mit LED-Kopfleiste und Bildschirmfläche.
struct PokedexPanel<Content: View>: View {
    let title: String
    var statusLED: Color = AppTheme.ledGreen
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .fill(AppTheme.backgroundTop.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .strokeBorder(AppTheme.screenGlow.opacity(0.25), lineWidth: 1)
                )
                .padding(10)
        }
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }

    private var header: some View {
        HStack(spacing: 8) {
            LED(color: statusLED, size: 12)
            LED(color: AppTheme.ledGold, size: 8)
            LED(color: AppTheme.ledRed, size: 8)
            Spacer()
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Circle()
                .fill(AppTheme.midnightPurple)
                .frame(width: 16, height: 16)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.elevatedAlt)
    }
}

/// Kleine Status-LED mit Glanzpunkt.
struct LED: View {
    var color: Color
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: -size * 0.16, y: -size * 0.16)
            )
            .shadow(color: color.opacity(0.7), radius: size * 0.4)
    }
}

/// Pokédex-Überschrift mit LED und Titel.
struct PokedexSectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var ledColor: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: 8) {
            LED(color: ledColor, size: 9)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PokedexPanel(title: "Scanner") {
            Text("Inhalt").foregroundStyle(AppTheme.ink)
        }
        PokedexSectionHeader(title: "Letzte Zugänge", systemImage: "clock")
    }
    .padding()
    .background(AppTheme.appBackground)
}
