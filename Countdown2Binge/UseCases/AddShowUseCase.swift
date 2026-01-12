//
//  AddShowUseCase.swift
//  Countdown2Binge
//

import Foundation
import SwiftData

/// Errors that can occur when adding a show
enum AddShowError: Error, LocalizedError {
    case alreadyFollowed
    case fetchFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .alreadyFollowed:
            return "You're already following this show"
        case .fetchFailed(let error):
            return "Failed to fetch show: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save show: \(error.localizedDescription)"
        }
    }
}

/// Protocol for adding shows (enables testing with mocks)
protocol AddShowUseCaseProtocol {
    func execute(tmdbId: Int) async throws -> Show
}

/// Use case for adding a new show to the user's followed list.
///
/// Flow:
/// 1. Check if already followed
/// 2. Fetch full show data from TMDB
/// 3. Save to repository (follow + cache)
/// 4. Return the saved show
@MainActor
final class AddShowUseCase: AddShowUseCaseProtocol {
    private let tmdbService: TMDBServiceProtocol
    private let repository: ShowRepositoryProtocol

    init(tmdbService: TMDBServiceProtocol, repository: ShowRepositoryProtocol) {
        self.tmdbService = tmdbService
        self.repository = repository
    }

    /// Add a show by its TMDB ID
    /// - Parameter tmdbId: The TMDB ID of the show to add
    /// - Returns: The saved Show domain model
    /// - Throws: AddShowError if the show is already followed or fetch/save fails
    func execute(tmdbId: Int) async throws -> Show {
        // 1. Check if already followed
        if repository.isShowFollowed(tmdbId: tmdbId) {
            throw AddShowError.alreadyFollowed
        }

        // 2. Fetch full show data from TMDB
        let show: Show
        do {
            show = try await tmdbService.getShowDetails(id: tmdbId)
        } catch {
            throw AddShowError.fetchFailed(error)
        }

        // 3. Save to repository (follow + cache)
        do {
            try await repository.save(show)
        } catch {
            throw AddShowError.saveFailed(error)
        }

        // 4. Return the saved show
        return show
    }
}
