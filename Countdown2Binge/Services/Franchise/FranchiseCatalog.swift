//
//  FranchiseCatalog.swift
//  Countdown2Binge
//
//  Local, bundled franchise/spin-off catalog with era grouping. Engine only —
//  no view code lives here.
//
//  A second franchise system alongside the existing FranchiseService /
//  Franchises.json (see FranchiseModels.swift) — this one does not touch,
//  replace, or share types with it. FollowedShowDetail's Spinoffs tab now
//  renders off THIS engine (SpinoffsEraSection); FranchiseService/
//  FranchiseModels remain in place only for SeriesManager.resolveSpinoffs'
//  follow-time related-id caching (FranchiseResolving), which nothing here
//  touches. Series and SeriesManager itself are untouched.
//

import Foundation

// MARK: - JSON DTOs

/// Top-level shape of `spinoffs_multilang.json`: { "franchises": { "<key>": FranchiseRecordDTO } }
struct FranchiseCatalogFileDTO: Decodable {
    let franchises: [String: FranchiseRecordDTO]
}

/// One franchise entry keyed by its franchise id (e.g. "breaking-bad").
struct FranchiseRecordDTO: Decodable {
    let franchiseName: [String: String]
    let parentShow: FranchiseParentShowDTO
    let spinoffs: [FranchiseSpinoffDTO]
    let watchOrder: FranchiseWatchOrderDTO

    private enum CodingKeys: String, CodingKey {
        case franchiseName, parentShow, spinoffs, watchOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        franchiseName = try container.decode([String: String].self, forKey: .franchiseName)
        parentShow = try container.decode(FranchiseParentShowDTO.self, forKey: .parentShow)
        spinoffs = try container.decodeIfPresent([FranchiseSpinoffDTO].self, forKey: .spinoffs) ?? []

        // A malformed watchOrder must never fail the whole franchise decode.
        // Fall back to an empty watch order instead of propagating the error.
        if let decodedWatchOrder = try? container.decode(FranchiseWatchOrderDTO.self, forKey: .watchOrder) {
            watchOrder = decodedWatchOrder
        } else {
            watchOrder = FranchiseWatchOrderDTO(release: [], chronological: [])
        }
    }
}

struct FranchiseParentShowDTO: Decodable {
    let title: String
    let tmdbId: Int
    let years: String
    let mediaType: String?
}

struct FranchiseSpinoffDTO: Decodable {
    let title: String
    let tmdbId: Int
    let years: String
    let type: String
    let status: String
    let mediaType: String?
}

struct FranchiseWatchOrderDTO: Decodable {
    let release: [FranchiseWatchOrderItemDTO]
    let chronological: [FranchiseWatchOrderItemDTO]

    init(release: [FranchiseWatchOrderItemDTO], chronological: [FranchiseWatchOrderItemDTO]) {
        self.release = release
        self.chronological = chronological
    }

    private enum CodingKeys: String, CodingKey {
        case release, chronological
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        release = try container.decodeIfPresent([FranchiseWatchOrderItemDTO].self, forKey: .release) ?? []
        chronological = try container.decodeIfPresent([FranchiseWatchOrderItemDTO].self, forKey: .chronological) ?? []
    }
}

struct FranchiseWatchOrderItemDTO: Decodable {
    let title: String
    let note: [String: String]
}

// MARK: - Media Type & Identity

/// TMDB uses separate id namespaces for TV and movies, so a bare tmdbId is not
/// unique on its own — every lookup/index/identity check must use `MediaKey`.
enum FranchiseMediaType: String, Codable, Sendable {
    case tv
    case movie

    /// Lenient resolution: an unrecognized or missing raw value defaults to `.tv`.
    init(lenientRawValue raw: String?) {
        guard let raw, let matched = FranchiseMediaType(rawValue: raw) else {
            self = .tv
            return
        }
        self = matched
    }
}

struct MediaKey: Hashable, Sendable {
    let tmdbId: Int
    let mediaType: FranchiseMediaType
}

// MARK: - Output Types

/// A franchise's full spin-off catalog, already localized and grouped for display.
struct FranchiseGroup: Sendable {
    let franchiseName: String
    let sections: [FranchiseSection]
    let showsSectionHeaders: Bool
    let totalEntryCount: Int
}

struct FranchiseSection: Sendable {
    let bucket: FranchiseBucket
    let title: String
    let entries: [FranchiseEntry]
}

/// rawValue defines display order.
enum FranchiseBucket: Int, CaseIterable, Sendable {
    case before = 0
    case main = 1
    case alongside = 2
    case after = 3
}

