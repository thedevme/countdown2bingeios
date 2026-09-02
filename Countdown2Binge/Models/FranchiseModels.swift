//
//  FranchiseModels.swift
//  Countdown2Binge
//
//  Models for franchise/spinoff data.
//
//  Schema note: these decode the shape the franchise feed actually ships
//  (Resources/Franchises.json today, the API later) — NOT an idealized one:
//    • `franchises` is an object keyed by id, so `id` comes from the key.
//    • `origin` is absent from every entry.
//    • `watchOrder` entries are objects ({title, note}), not bare strings.
//    • `status` uses "active", which predates this enum.
//  Decoding is deliberately lenient: one unrecognized type/status must not
//  throw away the whole file, because the loader's fallback is 8 hardcoded
//  franchises and the failure would look exactly like the feed working.
//

import Foundation

/// A franchise containing a parent show and its spinoffs
struct Franchise: Identifiable, Codable {
    let id: String
    let franchiseName: [String: String]  // Localized names: ["en": "Breaking Bad Universe", "es": "..."]
    /// Absent from the current feed; kept optional rather than dropped so a
    /// later API that does send it decodes without another model change.
    let origin: String?
    let parentShow: FranchiseShow
    let spinoffs: [SpinoffShow]
    let watchOrder: WatchOrder?

    /// Get localized franchise name
    func localizedName(for locale: String = "en") -> String {
        franchiseName[locale] ?? franchiseName["en"] ?? id
    }

    /// All TMDB IDs in this franchise (parent + spinoffs)
    var allTmdbIds: [Int] {
        [parentShow.tmdbId] + spinoffs.map { $0.tmdbId }
    }
}

/// A show within a franchise (parent or spinoff)
struct FranchiseShow: Codable {
    let title: String
    let tmdbId: Int
    let years: String
    let posterPath: String?

    init(title: String, tmdbId: Int, years: String, posterPath: String? = nil) {
        self.title = title
        self.tmdbId = tmdbId
        self.years = years
        self.posterPath = posterPath
    }
}

/// A spinoff show with additional metadata
struct SpinoffShow: Codable {
    let title: String
    let tmdbId: Int
    let years: String
    let type: SpinoffType
    let status: SpinoffStatus
    let posterPath: String?

    init(title: String, tmdbId: Int, years: String, type: SpinoffType, status: SpinoffStatus, posterPath: String? = nil) {
        self.title = title
        self.tmdbId = tmdbId
        self.years = years
        self.type = type
        self.status = status
        self.posterPath = posterPath
    }

    enum SpinoffType: String, Codable {
        case prequel
        case sequel
        case companion
        case remake
        case spinoff

        /// Unrecognized values fall back to the generic case rather than
        /// throwing — a new type on the server must not blank the feed.
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = SpinoffType(rawValue: raw) ?? .spinoff
        }
    }

    enum SpinoffStatus: String, Codable {
        case ended
        case returning
        case upcoming
        case inProduction = "in_production"

        /// The feed says "active" where this enum says "returning". Aliased
        /// here rather than renaming the case, which the UI switches on.
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "active": self = .returning
            default: self = SpinoffStatus(rawValue: raw) ?? .ended
            }
        }
    }
}

/// Watch order options for a franchise.
///
/// Nothing renders this yet — `SpinoffsWatchOrderTimeline` derives its order
/// from `spinoffs` + `type`. It is decoded only so its presence cannot fail
/// the whole file.
struct WatchOrder: Codable {
    let release: [WatchOrderEntry]
    let chronological: [WatchOrderEntry]
}

/// One step in a watch order. The feed sends `{title, note: {lang: text}}`;
/// earlier docs showed a bare string. Both decode.
struct WatchOrderEntry: Codable {
    let title: String
    let note: [String: String]?

    init(title: String, note: [String: String]? = nil) {
        self.title = title
        self.note = note
    }

    /// Localized note, same fallback chain as `Franchise.localizedName`.
    func localizedNote(for locale: String = "en") -> String? {
        note?[locale] ?? note?["en"]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let title = try? container.decode(String.self) {
            self.title = title
            self.note = nil
            return
        }
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try keyed.decode(String.self, forKey: .title)
        self.note = try keyed.decodeIfPresent([String: String].self, forKey: .note)
    }
}

/// Lets the hardcoded fallback in `FranchiseService` keep writing watch orders
/// as plain string arrays.
extension WatchOrderEntry: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(title: value, note: nil)
    }
}
