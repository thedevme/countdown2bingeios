//
//  TimelineViewModel.swift
//  Countdown2Binge
//

import Foundation
import SwiftUI

/// ViewModel for the Timeline screen.
/// Loads followed shows and groups them by timeline category.
@MainActor
@Observable
final class TimelineViewModel {
    // MARK: - Published Properties

    /// Shows currently airing (sorted by days until finale)
    var airingShows: [TimelineEntry] = []

    /// Shows premiering soon (sorted by days until premiere)
    var premieringShows: [TimelineEntry] = []

    /// Shows with no known air date
    var anticipatedShows: [TimelineEntry] = []

    /// Loading state
    var isLoading: Bool = false

    /// Error state
    var error: Error?

    // MARK: - Dependencies

    private let repository: ShowRepositoryProtocol
    private let timelineService: TimelineServiceProtocol

    // MARK: - Initialization

    init(repository: ShowRepositoryProtocol, timelineService: TimelineServiceProtocol? = nil) {
        self.repository = repository
        self.timelineService = timelineService ?? TimelineService()
    }

    // MARK: - Computed Properties

    /// Whether there are any shows to display
    var hasShows: Bool {
        !airingShows.isEmpty || !premieringShows.isEmpty || !anticipatedShows.isEmpty
    }

    /// Total count of timeline shows
    var totalShowCount: Int {
        airingShows.count + premieringShows.count + anticipatedShows.count
    }

    // MARK: - Load Shows

    /// Load and categorize all followed shows for the timeline.
    /// Timeline excludes binge-ready shows (they appear in Binge Ready tab).
    func loadShows() {
        isLoading = true
        error = nil

        // Fetch timeline shows (returning/inProduction only)
        let shows = repository.fetchTimelineShows()

        // Group by category using TimelineService
        let grouped = timelineService.groupByCategory(shows)

        // Distribute to properties (excluding bingeReady - that's a separate tab)
        airingShows = grouped[.airingNow] ?? []
        premieringShows = grouped[.premieringSoon] ?? []
        anticipatedShows = grouped[.anticipated] ?? []

        isLoading = false
    }

    /// Refresh shows (can be called on pull-to-refresh)
    func refresh() async {
        loadShows()
    }
}
