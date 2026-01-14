//
//  FullTimelineView.swift
//  Countdown2Binge
//

import SwiftUI
import SwiftData

/// Full timeline view showing all shows in Premiering Soon and Anticipated sections
struct FullTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FollowedShow.followedAt, order: .reverse)
    private var followedShows: [FollowedShow]
    @State private var selectedShow: Show?
    @State private var isExpanded: Bool = false  // Default to compact view

    private let timelineService = TimelineService()

    // MARK: - Computed Properties

    private var allShows: [Show] {
        followedShows.compactMap { $0.cachedData?.toShow() }
    }

    /// Ending soon entries (currently airing shows sorted by days until finale)
    private var endingSoonEntries: [(show: Show, daysUntilFinale: Int)] {
        allShows
            .filter { $0.lifecycleState == .airing }
            .compactMap { show -> (Show, Int)? in
                guard let days = show.daysUntilFinale else { return nil }
                return (show, days)
            }
            .sorted { $0.1 < $1.1 }
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

        return entries.sorted { entry1, entry2 in
            let hasDate1 = entry1.show.upcomingSeason?.airDate != nil
            let hasDate2 = entry2.show.upcomingSeason?.airDate != nil

            if hasDate1 && !hasDate2 { return true }
            if !hasDate1 && hasDate2 { return false }
            return entry1.show.name < entry2.show.name
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // ENDING SOON Section
                    endingSoonSection

                    // PREMIERING SOON Section
                    premieringSoonSection

                    // ANTICIPATED Section
                    anticipatedSection

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FULL TIMELINE")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "rectangle.ratio.3.to.4" : "rectangle.grid.1x2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(item: $selectedShow) { show in
            ShowDetailView(
                viewModel: ShowDetailViewModel(
                    show: show,
                    repository: ShowRepository(modelContext: modelContext)
                )
            )
        }
    }

    // MARK: - Ending Soon Section

    private var endingSoonSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line
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
                    isExpanded: .constant(true),
                    showDisclosure: false,
                    style: .endingSoon
                )

                Group {
                    if isExpanded {
                        // Expanded: Full cards
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
                                ForEach(Array(endingSoonEntries.enumerated()), id: \.element.show.id) { index, entry in
                                    TimelineShowCard(
                                        show: entry.show,
                                        seasonNumber: entry.show.currentSeason?.seasonNumber ?? 1,
                                        style: .endingSoon,
                                        daysUntil: entry.daysUntilFinale,
                                        expectedYear: nil,
                                        isFirst: index == 0,
                                        isLast: index == endingSoonEntries.count - 1
                                    )
                                    .frame(height: 190)
                                    .onTapGesture {
                                        selectedShow = entry.show
                                    }
                                }
                            }
                        }
                    } else {
                        // Compact: Portrait posters
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
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
    }

    // MARK: - Premiering Soon Section

    private var premieringSoonSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line
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
                    title: "PREMIERING SOON",
                    totalCount: premieringSoonEntries.count,
                    isExpanded: .constant(true),
                    showDisclosure: false,
                    style: .premiering
                )

                Group {
                    if isExpanded {
                        // Expanded: Full cards
                        if premieringSoonEntries.isEmpty {
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
                            VStack(spacing: 30) {
                                ForEach(Array(premieringSoonEntries.enumerated()), id: \.element.id) { index, entry in
                                    TimelineShowCard(
                                        show: entry.show,
                                        seasonNumber: entry.show.upcomingSeason?.seasonNumber ?? entry.show.currentSeason?.seasonNumber ?? 1,
                                        style: .premiering,
                                        daysUntil: entry.countdown?.days,
                                        expectedYear: nil,
                                        isFirst: index == 0,
                                        isLast: index == premieringSoonEntries.count - 1
                                    )
                                    .frame(height: 190)
                                    .onTapGesture {
                                        selectedShow = entry.show
                                    }
                                }
                            }
                        }
                    } else {
                        // Compact: Portrait posters
                        if premieringSoonEntries.isEmpty {
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
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
    }

    // MARK: - Anticipated Section

    private var anticipatedSection: some View {
        ZStack(alignment: .topLeading) {
            // Connector line
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 48))
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
                    isExpanded: .constant(true),
                    showDisclosure: false,
                    style: .anticipated
                )

                Group {
                    if isExpanded {
                        // Expanded: Full cards
                        if anticipatedEntries.isEmpty {
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
                            VStack(spacing: 30) {
                                ForEach(Array(anticipatedEntries.enumerated()), id: \.element.id) { index, entry in
                                    let expectedYear = Calendar.current.component(.year, from: entry.show.upcomingSeason?.airDate ?? Date())
                                    let hasDate = entry.show.upcomingSeason?.airDate != nil

                                    TimelineShowCard(
                                        show: entry.show,
                                        seasonNumber: entry.show.upcomingSeason?.seasonNumber ?? entry.show.currentSeason?.seasonNumber ?? 1,
                                        style: .anticipated,
                                        daysUntil: nil,
                                        expectedYear: hasDate ? expectedYear : nil,
                                        isFirst: index == 0,
                                        isLast: index == anticipatedEntries.count - 1
                                    )
                                    .frame(height: 190)
                                    .onTapGesture {
                                        selectedShow = entry.show
                                    }
                                }
                            }
                        }
                    } else {
                        // Compact: Portrait posters
                        if anticipatedEntries.isEmpty {
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
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FullTimelineView()
    }
    .modelContainer(for: [FollowedShow.self, CachedShowData.self], inMemory: true)
    .preferredColorScheme(.dark)
}
