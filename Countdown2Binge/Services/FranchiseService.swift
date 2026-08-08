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

        // TODO: Replace with actual Firebase fetch when SDK is added
        // let snapshot = try await Database.database().reference().child("franchises").getData()
        // franchises = parseFranchises(from: snapshot)

        // For now, use bundled JSON or mock data
        franchises = loadBundledFranchises()
        buildLookupMap()
        isLoaded = true
        print("FranchiseService: Loaded \(franchises.count) franchises")
    }

    /// Get franchise for a show (O(1) lookup)
    /// - Parameter tmdbId: The TMDB ID of the show
    /// - Returns: The franchise if the show belongs to one, nil otherwise
    func franchise(forShowId tmdbId: Int) -> Franchise? {
        return showToFranchise[tmdbId]
    }

    /// Get related show IDs for a show (excluding itself) - sync version.
    /// - Parameter tmdbId: The TMDB ID of the show
    /// - Returns: Array of related TMDB IDs, or empty if not part of a franchise
    func getRelatedShowIds(forShowId tmdbId: Int) -> [Int] {
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
            print("FranchiseService: Mapped \(franchise.parentShow.title) (ID: \(franchise.parentShow.tmdbId)) -> \(franchise.localizedName())")

            // Map all spinoffs
            for spinoff in franchise.spinoffs {
                showToFranchise[spinoff.tmdbId] = franchise
                print("FranchiseService: Mapped \(spinoff.title) (ID: \(spinoff.tmdbId)) -> \(franchise.localizedName())")
            }
        }

        print("FranchiseService: Built lookup map with \(showToFranchise.count) entries")
        print("FranchiseService: All mapped IDs: \(Array(showToFranchise.keys).sorted())")
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
                parentShow: FranchiseShow(title: "Breaking Bad", tmdbId: 1396, years: "2008-2013", posterPath: "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg"),
                spinoffs: [
                    SpinoffShow(title: "Better Call Saul", tmdbId: 60059, years: "2015-2022", type: .prequel, status: .ended, posterPath: "/fC2HDm5t0kHl7mTm7jxMR31b7by.jpg")
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
                parentShow: FranchiseShow(title: "Game of Thrones", tmdbId: 1399, years: "2011-2019", posterPath: "/suopoADq0k8YZr4dQXcU6pToj6s.jpg"),
                spinoffs: [
                    SpinoffShow(title: "House of the Dragon", tmdbId: 94997, years: "2022-", type: .prequel, status: .returning, posterPath: "/7QMsOTMUswlwxJP0rTTZfmz2tX2.jpg"),
                    SpinoffShow(title: "A Knight of the Seven Kingdoms", tmdbId: 209948, years: "2025-", type: .prequel, status: .upcoming, posterPath: "/serB0IcG2m1qJDA2e9pxQ7AEhW7.jpg")
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
                parentShow: FranchiseShow(title: "The Walking Dead", tmdbId: 1402, years: "2010-2022", posterPath: "/xf9wuDcqlUPWABZNeDKPbZUjWx0.jpg"),
                spinoffs: [
                    SpinoffShow(title: "Fear the Walking Dead", tmdbId: 62286, years: "2015-2023", type: .companion, status: .ended, posterPath: "/4UjiPdFKJGJYdxwRs2Rzg7EmWqr.jpg"),
                    SpinoffShow(title: "The Walking Dead: World Beyond", tmdbId: 94305, years: "2020-2021", type: .spinoff, status: .ended, posterPath: "/z31GxpVgDsFAF4paZR8PRsiP16D.jpg"),
                    SpinoffShow(title: "The Walking Dead: Dead City", tmdbId: 194583, years: "2023-", type: .sequel, status: .returning, posterPath: "/b6irp6Jj4Lqpwp0DSZ6NEPe39m.jpg"),
                    SpinoffShow(title: "The Walking Dead: Daryl Dixon", tmdbId: 131237, years: "2023-", type: .sequel, status: .returning, posterPath: "/36vj0jsJYZs8D5S2W5BqwpYGN4.jpg"),
                    SpinoffShow(title: "The Walking Dead: The Ones Who Live", tmdbId: 206559, years: "2024", type: .sequel, status: .ended, posterPath: "/lIrHbxn2r3FfhK8EEbqLZtbEJZ1.jpg")
                ],
                watchOrder: nil
            ),

            // Yellowstone
            Franchise(
                id: "yellowstone",
                franchiseName: ["en": "Yellowstone Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Yellowstone", tmdbId: 73586, years: "2018-", posterPath: "/peNC0eyc3TQJa6x4TdKcBPNP4t0.jpg"),
                spinoffs: [
                    SpinoffShow(title: "1883", tmdbId: 125910, years: "2021-2022", type: .prequel, status: .ended, posterPath: "/waGLPC0zaFIAyOJ3aXeNfjKj4uh.jpg"),
                    SpinoffShow(title: "1923", tmdbId: 157065, years: "2022-", type: .prequel, status: .returning, posterPath: "/8MZsH2OZwuiGPGUagGVzQgYmf0H.jpg")
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
                parentShow: FranchiseShow(title: "Money Heist", tmdbId: 71446, years: "2017-2021", posterPath: "/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg"),
                spinoffs: [
                    SpinoffShow(title: "Money Heist: Korea", tmdbId: 135095, years: "2022-", type: .remake, status: .returning, posterPath: "/pJpN3IHqL9iIAGaqeJzNvAEykN9.jpg"),
                    SpinoffShow(title: "Berlin", tmdbId: 210401, years: "2023-", type: .prequel, status: .returning, posterPath: "/69YjCvdx8rPN7z7MqLlgXGvE2J5.jpg")
                ],
                watchOrder: nil
            ),

            // Reacher
            Franchise(
                id: "reacher",
                franchiseName: ["en": "Reacher Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Reacher", tmdbId: 108978, years: "2022-", posterPath: "/9Wnmqxn7eJMGhQd3sBPBmY0Bmbi.jpg"),
                spinoffs: [
                    SpinoffShow(title: "Neagley", tmdbId: 999001, years: "TBA", type: .spinoff, status: .inProduction, posterPath: nil),
                    SpinoffShow(title: "The 110th", tmdbId: 999002, years: "TBA", type: .prequel, status: .inProduction, posterPath: nil),
                    SpinoffShow(title: "Dixon", tmdbId: 999003, years: "TBA", type: .spinoff, status: .inProduction, posterPath: nil),
                    SpinoffShow(title: "O'Donnell", tmdbId: 999004, years: "TBA", type: .spinoff, status: .inProduction, posterPath: nil)
                ],
                watchOrder: nil
            ),

            // The Witcher
            Franchise(
                id: "witcher",
                franchiseName: ["en": "The Witcher Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "The Witcher", tmdbId: 71912, years: "2019-", posterPath: "/7vjaCdMw15FEbXyLQTVa04URsPm.jpg"),
                spinoffs: [
                    SpinoffShow(title: "The Witcher: Blood Origin", tmdbId: 106541, years: "2022", type: .prequel, status: .ended, posterPath: "/vpfJK9F0UJNcAIITHSAoVhixoYs.jpg"),
                    SpinoffShow(title: "The Witcher: Nightmare of the Wolf", tmdbId: 814675, years: "2021", type: .prequel, status: .ended, posterPath: nil),
                    SpinoffShow(title: "The Witcher: Sirens of the Deep", tmdbId: 950387, years: "2025", type: .spinoff, status: .upcoming, posterPath: nil)
                ],
                watchOrder: WatchOrder(
                    release: ["The Witcher: Nightmare of the Wolf", "The Witcher", "The Witcher: Blood Origin"],
                    chronological: ["The Witcher: Blood Origin", "The Witcher: Nightmare of the Wolf", "The Witcher"]
                )
            ),

            // Daredevil / Marvel Netflix
            Franchise(
                id: "daredevil",
                franchiseName: ["en": "Daredevil Universe"],
                origin: "US",
                parentShow: FranchiseShow(title: "Daredevil", tmdbId: 61889, years: "2015-2018", posterPath: "/QWbPaDxiB6LW2LjASknzYBvjMj.jpg"),
                spinoffs: [
                    SpinoffShow(title: "The Punisher", tmdbId: 67178, years: "2017-2019", type: .spinoff, status: .ended, posterPath: "/lMYshWCk7PhG2GmZvQ5ISYanmF8.jpg"),
                    SpinoffShow(title: "Echo", tmdbId: 122226, years: "2024", type: .spinoff, status: .ended, posterPath: "/vLTq7zOmurQQFTcODyWCjpIsKSR.jpg"),
                    SpinoffShow(title: "Daredevil: Born Again", tmdbId: 202555, years: "2025-", type: .sequel, status: .returning, posterPath: "/vaCg3xKrnJz03Hu7jJWLnwddXB5.jpg")
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

// MARK: - FranchiseResolving Conformance

extension FranchiseService: FranchiseResolving {
    /// Async wrapper for relatedShowIds to conform to FranchiseResolving protocol.
    func relatedShowIds(forShowId showId: Int) async -> [Int] {
        // Ensure franchises are loaded
        await fetchFranchises()
        return getRelatedShowIds(forShowId: showId)
    }
}
