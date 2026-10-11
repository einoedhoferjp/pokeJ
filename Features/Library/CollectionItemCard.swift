import SwiftUI

struct CollectionItemCard: View {
    let item: CollectionItem

    private var card: Card? { item.variant?.card }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            imageView
            Text(card?.name ?? "Unbekannt")
                .font(.headline)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(item.confirmedCondition.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                Spacer()
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func placeholder(systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
            Image(systemName: systemName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}
