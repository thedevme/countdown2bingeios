import SwiftUI

// MARK: - Premiering Card (Wide horizontal card with countdown)
// Reusable in both walkthrough (with showId) and timeline (with ShowSummary)

struct PremieringCard: View {
    // For walkthrough (static images)
    let showId: String?
    let bucketKey: String?
    let namespace: Namespace.ID?

    // For timeline (real data)
    let show: ShowSummary?
    let showData: ShowData?

    // Walkthrough initializer
    init(showId: String, bucketKey: String, namespace: Namespace.ID) {
        self.showId = showId
        self.bucketKey = bucketKey
        self.namespace = namespace
        self.show = nil
        self.showData = nil
    }

    // Timeline initializer (ShowSummary - legacy)
    init(show: ShowSummary) {
        self.show = show
        self.showData = nil
        self.showId = nil
        self.bucketKey = nil
        self.namespace = nil
    }

    // Timeline initializer (ShowData - with lifecycle)
    init(showData: ShowData) {
        self.showData = showData
        self.show = nil
        self.showId = nil
        self.bucketKey = nil
        self.namespace = nil
    }

    private var mockData: (days: Int, season: String, platform: String, hasNew: Bool) {
        switch showId {
        case "shogun":
            return (10, "2", "FX", false)
        case "reacher":
            return (88, "3", "PRIME", true)
        case "stranger-things":
            return (99, "5", "NETFLIX", true)
        default:
            return (45, "2", "PRIME", false)
        }
    }

    private var daysUntilPremiere: Int {
        // Use ShowData lifecycle if available
        if let showData = showData {
            return showData.daysUntilPremiere ?? 0
        }
        // Fallback to ShowSummary
        if let show = show, let dateString = show.firstAirDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let airDate = formatter.date(from: dateString) {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: airDate).day ?? 0
                return max(0, days)
            }
        }
        return mockData.days
    }

    private var displayName: String {
        showData?.name ?? show?.name ?? showId ?? ""
    }

    private var posterURL: URL? {
        showData?.posterURL ?? show?.posterURL
    }

    private var seasonNumber: String {
        if let showData = showData {
            return String(showData.numberOfSeasons)
        }
        return mockData.season
    }

    private var platformString: String {
        if let showData = showData, let network = showData.networks.first {
            return network.name
        }
        return mockData.platform
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Countdown section
            HStack {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 0) {
                        Text("\(daysUntilPremiere)")
                            .font(.custom(.oswald.bold, size: CustomFont.size.xl7))
                            .foregroundColor(.white)
                            .tracking(-5)
                            .rotationEffect(.degrees(-90))
                            .padding(-30)

                        Text("DAYS")
                            .font(.custom(.oswald.bold, size: CustomFont.size.xl2))
                            .foregroundColor(Color.c2bTealBright)
                            .textCase(.uppercase)
                            .tracking(1.6)
                            .padding(-5)

                        Text("TO PREMIERE")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.xs))
                            .foregroundColor(Color(hex: "#52525b"))
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                }
                .padding(-7)
                .frame(width: 110, height: 140)
            }
            .padding(-20)

            // Right: Poster (flexible)
            ZStack(alignment: .topTrailing) {
                // Poster image - use AsyncImage for ShowData/ShowSummary, Image for showId
                if let url = posterURL {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(hex: "#1a1a1c"))
                    }
                    .frame(height: 140)
                    .clipped()
                    .overlay(Color.black.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .fill(Color(hex: "#5eead4").opacity(0.3))
                            .frame(width: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                } else if let showId = showId, show == nil && showData == nil {
                    Image(showId)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                        .overlay(Color.black.opacity(0.3))
                        .overlay(
                            Rectangle()
                                .fill(Color(hex: "#5eead4").opacity(0.3))
                                .frame(width: 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }

                // Overlay content
                VStack(alignment: .leading, spacing: 0) {
                    // Top badges
                    HStack(spacing: 6) {
                        if show == nil && showData == nil && mockData.hasNew {
                            Text("NEW")
                                .font(.system(size: CustomFont.size.xs, weight: .bold))
                                .foregroundColor(Color(hex: "#04201c"))
                                .textCase(.uppercase)
                                .tracking(1.4)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.c2bTealBright)
                                .cornerRadius(3)
                        }

                        Spacer()

                        Text(platformString)
                            .font(.custom(.jetbrains.bold, size: 9))
                            .foregroundColor(Color(hex: "#e7e7e7"))
                            .textCase(.uppercase)
                            .tracking(0.54)  // 0.06em
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#080808").opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }

                    Spacer()

                    // Bottom: Season + Show name
                    HStack(alignment: .bottom, spacing: 8) {
                        // Season badge (S2 style)
                        HStack(spacing: 0) {
                            Text("S")
                                .font(.custom(.oswald.bold, size: 28))
                                .foregroundColor(.white)
                            Text(seasonNumber)
                                .font(.custom(.oswald.light, size: 28))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                        Text(displayName.uppercased())
                            .font(.custom(.oswald.bold, size: 19))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(10)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .modifier(OptionalMatchedGeometry(id: showId, namespace: namespace))
    }
}

// Helper modifier for optional matched geometry effect
struct OptionalMatchedGeometry: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content.matchedGeometryEffect(id: id, in: namespace)
        } else {
            content
        }
    }
}
