//
//  MyListPosterGrid.swift
//  Countdown2Binge
//
//  3-column poster grid with different visual treatments per variant.
//

import SwiftUI
import SwiftData

// MARK: - Poster Variant

enum MyListPosterVariant {
    case active      // Normal poster
    case justDone    // Normal + "READY" badge
    case noDate      // Dimmed + "TBD" badge (no release date yet)
    case ended       // Dimmed + "COMPLETE" stamp
    case archived    // Grayscale + stripe pattern + archive icon
}

// MARK: - Binge Ready Info

/// Info about a show's binge-ready season (the unwatched complete season)
struct BingeReadyInfo {
    let seasonNumber: Int
    let finaleDate: Date?
}

// MARK: - Poster Grid

struct MyListPosterGrid: View {
    let shows: [ShowData]
    let variant: MyListPosterVariant
    let onTap: (ShowData) -> Void
    /// Optional lookup for binge-ready season info (used when variant is .justDone)
    var bingeReadyInfoLookup: ((Int) -> BingeReadyInfo?)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 13) {
            ForEach(shows, id: \.id) { show in
                MyListPosterTile(
                    show: show,
                    variant: variant,
                    bingeReadyInfo: bingeReadyInfoLookup?(show.id),
                    onTap: { onTap(show) }
                )
            }
        }
    }
}

// MARK: - Poster Tile

struct MyListPosterTile: View {
    let show: ShowData
    let variant: MyListPosterVariant
    var bingeReadyInfo: BingeReadyInfo? = nil
    let onTap: () -> Void

    /// The season number to display
    private var seasonNumber: Int {
        // For binge-ready shows, use the binge-ready season (the unwatched complete season)
        if variant == .justDone, let info = bingeReadyInfo {
            return info.seasonNumber
        }

        // Use currentSeason which excludes anticipated seasons
        if let current = show.currentSeason {
            return current.seasonNumber
        }
        // Fallback: find the highest season that has actually started
        let today = Calendar.current.startOfDay(for: Date())
        let startedSeasons = show.seasons.filter { season in
            guard !season.isSpecials else { return false }
            guard let premiere = season.premiereDate else { return false }
            return Calendar.current.startOfDay(for: premiere) <= today
        }
        return startedSeasons.map { $0.seasonNumber }.max() ?? 1
    }

    /// The anticipated season number (for noDate variant)
    private var anticipatedSeasonNumber: Int {
        show.anticipatedSeason?.seasonNumber ?? (seasonNumber + 1)
    }

    private var noteText: String {
        switch variant {
        case .justDone:
            // Show when the binge-ready season's finale aired
            let finaleDate = bingeReadyInfo?.finaleDate ?? show.currentSeason?.finaleDate
            if let finaleDate {
                let days = Calendar.current.dateComponents([.day], from: finaleDate, to: Date()).day ?? 0
                if days == 0 {
                    return "FINALE AIRED TODAY"
                } else if days == 1 {
                    return "FINALE AIRED YESTERDAY"
                } else if days <= 7 {
                    return "FINALE AIRED \(days) DAYS AGO"
                } else {
                    // More than 7 days ago - show date
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, yyyy"
                    return "FINALE AIRED \(formatter.string(from: finaleDate))"
                }
            }
            return "BINGE READY"

        case .active:
            // Show days until finale or premiere based on current season state
            if let currentSeason = show.currentSeason {
                // If season has started, show days until finale
                if let daysToFinale = currentSeason.daysUntilFinale, daysToFinale > 0 {
                    return String(localized: "mylist_note_binge_in \(daysToFinale)")
                }
                // If season hasn't started, show days until premiere
                if let daysToPremiere = currentSeason.daysUntilPremiere, daysToPremiere > 0 {
                    return String(localized: "mylist_note_premieres_in \(daysToPremiere)")
                }
            }
            // Check for anticipated season premiere
            if let anticipated = show.anticipatedSeason,
               let daysToPremiere = anticipated.daysUntilPremiere, daysToPremiere > 0 {
                return String(localized: "mylist_note_premieres_in \(daysToPremiere)")
            }
            return ""

        case .noDate:
            // Show "RENEWED · DATE TBD" or "EXPECTED YEAR"
            if let anticipated = show.anticipatedSeason {
                // Check if there's an estimated year from air date
                if let airDate = anticipated.airDate {
                    let year = Calendar.current.component(.year, from: airDate)
                    return String(localized: "mylist_note_expected \(year)")
                }
            }
            return String(localized: "mylist_note_date_tbd")

        case .ended:
            // Get year from the last non-specials season's finale
            let regularSeasons = show.seasons.filter { !$0.isSpecials }
            if let lastSeason = regularSeasons.max(by: { $0.seasonNumber < $1.seasonNumber }),
               let finaleDate = lastSeason.finaleDate {
                let year = Calendar.current.component(.year, from: finaleDate)
                return String(localized: "mylist_note_ended \(year)")
            } else if let firstAirDate = show.firstAirDate {
                let year = Calendar.current.component(.year, from: firstAirDate)
                return String(localized: "mylist_note_ended \(year)")
            }
            return String(localized: "mylist_note_series_ended")

        case .archived:
            return String(localized: "mylist_note_archived")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image with treatments
                posterImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                borderColor,
                                style: variant == .noDate
                                    ? StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                    : StrokeStyle(lineWidth: 1)
                            )
                    )