struct FranchiseEntry: Identifiable, Sendable {
    let id: MediaKey
    let tmdbId: Int
    let mediaType: FranchiseMediaType
    let title: String
    let years: String
    /// 1-based, continuous across all emitted sections in final display order.
    let displayNumber: Int
    let relationLabel: String
    let statusLabel: String?
    let note: String?
    let isCurrentShow: Bool
    let isMainSeries: Bool

    var isFollowable: Bool { mediaType == .tv }
}

// MARK: - Provider Protocol

protocol FranchiseProviding {
    func franchise(forShowId id: Int, mediaType: FranchiseMediaType, locale: Locale) async -> FranchiseGroup?
}

extension FranchiseProviding {
    func franchise(forShowId id: Int, locale: Locale) async -> FranchiseGroup? {
        await franchise(forShowId: id, mediaType: .tv, locale: locale)
    }
}

// MARK: - Bundled Provider

/// Reads franchise/spin-off data from a bundled JSON file. Decodes lazily on
/// first access and caches the result (and a reverse `MediaKey -> franchise key`
/// index) for the lifetime of the instance.
actor BundledFranchiseProvider: FranchiseProviding {
    static let shared = BundledFranchiseProvider()

    private let dataLoader: @Sendable () -> Data?

    private var franchisesByKey: [String: FranchiseRecordDTO]?
    private var reverseIndex: [MediaKey: String] = [:]

    /// Loads from a bundled JSON resource (the app's real catalog by default).
    init(bundle: Bundle = .main, resourceName: String = "spinoffs_multilang") {
        dataLoader = {
            guard let url = bundle.url(forResource: resourceName, withExtension: "json") else { return nil }
            return try? Data(contentsOf: url)
        }
    }

    /// Loads from raw JSON data directly — primarily for tests/fixtures.
    init(data: Data) {
        dataLoader = { data }
    }

    func franchise(forShowId id: Int, mediaType: FranchiseMediaType, locale: Locale) async -> FranchiseGroup? {
        loadIfNeeded()
        let key = MediaKey(tmdbId: id, mediaType: mediaType)
        guard let franchiseKey = reverseIndex[key], let record = franchisesByKey?[franchiseKey] else {
            return nil
        }
        return FranchiseCatalogBuilder.buildGroup(from: record, currentShow: key, locale: locale)
    }

    /// Number of franchises currently loaded (loads if needed). Test/debug hook.
    func franchiseCount() -> Int {
        loadIfNeeded()
        return franchisesByKey?.count ?? 0
    }

    /// Total number of parent+spinoff entries across all franchises. Test/debug hook.
    func totalEntryCount() -> Int {
        loadIfNeeded()
        return franchisesByKey?.values.reduce(0) { $0 + 1 + $1.spinoffs.count } ?? 0
    }

    /// Forces a reload on the next access. Test/debug hook.
    func invalidateCache() {
        franchisesByKey = nil
        reverseIndex.removeAll()
    }

    /// Builds every franchise's group, keyed on its own parent show. Test/debug hook
    /// for exercising bucketing/sorting/numbering across the whole catalog at once.
    func allFranchiseGroups(locale: Locale = Locale(identifier: "en")) -> [FranchiseGroup] {
        loadIfNeeded()
        guard let all = franchisesByKey else { return [] }
        return all.values.map { record in
            let mediaType = FranchiseMediaType(lenientRawValue: record.parentShow.mediaType)
            let key = MediaKey(tmdbId: record.parentShow.tmdbId, mediaType: mediaType)
            return FranchiseCatalogBuilder.buildGroup(from: record, currentShow: key, locale: locale)
        }
    }

    private func loadIfNeeded() {
        guard franchisesByKey == nil else { return }

        guard let data = dataLoader(),
              let fileDTO = try? JSONDecoder().decode(FranchiseCatalogFileDTO.self, from: data) else {
            franchisesByKey = [:]
            return
        }

        franchisesByKey = fileDTO.franchises
        buildReverseIndex(from: fileDTO.franchises)
    }

    private func buildReverseIndex(from franchises: [String: FranchiseRecordDTO]) {
        reverseIndex.removeAll()
        for (franchiseKey, record) in franchises {
            let parentMediaType = FranchiseMediaType(lenientRawValue: record.parentShow.mediaType)
            reverseIndex[MediaKey(tmdbId: record.parentShow.tmdbId, mediaType: parentMediaType)] = franchiseKey

            for spinoff in record.spinoffs {
                let spinoffMediaType = FranchiseMediaType(lenientRawValue: spinoff.mediaType)
                reverseIndex[MediaKey(tmdbId: spinoff.tmdbId, mediaType: spinoffMediaType)] = franchiseKey
            }
        }
    }
}

