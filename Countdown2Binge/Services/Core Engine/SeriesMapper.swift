//
//  SeriesMapper.swift
//  Countdown2Binge
//
//  The ONE bridge from the DTO tree (ShowData/SeasonData/EpisodeData) into the
//  SwiftData tree (Series/Season/Episode).
//
//  • On create: builds the full graph from a ShowData.
//  • On update: matches seasons by seasonNumber and episodes by episodeNumber,
//    updates metadata, and PRESERVES user watch state (hasWatched/watchedAt).
//    New seasons/episodes are appended; existing ones are never clobbered.
//
//  Specials (seasonNumber == 0) are excluded — the engine ignores them.
//
//  NOTE: This performs no saves. The caller (SeriesManager) owns the
//  ModelContext and the save, so all writes funnel through one place.
//

import Foundation
import SwiftData

enum SeriesMapper {

    // MARK: - Create

    /// Build a brand-new Series graph from a ShowData. Inserts child objects
    /// into the provided context. Does NOT save.
    @discardableResult
    static func makeSeries(from show: ShowData, in context: ModelContext) -> Series {
        let series = Series(id: show.id, name: show.name)
        apply(metadata: show, to: series)

        for seasonData in show.seasons where seasonData.seasonNumber > 0 {
            let season = makeSeason(from: seasonData, in: context)
            season.series = series
            series.seasons.append(season)
        }

        context.insert(series)
        return series
    }

    private static func makeSeason(from data: SeasonData, in context: ModelContext) -> Season {
        let season = Season(id: data.id, seasonNumber: data.seasonNumber, name: data.name)
        season.overview = data.overview ?? ""
        season.posterPath = data.posterPath
        season.airDate = data.airDate
        season.episodeCount = data.episodeCount
        season.voteAverage = data.voteAverage

        for epData in data.episodes {
            let episode = makeEpisode(from: epData)
            episode.season = season
            season.episodes.append(episode)
            context.insert(episode)
        }

        context.insert(season)
        return season
    }

    private static func makeEpisode(from data: EpisodeData) -> Episode {
        let episode = Episode(
            id: data.id,
            episodeNumber: data.episodeNumber,
            seasonNumber: data.seasonNumber,
            name: data.name
        )
        episode.overview = data.overview ?? ""
        episode.airDate = data.airDate
        episode.stillPath = data.stillPath
        episode.runtime = data.runtime ?? 0
        episode.episodeTypeRaw = data.episodeType.rawValue
        episode.voteAverage = data.voteAverage
        return episode
    }

    // MARK: - Update (preserves watch state)

    /// Update an existing Series from fresh ShowData. Matches by number,
    /// preserves hasWatched/watchedAt on seasons and episodes. Does NOT save.
    static func update(_ series: Series, from show: ShowData, in context: ModelContext) {
        apply(metadata: show, to: series)

        for seasonData in show.seasons where seasonData.seasonNumber > 0 {
            if let existing = series.seasons.first(where: { $0.seasonNumber == seasonData.seasonNumber }) {
                updateSeason(existing, from: seasonData, in: context)
            } else {
                let season = makeSeason(from: seasonData, in: context)
                season.series = series
                series.seasons.append(season)
            }
        }

        series.lastUpdated = .now
    }

    private static func updateSeason(_ season: Season, from data: SeasonData, in context: ModelContext) {
        // Metadata only — never touch hasWatched/watchedAt here.
        season.name = data.name
        season.overview = data.overview ?? ""
        season.posterPath = data.posterPath
        season.airDate = data.airDate
        season.episodeCount = data.episodeCount
        season.voteAverage = data.voteAverage

        for epData in data.episodes {
            if let existing = season.episodes.first(where: { $0.episodeNumber == epData.episodeNumber }) {
                updateEpisode(existing, from: epData)   // preserves hasWatched
            } else {
                let episode = makeEpisode(from: epData)
                episode.season = season
                season.episodes.append(episode)
                context.insert(episode)
            }
        }
    }

    private static func updateEpisode(_ episode: Episode, from data: EpisodeData) {
        // Metadata only — never touch hasWatched/watchedAt here.
        episode.name = data.name
        episode.overview = data.overview ?? ""
        episode.airDate = data.airDate
        episode.stillPath = data.stillPath
        episode.runtime = data.runtime ?? 0
        episode.episodeTypeRaw = data.episodeType.rawValue
        episode.voteAverage = data.voteAverage
    }

    // MARK: - Metadata

    private static func apply(metadata show: ShowData, to series: Series) {
        series.name = show.name
        series.overview = show.overview ?? ""
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
        series.lastUpdated = .now
    }
}
