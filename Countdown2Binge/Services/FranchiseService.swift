//
//  FranchiseService.swift
//  Countdown2Binge
//
//  Fetches franchise data from Firebase and provides O(1) lookups.
//

import Foundation
// import FirebaseDatabase  // Uncomment when Firebase SDK is added

/// Service for fetching and querying franchise/spinoff data
@MainActor
final class FranchiseService {
    static let shared = FranchiseService()

    /// All loaded franchises
    private var franchises: [Franchise] = []

    /// O(1) lookup map: TMDB ID → Franchise
    private var showToFranchise: [Int: Franchise] = [:]

    /// Whether franchise data has been loaded
    private(set) var isLoaded: Bool = false

    private init() {}

    // MARK: - Public API

    /// Fetch franchises from Firebase (call on app launch or when needed)
    func fetchFranchises() async {
        // Don't refetch if already loaded
        guard !isLoaded else { return }

        do {
            // TODO: Replace with actual Firebase fetch when SDK is added
            // let snapshot = try await Database.database().reference().child("franchises").getData()
            // franchises = parseFranchises(from: snapshot)

            // For now, use bundled JSON or mock data
            franchises = loadBundledFranchises()
            buildLookupMap()
            isLoaded = true
            print("FranchiseService: Loaded \(franchises.count) franchises")
        } catch {
            print("FranchiseService: Failed to fetch franchises - \(error)")
        }
    }

    /// Get franchise for a show (O(1) lookup)
    /// - Parameter tmdbId: The TMDB ID of the show
    /// - Returns: The franchise if the show belongs to one, nil otherwise
    func franchise(forShowId tmdbId: Int) -> Franchise? {
        return showToFranchise[tmdbId]
    }

    /// Get related show IDs for a show (excluding itself)
    /// - Parameter tmdbId: The TMDB ID of the show
    /// - Returns: Array of related TMDB IDs, or empty if not part of a franchise
    func relatedShowIds(forShowId tmdbId: Int) -> [Int] {
        guard let franchise = franchise(forShowId: tmdbId) else {
            return []
        }

        return franchise.allTmdbIds.filter { $0 != tmdbId }
    }

    /// Check if a show is part of any franchise
    func isPartOfFranchise(tmdbId: Int) -> Bool {
        return showToFranchise[tmdbId] != nil
    }

    // MARK: - Private

    /// Build the O(1) lookup map
    private func buildLookupMap() {
        showToFranchise.removeAll()

        for franchise in franchises {
            // Map parent show
            showToFranchise[franchise.parentShow.tmdbId] = franchise

            // Map all spinoffs
            for spinoff in franchise.spinoffs {
                showToFranchise[spinoff.tmdbId] = franchise
            }
        }

        print("FranchiseService: Built lookup map with \(showToFranchise.count) entries")
    }

    /// Load franchises from bundled JSON file
    private func loadBundledFranchises() -> [Franchise] {
        guard let url = Bundle.main.url(forResource: "Franchises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("FranchiseService: No bundled Franchises.json found, using built-in data")
            return builtInFranchises()
        }

        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(FranchiseContainer.self, from: data)
            return container.franchises
        } catch {
            print("FranchiseService: Failed to decode Franchises.json - \(error)")
            return builtInFranchises()
        }
    }

    /// Built-in franchise data (fallback)
    private func builtInFranchises() -> [Franchise] {
        return [
            // Breaking Bad Universe
            Franchise(
                id: "breaking-bad",
                franchiseName: ["en": "Breaking Bad Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Breaking Bad", tmdbId: 1396, years: "2008-2013"),
                spinoffs: [
                    SpinoffShow(title: "Better Call Saul", tmdbId: 60059, years: "2015-2022", type: .prequel, status: .ended)
                ],
                watchOrder: WatchOrder(
                    release: ["Breaking Bad", "Better Call Saul"],
                    chronological: ["Better Call Saul", "Breaking Bad"]
                )
            ),

            // Game of Thrones
            Franchise(
                id: "game-of-thrones",
                franchiseName: ["en": "Game of Thrones Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Game of Thrones", tmdbId: 1399, years: "2011-2019"),
                spinoffs: [
                    SpinoffShow(title: "House of the Dragon", tmdbId: 94997, years: "2022-", type: .prequel, status: .returning),
                    SpinoffShow(title: "A Knight of the Seven Kingdoms", tmdbId: 209948, years: "2025-", type: .prequel, status: .upcoming)
                ],
                watchOrder: WatchOrder(
                    release: ["Game of Thrones", "House of the Dragon", "A Knight of the Seven Kingdoms"],
                    chronological: ["A Knight of the Seven Kingdoms", "House of the Dragon", "Game of Thrones"]
                )
            ),

            // The Walking Dead
            Franchise(
                id: "walking-dead",
                franchiseName: ["en": "The Walking Dead Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "The Walking Dead", tmdbId: 1402, years: "2010-2022"),
                spinoffs: [
                    SpinoffShow(title: "Fear the Walking Dead", tmdbId: 62286, years: "2015-2023", type: .companion, status: .ended),
                    SpinoffShow(title: "The Walking Dead: World Beyond", tmdbId: 94305, years: "2020-2021", type: .spinoff, status: .ended),
                    SpinoffShow(title: "The Walking Dead: Dead City", tmdbId: 194583, years: "2023-", type: .sequel, status: .returning),
                    SpinoffShow(title: "The Walking Dead: Daryl Dixon", tmdbId: 131237, years: "2023-", type: .sequel, status: .returning),
                    SpinoffShow(title: "The Walking Dead: The Ones Who Live", tmdbId: 206559, years: "2024", type: .sequel, status: .ended)
                ],
                watchOrder: nil
            ),

            // Yellowstone
            Franchise(
                id: "yellowstone",
                franchiseName: ["en": "Yellowstone Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Yellowstone", tmdbId: 73586, years: "2018-"),
                spinoffs: [
                    SpinoffShow(title: "1883", tmdbId: 125910, years: "2021-2022", type: .prequel, status: .ended),
                    SpinoffShow(title: "1923", tmdbId: 157065, years: "2022-", type: .prequel, status: .returning)
                ],
                watchOrder: WatchOrder(
                    release: ["Yellowstone", "1883", "1923"],
                    chronological: ["1883", "1923", "Yellowstone"]
                )
            ),

            // Money Heist
            Franchise(
                id: "money-heist",
                franchiseName: ["en": "Money Heist Universe", "es": "La Casa de Papel"],
                origin: "ES",
                parentShow: FranchiseShow(title: "Money Heist", tmdbId: 71446, years: "2017-2021"),
                spinoffs: [
                    SpinoffShow(title: "Money Heist: Korea", tmdbId: 135095, years: "2022-", type: .remake, status: .returning),
                    SpinoffShow(title: "Berlin", tmdbId: 210401, years: "2023-", type: .prequel, status: .returning)
                ],
                watchOrder: nil
            )
        ]
    }
}

// MARK: - JSON Decoding Container

private struct FranchiseContainer: Codable {
    let franchises: [Franchise]
}