// MARK: - Group Builder

/// Pure, synchronous transformation from a decoded franchise record to the
/// localized, bucketed `FranchiseGroup` the view layer consumes. `internal`
/// (not file-private) so bucketing/sorting/numbering can be unit tested
/// directly, without going through the actor.
enum FranchiseCatalogBuilder {

    /// Intermediate representation before bucketing/sorting/numbering.
    struct RawEntry {
        let bucket: FranchiseBucket
        let mediaKey: MediaKey
        let title: String
        let years: String
        let sortYear: Int?
        let relationLabel: String
        let statusLabel: String?
        let note: String?
        let isMainSeries: Bool
    }

    static func buildGroup(from record: FranchiseRecordDTO, currentShow: MediaKey, locale: Locale) -> FranchiseGroup {
        let languageCode = FranchiseLocalization.languageCode(for: locale)

        var rawEntries: [RawEntry] = []
        rawEntries.append(parentRawEntry(from: record, languageCode: languageCode))
        for spinoff in record.spinoffs {
            rawEntries.append(spinoffRawEntry(spinoff, watchOrder: record.watchOrder, languageCode: languageCode))
        }

        var entriesByBucket: [FranchiseBucket: [RawEntry]] = [:]
        for entry in rawEntries {
            entriesByBucket[entry.bucket, default: []].append(entry)
        }

        var sections: [FranchiseSection] = []
        var displayNumber = 0

        for bucket in FranchiseBucket.allCases {
            guard let bucketEntries = entriesByBucket[bucket], !bucketEntries.isEmpty else { continue }

            let sortedEntries = stableSorted(bucketEntries)
            var builtEntries: [FranchiseEntry] = []
            builtEntries.reserveCapacity(sortedEntries.count)

            for raw in sortedEntries {
                displayNumber += 1
                builtEntries.append(FranchiseEntry(
                    id: raw.mediaKey,
                    tmdbId: raw.mediaKey.tmdbId,
                    mediaType: raw.mediaKey.mediaType,
                    title: raw.title,
                    years: raw.years,
                    displayNumber: displayNumber,
                    relationLabel: raw.relationLabel,
                    statusLabel: raw.statusLabel,
                    note: raw.note,
                    isCurrentShow: raw.mediaKey == currentShow,
                    isMainSeries: raw.isMainSeries
                ))
            }

            sections.append(FranchiseSection(
                bucket: bucket,
                title: sectionTitle(for: bucket),
                entries: builtEntries
            ))
        }

        let totalEntryCount = rawEntries.count

        return FranchiseGroup(
            franchiseName: FranchiseLocalization.resolve(record.franchiseName, languageCode: languageCode),
            sections: sections,
            // Always shown, unconditionally — every franchise gets its era
            // headers, even one like Game of Thrones where every spin-off
            // happens to land in the same bucket (both prequels), or one
            // with no spin-offs at all (a single "Main Series" header).
            showsSectionHeaders: true,
            totalEntryCount: totalEntryCount
        )
    }

    // MARK: Raw Entry Construction

    private static func parentRawEntry(from record: FranchiseRecordDTO, languageCode: String) -> RawEntry {
        let mediaType = FranchiseMediaType(lenientRawValue: record.parentShow.mediaType)
        let mediaKey = MediaKey(tmdbId: record.parentShow.tmdbId, mediaType: mediaType)
        return RawEntry(
            bucket: .main,
            mediaKey: mediaKey,
            title: record.parentShow.title,
            years: record.parentShow.years,
            sortYear: parseStartYear(record.parentShow.years),
            relationLabel: String(localized: "franchise_relation_main"),
            statusLabel: nil,
            note: findNote(forTitle: record.parentShow.title, in: record.watchOrder, languageCode: languageCode),
            isMainSeries: true
        )
    }

    private static func spinoffRawEntry(
        _ spinoff: FranchiseSpinoffDTO,
        watchOrder: FranchiseWatchOrderDTO,
        languageCode: String
    ) -> RawEntry {
        let mediaType = FranchiseMediaType(lenientRawValue: spinoff.mediaType)
        let mediaKey = MediaKey(tmdbId: spinoff.tmdbId, mediaType: mediaType)
        return RawEntry(
            bucket: bucket(forType: spinoff.type),
            mediaKey: mediaKey,
            title: spinoff.title,
            years: spinoff.years,
            sortYear: parseStartYear(spinoff.years),
            relationLabel: relationLabel(forType: spinoff.type),
            statusLabel: statusLabel(forStatus: spinoff.status),
            note: findNote(forTitle: spinoff.title, in: watchOrder, languageCode: languageCode),
            isMainSeries: false
        )
    }

