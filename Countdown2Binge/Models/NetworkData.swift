//
//  NetworkData.swift
//  Countdown2Binge
//
//  Domain model for a TV network.
//

import Foundation

struct NetworkData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?

    var logoURL: URL? {
        TMDBConfiguration.imageURL(path: logoPath, size: .logo)
    }
}