                // Title
                Text(show.name)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(variant == .archived ? .c2bMuted : .white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 8)

                // Note
                Text(noteText)
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.68)
                    .foregroundColor(variant == .justDone ? .c2bTealBright : .c2bMuted)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Poster Image

    @ViewBuilder
    private var posterImage: some View {
        ZStack(alignment: .bottomLeading) {
            // Base image
            PosterView(url: show.posterURL, cornerRadius: 0)
                .modifier(PosterImageModifier(variant: variant))

            // Overlays based on variant
            overlayContent
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch variant {
        case .justDone:
            // "READY" badge top-left + season badge bottom-left
            VStack {
                HStack {
                    MyListReadyBadge()
                        .padding(7)
                    Spacer()
                }
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: seasonNumber)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .active:
            // Just season badge
            VStack {
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: seasonNumber)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .noDate:
            // TBD badge top-left + season badge bottom-left
            VStack {
                HStack {
                    MyListTBDBadge()
                        .padding(7)
                    Spacer()
                }
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: anticipatedSeasonNumber, isDimmed: true)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .ended:
            // Gradient overlay + COMPLETE stamp
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .black.opacity(0.05)],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // Angled "COMPLETE" stamp
                MyListCompleteStamp()
                    .position(x: 55, y: 70)

                // Season badge
                VStack {
                    Spacer()
                    HStack {
                        MyListSeasonBadge(seasonNumber: seasonNumber)
                            .padding(.leading, 7)
                            .padding(.bottom, 6)
                        Spacer()
                    }
                }
            }

        case .archived:
            ZStack {
                // Diagonal stripe pattern
                MyListStripePattern()

                // Archive icon top-right
                VStack {
                    HStack {
                        Spacer()
                        MyListArchiveIcon()
                            .padding(7)
                    }
                    Spacer()
                }

                // Season badge
                VStack {
                    Spacer()
                    HStack {
                        MyListSeasonBadge(seasonNumber: seasonNumber, isDimmed: true)
                            .padding(.leading, 7)
                            .padding(.bottom, 6)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        switch variant {
        case .ended:
            return Color.c2bTealLine
        case .noDate:
            return Color.white.opacity(0.35)
        case .archived:
            return Color.white.opacity(0.1)
        default:
            return Color.white.opacity(0.1)
        }
    }
}

// MARK: - Image Modifier

private struct PosterImageModifier: ViewModifier {
    let variant: MyListPosterVariant

    func body(content: Content) -> some View {
        switch variant {
        case .active, .justDone:
            content

        case .noDate:
            content
                .brightness(-0.15)
                .saturation(0.85)

        case .ended:
            content
                .brightness(-0.28)

        case .archived:
            content
                .saturation(0)
                .brightness(-0.5)
                .contrast(1.05)
        }
    }
}

// MARK: - Series-Based Grid (reads state from BingeEngine)

struct SeriesPosterGrid: View {
    let seriesList: [Series]
    let variant: MyListPosterVariant
    let onTap: (Series) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 13) {
            ForEach(seriesList, id: \.id) { series in
                SeriesPosterTile(
                    series: series,
                    variant: variant,
                    onTap: { onTap(series) }
                )
            }
        }
    }
}

// MARK: - Series-Based Tile (reads state from BingeEngine)

struct SeriesPosterTile: View {
    let series: Series
    let variant: MyListPosterVariant
    let onTap: () -> Void

    /// The season number to display (reads from Series/BingeEngine)
    private var seasonNumber: Int {
        // For binge-ready shows, use the binge-ready season (the unwatched complete season)
        if variant == .justDone, let bingeReady = series.bingeReadySeason {
            return bingeReady.seasonNumber
        }
        // Use currentSeason from Series (computed via BingeEngine)
        if let current = series.currentSeason {
            return current.seasonNumber
        }
        // Fallback: use numberOfSeasons
        return series.numberOfSeasons
    }

    /// The anticipated season number (for noDate variant)
    private var anticipatedSeasonNumber: Int {
        // For anticipated shows, the next season is numberOfSeasons + 1
        return series.numberOfSeasons + 1
    }

