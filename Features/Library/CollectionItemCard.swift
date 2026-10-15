import SwiftUI

struct CollectionItemCard: View {
    let item: CollectionItem

    private var card: Card? { item.variant?.card }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            imageView
            Text(card?.name ?? "Unbekannt")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
            HStack(spacing: 8) {
                Text(item.confirmedCondition.displayName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent.opacity(0.20), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                Spacer(minLength: 0)
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .glossyCard()
        .card3D()
    }

    private var subtitle: String {
        guard let card else { return "" }
        var parts = [card.setName, "#\(card.localId)"]
        if let variant = item.variant {
            parts.append(variant.language.displayName)
            parts.append(variant.printing.displayName)
        }
        return parts.joined(separator: " · ")
    }

    private var imageView: some View {
        ZStack {
            if let url = card?.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            placeholder
                            ProgressView()
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
            glossOverlay
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: AppTheme.smallCardRadius))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius))
    }

    /// Glossy-Glanz-Overlay für moderne Kartenoberfläche.
    private var glossOverlay: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.30),
                Color.white.opacity(0.05),
                Color.black.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius))
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.smallCardRadius)
                .fill(Color.white.opacity(0.08))
            RoundedRectangle(cornerRadius: AppTheme.smallCardRadius)
                .strokeBorder(AppTheme.stroke, lineWidth: 1)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

/// Glossy-Karten-Container mit sanftem Glanz und Tiefe.
private struct GlossyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(AppTheme.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
                    )
                    .overlay(AppTheme.glossyCardGradient
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                        .blendMode(.overlay)
                        .opacity(0.5)
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 16, y: 10)
    }
}

extension View {
    func glossyCard() -> some View {
        modifier(GlossyCardModifier())
    }
}
