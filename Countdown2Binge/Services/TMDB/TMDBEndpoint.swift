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
        }

        return items
    }

    var url: URL {
        var components = URLComponents(string: TMDBConfiguration.baseURL + path)!
        components.queryItems = queryItems
        return components.url!
    }
}
