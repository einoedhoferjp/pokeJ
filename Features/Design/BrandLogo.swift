import SwiftUI
import UIKit

/// App-Logo. Nutzt das App-Icon, sofern ladbar, und zeichnet sonst einen
/// Poké-Ball im Midnight-Purple-Farbschema als Fallback.
struct BrandLogo: View {
    var size: CGFloat = 64
    var showsShadow = true

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                PokeballMark()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: showsShadow ? AppTheme.midnightPurple.opacity(0.6) : .clear, radius: size * 0.16, y: size * 0.06)
    }
}

/// Gezeichneter Poké-Ball im App-Farbschema.
struct PokeballMark: View {
    var body: some View {
        GeometryReader { proxy in
            let d = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(AppTheme.accent)
                Circle()
                    .fill(AppTheme.elevatedAlt)
                    .padding(.top, d * 0.5)
                Rectangle()
                    .fill(AppTheme.backgroundTop)
                    .frame(height: d * 0.09)
                Circle()
                    .fill(AppTheme.backgroundTop)
                    .frame(width: d * 0.30, height: d * 0.30)
                Circle()
                    .fill(AppTheme.ink)
                    .frame(width: d * 0.18, height: d * 0.18)
                Circle()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: d * 0.02)
            }
            .frame(width: d, height: d)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BrandLogo(size: 72)
        PokeballMark().frame(width: 72, height: 72)
    }
    .padding()
    .background(AppTheme.appBackground)
}
