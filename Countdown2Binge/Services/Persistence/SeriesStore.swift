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
            overview: show.overview,
            posterPath: show.posterPath,
            backdropPath: show.backdropPath,
            logoPath: show.logoPath,
            firstAirDate: show.firstAirDate,
            statusRaw: show.status.rawValue,
            inProduction: show.inProduction,
            voteAverage: show.voteAverage,
            numberOfSeasons: show.numberOfSeasons,
            numberOfEpisodes: show.numberOfEpisodes
        )
        series.genres = show.genres
        series.networks = show.networks
        series.creators = show.createdBy
        series.spinoffCount = show.spinoffCount

        // Add seasons and episodes
        for seasonData in show.seasons where !seasonData.isSpecials {
            let season = SeriesSeason(
                tmdbId: seasonData.id,
                seasonNumber: seasonData.seasonNumber,
                name: seasonData.name,
                overview: seasonData.overview,
                posterPath: seasonData.posterPath,
                airDate: seasonData.airDate,
                episodeCount: seasonData.episodeCount,
                voteAverage: seasonData.voteAverage
            )

            for episodeData in seasonData.episodes {
                let episode = SeriesEpisode(
                    tmdbId: episodeData.id,
                    episodeNumber: episodeData.episodeNumber,
                    seasonNumber: episodeData.seasonNumber,
                    name: episodeData.name,
                    overview: episodeData.overview,
                    airDate: episodeData.airDate,
                    stillPath: episodeData.stillPath,
                    runtime: episodeData.runtime,
                    episodeTypeRaw: episodeData.episodeType.rawValue,
                    voteAverage: episodeData.voteAverage
                )
                modelContext.insert(episode)
                season.episodes.append(episode)
            }

            modelContext.insert(season)
            series.seasons.append(season)
        }

        return series
    }

    private func updateSeries(_ series: Series, from show: ShowData) {
        series.name = show.name
        series.overview = show.overview
        series.posterPath = show.posterPath
        series.backdropPath = show.backdropPath
        series.logoPath = show.logoPath
        series.firstAirDate = show.firstAirDate
        series.statusRaw = show.status.rawValue
        series.inProduction = show.inProduction
        series.voteAverage = show.voteAverage
        series.numberOfSeasons = show.numberOfSeasons
        series.numberOfEpisodes = show.numberOfEpisodes
        series.genres = show.genres
        series.networks = show.networks
        series.creators = show.createdBy
        series.spinoffCount = show.spinoffCount
        series.updatedAt = Date()

        // Update seasons - preserve watched state
        for seasonData in show.seasons where !seasonData.isSpecials {
            if let existingSeason = series.seasons.first(where: { $0.seasonNumber == seasonData.seasonNumber }) {
                // Update existing season
                existingSeason.name = seasonData.name
                existingSeason.overview = seasonData.overview
                existingSeason.posterPath = seasonData.posterPath
                existingSeason.airDate = seasonData.airDate
                existingSeason.episodeCount = seasonData.episodeCount
                existingSeason.voteAverage = seasonData.voteAverage

                // Update episodes - preserve watched state
                for episodeData in seasonData.episodes {
                    if let existingEpisode = existingSeason.episodes.first(where: { $0.episodeNumber == episodeData.episodeNumber }) {
                        // Update existing episode (preserve isWatched)
                        existingEpisode.name = episodeData.name
                        existingEpisode.overview = episodeData.overview
                        existingEpisode.airDate = episodeData.airDate
                        existingEpisode.stillPath = episodeData.stillPath
                        existingEpisode.runtime = episodeData.runtime
                        existingEpisode.episodeTypeRaw = episodeData.episodeType.rawValue
                        existingEpisode.voteAverage = episodeData.voteAverage
                    } else {
                        // Add new episode
                        let episode = SeriesEpisode(
                            tmdbId: episodeData.id,
                            episodeNumber: episodeData.episodeNumber,
                            seasonNumber: episodeData.seasonNumber,
                            name: episodeData.name,
                            overview: episodeData.overview,
                            airDate: episodeData.airDate,
                            stillPath: episodeData.stillPath,
                            runtime: episodeData.runtime,
                            episodeTypeRaw: episodeData.episodeType.rawValue,
                            voteAverage: episodeData.voteAverage
                        )
                        modelContext.insert(episode)
                        existingSeason.episodes.append(episode)
                    }
                }
            } else {
                // Add new season
                let season = SeriesSeason(
                    tmdbId: seasonData.id,
                    seasonNumber: seasonData.seasonNumber,
                    name: seasonData.name,
                    overview: seasonData.overview,
                    posterPath: seasonData.posterPath,
                    airDate: seasonData.airDate,
                    episodeCount: seasonData.episodeCount,
                    voteAverage: seasonData.voteAverage
                )

                for episodeData in seasonData.episodes {
                    let episode = SeriesEpisode(
                        tmdbId: episodeData.id,
                        episodeNumber: episodeData.episodeNumber,
                        seasonNumber: episodeData.seasonNumber,
                        name: episodeData.name,
                        overview: episodeData.overview,
                        airDate: episodeData.airDate,
                        stillPath: episodeData.stillPath,
                        runtime: episodeData.runtime,
                        episodeTypeRaw: episodeData.episodeType.rawValue,
                        voteAverage: episodeData.voteAverage
                    )
                    modelContext.insert(episode)
                    season.episodes.append(episode)
                }

                modelContext.insert(season)
                series.seasons.append(season)
            }
        }
    }
}
