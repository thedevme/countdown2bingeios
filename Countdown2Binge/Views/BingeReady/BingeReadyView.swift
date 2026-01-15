//
//  BingeReadyView.swift
//  Countdown2Binge
//

import SwiftUI
import SwiftData

/// The Binge Ready screen showing all seasons ready to watch.
struct BingeReadyView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: BingeReadyViewModel
    @State private var selectedItem: BingeReadyItem?
    @State private var selectedIndices: [Int: Int] = [:] // showId -> card index
    @State private var currentShowIndex: Int = 0
    @State private var navigationDirection: NavigationDirection = .right
    @State private var isScrollingToShow: Bool = false
    @State private var hasLoadedOnce: Bool = false
    @State private var animatedWatchedCount: Int = 0
    @State private var markedWatchedSeasonIds: Set<Int> = [] // Track seasons marked watched this session

    private enum NavigationDirection {
        case left, right
    }

    /// Cache groups to avoid repeated computed property access
    /// In UI testing mode, returns mock data for the current scenario
    private var groups: [BingeReadyShowGroup] {
        if UITestDataProvider.isUITesting {
            return UITestDataProvider.bingeReadyGroupsForCurrentScenario()
        }
        return viewModel.groupedByShow
    }

    /// Whether there are binge-ready items (respects UI test mode)
    private var hasItems: Bool {
        if UITestDataProvider.isUITesting {
            return !groups.isEmpty
        }
        return viewModel.hasItems
    }

    private var currentGroup: BingeReadyShowGroup? {
        guard !groups.isEmpty, currentShowIndex < groups.count else { return nil }
        return groups[currentShowIndex]
    }

    private var currentSeason: Season? {
        guard let group = currentGroup else { return nil }
        let seasonIndex = selectedIndices[group.show.id] ?? 0
        guard seasonIndex < group.seasons.count else { return group.seasons.first }
        return group.seasons[seasonIndex]
    }

    private var currentWatchedCount: Int {
        guard let season = currentSeason else { return 0 }
        // If marked watched this session, return aired episode count
        if markedWatchedSeasonIds.contains(season.id) {
            return season.isComplete ? season.episodeCount : season.airedEpisodeCount
        }
        return season.watchedEpisodeCount
    }

    private var currentTotalCount: Int {
        guard let season = currentSeason else { return 0 }
        // Always show total episode count (premiere to finale)
        return season.episodeCount
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let cardSize = calculateCardSize(for: geometry.size)

                ZStack {
                    // Background
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Header row
                        HStack {
                            Text("BINGE READY")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.5))
                                .accessibilityAddTraits(.isHeader)

                            Spacer()

                            Button {
                                // Info action
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .accessibilityLabel("Information")
                            .accessibilityHint("Double tap for more information about Binge Ready")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        if viewModel.isLoading && !hasItems && !hasLoadedOnce {
                            Spacer()
                            loadingView
                            Spacer()
                        } else if !hasItems {
                            emptyStateView
                        } else {
                            // Main content
                            Spacer()
                            cardStackContent(cardSize: cardSize)
                                .id(currentShowIndex)
                                .transition(navigationDirection == .right ? .cardDropFromTop : .cardDropFromBottom)

                            // Progress bar (outside of id'd content so it animates)
                            EpisodeProgressBar(watchedCount: animatedWatchedCount, totalCount: currentTotalCount)
                                .padding(.horizontal, 30)
                                .padding(.top, 24 * (cardSize.width / BingeReadyPosterCard.defaultWidth))

                            Spacer()

                            // Bottom show selector
                            showSelector
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentShowIndex)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.loadSeasons()
                hasLoadedOnce = true
                // Initialize watched count
                animatedWatchedCount = currentWatchedCount
            }
            .onChange(of: viewModel.groupedByShow.count) { _, newCount in
                if currentShowIndex >= newCount && newCount > 0 {
                    currentShowIndex = newCount - 1
                }
            }
            .onChange(of: viewModel.groupedByShow) { _, newGroups in
                // Clamp season indices when seasons are removed
                for group in newGroups {
                    if let currentIndex = selectedIndices[group.show.id],
                       currentIndex >= group.seasons.count {
                        selectedIndices[group.show.id] = max(0, group.seasons.count - 1)
                    }
                }
                // Update watched count immediately when data changes
                animatedWatchedCount = currentWatchedCount
            }
            .onChange(of: currentShowIndex) { _, _ in
                // Reset watched count immediately when changing shows
                animatedWatchedCount = currentWatchedCount
            }
            .onChange(of: selectedIndices) { _, _ in
                // Update watched count when changing seasons within a show
                animatedWatchedCount = currentWatchedCount
            }
            .onChange(of: viewModel.refreshTrigger) { _, _ in
                // Animate to watched count (only aired episodes for airing seasons)
                animatedWatchedCount = currentWatchedCount
            }
            .navigationDestination(item: $selectedItem) { item in
                ShowDetailView(
                    viewModel: ShowDetailViewModel(
                        show: item.show,
                        repository: ShowRepository(modelContext: modelContext)
                    )
                )
            }
            .confirmationDialog(
                "Mark as Watched",
                isPresented: .init(
                    get: { viewModel.itemToMarkWatched != nil },
                    set: { if !$0 { viewModel.cancelMarkWatched() } }
                ),
                titleVisibility: .visible
            ) {
                Button("Mark Watched") {
                    Task {
                        await viewModel.confirmMarkWatched()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelMarkWatched()
                }
            } message: {
                if let item = viewModel.itemToMarkWatched {
                    Text("Mark \(item.show.name) Season \(item.season.seasonNumber) as watched?")
                }
            }
        }
    }

    // MARK: - Card Size Calculation

    /// Calculate card size based on available screen space
    private func calculateCardSize(for screenSize: CGSize) -> CGSize {
        let aspectRatio = BingeReadyPosterCard.defaultHeight / BingeReadyPosterCard.defaultWidth // ~1.5

        // Reserve space for: header (~50), show name (~60), progress bar (~80), bottom selector (~120)
        let reservedHeight: CGFloat = 310
        let availableHeight = screenSize.height - reservedHeight

        // Reserve horizontal padding for fanned cards
        let horizontalPadding: CGFloat = 80
        let availableWidth = screenSize.width - horizontalPadding

        // Calculate max card dimensions that fit
        let maxHeightBasedOnWidth = availableWidth * aspectRatio
        let maxWidthBasedOnHeight = availableHeight / aspectRatio

        // Use the smaller dimension to ensure it fits
        let cardWidth: CGFloat
        let cardHeight: CGFloat

        if maxHeightBasedOnWidth <= availableHeight {
            // Width is the constraint
            cardWidth = min(availableWidth, BingeReadyPosterCard.defaultWidth)
            cardHeight = cardWidth * aspectRatio
        } else {
            // Height is the constraint
            cardHeight = min(availableHeight, BingeReadyPosterCard.defaultHeight)
            cardWidth = cardHeight / aspectRatio
        }

        // Ensure minimum size for usability
        let minWidth: CGFloat = 200
        let finalWidth = max(minWidth, cardWidth)
        let finalHeight = finalWidth * aspectRatio

        return CGSize(width: finalWidth, height: finalHeight)
    }

    // MARK: - Card Stack Content

    @ViewBuilder
    private func cardStackContent(cardSize: CGSize) -> some View {
        if let group = currentGroup {
            let scaleFactor = cardSize.width / BingeReadyPosterCard.defaultWidth

            VStack(spacing: 24 * scaleFactor) {
                // Large show name
                Text(group.show.name.uppercased())
                    .font(.system(size: 32 * scaleFactor, weight: .heavy, design: .default).width(.condensed))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 20)

                // Card stack
                BingeReadyCardStack(
                    seasons: group.seasons,
                    show: group.show,
                    currentIndex: selectedIndexBinding(for: group),
                    cardSize: cardSize,
                    onMarkWatched: { season in
                        // Track this season as marked watched for this session
                        markedWatchedSeasonIds.insert(season.id)
                        Task {
                            await viewModel.markSeasonWatched(
                                showId: group.show.id,
                                seasonNumber: season.seasonNumber
                            )
                        }
                    },
                    onDeleteShow: {
                        Task {
                            await viewModel.deleteShow(group.show)
                        }
                    },
                    onTapCard: {
                        let seasonIndex = selectedIndices[group.show.id] ?? 0
                        let season = seasonIndex < group.seasons.count ? group.seasons[seasonIndex] : group.seasons.first!
                        selectedItem = BingeReadyItem(show: group.show, season: season)
                    }
                )
            }
        }
    }

    private func selectedIndexBinding(for group: BingeReadyShowGroup) -> Binding<Int> {
        Binding(
            get: {
                selectedIndices[group.show.id] ?? 0
            },
            set: { newValue in
                selectedIndices[group.show.id] = newValue
            }
        )
    }

    /// Scrolls through intermediate shows to reach the target index
    private func scrollToShow(index targetIndex: Int) {
        // Don't scroll if already at target or currently scrolling
        guard targetIndex != currentShowIndex, !isScrollingToShow else { return }

        isScrollingToShow = true
        let direction: NavigationDirection = targetIndex > currentShowIndex ? .right : .left
        let step = direction == .right ? 1 : -1

        // Calculate indices to scroll through
        var indicesToVisit: [Int] = []
        var current = currentShowIndex
        while current != targetIndex {
            current += step
            indicesToVisit.append(current)
        }

        // Animate through each show with decreasing delays
        // Fast scroll through middle ones, slower on the last one
        let totalSteps = indicesToVisit.count
        var accumulatedDelay: Double = 0

        for (i, nextIndex) in indicesToVisit.enumerated() {
            let isLastStep = i == totalSteps - 1
            // Faster for intermediate steps, slower for final landing
            let stepDuration: Double = isLastStep ? 0.35 : 0.12

            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay) {
                navigationDirection = direction
                withAnimation(.spring(response: isLastStep ? 0.5 : 0.25, dampingFraction: 0.8)) {
                    currentShowIndex = nextIndex
                }

                if isLastStep {
                    isScrollingToShow = false
                }
            }

            accumulatedDelay += stepDuration
        }
    }

    // MARK: - Show Selector

    private var showSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        showSelectorItem(group: group, index: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onChange(of: currentShowIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func showSelectorItem(group: BingeReadyShowGroup, index: Int) -> some View {
        let isSelected = index == currentShowIndex
        let posterURL = TMDBConfiguration.imageURL(path: group.show.posterPath, size: .posterSmall)

        return Button {
            scrollToShow(index: index)
        } label: {
            CachedAsyncImage(url: posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            }
            .frame(width: 56, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .drawingGroup() // Rasterizes for smooth scrolling
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? .white : Color.clear, lineWidth: 2)
            )
            .opacity(isSelected ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.show.name), \(group.seasons.count) season\(group.seasons.count == 1 ? "" : "s") ready")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white.opacity(0.6))
                .scaleEffect(1.2)

            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading binge ready shows")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.4))
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Nothing to Binge Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("When seasons finish airing, they'll\nappear here ready to watch")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .accessibilityElement(children: .combine)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview("With Items") {
    BingeReadyView(
        viewModel: BingeReadyViewModel(
            repository: MockBingeRepository()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    BingeReadyView(
        viewModel: BingeReadyViewModel(
            repository: MockEmptyBingeRepository()
        )
    )
    .preferredColorScheme(.dark)
}

// MARK: - Mock Repositories for Preview

private class MockBingeRepository: ShowRepositoryProtocol {
    func save(_ show: Show) async throws {}
    func fetchAllShows() -> [Show] { [] }
    func fetchShow(byTmdbId id: Int) -> Show? { nil }
    func fetchTimelineShows() -> [Show] { [] }
    func fetchBingeReadySeasons() -> [Season] { [] }
    func delete(_ show: Show) async throws {}
    func isShowFollowed(tmdbId: Int) -> Bool { false }
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {}
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {}
}

private class MockEmptyBingeRepository: ShowRepositoryProtocol {
    func save(_ show: Show) async throws {}
    func fetchAllShows() -> [Show] { [] }
    func fetchShow(byTmdbId id: Int) -> Show? { nil }
    func fetchTimelineShows() -> [Show] { [] }
    func fetchBingeReadySeasons() -> [Season] { [] }
    func delete(_ show: Show) async throws {}
    func isShowFollowed(tmdbId: Int) -> Bool { false }
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {}
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {}
}

// MARK: - Card Drop Transitions

extension AnyTransition {
    /// Cards drop from top (navigating right/forward)
    static var cardDropFromTop: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: CardDropModifier(offset: -250, opacity: 0, scale: 0.8),
                identity: CardDropModifier(offset: 0, opacity: 1, scale: 1)
            ),
            removal: .modifier(
                active: CardDropModifier(offset: 350, opacity: 0, scale: 0.8),
                identity: CardDropModifier(offset: 0, opacity: 1, scale: 1)
            )
        )
    }

    /// Cards rise from bottom (navigating left/backward)
    static var cardDropFromBottom: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: CardDropModifier(offset: 250, opacity: 0, scale: 0.8),
                identity: CardDropModifier(offset: 0, opacity: 1, scale: 1)
            ),
            removal: .modifier(
                active: CardDropModifier(offset: -350, opacity: 0, scale: 0.8),
                identity: CardDropModifier(offset: 0, opacity: 1, scale: 1)
            )
        )
    }
}

private struct CardDropModifier: ViewModifier {
    let offset: CGFloat
    let opacity: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
    }
}
