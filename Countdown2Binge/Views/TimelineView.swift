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
    @State private var lastRefreshed: Date? = Date()
    @Bindable private var settings = AppSettings.shared

    // Section expand/collapse state (both sections sync together)
    // Default to compact (collapsed) view
    @State private var isSectionsExpanded: Bool = false

    // Hero card stack index
    @State private var heroCardIndex: Int = 0

    // Refresh state
    @State private var isRefreshing: Bool = false

    // Full timeline navigation
    @State private var showFullTimeline: Bool = false

    private let timelineService = TimelineService()
    private let maxCardsPerSection = 3

    // MARK: - Cached Computed Data (to avoid recalculation)

    /// All shows converted from cache - computed once per data change
    /// In UI testing mode, returns mock data for the current scenario
    private var allShows: [Show] {
        if UITestDataProvider.isUITesting {
            return UITestDataProvider.showsForCurrentScenario()
        }
        return followedShows.compactMap { $0.cachedData?.toShow() }
    }

    /// Grouped timeline entries - computed once, used for both sections
    private var groupedEntries: [TimelineCategory: [TimelineEntry]] {
        timelineService.groupByCategory(allShows)
    }

    /// Currently airing shows sorted by soonest finale (TBD shows at end)
    private var airingShows: [(show: Show, daysUntilFinale: Int?, episodesUntilFinale: Int?, finaleDate: Date?)] {
        let airing = allShows.filter { $0.lifecycleState == .airing }
        return airing
            .map { show in
                (show, show.daysUntilFinale, show.episodesUntilFinale, show.currentSeason?.finaleDate)
            }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilFinale, rhs.daysUntilFinale) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return lhs.show.name < rhs.show.name
                }
            }
    }

    /// Current hero show based on card stack index
    private var currentHeroShow: (show: Show, daysUntilFinale: Int?, episodesUntilFinale: Int?, finaleDate: Date?)? {
        guard !airingShows.isEmpty, heroCardIndex < airingShows.count else { return nil }
        return airingShows[heroCardIndex]
    }

    /// The countdown value based on the display mode setting
    private var countdownValue: Int? {
        guard let hero = currentHeroShow else { return nil }
        return settings.countdownDisplayMode == .days ? hero.daysUntilFinale : hero.episodesUntilFinale
    }

    /// Premiering soon entries (uses cached groupedEntries)
    private var premieringSoonEntries: [TimelineEntry] {
        groupedEntries[.premieringSoon] ?? []
    }

    /// Anticipated entries (uses cached groupedEntries)
    private var anticipatedEntries: [TimelineEntry] {
        let entries = groupedEntries[.anticipated] ?? []
        return entries.sorted { entry1, entry2 in
            let hasDate1 = entry1.show.upcomingSeason?.airDate != nil
            let hasDate2 = entry2.show.upcomingSeason?.airDate != nil
            if hasDate1 && !hasDate2 { return true }
            if !hasDate1 && hasDate2 { return false }
            return entry1.show.name < entry2.show.name
        }
    }

    /// True if any section has at least one show (used to hide empty sections)
    private var hasAnyShows: Bool {
        !airingShows.isEmpty || !premieringSoonEntries.isEmpty || !anticipatedEntries.isEmpty
    }

    /// True if user has no followed shows at all (show empty timeline for onboarding)
    /// In UI testing mode, checks if the scenario is NoFollowedShows
    private var hasNoFollowedShows: Bool {
        if UITestDataProvider.isUITesting {
            return UITestDataProvider.currentScenario == .noFollowedShows
        }
        return followedShows.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        TimelineHeaderView(
                            lastUpdated: lastRefreshed,
                            isRefreshing: isRefreshing,
                            onRefresh: {
                                Task {
                                    await refreshShows()
                                }
                            },
                            onViewEntireTimeline: {
                                showFullTimeline = true
                            }
                        )

                        // Hero section (swipeable card stack)
                        ZStack {
                            // UI Test marker - zero-size text that XCUITest can find
                            if !airingShows.isEmpty {
                                Text("EndingSoon")
                                    .accessibilityIdentifier("EndingSoonSection")
                                    .frame(width: 0, height: 0)
                                    .opacity(0)
                            }

                            HeroCardStack(
                                shows: airingShows,
                                currentIndex: $heroCardIndex,
                                onShowTap: { show in
                                    selectedShow = show
                                }
                            )
                        }

                        // Connector from cards to countdown
                        verticalConnector
                            .frame(height: 50)

                        // Slot machine countdown (syncs with current card)
                        if currentHeroShow != nil {
                            SlotMachineCountdown(
                                value: countdownValue,
                                displayMode: settings.countdownDisplayMode
                            )
                        }

                        // Vertical connector from hero to sections
                        verticalConnector
                            .frame(height: 60)

                        if hasNoFollowedShows {
                            // No followed shows - show empty timeline for onboarding
                            // UI Test marker for empty state
                            Text("").accessibilityIdentifier("EmptySlotCards").frame(width: 0, height: 0)
                            premieringSoonSection
                            anticipatedSection
                        } else if hasAnyShows {
                            // Has shows in categories - only show sections with content
                            if !premieringSoonEntries.isEmpty {
                                premieringSoonSection
                            }
                            if !anticipatedEntries.isEmpty {
                                anticipatedSection
                            }
                        } else {
                            // Has followed shows but none in timeline categories
                            noTimelineShowsView
                            // UI Test marker
                            Text("NoTimeline")
                                .accessibilityIdentifier("NoTimelineShowsView")
                                .frame(width: 0, height: 0)
                                .opacity(0)
                        }

                        // Footer
                        TimelineFooterView(onViewFullTimeline: {
                            showFullTimeline = true
                        })
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
            .navigationDestination(isPresented: $showFullTimeline) {
                FullTimelineView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            SoundManager.warmUp()
        }
    }

    // MARK: - Premiering Soon Section

    private var premieringSoonSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line running through entire section
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 48)) // Start below header badge
                    path.addLine(to: CGPoint(x: 40, y: geometry.size.height))
                }
                .stroke(
                    Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                )
            }
            .frame(width: 80)

            VStack(spacing: 0) {
                TimelineSectionHeader(
                    title: "PREMIERING SOON",
                    totalCount: premieringSoonEntries.count,
                    isExpanded: $isSectionsExpanded,
                    showDisclosure: true,
                    style: .premiering
                )

                Group {
                if isSectionsExpanded {
                    // Expanded: Show full timeline cards with landscape backdrops
                    if premieringSoonEntries.isEmpty {
                        // Empty slots
                        VStack(spacing: 30) {
                            ForEach(0..<3, id: \.self) { index in
                                EmptySlotCard(
                                    style: .premiering,
                                    isFirst: index == 0,
                                    isLast: index == 2
                                )
                                .frame(height: 190)
                            }
                        }
                    } else {
                        // Show cards (max 3)
                        VStack(spacing: 30) {
                            let displayEntries = Array(premieringSoonEntries.prefix(maxCardsPerSection))
                            ForEach(Array(displayEntries.enumerated()), id: \.element.id) { index, entry in
                                TimelineShowCard(
                                    show: entry.show,
                                    seasonNumber: entry.show.upcomingSeason?.seasonNumber ?? entry.show.currentSeason?.seasonNumber ?? 1,
                                    style: .premiering,
                                    daysUntil: entry.countdown?.days,
                                    expectedYear: nil,
                                    isFirst: index == 0,
                                    isLast: index == displayEntries.count - 1
                                )
                                .frame(height: 190)
                                .onTapGesture {
                                    selectedShow = entry.show
                                }
                            }
                        }
                    }
                } else {
                    // Collapsed: Show compact portrait posters or empty portrait slots
                    if premieringSoonEntries.isEmpty {
                        // Empty portrait slots when collapsed
                        EmptyPortraitSlots(style: .premiering)
                    } else {
                        CompactPosterRow(
                            shows: premieringSoonEntries.map { $0.show },
                            style: .premiering,
                            onShowTap: { show in
                                selectedShow = show
                            }
                        )
                    }
                }
                }
                .animation(.easeInOut(duration: 0.3), value: isSectionsExpanded)
            }
        }
    }

    // MARK: - Anticipated Section

    private var anticipatedSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line running through entire section
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 48)) // Start below header badge
                    path.addLine(to: CGPoint(x: 40, y: geometry.size.height))
                }
                .stroke(
                    Color(white: 0.4).opacity(0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                )
            }
            .frame(width: 80)

            VStack(spacing: 0) {
                TimelineSectionHeader(
                    title: "ANTICIPATED",
                    totalCount: anticipatedEntries.count,
                    isExpanded: $isSectionsExpanded,
                    showDisclosure: false,
                    style: .anticipated
                )

                Group {
                    if isSectionsExpanded {
                        // Expanded: Show full timeline cards with landscape backdrops
                        if anticipatedEntries.isEmpty {
                            // Empty slots
                            VStack(spacing: 30) {
                                ForEach(0..<3, id: \.self) { index in
                                    EmptySlotCard(
                                        style: .anticipated,
                                        isFirst: index == 0,
                                        isLast: index == 2
                                    )
                                    .frame(height: 190)
                                }
                            }
                        } else {
                            // Show cards (max 3)
                            VStack(spacing: 30) {
                                let displayEntries = Array(anticipatedEntries.prefix(maxCardsPerSection))
                                ForEach(Array(displayEntries.enumerated()), id: \.element.id) { index, entry in
                                    let expectedYear = Calendar.current.component(.year, from: entry.show.upcomingSeason?.airDate ?? Date())
                                    let hasDate = entry.show.upcomingSeason?.airDate != nil

                                    TimelineShowCard(
                                        show: entry.show,
                                        seasonNumber: entry.show.upcomingSeason?.seasonNumber ?? entry.show.currentSeason?.seasonNumber ?? 1,
                                        style: .anticipated,
                                        daysUntil: nil,
                                        expectedYear: hasDate ? expectedYear : nil,
                                        isFirst: index == 0,
                                        isLast: index == displayEntries.count - 1
                                    )
                                    .frame(height: 190)
                                    .onTapGesture {
                                        selectedShow = entry.show
                                    }
                                }
                            }
                        }
                    } else {
                        // Collapsed: Show compact portrait posters or empty portrait slots
                        if anticipatedEntries.isEmpty {
                            // Empty portrait slots when collapsed
                            EmptyPortraitSlots(style: .anticipated)
                        } else {
                            CompactPosterRow(
                                shows: anticipatedEntries.map { $0.show },
                                style: .anticipated,
                                onShowTap: { show in
                                    selectedShow = show
                                }
                            )
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isSectionsExpanded)
        }
    }

    // MARK: - No Timeline Shows View

    /// Shown when user has followed shows but none fall into timeline categories
    private var noTimelineShowsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.5))

            VStack(spacing: 8) {
                Text("Nothing on the Timeline")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Your followed shows aren't currently\nairing or premiering soon")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Vertical Connector

    private var verticalConnector: some View {
        GeometryReader { geometry in
            Path { path in
                let x = geometry.size.width / 2
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: geometry.size.height))
            }
            .stroke(
                Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.8),
                style: StrokeStyle(lineWidth: 2, dash: [4, 4])
            )
        }
    }

    // MARK: - Refresh

    private func refreshShows() async {
        isRefreshing = true
        let refreshService = StateRefreshService(
            modelContainer: modelContext.container,
            tmdbService: TMDBService()
        )
        await refreshService.refreshWithAPIData()
        lastRefreshed = Date()
        isRefreshing = false
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

#Preview("Timeline") {
    TimelineView()
        .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
}
