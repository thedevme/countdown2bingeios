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
    case trendingTV
    case discoverAiring(page: Int)
    case discoverByGenre(genreIds: [Int], page: Int)

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
        case .trendingTV:
            return "/trending/tv/week"
        case .discoverAiring:
            return "/tv/on_the_air"
        case .discoverByGenre:
            return "/discover/tv"
        }
    }

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "api_key", value: TMDBConfiguration.apiKey)]

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
            items.append(URLQueryItem(name: "include_image_language", value: "en,null"))
        case .tvVideos:
            break
        case .tvCredits:
            break
        case .tvRecommendations:
            break
        case .trendingTV:
            break
        case .discoverAiring(let page):
            items.append(URLQueryItem(name: "page", value: String(page)))
        case .discoverByGenre(let genreIds, let page):
            items.append(URLQueryItem(name: "with_genres", value: genreIds.map(String.init).joined(separator: "|")))
            items.append(URLQueryItem(name: "page", value: String(page)))
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "include_adult", value: "false"))
        }

        return items
    }

    var url: URL {
        var components = URLComponents(string: TMDBConfiguration.baseURL + path)!
        components.queryItems = queryItems
        return components.url!
    }
}
