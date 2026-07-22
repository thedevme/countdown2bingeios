//
//  TimelineViewModel.swift
//  Countdown2Binge
//
//  Manages state for the Timeline screen.
//  Fetches followed shows and categorizes them by lifecycle state.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class TimelineViewModel {
    // MARK: - State

    private(set) var followedShows: [ShowData] = []
    private(set) var isLoading = false

    // MARK: - Categorized Shows

    /// Shows currently releasing episodes (sorted by finale date, soonest first)
    var airingNowShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .airingNow }
            .sorted { ($0.daysUntilFinale ?? 999) < ($1.daysUntilFinale ?? 999) }
    }

    /// Shows with known premiere date (sorted by premiere date, soonest first)
    var premieringSoonShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .premieringSoon }
            .sorted { ($0.daysUntilPremiere ?? 999) < ($1.daysUntilPremiere ?? 999) }
    }

    /// Shows with no date announced - TBD (sorted alphabetically)
    var anticipatedShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .anticipated }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Completed or cancelled shows - ready to binge (sorted alphabetically)
    var bingeReadyShows: [ShowData] {
        followedShows
            .filter { $0.timelineCategory == .bingeReady }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Hero shows for the card stack (airing now, sorted by finale)
    var heroShows: [ShowData] {
        Array(airingNowShows.prefix(5))
    }

    /// Hero shows as tuples for HeroCardStack
    var heroShowTuples: [HeroCardStack.ShowDataTuple] {
        heroShows.map { show in
            (
                show: show,
                daysUntilFinale: show.daysUntilFinale,
                episodesUntilFinale: nil, // Not tracked currently
                finaleDate: show.currentSeason?.episodes
                    .max(by: { $0.episodeNumber < $1.episodeNumber })?.airDate
            )
        }
    }

    var trackedCount: Int {
        followedShows.count
    }

    var upcomingCount: Int {
        airingNowShows.count
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var store: FollowedShowsStore?

    // MARK: - Init

    init() {}

    // MARK: - Public API

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.store = FollowedShowsStore(modelContext: modelContext)
    }

    func loadFollowedShows() async {
        guard let store else { return }

        isLoading = true

        do {
            followedShows = try await store.getAllFollowedAsShowData()

            print("\n=== TIMELINE DEBUG ===\n")

            for show in followedShows {
                print("SHOW: \(show.name)")
                print("  inProduction: \(show.inProduction)")
                print("  status: \(show.status)")
                print("  lifecycleState: \(show.lifecycleState)")
                print("  timelineCategory: \(show.timelineCategory)")
                print("  seasons: \(show.numberOfSeasons)")
                if let current = show.currentSeason {
                    print("  currentSeason: S\(current.seasonNumber) - hasStarted: \(current.hasStarted), isComplete: \(current.isComplete)")
                } else {
                    print("  currentSeason: nil")
                }
                print("")
            }

            print("==============================\n")
        } catch {
            print("Error loading followed shows: \(error)")
            followedShows = []
        }

        isLoading = false
    }

    func refresh() async {
        await loadFollowedShows()
    }

    /// Unfollow a show
    func unfollowShow(_ show: ShowData) async {
        guard let store else { return }

        do {
            try store.unfollow(tmdbId: show.id)
            // Remove from local list
            followedShows.removeAll { $0.id == show.id }
        } catch {
            print("Error unfollowing show: \(error)")
        }
    }

    /// Get anticipated season number for display (numberOfSeasons + 1)
    func anticipatedSeasonNumber(for show: ShowData) -> Int {
        show.numberOfSeasons + 1
    }
}
