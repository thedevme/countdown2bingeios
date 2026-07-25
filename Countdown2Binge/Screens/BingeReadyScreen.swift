//
//  BingeReadyScreen.swift
//  Countdown2Binge
//
//  Binge view - Spotlight design with hero card, episode strip, and library rail.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Binge Ready Screen
struct BingeReadyScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BingeReadyViewModel()
    @StateObject private var watchProgress = WatchProgressManager.shared

    @State private var heroShowId: Int?
    @State private var selectedSeasonNumber: [Int: Int] = [:]
    @State private var showSeasonModal = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedSegment: BingeSegment = .active

    enum BingeSegment: String, CaseIterable {
        case active = "segment_active"
        case ended = "segment_ended"
        case archived = "segment_archived"
    }

    private var shows: [ShowData] {
        let allShows = viewModel.bingeReadyShows
        switch selectedSegment {
        case .active:
            // Shows still in production, not archived
            return allShows.filter { show in
                show.lifecycleState != .ended && !viewModel.isArchived(show.id)
            }
        case .ended:
            // Shows that have ended (not in production) and not archived
            return allShows.filter { show in
                show.lifecycleState == .ended && !viewModel.isArchived(show.id)
            }
        case .archived:
            // User-archived shows
            return allShows.filter { show in
                viewModel.isArchived(show.id)
            }
        }
    }

    private var activeCount: Int {
        viewModel.bingeReadyShows.filter { show in
            show.lifecycleState != .ended && !viewModel.isArchived(show.id)
        }.count
    }

    private var endedCount: Int {
        viewModel.bingeReadyShows.filter { show in
            show.lifecycleState == .ended && !viewModel.isArchived(show.id)
        }.count
    }

    private var archivedCount: Int {
        viewModel.bingeReadyShows.filter { show in
            viewModel.isArchived(show.id)
        }.count
    }

    private var heroShow: ShowData? {
        if let id = heroShowId {
            return shows.first { $0.id == id }
        }
        return shows.first
    }

    private var currentSeason: SeasonData? {
        guard let show = heroShow else { return nil }
        if let selected = selectedSeasonNumber[show.id] {
            return show.seasons.first { $0.seasonNumber == selected }
        }
        return watchProgress.currentSeason(for: show)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 7) {
                    Text("header_binge")
                        .font(.custom(.oswald.bold, size: 27))
                        .tracking(0.54)
                        .foregroundColor(.white)

                    Text("header_seasons_progress")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.14)
                        .foregroundColor(.c2bMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 52)
                .padding(.horizontal, 20)

                // Segment Bar
                BingeSegmentBar(
                    selectedSegment: $selectedSegment,
                    activeCount: activeCount,
                    endedCount: endedCount,
                    archivedCount: archivedCount
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if shows.isEmpty {
                    BingeEmptyState(segment: selectedSegment)
                        .padding(.top, 40)
                } else if let show = heroShow {
                    // Hero Card - tap to navigate
                    BingeHeroCard(
                        show: show,
                        watchProgress: watchProgress,
                        isLatest: shows.first?.id == show.id
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .onTapGesture {
                        navigationPath.append(show)
                    }

                    // Streaming app deep link
                    StreamingLinkButton(
                        network: show.primaryNetwork,
                        showName: show.name
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Action Buttons
                    BingeActionButtons(
                        onRemove: {
                            Task {
                                await viewModel.unfollowShow(show)
                            }
                            if heroShowId == show.id {
                                heroShowId = nil
                            }
                        },
                        onComplete: {
                            // Mark all episodes as watched
                            for season in show.seasons {
                                watchProgress.setSeasonWatched(
                                    showId: show.id,
                                    season: season.seasonNumber,
                                    episodeCount: season.episodeCount,
                                    watched: true
                                )
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Season Selector
                    if let season = currentSeason {
                        BingeSeasonSelector(
                            show: show,
                            season: season,
                            watchProgress: watchProgress,
                            onOpenModal: { showSeasonModal = true }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Episode Strip
                        BingeEpisodeStrip(
                            show: show,
                            season: season,
                            watchProgress: watchProgress
                        )
                        .padding(.top, 22)
                    }

                    // Archive Button
                    BingeArchiveButton(
                        isArchived: viewModel.isArchived(show.id),
                        onArchive: {
                            viewModel.archiveShow(show.id)
                            // Move to next show if this was the hero
                            if heroShowId == show.id {
                                heroShowId = nil
                            }
                        },
                        onUnarchive: {
                            viewModel.unarchiveShow(show.id)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Library Rail - tap to switch hero content
                    BingeLibraryRail(
                        shows: shows,
                        selectedId: heroShowId ?? shows.first?.id,
                        watchProgress: watchProgress,
                        onSelect: { heroShowId = $0 },
                        onUnfollow: { show in
                            Task {
                                await viewModel.unfollowShow(show)
                            }
                            // Reset hero if unfollowed show was selected
                            if heroShowId == show.id {
                                heroShowId = nil
                            }
                        }
                    )
                    .padding(.top, 26)
                }

                Spacer()
                    .frame(height: 150)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(Color.c2bBackground)
        .refreshable {
            await viewModel.refreshShows()
        }
        .onAppear {
            viewModel.configure(with: modelContext, container: modelContext.container)
            Task { await viewModel.loadShows() }
        }
        .sheet(isPresented: $showSeasonModal) {
            if let show = heroShow {
                BingeSeasonPickerModal(
                    show: show,
                    watchProgress: watchProgress,
                    selectedSeason: currentSeason?.seasonNumber ?? 1,
                    onSelect: { selectedSeasonNumber[show.id] = $0 }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .navigationDestination(for: ShowData.self) { show in
            FollowedShowDetail(
                show: show,
                onDismiss: { navigationPath.removeLast() },
                onUnfollow: {
                    Task { await viewModel.unfollowShow(show) }
                }
            )
                .navigationBarHidden(true)
        }
        }
    }
}

// MARK: - Binge Ready ViewModel
@MainActor
@Observable
final class BingeReadyViewModel {
    private(set) var followedShows: [ShowData] = []
    private(set) var isLoading = false
    private(set) var isRefreshing = false

    /// User-archived show IDs (persisted via UserDefaults)
    private(set) var archivedShowIds: Set<Int> = []

    var bingeReadyShows: [ShowData] {
        // Show all followed shows (for testing - normally filter for .bingeReady only)
        followedShows
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var modelContext: ModelContext?
    private var modelContainer: ModelContainer?
    private var store: FollowedShowsStore?

    private let archivedShowsKey = "archivedShowIds"

    init() {
        loadArchivedShowIds()
    }

    // MARK: - Archive Management

    func isArchived(_ showId: Int) -> Bool {
        archivedShowIds.contains(showId)
    }

    func archiveShow(_ showId: Int) {
        archivedShowIds.insert(showId)
        saveArchivedShowIds()
    }

    func unarchiveShow(_ showId: Int) {
        archivedShowIds.remove(showId)
        saveArchivedShowIds()
    }

    private func loadArchivedShowIds() {
        if let ids = UserDefaults.standard.array(forKey: archivedShowsKey) as? [Int] {
            archivedShowIds = Set(ids)
        }
    }

    private func saveArchivedShowIds() {
        UserDefaults.standard.set(Array(archivedShowIds), forKey: archivedShowsKey)
    }

    func configure(with modelContext: ModelContext, container: ModelContainer? = nil) {
        self.modelContext = modelContext
        self.modelContainer = container
        self.store = FollowedShowsStore(modelContext: modelContext)
    }

    func loadShows() async {
        guard let store else { return }
        isLoading = true
        do {
            followedShows = try await store.getAllFollowedAsShowData()
        } catch {
            print("Error loading followed shows: \(error)")
            followedShows = []
        }
        isLoading = false
    }

    /// Refresh all followed shows from TMDB API
    func refreshShows() async {
        guard let modelContainer, let store else { return }
        isRefreshing = true

        let refreshService = StateRefreshService(modelContainer: modelContainer)
        await refreshService.forceRefreshAllShows()

        // Reload from updated cache
        do {
            followedShows = try await store.getAllFollowedAsShowData()
        } catch {
            print("Error reloading shows after refresh: \(error)")
        }

        isRefreshing = false
    }

    /// Unfollow a show
    func unfollowShow(_ show: ShowData) async {
        guard let store else { return }
        do {
            try store.unfollow(tmdbId: show.id)
            // Force reload from database to ensure consistency
            followedShows = try await store.getAllFollowedAsShowData()
        } catch {
            print("Error unfollowing show: \(error)")
            // Fallback to local removal
            followedShows.removeAll { $0.id == show.id }
        }
    }
}

// MARK: - Empty State
private struct BingeEmptyState: View {
    let segment: BingeReadyScreen.BingeSegment

    private var icon: String {
        switch segment {
        case .active: return "play.rectangle.on.rectangle"
        case .ended: return "tv"
        case .archived: return "archivebox"
        }
    }

    private var title: LocalizedStringKey {
        switch segment {
        case .active: return "empty_no_active_shows"
        case .ended: return "empty_no_ended_shows"
        case .archived: return "empty_no_archived_shows"
        }
    }

    private var subtitle: LocalizedStringKey {
        switch segment {
        case .active: return "empty_active_subtitle"
        case .ended: return "empty_ended_subtitle"
        case .archived: return "empty_archived_subtitle"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.c2bMuted)

            Text(title)
                .font(.custom(.oswald.regular, size: 18))
                .foregroundColor(.c2bDim)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Progress Ring
struct BingeProgressRing: View {
    let progress: CGFloat
    let size: CGFloat
    let strokeWidth: CGFloat
    var label: String? = nil
    var color: Color = .c2bTealBright

    private var isDone: Bool { progress >= 1.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)

            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(color)
            } else if let label = label {
                Text(label)
                    .font(.custom(.oswald.bold, size: size * 0.3))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Watch Progress Manager
final class WatchProgressManager: ObservableObject {
    static let shared = WatchProgressManager()

    private let storageKey = "c2b_watched_v1"
    @Published var watchedEpisodes: Set<String> = []

    init() {
        loadWatched()
    }

    private func loadWatched() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            watchedEpisodes = decoded
        }
    }

    private func saveWatched() {
        if let data = try? JSONEncoder().encode(watchedEpisodes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func episodeKey(showId: Int, season: Int, episode: Int) -> String {
        "\(showId)-\(season)-\(episode)"
    }

    func isWatched(showId: Int, season: Int, episode: Int) -> Bool {
        watchedEpisodes.contains(episodeKey(showId: showId, season: season, episode: episode))
    }

    func toggleWatched(showId: Int, season: Int, episode: Int) {
        let key = episodeKey(showId: showId, season: season, episode: episode)
        if watchedEpisodes.contains(key) {
            watchedEpisodes.remove(key)
        } else {
            watchedEpisodes.insert(key)
        }
        saveWatched()
    }

    func setSeasonWatched(showId: Int, season: Int, episodeCount: Int, watched: Bool) {
        for ep in 1...episodeCount {
            let key = episodeKey(showId: showId, season: season, episode: ep)
            if watched {
                watchedEpisodes.insert(key)
            } else {
                watchedEpisodes.remove(key)
            }
        }
        saveWatched()
    }

    func seasonWatchedCount(showId: Int, season: Int, episodeCount: Int) -> Int {
        guard episodeCount > 0 else { return 0 }
        return (1...episodeCount).filter { isWatched(showId: showId, season: season, episode: $0) }.count
    }

    func showWatchedCount(show: ShowData) -> Int {
        show.seasons.reduce(0) { total, season in
            total + seasonWatchedCount(showId: show.id, season: season.seasonNumber, episodeCount: season.episodeCount)
        }
    }

    func showTotalEpisodes(show: ShowData) -> Int {
        show.seasons.reduce(0) { $0 + $1.episodeCount }
    }

    func currentSeason(for show: ShowData) -> SeasonData? {
        show.seasons.first { season in
            seasonWatchedCount(showId: show.id, season: season.seasonNumber, episodeCount: season.episodeCount) < season.episodeCount
        } ?? show.seasons.last
    }

    /// Get set of watched episode numbers for a season
    func watchedEpisodeNumbers(showId: Int, season: Int, episodeCount: Int) -> Set<Int> {
        guard episodeCount > 0 else { return [] }
        return Set((1...episodeCount).filter { isWatched(showId: showId, season: season, episode: $0) })
    }

    /// Mark all aired episodes as watched
    func markAiredWatched(showId: Int, season: Int, airedEpisodes: [Int]) {
        for ep in airedEpisodes {
            let key = episodeKey(showId: showId, season: season, episode: ep)
            watchedEpisodes.insert(key)
        }
        saveWatched()
    }
}

// MARK: - Hero Card
private struct BingeHeroCard: View {
    let show: ShowData
    @ObservedObject var watchProgress: WatchProgressManager
    let isLatest: Bool

    private var progress: CGFloat {
        let total = watchProgress.showTotalEpisodes(show: show)
        guard total > 0 else { return 0 }
        return CGFloat(watchProgress.showWatchedCount(show: show)) / CGFloat(total)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image - flexible, fills available space
            CachedAsyncImage(url: show.backdropURL ?? show.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.c2bSurface)
            }

            // Gradient overlay
            LinearGradient(
                colors: [Color(hex: "#0b0b0c"), Color(hex: "#0b0b0c").opacity(0.2), Color(hex: "#0b0b0c").opacity(0.55)],
                startPoint: .bottom,
                endPoint: .top
            )

            // Top bar with badge and progress ring
            VStack {
                HStack {
                    if isLatest {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "#04201c"))
                            Text("badge_latest_added")
                                .font(.custom(.jetbrains.bold, size: 8.5))
                                .tracking(1.19)
                                .foregroundColor(Color(hex: "#04201c"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.c2bTealBright)
                        .cornerRadius(999)
                    }
                    Spacer()

                    BingeProgressRing(
                        progress: progress,
                        size: 46,
                        strokeWidth: 4,
                        label: "\(Int(progress * 100))"
                    )
                }
                .padding(14)
                Spacer()
            }

            // Title area at bottom
            VStack(alignment: .leading, spacing: 7) {
                Text("\(show.primaryNetwork?.name ?? "TV") · \(show.numberOfSeasons) \(show.numberOfSeasons == 1 ? "season" : "seasons")")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(1.26)
                    .foregroundColor(.c2bDim)
                    .textCase(.uppercase)

                Text(show.name)
                    .font(.custom(.oswald.bold, size: 34))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Season Selector
private struct BingeSeasonSelector: View {
    let show: ShowData
    let season: SeasonData
    @ObservedObject var watchProgress: WatchProgressManager
    let onOpenModal: () -> Void

    private var watchedCount: Int {
        watchProgress.seasonWatchedCount(showId: show.id, season: season.seasonNumber, episodeCount: season.episodeCount)
    }

    private var progress: CGFloat {
        guard season.episodeCount > 0 else { return 0 }
        return CGFloat(watchedCount) / CGFloat(season.episodeCount)
    }

    private var isComplete: Bool { progress >= 1.0 }
    private var isCurrent: Bool {
        watchProgress.currentSeason(for: show)?.seasonNumber == season.seasonNumber
    }

    var body: some View {
        Button(action: {
            if show.numberOfSeasons > 1 {
                onOpenModal()
            }
        }) {
            HStack(spacing: 14) {
                BingeProgressRing(
                    progress: progress,
                    size: 40,
                    strokeWidth: 4,
                    label: "\(watchedCount)",
                    color: isComplete ? .c2bTealBright : .c2bTeal
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(String(localized: "season_number \(season.seasonNumber)"))
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)

                    Text(String(localized: "binge_watched_count \(watchedCount) \(season.episodeCount)") + (isComplete ? String(localized: "binge_complete_suffix") : (isCurrent ? String(localized: "binge_current_suffix") : "")))
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .tracking(0.85)
                        .foregroundColor(isComplete ? .c2bTealBright : .c2bMuted)
                        .textCase(.uppercase)
                }

                Spacer()

                if show.numberOfSeasons > 1 {
                    HStack(spacing: 6) {
                        Text(String(localized: "binge_seasons_count \(show.numberOfSeasons)"))
                            .font(.custom(.jetbrains.bold, size: 8.5))
                            .tracking(0.85)
                            .foregroundColor(.c2bMuted)
                            .textCase(.uppercase)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.c2bMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.04))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(show.numberOfSeasons <= 1)
        .background(Color(hex: "#0b0b0c"))
    }
}

// MARK: - Episode Strip
private struct BingeEpisodeStrip: View {
    let show: ShowData
    let season: SeasonData
    @ObservedObject var watchProgress: WatchProgressManager

    private var watchedCount: Int {
        watchProgress.seasonWatchedCount(showId: show.id, season: season.seasonNumber, episodeCount: season.episodeCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "season_episode_info \(season.seasonNumber) \(season.episodeCount)"))
                    .font(.custom(.jetbrains.bold, size: 9.5))
                    .tracking(1.52)
                    .foregroundColor(.c2bMuted)
                    .textCase(.uppercase)

                Spacer()

                Text("\(watchedCount)/\(season.episodeCount)")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(1.08)
                    .foregroundColor(watchedCount == season.episodeCount ? .c2bTealBright : .c2bMuted)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...max(1, season.episodeCount), id: \.self) { episodeNum in
                        BingeEpisodeCard(
                            show: show,
                            seasonNumber: season.seasonNumber,
                            episodeNumber: episodeNum,
                            isWatched: watchProgress.isWatched(showId: show.id, season: season.seasonNumber, episode: episodeNum),
                            onToggle: {
                                watchProgress.toggleWatched(showId: show.id, season: season.seasonNumber, episode: episodeNum)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Episode Card
private struct BingeEpisodeCard: View {
    let show: ShowData
    let seasonNumber: Int
    let episodeNumber: Int
    let isWatched: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    CachedAsyncImage(url: show.backdropURL ?? show.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 88)
                            .clipped()
                            .brightness(isWatched ? -0.3 : -0.08)
                            .saturation(isWatched ? 0.75 : 1.0)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(width: 150, height: 88)
                    }

                    Text("\(episodeNumber)")
                        .font(.custom(.oswald.bold, size: 26))
                        .foregroundColor(isWatched ? Color.white.opacity(0.55) : .white)
                        .shadow(color: .black.opacity(0.7), radius: 8, y: 2)
                        .padding(.leading, 9)
                        .padding(.bottom, 5)

                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(isWatched ? Color.c2bTeal : Color(hex: "#080808").opacity(0.55))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(isWatched ? Color.c2bTeal : Color.white.opacity(0.5), lineWidth: 1.5)
                                    )

                                if isWatched {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "#04201c"))
                                }
                            }
                            .padding(7)
                        }
                        Spacer()
                    }
                }
                .frame(width: 150, height: 88)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWatched ? Color.c2bTealLine : Color.white.opacity(0.1), lineWidth: 1)
                )

                Text(String(localized: "episode_number \(episodeNumber)"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isWatched ? .c2bDim : .white)
                    .padding(.top, 8)

                Text(String(localized: "episode_short \(episodeNumber)"))
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(0.51)
                    .foregroundColor(.c2bMuted)
                    .padding(.top, 3)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Rail
private struct BingeLibraryRail: View {
    let shows: [ShowData]
    let selectedId: Int?
    @ObservedObject var watchProgress: WatchProgressManager
    let onSelect: (Int) -> Void
    let onUnfollow: (ShowData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("header_your_library")
                .font(.custom(.jetbrains.bold, size: 9.5))
                .tracking(1.52)
                .foregroundColor(.c2bMuted)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shows, id: \.id) { show in
                        BingeLibraryCard(
                            show: show,
                            isSelected: selectedId == show.id,
                            isLatest: shows.first?.id == show.id,
                            watchProgress: watchProgress,
                            onTap: { onSelect(show.id) },
                            onUnfollow: { onUnfollow(show) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Library Card
private struct BingeLibraryCard: View {
    let show: ShowData
    let isSelected: Bool
    let isLatest: Bool
    @ObservedObject var watchProgress: WatchProgressManager
    let onTap: () -> Void
    let onUnfollow: () -> Void

    private var progress: CGFloat {
        let total = watchProgress.showTotalEpisodes(show: show)
        guard total > 0 else { return 0 }
        return CGFloat(watchProgress.showWatchedCount(show: show)) / CGFloat(total)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    CachedAsyncImage(url: show.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 144)
                            .clipped()
                            .brightness(isSelected ? 0 : -0.25)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(width: 96, height: 144)
                    }

                    if isLatest {
                        Circle()
                            .fill(Color.c2bTealBright)
                            .frame(width: 8, height: 8)
                            .shadow(color: .c2bTealBright, radius: 8)
                            .padding(6)
                    }
                }
                .frame(width: 96, height: 144)
                .cornerRadius(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? Color.c2bTealBright : Color.clear, lineWidth: 2)
                        .padding(-2)
                )

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.12))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(colors: [.c2bTeal, .c2bTealBright], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
                .padding(.top, 8)

                Text(show.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.c2bDim)
                    .lineLimit(1)
                    .padding(.top, 7)
            }
            .frame(width: 96)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onUnfollow) {
                Label("button_unfollow", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Season Picker Modal
private struct BingeSeasonPickerModal: View {
    let show: ShowData
    @ObservedObject var watchProgress: WatchProgressManager
    let selectedSeason: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(show.name)
                    .font(.custom(.oswald.bold, size: 24))
                    .foregroundColor(.white)

                Spacer()

                Text(String(localized: "binge_seasons_count \(show.numberOfSeasons)"))
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(1.08)
                    .foregroundColor(.c2bMuted)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(show.seasons, id: \.seasonNumber) { season in
                        BingeSeasonRow(
                            show: show,
                            season: season,
                            isSelected: season.seasonNumber == selectedSeason,
                            watchProgress: watchProgress,
                            onTap: {
                                onSelect(season.seasonNumber)
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 26)
            }
        }
        .background(Color(hex: "#0e0e0f"))
    }
}

// MARK: - Season Row
private struct BingeSeasonRow: View {
    let show: ShowData
    let season: SeasonData
    let isSelected: Bool
    @ObservedObject var watchProgress: WatchProgressManager
    let onTap: () -> Void

    private var watchedCount: Int {
        watchProgress.seasonWatchedCount(showId: show.id, season: season.seasonNumber, episodeCount: season.episodeCount)
    }

    private var progress: CGFloat {
        guard season.episodeCount > 0 else { return 0 }
        return CGFloat(watchedCount) / CGFloat(season.episodeCount)
    }

    private var isComplete: Bool { progress >= 1.0 }
    private var isCurrent: Bool {
        watchProgress.currentSeason(for: show)?.seasonNumber == season.seasonNumber
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                BingeProgressRing(
                    progress: progress,
                    size: 40,
                    strokeWidth: 4,
                    label: "\(watchedCount)",
                    color: isComplete ? .c2bTealBright : (isSelected ? .c2bTeal : .c2bMuted)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(String(localized: "season_number \(season.seasonNumber)"))
                        .font(.custom(.oswald.bold, size: 19))
                        .foregroundColor(isSelected ? .white : .c2bDim)

                    Text(isComplete ? String(localized: "binge_status_complete") : (isCurrent ? String(localized: "binge_status_current \(watchedCount) \(season.episodeCount)") : String(localized: "binge_watched_count \(watchedCount) \(season.episodeCount)")))
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .tracking(0.85)
                        .foregroundColor(isComplete ? .c2bTealBright : .c2bMuted)
                        .textCase(.uppercase)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.c2bTealBright)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(isSelected ? Color.c2bTeal.opacity(0.1) : Color.white.opacity(0.04))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.c2bTeal : Color.white.opacity(0.09), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segment Bar
private struct BingeSegmentBar: View {
    @Binding var selectedSegment: BingeReadyScreen.BingeSegment
    let activeCount: Int
    let endedCount: Int
    let archivedCount: Int

    private func count(for segment: BingeReadyScreen.BingeSegment) -> Int {
        switch segment {
        case .active: return activeCount
        case .ended: return endedCount
        case .archived: return archivedCount
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BingeReadyScreen.BingeSegment.allCases, id: \.self) { segment in
                let isSelected = selectedSegment == segment

                Button(action: { selectedSegment = segment }) {
                    HStack(spacing: 6) {
                        Text(segment.rawValue)
                            .font(.custom(.jetbrains.bold, size: 10))
                            .tracking(1.2)
                            .textCase(.uppercase)

                        Text("\(count(for: segment))")
                            .font(.custom(.jetbrains.bold, size: 9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                isSelected ? Color.c2bTeal.opacity(0.2) : Color.white.opacity(0.08)
                            )
                            .cornerRadius(6)
                    }
                    .foregroundColor(isSelected ? .c2bTealBright : .c2bMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color.c2bTeal.opacity(0.08) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Action Buttons
private struct BingeActionButtons: View {
    let onRemove: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Unfollow Show Button
            Button(action: onRemove) {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 12, weight: .semibold))
                    Text("button_unfollow_show")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.14)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundColor(.c2bMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Complete Show Button
            Button(action: onComplete) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("button_completed_show")
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(1.14)
                }
                .foregroundColor(Color(hex: "#04201c"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.c2bTeal)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Archive Button
private struct BingeArchiveButton: View {
    let isArchived: Bool
    let onArchive: () -> Void
    let onUnarchive: () -> Void

    var body: some View {
        Button(action: { isArchived ? onUnarchive() : onArchive() }) {
            HStack(spacing: 8) {
                Image(systemName: isArchived ? "arrow.uturn.backward" : "archivebox")
                    .font(.system(size: 12, weight: .semibold))
                Text(isArchived ? "button_unarchive" : "button_archive_show")
                    .font(.custom(.jetbrains.bold, size: 9.5))
                    .tracking(1.14)
            }
            .foregroundColor(isArchived ? .c2bTealBright : .c2bMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isArchived ? Color.c2bTeal.opacity(0.1) : Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isArchived ? Color.c2bTeal.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
