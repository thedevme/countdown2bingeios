import SwiftUI
import SwiftData

// MARK: - Premiering Card (Wide horizontal card with countdown)
// Reusable in both walkthrough (with showId) and timeline (with Series/ShowSummary)

struct PremieringCard: View {
    // For walkthrough (static images)
    let showId: String?
    let bucketKey: String?
    let namespace: Namespace.ID?

    // For timeline (real data)
    let show: ShowSummary?
    let showData: ShowData?
    let series: Series?

    // Walkthrough initializer
    init(showId: String, bucketKey: String, namespace: Namespace.ID) {
        self.showId = showId
        self.bucketKey = bucketKey
        self.namespace = namespace
        self.show = nil
        self.showData = nil
        self.series = nil
    }

    // Timeline initializer (ShowSummary - legacy)
    init(show: ShowSummary) {
        self.show = show
        self.showData = nil
        self.series = nil
        self.showId = nil
        self.bucketKey = nil
        self.namespace = nil
    }

    // Timeline initializer (ShowData - for discover/search)
    init(showData: ShowData) {
        self.showData = showData
        self.show = nil
        self.series = nil
        self.showId = nil
        self.bucketKey = nil
        self.namespace = nil
    }

    // Timeline initializer (Series - primary, reads state from BingeEngine)
    init(series: Series) {
        self.series = series
        self.showData = nil
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
        // Primary: read from Series (BingeEngine state)
        if let series = series {
            return series.daysUntilPremiere ?? 0
        }
        // Fallback: ShowData (for discover/search)
        if let showData = showData {
            return showData.daysUntilPremiere ?? 0
        }
        // Legacy: ShowSummary
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
        series?.name ?? showData?.name ?? show?.name ?? showId ?? ""
    }

    private var posterURL: URL? {
        series?.posterURL ?? showData?.posterURL ?? show?.posterURL
    }

    private var seasonNumber: String {
        if let series = series {
            return String(series.numberOfSeasons)
        }
        if let showData = showData {
            return String(showData.numberOfSeasons)
        }
        return mockData.season
    }

    private var platformString: String {
        if let series = series, let network = series.networks.first {
            return network.name
        }
        if let showData = showData, let network = showData.networks.first {
            return network.name
        }
        return mockData.platform
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Countdown section
            CountdownLabelView(
                number: daysUntilPremiere,
                accentColor: .c2bTealBright,
                bottomLabel: "timeline_to_premiere"
            )

            // Right: Poster (flexible)
            ZStack(alignment: .topTrailing) {
                // Poster image - use AsyncImage for ShowData/ShowSummary, Image for showId
                if let url = posterURL {
                    BackdropView(url: url, height: 140)
                    .overlay(Color.black.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .fill(Color.c2bTealLine)
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
                            Text("badge_new")
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
                            Text("season_abbrev")
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
        .contentShape(Rectangle())
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
