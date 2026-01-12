//
//  MarkEpisodeWatchedUseCase.swift
//  Countdown2Binge
//

import Foundation

/// Protocol for mark episode watched use case (enables testing with mocks)
protocol MarkEpisodeWatchedUseCaseProtocol {
    func execute(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws
}

/// Use case for toggling an episode's watched status.
@MainActor
final class MarkEpisodeWatchedUseCase: MarkEpisodeWatchedUseCaseProtocol {
    private let repository: ShowRepositoryProtocol

    init(repository: ShowRepositoryProtocol) {
        self.repository = repository
    }

    /// Toggle an episode's watched status.
    /// - Parameters:
    ///   - showId: The TMDB ID of the show
    ///   - seasonNumber: The season number
    ///   - episodeNumber: The episode number
    ///   - watched: Whether to mark as watched (true) or unwatched (false)
    func execute(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {
        try await repository.markEpisodeWatched(
            showId: showId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            watched: watched
        )
    }
}