    /// Binge-ready season info for the note text
    private var bingeReadyInfo: BingeReadyInfo? {
        guard let season = series.bingeReadySeason else { return nil }
        return BingeReadyInfo(seasonNumber: season.seasonNumber, finaleDate: season.finaleDate)
    }

    private var noteText: String {
        switch variant {
        case .justDone:
            // Show when the binge-ready season's finale aired
            let finaleDate = series.bingeReadySeason?.finaleDate ?? series.currentSeason?.finaleDate
            if let finaleDate {
                let days = Calendar.current.dateComponents([.day], from: finaleDate, to: Date()).day ?? 0
                if days == 0 {
                    return "FINALE AIRED TODAY"
                } else if days == 1 {
                    return "FINALE AIRED YESTERDAY"
                } else if days <= 7 {
                    return "FINALE AIRED \(days) DAYS AGO"
                } else {
                    // More than 7 days ago - show date
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, yyyy"
                    return "FINALE AIRED \(formatter.string(from: finaleDate))"
                }
            }
            return "BINGE READY"

        case .active:
            // Show days until finale or premiere based on current season state
            if let daysToFinale = series.daysUntilFinale, daysToFinale > 0 {
                return String(localized: "mylist_note_binge_in \(daysToFinale)")
            }
            if let daysToPremiere = series.daysUntilPremiere, daysToPremiere > 0 {
                return String(localized: "mylist_note_premieres_in \(daysToPremiere)")
            }
            return ""

        case .noDate:
            return String(localized: "mylist_note_date_tbd")

        case .ended:
            // Get year from the last season's finale
            if let lastSeason = series.regularSeasons.last,
               let finaleDate = lastSeason.finaleDate {
                let year = Calendar.current.component(.year, from: finaleDate)
                return String(localized: "mylist_note_ended \(year)")
            } else if let firstAirDate = series.firstAirDate {
                let year = Calendar.current.component(.year, from: firstAirDate)
                return String(localized: "mylist_note_ended \(year)")
            }
            return String(localized: "mylist_note_series_ended")

        case .archived:
            return String(localized: "mylist_note_archived")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image with treatments
                posterImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                borderColor,
                                style: variant == .noDate
                                    ? StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                    : StrokeStyle(lineWidth: 1)
                            )
                    )

                // Title
                Text(series.name)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(variant == .archived ? .c2bMuted : .white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 8)

                // Note
                Text(noteText)
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.68)
                    .foregroundColor(variant == .justDone ? .c2bTealBright : .c2bMuted)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Poster Image

    @ViewBuilder
    private var posterImage: some View {
        ZStack(alignment: .bottomLeading) {
            // Base image
            PosterView(url: series.posterURL, cornerRadius: 0)
                .modifier(PosterImageModifier(variant: variant))

            // Overlays based on variant
            overlayContent
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch variant {
        case .justDone:
            // "READY" badge top-left + season badge bottom-left
            VStack {
                HStack {
                    MyListReadyBadge()
                        .padding(7)
                    Spacer()
                }
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: seasonNumber)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .active:
            // Just season badge
            VStack {
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: seasonNumber)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .noDate:
            // TBD badge top-left + season badge bottom-left
            VStack {
                HStack {
                    MyListTBDBadge()
                        .padding(7)
                    Spacer()
                }
                Spacer()
                HStack {
                    MyListSeasonBadge(seasonNumber: anticipatedSeasonNumber, isDimmed: true)
                        .padding(.leading, 7)
                        .padding(.bottom, 6)
                    Spacer()
                }
            }

        case .ended:
            // Gradient overlay + COMPLETE stamp
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .black.opacity(0.05)],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // Angled "COMPLETE" stamp
                MyListCompleteStamp()
                    .position(x: 55, y: 70)

                // Season badge
                VStack {
                    Spacer()
                    HStack {
                        MyListSeasonBadge(seasonNumber: seasonNumber)
                            .padding(.leading, 7)
                            .padding(.bottom, 6)
                        Spacer()
                    }
                }
            }

        case .archived:
            ZStack {
                // Diagonal stripe pattern
                MyListStripePattern()

                // Archive icon top-right
                VStack {
                    HStack {
                        Spacer()
                        MyListArchiveIcon()
                            .padding(7)
                    }
                    Spacer()
                }

                // Season badge
                VStack {
                    Spacer()
                    HStack {
                        MyListSeasonBadge(seasonNumber: seasonNumber, isDimmed: true)
                            .padding(.leading, 7)
                            .padding(.bottom, 6)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        switch variant {
        case .ended:
            return Color.c2bTealLine
        case .noDate:
            return Color.white.opacity(0.35)
        case .archived:
            return Color.white.opacity(0.1)
        default:
            return Color.white.opacity(0.1)
        }
    }
}
