import SwiftUI

/// Kurzes Snackbar-Banner, das eine soeben erhaltene Punkte-Belohnung anzeigt.
struct RewardBanner: View {
    let event: PointsStore.RewardEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.ink)
                .symbolEffect(.bounce, value: event.id)
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(event.amount) Punkte")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(event.reason)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.ink.opacity(0.75))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.goldGradient, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: AppTheme.gold.opacity(0.45), radius: 14, y: 6)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Belohnung: plus \(event.amount) Punkte, \(event.reason)")
    }
}

private struct RewardBannerModifier: ViewModifier {
    @ObservedObject var points: PointsStore

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let reward = points.reward {
                RewardBanner(event: reward)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: points.reward?.id)
    }
}

extension View {
    /// Blendet bei neuen Punkte-Belohnungen eine Snackbar am oberen Rand ein.
    func rewardBanner(points: PointsStore) -> some View {
        modifier(RewardBannerModifier(points: points))
    }
}
