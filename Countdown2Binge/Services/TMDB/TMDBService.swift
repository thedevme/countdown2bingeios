//
//  TMDBService.swift
//  Countdown2Binge
//

import Foundation

/// Errors that can occur during TMDB API calls
enum TMDBError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}

/// Protocol for TMDB API operations (enables testing with mocks)
protocol TMDBServiceProtocol {
    func searchShows(query: String, page: Int) async throws -> TMDBSearchResponse
    func getShowDetails(id: Int) async throws -> Show
    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> Season
}

/// Service for interacting with the TMDB API
final class TMDBService: TMDBServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Search for TV shows by query
    func searchShows(query: String, page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.searchTV(query: query, page: page)
        return try await fetch(endpoint)
    }

    /// Get full show details with all season episodes
    func getShowDetails(id: Int) async throws -> Show {
        // First, get the show details
        let endpoint = TMDBEndpoint.tvDetails(id: id)
        let details: TMDBShowDetails = try await fetch(endpoint)

        // Then fetch episode details for each season (excluding specials)
        let regularSeasons = details.seasons.filter { $0.seasonNumber > 0 }
        var seasons: [Season] = []

        for seasonSummary in regularSeasons {
            do {
                let season = try await getSeasonDetails(tvId: id, seasonNumber: seasonSummary.seasonNumber)
                seasons.append(season)
            } catch {
                // If we can't fetch season details, use the summary
                seasons.append(TMDBMapper.map(seasonSummary))
            }
        }

        return TMDBMapper.map(details, seasons: seasons)
    }

    /// Get detailed season info including episodes
    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> Season {
        let endpoint = TMDBEndpoint.seasonDetails(tvId: tvId, seasonNumber: seasonNumber)
        let details: TMDBSeasonDetails = try await fetch(endpoint)
        return TMDBMapper.map(details)
    }

    // MARK: - Private

    private func fetch<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        let (data, response) = try await session.data(from: endpoint.url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDBError.decodingError(error)
        }
    }
}