    // MARK: Bucketing

    private static func bucket(forType type: String) -> FranchiseBucket {
        switch type {
        case "prequel": return .before
        case "companion": return .alongside
        case "sequel": return .after
        default: return .alongside
        }
    }

    // MARK: Sorting

    /// Ascending by start year; entries with no parseable year sort last.
    /// Ties broken explicitly by original (source) index rather than relying
    /// on `sorted(by:)`'s stability guarantee — correct either way on modern
    /// toolchains, but this makes it correct by construction and impossible
    /// to regress if that ever changes.
    static func stableSorted(_ entries: [RawEntry]) -> [RawEntry] {
        entries.enumerated()
            .sorted { lhs, rhs in
                let lhsKey = (lhs.element.sortYear ?? .max, lhs.offset)
                let rhsKey = (rhs.element.sortYear ?? .max, rhs.offset)
                return lhsKey < rhsKey
            }
            .map(\.element)
    }

    /// Parses the first run of 4 consecutive digits in `years` (e.g. "2019-present" -> 2019).
    /// Returns nil for anything without one (e.g. "TBA"). Never throws.
    static func parseStartYear(_ years: String) -> Int? {
        var digits = ""
        for character in years {
            if character.isNumber {
                digits.append(character)
                if digits.count == 4 {
                    return Int(digits)
                }
            } else {
                digits = ""
            }
        }
        return nil
    }

    // MARK: Labels
    //
    // UI labels (era/relation/status) resolve via String(localized:) — the
    // app's normal, device-locale-driven mechanism, same as every other
    // string in the app. Only the JSON-embedded values below (franchiseName,
    // watchOrder notes) need FranchiseLocalization's explicit-locale
    // resolution, because those dictionaries carry 10 languages independent
    // of the device's own locale.

    private static func sectionTitle(for bucket: FranchiseBucket) -> String {
        switch bucket {
        case .before: return String(localized: "franchise_era_before")
        case .main: return String(localized: "franchise_era_main")
        case .alongside: return String(localized: "franchise_era_alongside")
        case .after: return String(localized: "franchise_era_after")
        }
    }

    private static func relationLabel(forType type: String) -> String {
        switch type {
        case "prequel": return String(localized: "franchise_relation_prequel")
        case "sequel": return String(localized: "franchise_relation_sequel")
        default: return String(localized: "franchise_relation_companion")
        }
    }

    /// nil for "ended", "released", or any status without a defined label (e.g. "active").
    private static func statusLabel(forStatus status: String) -> String? {
        switch status {
        case "announced": return String(localized: "franchise_status_announced")
        case "in_development": return String(localized: "franchise_status_development")
        case "returning": return String(localized: "franchise_status_returning")
        default: return nil
        }
    }

    // MARK: Notes

    /// Exact, case-sensitive title match against `watchOrder.chronological` only.
    /// Never fuzzy-matches; unmatched rows never surface as entries or notes.
    private static func findNote(forTitle title: String, in watchOrder: FranchiseWatchOrderDTO, languageCode: String) -> String? {
        guard let item = watchOrder.chronological.first(where: { $0.title == title }) else { return nil }
        return FranchiseLocalization.resolve(item.note, languageCode: languageCode)
    }
}

// MARK: - Localization (JSON-embedded values only)

/// Resolves JSON-embedded multi-language values (franchiseName, notes)
/// against an explicit language code. UI labels (era/relation/status) do NOT
/// go through this — they use `String(localized:)` directly, same as the
/// rest of the app.
enum FranchiseLocalization {

    private static let supportedLanguageCodes: Set<String> = [
        "en", "es", "fr", "de", "pt", "it", "ja", "ko", "zh-Hans", "ar"
    ]

    /// Resolves a `Locale` to one of the ten supported codes, falling back to "en".
    static func languageCode(for locale: Locale) -> String {
        guard let rawCode = locale.language.languageCode?.identifier.lowercased() else { return "en" }
        if rawCode == "zh" { return "zh-Hans" }
        return supportedLanguageCodes.contains(rawCode) ? rawCode : "en"
    }

    /// Resolves a JSON-embedded multi-language dictionary (franchiseName, note) for `languageCode`.
    static func resolve(_ values: [String: String], languageCode: String) -> String {
        values[languageCode] ?? values["en"] ?? values.values.first ?? ""
    }
}
