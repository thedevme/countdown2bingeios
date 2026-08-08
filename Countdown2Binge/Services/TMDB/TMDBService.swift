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
            return String(localized: "error_invalid_url")
        case .networkError(let error):
            return String(localized: "error_network \(error.localizedDescription)")
        case .decodingError(let error):
            return String(localized: "error_decode \(error.localizedDescription)")
        case .noData:
            return String(localized: "error_no_data")
        case .httpError(let statusCode):
            return String(localized: "error_http \(statusCode)")
        }
    }
}

/// Full show details with extras (credits, videos, recommendations)
struct ShowDetailsWithExtras {
    let show: ShowData
    let cast: [TMDBCastMember]
    let videos: [TMDBVideo]
    let recommendations: [TMDBShowSummary]
}

/// Protocol for TMDB API operations (enables testing with mocks)
protocol TMDBServiceProtocol {
    func searchShows(query: String, page: Int) async throws -> TMDBSearchResponse
    func getShowDetails(id: Int) async throws -> ShowData
    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> SeasonData
    func getTrendingShows(page: Int) async throws -> TMDBSearchResponse
    func getAiringShows(page: Int) async throws -> TMDBSearchResponse
    func getShowsByGenre(genreIds: [Int], page: Int) async throws -> TMDBSearchResponse
    func getShowsByNetwork(networkId: Int, page: Int) async throws -> TMDBSearchResponse
    func getShowsByDateRange(networkId: Int, startDate: Date, endDate: Date, page: Int) async throws -> TMDBSearchResponse
    func getShowLogo(id: Int) async -> String?
    func getShowVideos(id: Int) async throws -> [TMDBVideo]
    func getShowCredits(id: Int) async throws -> TMDBCreditsResponse
    func getShowRecommendations(id: Int) async throws -> [TMDBShowSummary]
    func getWatchProviders(id: Int) async throws -> TMDBWatchProvidersResponse
    func getWatchProvidersTV(region: String) async throws -> [TMDBWatchProvider]

    // Preference-driven discovery (params from DiscoverQueryBuilder)
    func discover(query: DiscoverQuery, relaxation: DiscoverQuery.Relaxation) async throws -> TMDBSearchResponse

    // Parallel batch methods
    func getShowDetailsWithExtras(id: Int) async throws -> ShowDetailsWithExtras
    func getMultipleShowDetails(ids: [Int]) async throws -> [ShowData]
    func getMultipleShowsByNetwork(networkIds: [Int], page: Int) async throws -> [Int: [ShowSummary]]
    func getMultipleShowsByGenre(genreIds: [Int], page: Int) async throws -> [Int: [ShowSummary]]

    // Lightweight methods (no season fetching)
    func getShowName(id: Int) async throws -> String
    func getShowBasicInfo(id: Int) async throws -> (episodes: Int, seasons: Int)
    func getMultipleShowBasicInfo(ids: [Int]) async throws -> [Int: (episodes: Int, seasons: Int)]
}

