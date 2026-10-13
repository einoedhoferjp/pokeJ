import SwiftUI

/// Kurzes Snackbar-Banner, das eine soeben erhaltene Punkte-Belohnung anzeigt.
struct RewardBanner: View {
    let event: PointsStore.RewardEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(event.amount) Punkte")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(event.reason)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.accent, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
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
