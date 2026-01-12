//
//  MarkWatchedUseCase.swift
//  Countdown2Binge
//

import Foundation

/// Result of marking a season as watched
enum MarkWatchedResult: Equatable {
    /// Series has ended - no more seasons coming
    case showComplete
    /// Next season was added to anticipated
    case nextSeasonAdded(seasonNumber: Int)
    /// Show is returning but no TMDB data for next season yet
    case nextSeasonPlaceholder(seasonNumber: Int)
}

/// Errors that can occur when marking watched
enum MarkWatchedError: Error, LocalizedError, Equatable {
    case showNotFound
    case seasonNotFound
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .showNotFound:
            return "Show not found"
        case .seasonNotFound:
            return "Season not found"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        }
    }

    static func saveFailed(_ error: Error) -> MarkWatchedError {
        .saveFailed(error.localizedDescription)
    }
}

/// Protocol for mark watched use case (enables testing with mocks)
protocol MarkWatchedUseCaseProtocol {
    func execute(showId: Int, seasonNumber: Int) async throws -> MarkWatchedResult
}

/// Use case for marking a season as watched.
/// Handles the lifecycle transition: marks season watched and determines next state.
@MainActor
final class MarkWatchedUseCase: MarkWatchedUseCaseProtocol {
    private let repository: ShowRepositoryProtocol

    init(repository: ShowRepositoryProtocol) {
        self.repository = repository
    }

    /// Mark a season as watched and determine the result.
    /// - Parameters:
    ///   - showId: The TMDB ID of the show
    ///   - seasonNumber: The season number to mark as watched
    /// - Returns: The result indicating what happens next
    func execute(showId: Int, seasonNumber: Int) async throws -> MarkWatchedResult {
        // Get the show
        guard let show = repository.fetchShow(byTmdbId: showId) else {
            throw MarkWatchedError.showNotFound
        }

        // Verify the season exists
        guard show.seasons.contains(where: { $0.seasonNumber == seasonNumber }) else {
            throw MarkWatchedError.seasonNotFound
        }

        // Mark the season as watched
        do {
            try await repository.markSeasonWatched(showId: showId, seasonNumber: seasonNumber)
        } catch {
            throw MarkWatchedError.saveFailed(error)
        }

        // Determine the result based on show status
        return determineResult(for: show, watchedSeasonNumber: seasonNumber)
    }

    // MARK: - Private

    private func determineResult(for show: Show, watchedSeasonNumber: Int) -> MarkWatchedResult {
        let nextSeasonNumber = watchedSeasonNumber + 1

        // Check if the show has ended or been cancelled
        switch show.status {
        case .ended, .cancelled:
            // No more seasons coming
            return .showComplete

        case .returning, .inProduction, .planned, .pilot:
            // Show is ongoing - check if next season exists in TMDB data
            if show.seasons.contains(where: { $0.seasonNumber == nextSeasonNumber }) {
                return .nextSeasonAdded(seasonNumber: nextSeasonNumber)
            } else {
                // Next season not in TMDB yet (will appear when TMDB adds it)
                return .nextSeasonPlaceholder(seasonNumber: nextSeasonNumber)
            }
        }
    }
}
