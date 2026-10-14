import SwiftUI

/// Farbwelten je Sammel-Ära für das Booster-Design.
enum BoosterPalette {
    static func colors(for serieId: String?) -> [Color] {
        switch serieId {
        case "base":
            return [Color(red: 0.42, green: 0.20, blue: 0.14), Color(red: 0.86, green: 0.49, blue: 0.16)]
        case "neo":
            return [Color(red: 0.05, green: 0.31, blue: 0.29), Color(red: 0.18, green: 0.64, blue: 0.56)]
        case "ecard":
            return [Color(red: 0.17, green: 0.23, blue: 0.40), Color(red: 0.35, green: 0.44, blue: 0.69)]
        case "ex":
            return [Color(red: 0.29, green: 0.12, blue: 0.17), Color(red: 0.63, green: 0.19, blue: 0.31)]
        case "dp":
            return [Color(red: 0.11, green: 0.25, blue: 0.43), Color(red: 0.29, green: 0.53, blue: 0.78)]
        case "pl":
            return [Color(red: 0.23, green: 0.25, blue: 0.30), Color(red: 0.54, green: 0.58, blue: 0.65)]
        case "hgss":
            return [Color(red: 0.35, green: 0.23, blue: 0.07), Color(red: 0.78, green: 0.60, blue: 0.29)]
        case "col":
            return [Color(red: 0.07, green: 0.23, blue: 0.35), Color(red: 0.25, green: 0.53, blue: 0.69)]
        case "bw":
            return [Color(red: 0.07, green: 0.07, blue: 0.09), Color(red: 0.29, green: 0.31, blue: 0.36)]
        case "xy":
            return [Color(red: 0.35, green: 0.11, blue: 0.23), Color(red: 0.69, green: 0.25, blue: 0.48)]
        case "sm":
            return [Color(red: 0.11, green: 0.16, blue: 0.37), Color(red: 0.42, green: 0.31, blue: 0.75)]
        case "swsh":
            return [Color(red: 0.06, green: 0.29, blue: 0.29), Color(red: 0.18, green: 0.63, blue: 0.63)]
        case "sv":
            return [Color(red: 0.42, green: 0.09, blue: 0.09), Color(red: 0.76, green: 0.23, blue: 0.23)]
        case "me":
            return [Color(red: 0.23, green: 0.06, blue: 0.29), Color(red: 0.63, green: 0.23, blue: 0.75)]
        case "tcgp":
            return [Color(red: 0.04, green: 0.23, blue: 0.42), Color(red: 0.16, green: 0.54, blue: 0.82)]
        default:
            return [AppTheme.accent, Color(red: 0.52, green: 0.42, blue: 0.85)]
        }
    }
}

/// Stilisierter Booster-Wrapper: Epochen-Farbverlauf, Set-Logo, Metallschimmer.
struct BoosterPackArt: View {
    let pack: PackDefinition
    var width: CGFloat = 150
    var showsDetails: Bool = true

    private var height: CGFloat { (width / 0.70).rounded() }
    private var corner: CGFloat { width * 0.10 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: BoosterPalette.colors(for: pack.serieId),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            LinearGradient(
                colors: [.white.opacity(0.22), .clear, .white.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)

            PokeballMark()
                .frame(width: width * 0.6, height: width * 0.6)
                .opacity(0.12)
                .offset(x: width * 0.18, y: width * 0.2)

            content
        }
        .frame(width: width, height: height)
        .overlay(alignment: .top) { crimp }
        .overlay(alignment: .bottom) { crimp }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: width * 0.1, y: width * 0.05)
    }

    private var content: some View {
        VStack(spacing: width * 0.05) {
            HStack {
                Text("BOOSTER")
                    .font(.system(size: width * 0.085, weight: .heavy))
                    .tracking(width * 0.008)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, width * 0.07)
                    .padding(.vertical, width * 0.028)
                    .background(.black.opacity(0.28), in: Capsule())
                Spacer(minLength: 0)
            }

            Spacer(minLength: width * 0.04)
            logoOrName
            Spacer(minLength: width * 0.04)

            if showsDetails {
                VStack(spacing: width * 0.025) {
                    Text(pack.eraName ?? "Booster")
                        .font(.system(size: width * 0.078, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: width * 0.05) {
                        if let year = pack.releaseYearText {
                            Label(year, systemImage: "calendar")
                        }
                        Label("\(pack.cardCount)", systemImage: "rectangle.stack.fill")
                    }
                    .font(.system(size: width * 0.066, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, width * 0.1)
        .padding(.vertical, width * 0.08)
    }

    @ViewBuilder
    private var logoOrName: some View {
        if let url = pack.logoURL {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFit()
                        .shadow(color: .black.opacity(0.35), radius: width * 0.03, y: width * 0.01)
                } else {
                    nameFallback
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            nameFallback
        }
    }

    private var nameFallback: some View {
        Text(pack.setName ?? pack.name)
            .font(.system(size: width * 0.12, weight: .heavy))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .lineLimit(3)
            .padding(.horizontal, width * 0.05)
            .padding(.vertical, width * 0.04)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: width * 0.06, style: .continuous))
    }

    private var crimp: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(height: width * 0.05)
    }
}

#Preview {
    HStack(spacing: 16) {
        BoosterPackArt(pack: PackDefinition.standard, width: 160)
        BoosterPackArt(pack: PackDefinition.premium, width: 100)
    }
    .padding()
    .background(AppTheme.appBackground)
}
