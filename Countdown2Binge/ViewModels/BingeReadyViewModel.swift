//
//  BingeReadyViewModel.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

/// A season paired with its parent show for display
struct BingeReadyItem: Identifiable, Equatable, Hashable {
    let show: Show
    let season: Season

    var id: String {
        "\(show.id)-\(season.seasonNumber)"
    }

    static func == (lhs: BingeReadyItem, rhs: BingeReadyItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A group of binge-ready seasons for a single show
struct BingeReadyShowGroup: Identifiable {
    let show: Show
    let seasons: [Season]

    var id: Int { show.id }
}

/// ViewModel for the Binge Ready screen.
/// Manages the list of seasons that are ready to binge.
@MainActor
@Observable
final class BingeReadyViewModel {
    // MARK: - Properties

    /// Seasons ready to binge, paired with their shows
    var bingeReadyItems: [BingeReadyItem] = []

    /// Loading state
    var isLoading: Bool = false

    /// Error state
    var error: Error?

    /// Item currently being marked as watched
    var markingWatchedItemId: String?

    /// Result of the last mark watched action (for feedback)
    var lastMarkWatchedResult: MarkWatchedResult?

    /// Show confirmation alert for this item
    var itemToMarkWatched: BingeReadyItem?

    // MARK: - Dependencies

    private let repository: ShowRepositoryProtocol
    private let markWatchedUseCase: MarkWatchedUseCaseProtocol

    // MARK: - Initialization

    init(repository: ShowRepositoryProtocol, markWatchedUseCase: MarkWatchedUseCaseProtocol? = nil) {
        self.repository = repository
        self.markWatchedUseCase = markWatchedUseCase ?? MarkWatchedUseCase(repository: repository)
    }

    // MARK: - Computed Properties

    /// Whether there are any binge-ready seasons
    var hasItems: Bool {
        !bingeReadyItems.isEmpty
    }

    /// Total count of binge-ready seasons
    var itemCount: Int {
        bingeReadyItems.count
    }

    /// Total episodes across all binge-ready seasons
    var totalEpisodes: Int {
        bingeReadyItems.reduce(0) { $0 + $1.season.episodeCount }
    }

    /// Items grouped by show for card stack display
    var groupedByShow: [BingeReadyShowGroup] {
        let grouped = Dictionary(grouping: bingeReadyItems) { $0.show.id }
        return grouped.compactMap { (showId, items) -> BingeReadyShowGroup? in
            guard let firstItem = items.first else { return nil }
            let seasons = items.map { $0.season }.sorted { $0.seasonNumber > $1.seasonNumber }
            return BingeReadyShowGroup(
                show: firstItem.show,
                seasons: seasons
            )
        }.sorted { group1, group2 in
            // Sort by most recent finale date across all seasons in the group
            let date1 = group1.seasons.compactMap { $0.finaleDate }.max()
            let date2 = group2.seasons.compactMap { $0.finaleDate }.max()
            guard let d1 = date1 else { return false }
            guard let d2 = date2 else { return true }
            return d1 > d2
        }
    }

    // MARK: - Load Seasons

    /// Load all binge-ready seasons from followed shows
    func loadSeasons() {
        isLoading = true
        error = nil

        let allShows = repository.fetchAllShows()
        var items: [BingeReadyItem] = []

        for show in allShows {
            // Get seasons that are binge ready (complete and not watched)
            let readySeasons = show.seasons.filter { season in
                season.seasonNumber > 0 && season.isBingeReady
            }

            for season in readySeasons {
                items.append(BingeReadyItem(show: show, season: season))
            }
        }

        // Sort by finale date (most recent first)
        bingeReadyItems = items.sorted { item1, item2 in
            guard let date1 = item1.season.finaleDate else { return false }
            guard let date2 = item2.season.finaleDate else { return true }
            return date1 > date2
        }

        isLoading = false
    }

    /// Refresh seasons (can be called on pull-to-refresh)
    func refresh() async {
        loadSeasons()
    }

    // MARK: - Mark Watched

    /// Check if an item is currently being marked
    func isMarking(item: BingeReadyItem) -> Bool {
        markingWatchedItemId == item.id
    }

    /// Request to mark an item as watched (shows confirmation)
    func requestMarkWatched(_ item: BingeReadyItem) {
        itemToMarkWatched = item
    }

    /// Cancel the mark watched request
    func cancelMarkWatched() {
        itemToMarkWatched = nil
    }

    /// Confirm and execute marking a season as watched
    func confirmMarkWatched() async {
        guard let item = itemToMarkWatched else { return }

        itemToMarkWatched = nil
        markingWatchedItemId = item.id
        error = nil

        do {
            let result = try await markWatchedUseCase.execute(
                showId: item.show.id,
                seasonNumber: item.season.seasonNumber
            )
            lastMarkWatchedResult = result

            // Reload the list to reflect the change
            loadSeasons()

            // Clear result after delay
            Task {
                try? await Task.sleep(for: .seconds(3))
                if lastMarkWatchedResult == result {
                    lastMarkWatchedResult = nil
                }
            }
        } catch {
            self.error = error
        }

        markingWatchedItemId = nil
    }

    /// Mark a season as watched (called from card stack swipe down)
    func markSeasonWatched(showId: Int, seasonNumber: Int) async {
        let itemId = "\(showId)-\(seasonNumber)"
        markingWatchedItemId = itemId
        error = nil

        do {
            let result = try await markWatchedUseCase.execute(
                showId: showId,
                seasonNumber: seasonNumber
            )
            lastMarkWatchedResult = result
            loadSeasons()

            Task {
                try? await Task.sleep(for: .seconds(3))
                if lastMarkWatchedResult == result {
                    lastMarkWatchedResult = nil
                }
            }
        } catch {
            self.error = error
        }

        markingWatchedItemId = nil
    }

    /// Delete a show (called from card stack swipe up)
    func deleteShow(_ show: Show) async {
        do {
            try await repository.delete(show)
            loadSeasons()
        } catch {
            self.error = error
        }
    }
}
