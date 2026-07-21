import SwiftUI

// MARK: - Full Timeline Screen
struct FullTimelineScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.c2bBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.c2bText)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.top, 50)
                    .padding(.bottom, 20)

                    // Last updated
                    Text("Last updated: 4:34 pm")
                        .monoStyle(size: 10, color: .c2bMuted)
                        .padding(.bottom, 20)

                    // Stats bar
                    HStack(spacing: 10) {
                        StatCard(number: "12", label: "TRACKED")
                        StatCard(number: "05", label: "UPCOMING")
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 28)

                    // Ending Soon Section
                    TimelineSection(
                        title: "ENDING SOON",
                        tone: .c2bTeal,
                        count: 3
                    ) { _ in
                        VStack(spacing: 20) {
                            ForEach(0..<3) { index in
                                FullTimelinePosterCard(
                                    showTitle: ["The Last of Us", "Reacher", "Shōgun"][index],
                                    season: ["S2", "S3", "S2"][index],
                                    platform: ["MAX", "PRIME", "HULU"][index],
                                    days: [18, 40, 74][index]
                                )
                            }
                        }
                        .padding(.horizontal, C2BLayout.horizontalPadding)
                    }

                    // More sections here...

                    Spacer()
                        .frame(height: 150)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let number: String
    let label: String

    var body: some View {
        ZStack {
            // Background giant number
            Text(number)
                .displayStyle(size: 110, color: Color.c2bTeal.opacity(0.22))

            // Foreground content
            VStack(spacing: 5) {
                Text(number)
                    .displayStyle(size: 44, color: .c2bTealBright)

                Text(label)
                    .monoStyle(size: 9, color: .c2bDim)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.white.opacity(0.02))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Full Timeline Poster Card
struct FullTimelinePosterCard: View {
    let showTitle: String
    let season: String
    let platform: String
    let days: Int

    private var posterImageName: String {
        switch showTitle.lowercased() {
        case "the last of us": return "the-last-of-us"
        case "reacher": return "reacher"
        case "shōgun", "shogun": return "shogun"
        case "the bear": return "the-bear"
        case "severance": return "severance"
        case "fallout": return "fallout"
        case "stranger things": return "stranger-things"
        case "outlander": return "outlander"
        case "squid game": return "squid-game"
        default: return "the-last-of-us"
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Poster image
            Image(posterImageName)
                .resizable()
                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    // Gradient overlay
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                )
                .overlay(
                    // Days label on left
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(days)")
                                    .displayStyle(size: 52, color: .c2bTealBright)

                                Text("DAYS")
                                    .monoStyle(size: 9, color: .c2bTealBright)

                                Text("TO BINGE")
                                    .monoStyle(size: 8, color: .c2bMuted)
                            }
                            .padding(.leading, 26)
                            .padding(.bottom, 26)

                            Spacer()

                            // Season indicator
                            Text(season)
                                .displayStyle(size: 52, color: .white)
                                .padding(.trailing, 26)
                                .padding(.bottom, 26)
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 16)

            // Platform badge
            Text(platform)
                .monoStyle(size: 9, color: .c2bText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .padding(16)
        }
    }
}
