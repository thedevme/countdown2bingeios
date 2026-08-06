//
//  StreamingLinkButton.swift
//  Countdown2Binge
//
//  Deep link button to open show in streaming app
//

import SwiftUI

struct StreamingLinkButton: View {
    let network: NetworkData?
    let showName: String

    @Environment(\.openURL) private var openURL

    private var streamingService: StreamingService? {
        guard let network = network else { return nil }
        return StreamingService.from(networkId: network.id, networkName: network.name)
    }

    var body: some View {
        if let service = streamingService {
            Button(action: { openStreamingApp(service: service) }) {
                HStack(spacing: 10) {
                    // Service logo or icon
                    if let logoURL = network?.logoURL {
                        CachedAsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "play.tv")
                                .font(.system(size: 16))
                        }
                        .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "play.tv")
                            .font(.system(size: 16))
                    }

                    Text(String(localized: "watch_on \(service.displayName)"))
                        .font(.custom(.jetbrains.bold, size: 11))
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(service.brandColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(service.brandColor.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }

    private func openStreamingApp(service: StreamingService) {
        // Try deep link first, fall back to web URL
        if let deepLink = service.deepLinkURL(for: showName),
           UIApplication.shared.canOpenURL(deepLink) {
            openURL(deepLink)
        } else if let webURL = service.webURL(for: showName) {
            openURL(webURL)
        }
    }
}

// MARK: - Streaming Service

enum StreamingService {
    case netflix
    case appleTV
    case amazonPrime
    case disneyPlus
    case hulu
    case max
    case paramountPlus
    case peacock
    case starz
    case showtime
    case amc
    case fx
    case hbo

    var displayName: String {
        switch self {
        case .netflix: return "Netflix"
        case .appleTV: return "Apple TV+"
        case .amazonPrime: return "Prime Video"
        case .disneyPlus: return "Disney+"
        case .hulu: return "Hulu"
        case .max: return "Max"
        case .paramountPlus: return "Paramount+"
        case .peacock: return "Peacock"
        case .starz: return "STARZ"
        case .showtime: return "Showtime"
        case .amc: return "AMC+"
        case .fx: return "FX"
        case .hbo: return "Max"
        }
    }

    var brandColor: Color {
        switch self {
        case .netflix: return Color(red: 0.89, green: 0.09, blue: 0.14)
        case .appleTV: return Color.white
        case .amazonPrime: return Color(red: 0.0, green: 0.66, blue: 0.94)
        case .disneyPlus: return Color(red: 0.07, green: 0.21, blue: 0.55)
        case .hulu: return Color(red: 0.11, green: 0.83, blue: 0.47)
        case .max: return Color(white: 0.7)
        case .paramountPlus: return Color(red: 0.0, green: 0.38, blue: 0.91)
        case .peacock: return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .starz: return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .showtime: return Color(red: 0.78, green: 0.05, blue: 0.18)
        case .amc: return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .fx: return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .hbo: return Color(white: 0.7)
        }
    }

    func deepLinkURL(for showName: String) -> URL? {
        let encoded = showName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? showName

        switch self {
        case .netflix:
            return URL(string: "netflix://search?q=\(encoded)")
        case .appleTV:
            return URL(string: "https://tv.apple.com/search?term=\(encoded)")
        case .amazonPrime:
            return URL(string: "aiv://aiv/search?searchTerm=\(encoded)")
        case .disneyPlus:
            return URL(string: "disneyplus://search?q=\(encoded)")
        case .hulu:
            return URL(string: "hulu://search?query=\(encoded)")
        case .max:
            return URL(string: "hbomax://search?q=\(encoded)")
        case .paramountPlus:
            return URL(string: "paramountplus://search?q=\(encoded)")
        case .peacock:
            return URL(string: "peacock://search?q=\(encoded)")
        case .starz:
            return URL(string: "starz://search?q=\(encoded)")
        case .showtime:
            return URL(string: "showtime://search?q=\(encoded)")
        case .amc:
            return URL(string: "amcplus://search?q=\(encoded)")
        case .fx:
            // FX shows are on Hulu
            return URL(string: "hulu://search?query=\(encoded)")
        case .hbo:
            return URL(string: "hbomax://search?q=\(encoded)")
        }
    }

    func webURL(for showName: String) -> URL? {
        let encoded = showName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? showName

        switch self {
        case .netflix:
            return URL(string: "https://www.netflix.com/search?q=\(encoded)")
        case .appleTV:
            return URL(string: "https://tv.apple.com/search?term=\(encoded)")
        case .amazonPrime:
            return URL(string: "https://www.amazon.com/s?k=\(encoded)&i=instant-video")
        case .disneyPlus:
            return URL(string: "https://www.disneyplus.com/search?q=\(encoded)")
        case .hulu:
            return URL(string: "https://www.hulu.com/search?q=\(encoded)")
        case .max:
            return URL(string: "https://www.max.com/search?q=\(encoded)")
        case .paramountPlus:
            return URL(string: "https://www.paramountplus.com/search/?q=\(encoded)")
        case .peacock:
            return URL(string: "https://www.peacocktv.com/search?q=\(encoded)")
        case .starz:
            return URL(string: "https://www.starz.com/search?q=\(encoded)")
        case .showtime:
            return URL(string: "https://www.sho.com/search?q=\(encoded)")
        case .amc:
            return URL(string: "https://www.amcplus.com/search?q=\(encoded)")
        case .fx:
            return URL(string: "https://www.hulu.com/search?q=\(encoded)")
        case .hbo:
            return URL(string: "https://www.max.com/search?q=\(encoded)")
        }
    }

    // MARK: - Network Mapping

    static func from(networkId: Int, networkName: String) -> StreamingService? {
        // TMDB Network IDs
        switch networkId {
        case 213: return .netflix           // Netflix
        case 2552: return .appleTV          // Apple TV+
        case 1024: return .amazonPrime      // Amazon Prime Video
        case 2739: return .disneyPlus       // Disney+
        case 453: return .hulu              // Hulu
        case 3186: return .max              // Max (HBO Max)
        case 4330: return .paramountPlus    // Paramount+
        case 3353: return .peacock          // Peacock
        case 318: return .starz             // Starz
        case 67: return .showtime           // Showtime
        case 174: return .amc               // AMC
        case 88: return .fx                 // FX
        case 49: return .hbo                // HBO
        default: break
        }

        // Fallback to name matching
        let lowercased = networkName.lowercased()
        if lowercased.contains("netflix") { return .netflix }
        if lowercased.contains("apple") { return .appleTV }
        if lowercased.contains("amazon") || lowercased.contains("prime") { return .amazonPrime }
        if lowercased.contains("disney") { return .disneyPlus }
        if lowercased.contains("hulu") { return .hulu }
        if lowercased.contains("max") || lowercased.contains("hbo") { return .max }
        if lowercased.contains("paramount") { return .paramountPlus }
        if lowercased.contains("peacock") { return .peacock }
        if lowercased.contains("starz") { return .starz }
        if lowercased.contains("showtime") { return .showtime }
        if lowercased.contains("amc") { return .amc }
        if lowercased.contains("fx") { return .fx }

        return nil
    }
}
