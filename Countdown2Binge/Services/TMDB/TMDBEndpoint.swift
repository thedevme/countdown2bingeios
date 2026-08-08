//
//  TMDBEndpoint.swift
//  Countdown2Binge
//

import Foundation

/// TMDB API endpoints
enum TMDBEndpoint {
    case searchTV(query: String, page: Int)
    case tvDetails(id: Int)
    case seasonDetails(tvId: Int, seasonNumber: Int)
    case tvImages(id: Int)
    case tvVideos(id: Int)
    case tvCredits(id: Int)
    case tvRecommendations(id: Int)
    case tvWatchProviders(id: Int)
    case trendingTV(page: Int)
    case discoverAiring(page: Int)
    case discoverByGenre(genreIds: [Int], page: Int)
    case discoverByNetwork(networkId: Int, page: Int)
    case discoverByDateRange(networkId: Int, startDate: Date, endDate: Date, page: Int)
    /// Preference-driven discovery. Query items come pre-built from
    /// `DiscoverQueryBuilder` — the single source of discovery parameters.
    case discover(items: [URLQueryItem])
    /// Live watch-provider catalog for a region (source of truth for provider IDs).
    case watchProvidersTV(region: String)

    var path: String {
        switch self {
        case .searchTV:
            return "/search/tv"
        case .tvDetails(let id):
            return "/tv/\(id)"
        case .seasonDetails(let tvId, let seasonNumber):
            return "/tv/\(tvId)/season/\(seasonNumber)"
        case .tvImages(let id):
            return "/tv/\(id)/images"
        case .tvVideos(let id):
            return "/tv/\(id)/videos"
        case .tvCredits(let id):
            return "/tv/\(id)/credits"
        case .tvRecommendations(let id):
            return "/tv/\(id)/recommendations"
        case .tvWatchProviders(let id):
            return "/tv/\(id)/watch/providers"
        case .trendingTV:
            return "/trending/tv/week"
        case .discoverAiring:
            return "/tv/on_the_air"
        case .discoverByGenre:
            return "/discover/tv"
        case .discoverByNetwork:
            return "/discover/tv"
        case .discoverByDateRange:
            return "/discover/tv"
        case .discover:
            return "/discover/tv"
        case .watchProvidersTV:
            return "/watch/providers/tv"
        }
    }

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "api_key", value: TMDBConfiguration.apiKey),
            URLQueryItem(name: "language", value: TMDBConfiguration.currentLanguage)
        ]

        switch self {
        case .searchTV(let query, let page):
            items.append(URLQueryItem(name: "query", value: query))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "include_adult", value: "false"))
        case .tvDetails:
            items.append(URLQueryItem(name: "append_to_response", value: "external_ids"))
        case .seasonDetails:
            break
        case .tvImages:
            // For images, include the current language plus English fallback and null (no language)
            let langCode = Locale.current.language.languageCode?.identifier ?? "en"
            items.append(URLQueryItem(name: "include_image_language", value: "\(langCode),en,null"))
        case .tvVideos:
            break
        case .tvCredits:
            break
        case .tvRecommendations:
            break
        case .tvWatchProviders:
            break
        case .trendingTV(let page):
            items.append(URLQueryItem(name: "page", value: String(page)))
        case .discoverAiring(let page):
            items.append(URLQueryItem(name: "page", value: String(page)))
        case .discoverByGenre(let genreIds, let page):
            items.append(URLQueryItem(name: "with_genres", value: genreIds.map(String.init).joined(separator: "|")))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "include_adult", value: "false"))
        case .discoverByNetwork(let networkId, let page):
            items.append(URLQueryItem(name: "with_networks", value: String(networkId)))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "include_adult", value: "false"))
            items.append(URLQueryItem(name: "with_status", value: "0")) // Returning Series only
            items.append(URLQueryItem(name: "without_genres", value: "16")) // Exclude Animation
            items.append(URLQueryItem(name: "with_type", value: "2")) // Scripted only
        case .discoverByDateRange(let networkId, let startDate, let endDate, let page):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            items.append(URLQueryItem(name: "with_networks", value: String(networkId)))
            items.append(URLQueryItem(name: "first_air_date.gte", value: formatter.string(from: startDate)))
            items.append(URLQueryItem(name: "first_air_date.lte", value: formatter.string(from: endDate)))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "sort_by", value: "first_air_date.asc"))
            items.append(URLQueryItem(name: "include_adult", value: "false"))
            items.append(URLQueryItem(name: "without_genres", value: "16")) // Exclude Animation
            items.append(URLQueryItem(name: "with_type", value: "2")) // Scripted only (no reality/talk)
        case .discover(let discoverItems):
            // Parameters are pre-composed by DiscoverQueryBuilder (single source).
            items.append(contentsOf: discoverItems)
        case .watchProvidersTV(let region):
            items.append(URLQueryItem(name: "watch_region", value: region))
        }

        return items
    }

    var url: URL {
        var components = URLComponents(string: TMDBConfiguration.baseURL + path)!
        components.queryItems = queryItems
        return components.url!
    }
}
