//
//  TimelineView.swift
//  Countdown2Binge
//
//  The main timeline home screen displaying shows by lifecycle category.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FollowedShow.followedAt, order: .reverse)
    private var followedShows: [FollowedShow]
    @State private var selectedShow: Show?

    private let timelineService = TimelineService()

    private var groupedShows: [(category: TimelineCategory, entries: [TimelineEntry])] {
        let shows = followedShows.compactMap { $0.cachedData?.toShow() }
        let grouped = timelineService.groupByCategory(shows)
        // Exclude bingeReady - those shows appear in the Binge Ready tab, not Timeline
        return timelineService.sortedCategories(from: grouped)
            .filter { $0.category != .bingeReady }
    }

    /// Whether cached data has been loaded for followed shows
    private var hasCachedData: Bool {
        followedShows.contains { $0.cachedData != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep background with subtle gradient
                LinearGradient(
                    colors: [
                        Color(hex: "0A0A0A"),
                        Color(hex: "0F0F0F"),
                        Color(hex: "0A0A0A")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if followedShows.isEmpty {
                    EmptyStateView()
                } else if !hasCachedData {
                    // Has followed shows but no cached data yet
                    LoadingStateView()
                } else if groupedShows.isEmpty {
                    // Has cached data but all shows are in Binge Ready tab
                    AllBingeReadyStateView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 40) {
                            // Header
                            HeaderView()
                                .padding(.horizontal, 24)
                                .padding(.top, 16)

                            // Timeline sections
                            ForEach(groupedShows, id: \.category) { section in
                                TimelineSectionView(
                                    category: section.category,
                                    entries: section.entries,
                                    onShowSelected: { show in
                                        selectedShow = show
                                    }
                                )
                            }

                            Spacer(minLength: 100)
                        }
                    }
                    .refreshable {
                        await refreshShows()
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedShow) { show in
                ShowDetailView(
                    viewModel: ShowDetailViewModel(
                        show: show,
                        repository: ShowRepository(modelContext: modelContext)
                    )
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Refresh

    private func refreshShows() async {
        let refreshService = StateRefreshService(
            modelContainer: modelContext.container,
            tmdbService: TMDBService()
        )
        await refreshService.refreshWithAPIData()
    }
}

// MARK: - Header View

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COUNTDOWN")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(3)
                .foregroundColor(Color(hex: "D4A574"))

            Text("Your Shows")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 120, height: 120)

                Image(systemName: "tv")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color(hex: "D4A574"))
            }

            VStack(spacing: 12) {
                Text("No Shows Yet")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text("Follow shows to track when\nthey're ready to binge.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(40)
    }
}

// MARK: - Loading State

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "D4A574"))

            Text("Loading your shows...")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "666666"))
        }
    }
}

// MARK: - All Binge Ready State

private struct AllBingeReadyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color(hex: "4CAF50"))
            }

            VStack(spacing: 12) {
                Text("All Caught Up!")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text("All your shows are ready to binge.\nCheck the Binge Ready tab.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(40)
    }
}

// MARK: - Timeline Section

struct TimelineSectionView: View {
    let category: TimelineCategory
    let entries: [TimelineEntry]
    let onShowSelected: (Show) -> Void

    private var sectionIcon: String {
        switch category {
        case .bingeReady: return "checkmark.circle.fill"
        case .airingNow: return "play.circle.fill"
        case .premieringSoon: return "calendar.circle.fill"
        case .anticipated: return "sparkles"
        }
    }

    private var accentColor: Color {
        switch category {
        case .bingeReady: return Color(hex: "4CAF50")
        case .airingNow: return Color(hex: "D4A574")
        case .premieringSoon: return Color(hex: "64B5F6")
        case .anticipated: return Color(hex: "9E9E9E")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: sectionIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)

                Text(category.rawValue.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "888888"))

                Text("·")
                    .foregroundColor(Color(hex: "444444"))

                Text("\(entries.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))

                Spacer()
            }
            .padding(.horizontal, 24)

            // Horizontal scroll of cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(entries) { entry in
                        ShowCardView(entry: entry, accentColor: accentColor)
                            .onTapGesture {
                                onShowSelected(entry.show)
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Show Card

struct ShowCardView: View {
    let entry: TimelineEntry
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster
            ZStack {
                // Poster image or placeholder
                if let url = TMDBConfiguration.imageURL(path: entry.show.posterPath, size: .poster) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            posterPlaceholder
                        case .empty:
                            posterPlaceholder
                                .overlay(
                                    ProgressView()
                                        .tint(Color(hex: "666666"))
                                )
                        @unknown default:
                            posterPlaceholder
                        }
                    }
                } else {
                    posterPlaceholder
                }

                // Countdown badge
                if let countdown = entry.countdown {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            CountdownBadgeView(countdown: countdown, accentColor: accentColor)
                                .padding(12)
                        }
                    }
                }

                // Binge ready checkmark
                if entry.category == .bingeReady {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 28, height: 28)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .padding(12)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 140, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Show info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.show.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let countdown = entry.countdown {
                    Text(countdown.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                } else {
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))
                }
            }
            .padding(.top, 12)
            .frame(width: 140, alignment: .leading)
        }
    }

    private var statusText: String {
        switch entry.category {
        case .bingeReady: return "Ready to binge"
        case .airingNow: return "Currently airing"
        case .premieringSoon: return "Coming soon"
        case .anticipated: return "Date TBD"
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "1A1A1A"),
                    Color(hex: "151515")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(String(entry.show.name.prefix(1)))
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "2A2A2A"))
        }
    }
}

// MARK: - Countdown Badge

struct CountdownBadgeView: View {
    let countdown: CountdownInfo
    let accentColor: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(countdown.days)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("days")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "AAAAAA"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Timeline with Shows") {
    TimelineView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
}

#Preview("Empty State") {
    TimelineView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
}
