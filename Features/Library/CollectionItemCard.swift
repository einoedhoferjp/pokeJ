import SwiftUI

struct CollectionItemCard: View {
    let item: CollectionItem

    private var card: Card? { item.variant?.card }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            imageView
            Text(card?.name ?? "Unbekannt")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(item.confirmedCondition.displayName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent.opacity(0.18), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                Spacer(minLength: 0)
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .surfaceCard()
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
        AsyncImage(url: card?.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                placeholder(systemName: "photo.badge.exclamationmark")
            case .empty:
                ZStack {
                    placeholder(systemName: "photo")
                    ProgressView()
                }
            @unknown default:
                placeholder(systemName: "photo")
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall))
    }

    private func placeholder(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardRadiusSmall)
                .fill(Color.white.opacity(0.06))
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
