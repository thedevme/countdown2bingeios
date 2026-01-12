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
    let show: Show

    /// Currently selected season number
    var selectedSeasonNumber: Int

    /// Whether this show is followed by the user
    var isFollowed: Bool

    /// Loading state for remove action
    var isRemoving: Bool = false

    /// Loading state for add action
    var isAdding: Bool = false

    /// Error state
    var error: Error?

    /// Whether the show was successfully removed (for dismissal)
    var didRemoveShow: Bool = false

    // MARK: - Dependencies

    private let repository: ShowRepositoryProtocol

    // MARK: - Initialization

    init(show: Show, repository: ShowRepositoryProtocol) {
        self.show = show
        self.repository = repository
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
}
