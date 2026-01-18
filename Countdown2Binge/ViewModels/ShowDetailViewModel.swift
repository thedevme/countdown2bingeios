//
//  ShowDetailViewModel.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

/// ViewModel for the Show Detail screen.
/// Manages show data, season selection, and unfollow actions.
@MainActor
@Observable
final class ShowDetailViewModel {
    // MARK: - Properties

    /// The show being displayed
    var show: Show

    /// Currently selected season number
    var selectedSeasonNumber: Int

    /// Whether this show is followed by the user
    var isFollowed: Bool

    /// Loading state for remove action
    var isRemoving: Bool = false

    /// Loading state for add action
    var isAdding: Bool = false

    /// Loading state for mark watched action
    var isMarkingWatched: Bool = false

    /// Show confirmation for mark watched
    var showMarkWatchedConfirmation: Bool = false

    /// Result of mark watched action (for feedback)
    var markWatchedResult: MarkWatchedResult?

    /// Whether the episode list is expanded
    var isEpisodeListExpanded: Bool = false

    /// Error state
    var error: Error?

    /// Whether the show was successfully removed (for dismissal)
    var didRemoveShow: Bool = false

    // MARK: - Additional Content Properties

    /// Videos (trailers, clips) for the show
    var videos: [TMDBVideo] = []

    /// Cast members
    var cast: [TMDBCastMember] = []

    /// Crew members (directors, creators)
    var crew: [TMDBCrewMember] = []

    /// Recommended similar shows
    var recommendations: [TMDBShowSummary] = []

    /// Loading state for additional content
    var isLoadingAdditionalContent: Bool = false

    /// IDs of recommendations currently being added/followed
    private var addingRecommendationIds: Set<Int> = []

    /// Selected recommendation show for navigation
    var selectedRecommendation: Show?

    /// Whether to show notification settings modal after adding
    var showNotificationSettings: Bool = false

    /// Notification settings being configured
    var pendingNotificationSettings: NotificationSettings = .default

    // MARK: - Dependencies

    private let repository: ShowRepositoryProtocol
    private let markWatchedUseCase: MarkWatchedUseCaseProtocol
    private let markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCaseProtocol
    private let tmdbService: TMDBServiceProtocol

    // MARK: - Initialization

    init(
        show: Show,
        repository: ShowRepositoryProtocol,
        tmdbService: TMDBServiceProtocol? = nil,
        markWatchedUseCase: MarkWatchedUseCaseProtocol? = nil,
        markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCaseProtocol? = nil
    ) {
        self.show = show
        self.repository = repository
        self.tmdbService = tmdbService ?? TMDBService()
        self.markWatchedUseCase = markWatchedUseCase ?? MarkWatchedUseCase(repository: repository)
        self.markEpisodeWatchedUseCase = markEpisodeWatchedUseCase ?? MarkEpisodeWatchedUseCase(repository: repository)
        self.isFollowed = repository.isShowFollowed(tmdbId: show.id)

        // Default to current/latest season
        self.selectedSeasonNumber = show.currentSeason?.seasonNumber ?? 1
    }

    // MARK: - Computed Properties

    /// The currently selected season
    var selectedSeason: Season? {
        show.seasons.first { $0.seasonNumber == selectedSeasonNumber }
    }

    /// All regular seasons (excluding specials/season 0)
    var regularSeasons: [Season] {
        show.seasons
            .filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
    }

    /// Whether the show has multiple seasons to pick from
    var hasMultipleSeasons: Bool {
        regularSeasons.count > 1
    }

    /// Countdown info for the selected season
    var countdownInfo: (type: String, days: Int, label: String)? {
        guard let season = selectedSeason else { return nil }

        if let days = season.daysUntilPremiere, days >= 0 {
            return (
                type: "premiere",
                days: days,
                label: days == 1 ? "day until premiere" : "days until premiere"
            )
        }

        if let days = season.daysUntilFinale, days >= 0 {
            return (
                type: "finale",
                days: days,
                label: days == 1 ? "day until finale" : "days until finale"
            )
        }

        return nil
    }

    /// Status text for display
    var statusText: String {
        switch show.status {
        case .returning:
            return "Returning Series"
        case .ended:
            return "Ended"
        case .cancelled:
            return "Cancelled"
        case .inProduction:
            return "In Production"
        case .planned:
            return "Planned"
        case .pilot:
            return "Pilot"
        }
    }

    /// Lifecycle state badge style
    var lifecycleBadgeStyle: StateBadgeStyle {
        switch show.lifecycleState {
        case .anticipated:
            return .anticipated
        case .airing:
            return .airing
        case .completed:
            return .bingeReady
        case .cancelled:
            return .cancelled
        }
    }

    /// Whether the selected season can be marked as watched
    var canMarkSelectedSeasonWatched: Bool {
        guard isFollowed, let season = selectedSeason else { return false }
        return season.isBingeReady
    }

    // MARK: - Actions

    /// Select a different season
    func selectSeason(_ number: Int) {
        guard regularSeasons.contains(where: { $0.seasonNumber == number }) else { return }
        selectedSeasonNumber = number
    }

