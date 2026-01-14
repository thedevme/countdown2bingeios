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
    private let maxEndingSoonCards = 5
    private let maxCardsPerSection = 3

    // MARK: - Computed Properties

    private var allShows: [Show] {
        followedShows.compactMap { $0.cachedData?.toShow() }
    }

    private var hasCachedData: Bool {
        followedShows.contains { $0.cachedData != nil }
    }

    /// Currently airing shows sorted by soonest finale (for hero card stack)
    private var airingShowsWithFinale: [(show: Show, daysUntilFinale: Int)] {
        let airingShows = allShows.filter { $0.lifecycleState == .airing }
        return airingShows
            .compactMap { show -> (Show, Int)? in
                guard let days = show.daysUntilFinale else { return nil }
                return (show, days)
            }
            .sorted { $0.1 < $1.1 }
    }

    /// Current hero show based on card stack index
    private var currentHeroShow: (show: Show, daysUntilFinale: Int)? {
        guard !airingShowsWithFinale.isEmpty,
              heroCardIndex < airingShowsWithFinale.count else { return nil }
        return airingShowsWithFinale[heroCardIndex]
    }

    /// Ending soon entries (currently airing shows sorted by days until finale)
    private var endingSoonEntries: [(show: Show, daysUntilFinale: Int)] {
        airingShowsWithFinale
    }

    /// Premiering soon entries (sorted by days until premiere)
    private var premieringSoonEntries: [TimelineEntry] {
        let grouped = timelineService.groupByCategory(allShows)
        return grouped[.premieringSoon] ?? []
    }

    /// Anticipated entries (shows with dates first, then TBD)
    private var anticipatedEntries: [TimelineEntry] {
        let grouped = timelineService.groupByCategory(allShows)
        let entries = grouped[.anticipated] ?? []

        // Sort: shows with expected dates first, then TBD (alphabetical)
        return entries.sorted { entry1, entry2 in
            let hasDate1 = entry1.show.upcomingSeason?.airDate != nil
            let hasDate2 = entry2.show.upcomingSeason?.airDate != nil

            if hasDate1 && !hasDate2 { return true }
            if !hasDate1 && hasDate2 { return false }
            return entry1.show.name < entry2.show.name
        }
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
                        HeroCardStack(
                            shows: airingShowsWithFinale,
                            currentIndex: $heroCardIndex,
                            onShowTap: { show in
                                selectedShow = show
                            }
                        )

                        // Slot machine countdown (syncs with current card)
                        if let hero = currentHeroShow {
                            SlotMachineCountdown(
                                days: hero.daysUntilFinale,
                                targetDate: Date().addingTimeInterval(Double(hero.daysUntilFinale) * 86400)
                            )
                        }

                        // Vertical connector from hero to sections
                        verticalConnector
                            .frame(height: 60)

                        // ENDING SOON Section (5 shows max)
                        endingSoonSection

                        // PREMIERING SOON Section (3 shows max)
                        premieringSoonSection

                        // ANTICIPATED Section (3 shows max)
                        anticipatedSection

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

    // MARK: - Ending Soon Section

    private var endingSoonSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line running through entire section
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 48))
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
                    title: "ENDING SOON",
                    totalCount: endingSoonEntries.count,
                    isExpanded: $isSectionsExpanded,
                    showDisclosure: true,
                    style: .endingSoon
                )

                Group {
                    if isSectionsExpanded {
                        if endingSoonEntries.isEmpty {
                            VStack(spacing: 30) {
                                ForEach(0..<3, id: \.self) { index in
                                    EmptySlotCard(
                                        style: .endingSoon,
                                        isFirst: index == 0,
                                        isLast: index == 2
                                    )
                                    .frame(height: 190)
                                }
                            }
                        } else {
                            VStack(spacing: 30) {
                                let displayEntries = Array(endingSoonEntries.prefix(maxEndingSoonCards))
                                ForEach(Array(displayEntries.enumerated()), id: \.element.show.id) { index, entry in
                                    TimelineShowCard(
                                        show: entry.show,
                                        seasonNumber: entry.show.currentSeason?.seasonNumber ?? 1,
                                        style: .endingSoon,
                                        daysUntil: entry.daysUntilFinale,
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
                        if endingSoonEntries.isEmpty {
                            EmptyPortraitSlots(style: .endingSoon)
                        } else {
                            CompactPosterRow(
                                shows: endingSoonEntries.map { $0.show },
                                style: .endingSoon,
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
