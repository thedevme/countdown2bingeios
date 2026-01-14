//
//  TMDBConfiguration.swift
//  Countdown2Binge
//

import Foundation

/// TMDB API configuration
enum TMDBConfiguration {
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"

    /// API key loaded from Config.plist
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["TMDB_API_KEY"] as? String,
              key != "YOUR_TMDB_API_KEY_HERE" else {
            // Return empty key for tests or when not configured
            // API calls will fail, but app won't crash
            return ""
        }
        return key
    }

    /// Image size variants
    enum ImageSize {
        case poster
        case posterSmall
        case backdrop
        case backdropSmall
        case still
        case logo
        case original

        var path: String {
            switch self {
            case .poster: "/w500"
            case .posterSmall: "/w185"
            case .backdrop: "/w780"
            case .backdropSmall: "/w300"
            case .still: "/w300"
            case .logo: "/w500"
            case .original: "/original"
            }
        }
    }

    /// Build full image URL from path
    static func imageURL(path: String?, size: ImageSize = .poster) -> URL? {
        guard let path else { return nil }
        return URL(string: "\(imageBaseURL)\(size.path)\(path)")
    }
}
