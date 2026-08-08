//
//  TMDBConfiguration.swift
//  Countdown2Binge
//

import Foundation

/// TMDB API configuration
enum TMDBConfiguration {
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"

    /// Supported languages mapped to TMDB API format
    private static let languageMapping: [String: String] = [
        "en": "en-US",
        "es": "es-ES",
        "fr": "fr-FR",
        "de": "de-DE",
        "pt": "pt-BR",
        "it": "it-IT",
        "ja": "ja-JP",
        "ko": "ko-KR",
        "zh": "zh-CN",
        "ar": "ar-SA",
        "ru": "ru-RU",
        "tr": "tr-TR",
        "pl": "pl-PL",
        "nl": "nl-NL",
        "th": "th-TH"
    ]

    /// Current device language in TMDB API format
    static var currentLanguage: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageMapping[languageCode] ?? "en-US"
    }

    /// Current device region (ISO 3166-1) for `watch_region`. `Locale.current`
    /// region is optional, so nil never propagates into a query — defaults to "US".
    static var currentRegion: String {
        Locale.current.region?.identifier ?? "US"
    }

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
