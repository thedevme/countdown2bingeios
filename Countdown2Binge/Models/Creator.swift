//
//  Creator.swift
//  Countdown2Binge
//
//  Domain model for a TV show creator.
//

import Foundation

struct Creator: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let profilePath: String?

    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "\(TMDBConfiguration.imageBaseURL)/w185\(profilePath)")
    }
}