/// Service for interacting with the TMDB API
final class TMDBService: TMDBServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Search for TV shows by query
    func searchShows(query: String, page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.searchTV(query: query, page: page)
        return try await fetch(endpoint)
    }

    /// Get trending TV shows for the week
    func getTrendingShows(page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.trendingTV(page: page)
        return try await fetch(endpoint)
    }

    /// Get currently airing TV shows
    func getAiringShows(page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.discoverAiring(page: page)
        return try await fetch(endpoint)
    }

    /// Get TV shows by genre
    func getShowsByGenre(genreIds: [Int], page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.discoverByGenre(genreIds: genreIds, page: page)
        return try await fetch(endpoint)
    }

    /// Get TV shows by network
    func getShowsByNetwork(networkId: Int, page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.discoverByNetwork(networkId: networkId, page: page)
        return try await fetch(endpoint)
    }

    /// Get TV shows by network and date range
    func getShowsByDateRange(networkId: Int, startDate: Date, endDate: Date, page: Int = 1) async throws -> TMDBSearchResponse {
        let endpoint = TMDBEndpoint.discoverByDateRange(networkId: networkId, startDate: startDate, endDate: endDate, page: page)
        return try await fetch(endpoint)
    }

    /// Get the show's title in the current app language (one request, no season
    /// fetching). Used to re-localize stored titles when the language changes.
    func getShowName(id: Int) async throws -> String {
        let details: TMDBShowDetails = try await fetch(TMDBEndpoint.tvDetails(id: id))
        return details.name
    }

    /// Get basic show info (episode/season counts only - no season details)
    func getShowBasicInfo(id: Int) async throws -> (episodes: Int, seasons: Int) {
        let endpoint = TMDBEndpoint.tvDetails(id: id)
        let details: TMDBShowDetails = try await fetch(endpoint)
        return (episodes: details.numberOfEpisodes, seasons: details.numberOfSeasons)
    }

    /// Get basic info for multiple shows in parallel
    func getMultipleShowBasicInfo(ids: [Int]) async throws -> [Int: (episodes: Int, seasons: Int)] {
        var result: [Int: (episodes: Int, seasons: Int)] = [:]

        try await withThrowingTaskGroup(of: (Int, Int, Int)?.self) { group in
            for id in ids {
                group.addTask {
                    do {
                        let info = try await self.getShowBasicInfo(id: id)
                        return (id, info.episodes, info.seasons)
                    } catch {
                        return nil
                    }
                }
            }

            for try await item in group {
                if let (id, episodes, seasons) = item {
                    result[id] = (episodes: episodes, seasons: seasons)
                }
            }
        }

        return result
    }

    /// Get full show details with all season episodes (fetched in parallel)
    func getShowDetails(id: Int) async throws -> ShowData {
        // First, get the show details
        let endpoint = TMDBEndpoint.tvDetails(id: id)
        let details: TMDBShowDetails = try await fetch(endpoint)

        // Fetch logo in parallel with seasons
        async let logoPath = getShowLogo(id: id)

        // Fetch all season details in parallel using TaskGroup
        let regularSeasons = details.seasons.filter { $0.seasonNumber > 0 }
        var seasons: [SeasonData] = []

        try await withThrowingTaskGroup(of: SeasonData.self) { group in
            for seasonSummary in regularSeasons {
                group.addTask {
                    return try await self.getSeasonDetails(tvId: id, seasonNumber: seasonSummary.seasonNumber)
                }
            }

            for try await seasonDetails in group {
                seasons.append(seasonDetails)
            }
        }

        // Sort seasons by season number
        seasons.sort { $0.seasonNumber < $1.seasonNumber }

        return TMDBMapper.map(details, seasons: seasons, logoPath: await logoPath)
    }

    /// Get the best available logo for a show
    func getShowLogo(id: Int) async -> String? {
        do {
            let endpoint = TMDBEndpoint.tvImages(id: id)
            let images: TMDBImagesResponse = try await fetch(endpoint)

            // Prefer English logos, then fallback to any available
            let englishLogos = images.logos.filter { $0.iso6391 == "en" }
            let bestLogo = englishLogos.first ?? images.logos.first

            return bestLogo?.filePath
        } catch {
            // Logo fetch failed, return nil (will fall back to text)
            return nil
        }
    }

    /// Get detailed season info including episodes
    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> SeasonData {
        let endpoint = TMDBEndpoint.seasonDetails(tvId: tvId, seasonNumber: seasonNumber)
        let details: TMDBSeasonDetails = try await fetch(endpoint)
        return TMDBMapper.map(details)
    }

    /// Get videos (trailers, clips) for a show
    func getShowVideos(id: Int) async throws -> [TMDBVideo] {
        let endpoint = TMDBEndpoint.tvVideos(id: id)
        let response: TMDBVideosResponse = try await fetch(endpoint)
        // Filter for trailers and teasers, prefer official videos
        return response.results
            .filter { ["Trailer", "Teaser", "Clip", "Featurette"].contains($0.type) }
            .sorted { ($0.official ? 0 : 1) < ($1.official ? 0 : 1) }
    }

    /// Get cast and crew for a show
    func getShowCredits(id: Int) async throws -> TMDBCreditsResponse {
        let endpoint = TMDBEndpoint.tvCredits(id: id)
        return try await fetch(endpoint)
    }

    /// Get recommended shows similar to a given show
    func getShowRecommendations(id: Int) async throws -> [TMDBShowSummary] {
        let endpoint = TMDBEndpoint.tvRecommendations(id: id)
        let response: TMDBSearchResponse = try await fetch(endpoint)
        return response.results
    }

    /// Get watch/streaming providers for a show
    func getWatchProviders(id: Int) async throws -> TMDBWatchProvidersResponse {
        let endpoint = TMDBEndpoint.tvWatchProviders(id: id)
        return try await fetch(endpoint)
    }

    /// Get the live watch-provider catalog for a region (source of truth for IDs)
    func getWatchProvidersTV(region: String) async throws -> [TMDBWatchProvider] {
        let response: TMDBProviderListResponse = try await fetch(.watchProvidersTV(region: region))
        return response.results
    }

    /// Preference-driven discovery. All parameters come from DiscoverQueryBuilder
    /// (the single source) — this method never composes discovery params itself.
    func discover(query: DiscoverQuery,
                  relaxation: DiscoverQuery.Relaxation = .full) async throws -> TMDBSearchResponse {
        let items = DiscoverQueryBuilder.queryItems(for: query, relaxation: relaxation)
        return try await fetch(.discover(items: items))
    }

    // MARK: - Parallel Batch Methods

    /// Get show details with credits, videos, and recommendations in parallel
    func getShowDetailsWithExtras(id: Int) async throws -> ShowDetailsWithExtras {
        async let showTask = getShowDetails(id: id)
        async let creditsTask = getShowCredits(id: id)
        async let videosTask = getShowVideos(id: id)
        async let recommendationsTask = getShowRecommendations(id: id)

        let show = try await showTask
        let credits = (try? await creditsTask)?.cast ?? []
        let videos = (try? await videosTask) ?? []
        let recommendations = (try? await recommendationsTask) ?? []

        return ShowDetailsWithExtras(
            show: show,
            cast: credits,
            videos: videos,
            recommendations: recommendations
        )
    }

    /// Get multiple show details in parallel
    func getMultipleShowDetails(ids: [Int]) async throws -> [ShowData] {
        var shows: [ShowData] = []

        try await withThrowingTaskGroup(of: ShowData?.self) { group in
            for id in ids {
                group.addTask {
                    try? await self.getShowDetails(id: id)
                }
            }

            for try await show in group {
                if let show {
                    shows.append(show)
                }
            }
        }

        return shows
    }

    /// Get shows from multiple networks in parallel
    func getMultipleShowsByNetwork(networkIds: [Int], page: Int = 1) async throws -> [Int: [ShowSummary]] {
        var result: [Int: [ShowSummary]] = [:]

        try await withThrowingTaskGroup(of: (Int, [ShowSummary])?.self) { group in
            for networkId in networkIds {
                group.addTask {
                    do {
                        let response = try await self.getShowsByNetwork(networkId: networkId, page: page)
                        return (networkId, response.results.map { $0.toShowSummary() })
                    } catch {
                        return nil
                    }
                }
            }

            for try await item in group {
                if let (networkId, shows) = item {
                    result[networkId] = shows
                }
            }
        }

        return result
    }

    /// Get shows from multiple genres in parallel
    func getMultipleShowsByGenre(genreIds: [Int], page: Int = 1) async throws -> [Int: [ShowSummary]] {
        var result: [Int: [ShowSummary]] = [:]

        try await withThrowingTaskGroup(of: (Int, [ShowSummary])?.self) { group in
            for genreId in genreIds {
                group.addTask {
                    do {
                        let response = try await self.getShowsByGenre(genreIds: [genreId], page: page)
                        return (genreId, response.results.map { $0.toShowSummary() })
                    } catch {
                        return nil
                    }
                }
            }

            for try await item in group {
                if let (genreId, shows) = item {
                    result[genreId] = shows
                }
            }
        }

        return result
    }

    // MARK: - Private

    /// Fetch and decode - runs on cooperative thread pool (not main thread)
    nonisolated private func fetch<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        let (data, response) = try await session.data(from: endpoint.url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDBError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TMDBError.decodingError(error)
        }
    }
}
