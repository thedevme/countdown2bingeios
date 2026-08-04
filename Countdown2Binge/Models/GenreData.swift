//
//  GenreData.swift
//  Countdown2Binge
//
//  Domain model for a TV genre.
//

import Foundation

struct GenreData: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let name: String
}
