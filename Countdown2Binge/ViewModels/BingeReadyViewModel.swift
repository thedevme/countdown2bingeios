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

    // MARK: - Dependencies

    private let repository: ShowRepositoryProtocol

    // MARK: - Initialization

    init(repository: ShowRepositoryProtocol) {
        self.repository = repository
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

    // MARK: - Load Seasons

    /// Load all binge-ready seasons from followed shows
    func loadSeasons() {
        isLoading = true
        error = nil

        let allShows = repository.fetchAllShows()
        var items: [BingeReadyItem] = []

        for show in allShows {
            // Get seasons that are complete (all episodes aired)
            let readySeasons = show.seasons.filter { season in
                season.seasonNumber > 0 && season.isComplete
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
}
