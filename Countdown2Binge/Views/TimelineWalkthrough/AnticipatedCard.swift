import SwiftUI
import SwiftData

// MARK: - Anticipated Card (Wide horizontal card with countdown)
struct AnticipatedCard: View {
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
        case "reacher":
            return (88, "2", "NETFLIX", true)
        case "shogun":
            return (10, "5", "NETFLIX", false)
        default:
            return (12, "2", "PRIME", false)
        }
    }

    private var daysUntilPremiere: Int {
        // Primary: read from Series
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

    /// The real anticipated/next season number — the engine's current season for a
    /// Series (the announced not-yet-started season), or the DTO's announced-season
    /// computed for ShowData. Nil when there is NO real next season in the data, so
    /// the view renders no season badge rather than fabricating `numberOfSeasons + 1`.
    private var anticipatedSeasonNumber: Int? {
        if let series = series {
            return series.currentSeason?.seasonNumber
        }
        if let showData = showData {
            return showData.anticipatedSeason?.seasonNumber
        }
        return Int(mockData.season) // walkthrough mock
    }

    // Expected release year (next year, formatted as '26)
    private var expectedYearDisplay: String {
        let nextYear = Calendar.current.component(.year, from: Date()) + 1
        let shortYear = nextYear % 100
        return "'\(shortYear)"
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
                text: expectedYearDisplay,
                middleLabel: "timeline_exp",
                accentColor: .c2bTealBright,
                bottomLabel: "timeline_release"
            )

            // Right: Poster (flexible)
            ZStack(alignment: .topTrailing) {
                // Poster image - use AsyncImage for ShowData/ShowSummary, Image for showId
                if let url = posterURL {
                    BackdropView(url: url, height: 140)
                    .grayscale(1.0)
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
                        .grayscale(1.0)
                        .clipped()
                        .overlay(Color.black.opacity(0.3))
                        .overlay(
                            Rectangle()
                                .fill(Color(hex: "#5eead4").opacity(0.3))
                                .frame(width: 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }

                // Badges overlay
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
                        // Season badge (S5 style) — only when a real season exists
                        if let seasonNum = anticipatedSeasonNumber {
                            HStack(spacing: 0) {
                                Text("season_abbrev")
                                    .font(.custom(.oswald.bold, size: 28))
                                    .foregroundColor(.white)
                                Text(String(seasonNum))
                                    .font(.custom(.oswald.light, size: 28))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                        }

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

// Preview disabled - requires namespace parameter
// #Preview {
//     VStack(spacing: 20) {
//         AnticipatedCard(showId: "stranger-things")
//         AnticipatedCard(showId: "fallout")
//     }
//     .padding()
//     .background(Color.c2bBackground)
// }