    /// Add (follow) this show
    func addShow() async {
        guard !isFollowed, !isAdding else { return }

        isAdding = true
        error = nil

        do {
            try await repository.save(show)
            isFollowed = true

            // Check if we should show notification settings modal
            let settings = AppSettings.shared
            if !settings.useGlobalNotificationDefaults {
                pendingNotificationSettings = .default
                showNotificationSettings = true
            }
        } catch {
            self.error = error
        }

        isAdding = false
    }

    /// Remove (unfollow) this show
    func removeShow() async {
        guard isFollowed, !isRemoving else { return }

        isRemoving = true
        error = nil

        do {
            try await repository.delete(show)
            isFollowed = false
            didRemoveShow = true
        } catch {
            self.error = error
        }

        isRemoving = false
    }

    /// Mark the selected season as watched
    func markSeasonWatched() async {
        guard canMarkSelectedSeasonWatched, !isMarkingWatched else { return }

        isMarkingWatched = true
        error = nil
        showMarkWatchedConfirmation = false

        do {
            let result = try await markWatchedUseCase.execute(
                showId: show.id,
                seasonNumber: selectedSeasonNumber
            )
            markWatchedResult = result

            // Clear result after delay
            Task {
                try? await Task.sleep(for: .seconds(3))
                if markWatchedResult == result {
                    markWatchedResult = nil
                }
            }
        } catch {
            self.error = error
        }

        isMarkingWatched = false
    }

    /// Toggle episode list expansion
    func toggleEpisodeList() {
        isEpisodeListExpanded.toggle()
    }

    /// Toggle an episode's watched status
    func toggleEpisodeWatched(_ episode: Episode) async {
        guard isFollowed, episode.hasAired else { return }

        let newWatchedState = !episode.isWatched

        // Update local state immediately for responsive UI
        updateLocalEpisodeWatchedState(
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
            watched: newWatchedState
        )

        do {
            try await markEpisodeWatchedUseCase.execute(
                showId: show.id,
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber,
                watched: newWatchedState
            )
        } catch {
            // Revert on error
            updateLocalEpisodeWatchedState(
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber,
                watched: !newWatchedState
            )
            self.error = error
        }
    }

    /// Update local episode watched state for immediate UI feedback
    private func updateLocalEpisodeWatchedState(seasonNumber: Int, episodeNumber: Int, watched: Bool) {
        guard let seasonIndex = show.seasons.firstIndex(where: { $0.seasonNumber == seasonNumber }),
              let episodeIndex = show.seasons[seasonIndex].episodes.firstIndex(where: { $0.episodeNumber == episodeNumber }) else {
            return
        }
        show.seasons[seasonIndex].episodes[episodeIndex].watchedDate = watched ? Date() : nil
    }

    // MARK: - Additional Content Loading

    /// Load videos, credits, and recommendations from TMDB
    func loadAdditionalContent() async {
        guard !isLoadingAdditionalContent else { return }
        isLoadingAdditionalContent = true

        // Fetch all data in parallel
        async let videosTask = tmdbService.getShowVideos(id: show.id)
        async let creditsTask = tmdbService.getShowCredits(id: show.id)
        async let recommendationsTask = tmdbService.getShowRecommendations(id: show.id)

        // Videos
        do {
            videos = try await videosTask
        } catch {
            // Silently fail - videos are optional
            videos = []
        }

        // Credits
        do {
            let credits = try await creditsTask
            cast = Array(credits.cast.prefix(10))
            crew = credits.crew.filter { ["Director", "Creator", "Executive Producer"].contains($0.job) }
        } catch {
            // Silently fail - credits are optional
            cast = []
            crew = []
        }

        // Recommendations
        do {
            recommendations = try await recommendationsTask
        } catch {
            // Silently fail - recommendations are optional
            recommendations = []
        }

        isLoadingAdditionalContent = false
    }

    // MARK: - Recommendation Actions

    /// Check if a recommendation is followed
    func isRecommendationFollowed(tmdbId: Int) -> Bool {
        repository.isShowFollowed(tmdbId: tmdbId)
    }

    /// Check if a recommendation is currently being added
    func isRecommendationAdding(tmdbId: Int) -> Bool {
        addingRecommendationIds.contains(tmdbId)
    }

    /// Toggle follow state for a recommendation
    func toggleRecommendationFollow(tmdbId: Int) async {
        guard !addingRecommendationIds.contains(tmdbId) else { return }

        addingRecommendationIds.insert(tmdbId)

        do {
            if repository.isShowFollowed(tmdbId: tmdbId) {
                // Unfollow - need to get the show first
                if let show = repository.fetchShow(byTmdbId: tmdbId) {
                    try await repository.delete(show)
                }
            } else {
                // Follow - fetch full show details and save
                let show = try await tmdbService.getShowDetails(id: tmdbId)
                try await repository.save(show)
            }
        } catch {
            self.error = error
        }

        addingRecommendationIds.remove(tmdbId)
    }

    /// Select a recommendation to view details
    func selectRecommendation(tmdbId: Int) async {
        do {
            selectedRecommendation = try await tmdbService.getShowDetails(id: tmdbId)
        } catch {
            self.error = error
        }
    }
}
