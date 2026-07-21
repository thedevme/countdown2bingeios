//
//  SeriesStore.swift
//  Countdown2Binge
//
//  Data access layer for Series/Season/Episode models.
//  Handles watch progress tracking and metadata updates.
//

import Foundation
import SwiftData

@MainActor
final class SeriesStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    /// Save or update a series from ShowData
    func save(from show: ShowData) throws {
        if let existing = fetchSeries(tmdbId: show.id) {
            // Update existing
            updateSeries(existing, from: show)
        } else {
            // Create new
            let series = createSeries(from: show)
            modelContext.insert(series)
        }
        try modelContext.save()
    }

    /// Delete a series
    func delete(tmdbId: Int) throws {
        guard let series = fetchSeries(tmdbId: tmdbId) else { return }
        modelContext.delete(series)
        try modelContext.save()
    }

    /// Fetch all series
    func fetchAll() throws -> [Series] {
        let descriptor = FetchDescriptor<Series>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a specific series
    func fetchSeries(tmdbId: Int) -> Series? {
        let descriptor = FetchDescriptor<Series>(
            predicate: #Predicate { $0.tmdbId == tmdbId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Watch Progress

    /// Toggle watched state for an episode
    func toggleEpisodeWatched(episodeId: Int) throws {
        let descriptor = FetchDescriptor<SeriesEpisode>(
            predicate: #Predicate { $0.tmdbId == episodeId }
        )

        guard let episode = try modelContext.fetch(descriptor).first else { return }

        episode.isWatched.toggle()
        episode.watchedAt = episode.isWatched ? Date() : nil
        try modelContext.save()
    }

    /// Mark an episode as watched
    func markEpisodeWatched(episodeId: Int, watched: Bool = true) throws {
        let descriptor = FetchDescriptor<SeriesEpisode>(
            predicate: #Predicate { $0.tmdbId == episodeId }
        )

        guard let episode = try modelContext.fetch(descriptor).first else { return }

        episode.isWatched = watched
        episode.watchedAt = watched ? Date() : nil
        try modelContext.save()
    }

    /// Mark all episodes in a season as watched
    func markSeasonWatched(seasonId: Int, watched: Bool = true) throws {
        let descriptor = FetchDescriptor<SeriesSeason>(
            predicate: #Predicate { $0.tmdbId == seasonId }
        )

        guard let season = try modelContext.fetch(descriptor).first else { return }

        let watchedAt = watched ? Date() : nil
        for episode in season.episodes {
            episode.isWatched = watched
            episode.watchedAt = watchedAt
        }
        try modelContext.save()
    }

    /// Mark all episodes up to a specific episode as watched
    func markWatchedUpTo(seriesId: Int, seasonNumber: Int, episodeNumber: Int) throws {
        guard let series = fetchSeries(tmdbId: seriesId) else { return }

        let watchedAt = Date()
        for season in series.seasons {
            for episode in season.episodes {
                if season.seasonNumber < seasonNumber ||
                    (season.seasonNumber == seasonNumber && episode.episodeNumber <= episodeNumber) {
                    episode.isWatched = true
                    episode.watchedAt = watchedAt
                }
            }
        }
        try modelContext.save()
    }

    // MARK: - Metadata Updates

    /// Update series metadata from fresh ShowData
    func updateMetadata(for tmdbId: Int, from show: ShowData) throws {
        guard let series = fetchSeries(tmdbId: tmdbId) else {
            // Create if doesn't exist
            try save(from: show)
            return
        }

        updateSeries(series, from: show)
        try modelContext.save()
    }

    // MARK: - Private Helpers

    private func createSeries(from show: ShowData) -> Series {
        let series = Series(
            tmdbId: show.id,
            name: show.name,
            posterPath: show.posterPath,
            numberOfSeasons: show.numberOfSeasons,
            numberOfEpisodes: show.numberOfEpisodes
        )

        // Add seasons and episodes
        for seasonData in show.seasons where !seasonData.isSpecials {
            let season = SeriesSeason(
                tmdbId: seasonData.id,
                seasonNumber: seasonData.seasonNumber,
                name: seasonData.name,
                airDate: seasonData.airDate,
                episodeCount: seasonData.episodeCount
            )

            for episodeData in seasonData.episodes {
                let episode = SeriesEpisode(
                    tmdbId: episodeData.id,
                    episodeNumber: episodeData.episodeNumber,
                    seasonNumber: episodeData.seasonNumber,
                    name: episodeData.name,
                    airDate: episodeData.airDate,
                    runtime: episodeData.runtime
                )
                season.episodes.append(episode)
            }

            series.seasons.append(season)
        }

        return series
    }

    private func updateSeries(_ series: Series, from show: ShowData) {
        series.name = show.name
        series.posterPath = show.posterPath
        series.numberOfSeasons = show.numberOfSeasons
        series.numberOfEpisodes = show.numberOfEpisodes
        series.updatedAt = Date()

        // Update seasons - preserve watched state
        for seasonData in show.seasons where !seasonData.isSpecials {
            if let existingSeason = series.seasons.first(where: { $0.seasonNumber == seasonData.seasonNumber }) {
                // Update existing season
                existingSeason.name = seasonData.name
                existingSeason.airDate = seasonData.airDate
                existingSeason.episodeCount = seasonData.episodeCount

                // Update episodes - preserve watched state
                for episodeData in seasonData.episodes {
                    if let existingEpisode = existingSeason.episodes.first(where: { $0.episodeNumber == episodeData.episodeNumber }) {
                        // Update existing episode (preserve isWatched)
                        existingEpisode.name = episodeData.name
                        existingEpisode.airDate = episodeData.airDate
                        existingEpisode.runtime = episodeData.runtime
                    } else {
                        // Add new episode
                        let episode = SeriesEpisode(
                            tmdbId: episodeData.id,
                            episodeNumber: episodeData.episodeNumber,
                            seasonNumber: episodeData.seasonNumber,
                            name: episodeData.name,
                            airDate: episodeData.airDate,
                            runtime: episodeData.runtime
                        )
                        existingSeason.episodes.append(episode)
                    }
                }
            } else {
                // Add new season
                let season = SeriesSeason(
                    tmdbId: seasonData.id,
                    seasonNumber: seasonData.seasonNumber,
                    name: seasonData.name,
                    airDate: seasonData.airDate,
                    episodeCount: seasonData.episodeCount
                )

                for episodeData in seasonData.episodes {
                    let episode = SeriesEpisode(
                        tmdbId: episodeData.id,
                        episodeNumber: episodeData.episodeNumber,
                        seasonNumber: episodeData.seasonNumber,
                        name: episodeData.name,
                        airDate: episodeData.airDate,
                        runtime: episodeData.runtime
                    )
                    season.episodes.append(episode)
                }

                series.seasons.append(season)
            }
        }
    }
}
