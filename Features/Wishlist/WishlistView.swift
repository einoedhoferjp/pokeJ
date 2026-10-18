import SwiftData
import SwiftUI

/// Wunschliste: gewünschte Karten, erfüllte Wünsche werden automatisch
/// markiert, sobald die Karte in der Sammlung auftaucht.
struct WishlistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WishCard.createdAt, order: .reverse) private var wishes: [WishCard]
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: AppTheme.gridSpacing)]

    /// Externe IDs aller Karten, die (in irgendeiner Sprache/Variantenform)
    /// bereits in der Sammlung stecken.
    private var ownedIds: Set<String> {
        Set(items.compactMap { $0.variant?.card?.externalId })
    }

    var body: some View {
        Group {
            if wishes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                        ForEach(wishes) { wish in
                            WishlistCell(wish: wish, isFulfilled: ownedIds.contains(wish.externalId))
                                .contextMenu {
                                    Button(role: .destructive) {
                                        WishlistStore.remove(externalId: wish.externalId, context: context)
                                    } label: {
                                        Label("Von der Wunschliste", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wunschliste")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundTop, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(AppTheme.appBackground.ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.textTertiary)
            Text("Deine Wunschliste ist leer")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            Text("Tippe in den Sets auf das Herz, um Karten zu merken. Fehlt eine gewünschte Karte später in deiner Sammlung, wird sie hier automatisch abgehakt.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }
}

/// Einzelnes Wunsch-Kachelchen.
private struct WishlistCell: View {
    let wish: WishCard
    let isFulfilled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AsyncImage(url: wish.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack { placeholder; ProgressView() }
                    @unknown default:
                        placeholder
                    }
                }
                .aspectRatio(0.72, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous))

                if isFulfilled {
                    Color.black.opacity(0.45)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous))
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.mint)
                            .shadow(color: AppTheme.mint.opacity(0.8), radius: 8)
                        Text("Gefunden")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("#\(wish.localId)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                    .padding(6)
                }
            }

            Text(wish.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isFulfilled ? AppTheme.mint : AppTheme.ink)
                .lineLimit(1)
            Text(wish.setName)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.elevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(isFulfilled ? AppTheme.mint.opacity(0.4) : AppTheme.stroke, lineWidth: 1)
        )
        .opacity(isFulfilled ? 0.85 : 1)
        .animation(AppTheme.Motion.smooth, value: isFulfilled)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: AppTheme.smallCardRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(AppTheme.textSecondary)
            }
    }
}

#Preview {
    WishlistView()
        .modelContainer(PreviewData.container)
}
