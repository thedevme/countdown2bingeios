//
//  ShowDetailView.swift
//  Countdown2Binge
//

import SwiftUI

/// Detail view for a single TV show.
/// Displays backdrop, title, status, season info, countdown, and actions.
struct ShowDetailView: View {
    @State private var viewModel: ShowDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showRemoveConfirmation: Bool = false

    init(viewModel: ShowDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Backdrop header
                    backdropHeader

                    // Content
                    VStack(spacing: 28) {
                        // Title and status section
                        titleSection

                        // Season info section
                        seasonSection

                        // Episode list (for followed shows with episodes)
                        if viewModel.isFollowed, let season = viewModel.selectedSeason, !season.episodes.isEmpty {
                            episodeListSection
                        }

                        // Countdown section
                        if viewModel.countdownInfo != nil {
                            countdownSection
                        }

                        // Season picker (if multiple seasons)
                        if viewModel.hasMultipleSeasons {
                            seasonPicker
                        }

                        // Actions section
                        actionsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .frame(width: geometry.size.width)
            }
        }
        .background(Color.black)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove Show",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.removeShow()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stop following \(viewModel.show.name)?")
        }
        .confirmationDialog(
            "Mark as Watched",
            isPresented: $viewModel.showMarkWatchedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mark Watched") {
                Task {
                    await viewModel.markSeasonWatched()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark \(viewModel.show.name) Season \(viewModel.selectedSeasonNumber) as watched?")
        }
        .onChange(of: viewModel.didRemoveShow) { _, didRemove in
            if didRemove {
                dismiss()
            }
        }
    }

    // MARK: - Backdrop Header

    private var backdropHeader: some View {
        ZStack(alignment: .bottom) {
            // Backdrop image
            backdropImage
                .frame(height: 280)

            // Gradient overlay
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.6),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
        }
        .frame(height: 280)
    }

    @ViewBuilder
    private var backdropImage: some View {
        if let url = TMDBConfiguration.imageURL(path: viewModel.show.backdropPath, size: .backdrop) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    backdropPlaceholder
                }
            }
        } else {
            backdropPlaceholder
        }
    }

    private var backdropPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(white: 0.15),
                    Color(white: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: "tv")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.1))
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(viewModel.show.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            // Status row
            HStack(spacing: 12) {
                StateBadge(style: viewModel.lifecycleBadgeStyle)

                Text(viewModel.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                if let year = extractYear(from: viewModel.show.firstAirDate) {
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Overview
            if let overview = viewModel.show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(4)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Season Section

    private var seasonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("CURRENT SEASON")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))

            if let season = viewModel.selectedSeason {
                SeasonInfoCard(season: season)
            } else {
                Text("No season information available")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Countdown Section

    @ViewBuilder
    private var countdownSection: some View {
        if let countdown = viewModel.countdownInfo {
            VStack(spacing: 8) {
                // Large countdown number
                Text("\(countdown.days)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                // Label
                Text(countdown.label.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Episode List Section

    private var episodeListSection: some View {
        EpisodeListView(
            episodes: viewModel.selectedSeason?.episodes ?? [],
            isExpanded: viewModel.isEpisodeListExpanded,
            onToggleExpand: {
                viewModel.toggleEpisodeList()
            },
            onToggleWatched: { episode in
                Task {
                    await viewModel.toggleEpisodeWatched(episode)
                }
            }
        )
    }

    // MARK: - Season Picker

    private var seasonPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SEASONS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.4))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.regularSeasons) { season in
                        SeasonPickerButton(
                            seasonNumber: season.seasonNumber,
                            isSelected: season.seasonNumber == viewModel.selectedSeasonNumber,
                            isComplete: season.isComplete
                        ) {
                            viewModel.selectSeason(season.seasonNumber)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))

            if viewModel.isFollowed {
                // Mark Watched button (if season is binge ready)
                if viewModel.canMarkSelectedSeasonWatched {
                    Button {
                        viewModel.showMarkWatchedConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isMarkingWatched {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }

                            Text("Mark Season \(viewModel.selectedSeasonNumber) Watched")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.45, green: 0.90, blue: 0.70))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isMarkingWatched)
                }

                // Remove button
                Button {
                    showRemoveConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isRemoving {
                            ProgressView()
                                .tint(.red.opacity(0.8))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "minus.circle")
                        }

                        Text("Remove Show")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRemoving)
            } else {
                // Add button
                Button {
                    Task {
                        await viewModel.addShow()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isAdding {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }

                        Text("Add to My Shows")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isAdding)
            }
        }
    }

    // MARK: - Helpers

    private func extractYear(from date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Season Info Card

private struct SeasonInfoCard: View {
    let season: Season

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Season header
            HStack {
                Text("Season \(season.seasonNumber)")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if season.isComplete {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70))
                } else if season.isAiring {
                    Label("Airing", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.25))
                }
            }

            // Episode info
            HStack(spacing: 16) {
                InfoItem(
                    label: "Episodes",
                    value: "\(season.episodeCount)"
                )

                if season.airedEpisodeCount > 0 && season.airedEpisodeCount < season.episodeCount {
                    InfoItem(
                        label: "Aired",
                        value: "\(season.airedEpisodeCount)"
                    )
                }

                if let date = season.airDate {
                    InfoItem(
                        label: "Premiere",
                        value: formatDate(date)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Info Item

private struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2)
                .fontWeight(.medium)
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.4))

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

// MARK: - Season Picker Button

private struct SeasonPickerButton: View {
    let seasonNumber: Int
    let isSelected: Bool
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(seasonNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? .white : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Show Detail") {
    NavigationStack {
        ShowDetailView(
            viewModel: ShowDetailViewModel(
                show: Show(
                    id: 1,
                    name: "Severance",
                    overview: "Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.",
                    posterPath: nil,
                    backdropPath: nil,
                    firstAirDate: Date(),
                    status: .returning,
                    genres: [],
                    networks: [],
                    seasons: [
                        Season(
                            id: 1,
                            seasonNumber: 1,
                            name: "Season 1",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 9,
                            episodes: []
                        ),
                        Season(
                            id: 2,
                            seasonNumber: 2,
                            name: "Season 2",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 10,
                            episodes: []
                        )
                    ],
                    numberOfSeasons: 2,
                    numberOfEpisodes: 19,
                    inProduction: true
                ),
                repository: MockDetailRepository()
            )
        )
    }
    .preferredColorScheme(.dark)
}

// MARK: - Mock Repository for Preview

private class MockDetailRepository: ShowRepositoryProtocol {
    func save(_ show: Show) async throws {}
    func fetchAllShows() -> [Show] { [] }
    func fetchShow(byTmdbId id: Int) -> Show? { nil }
    func fetchTimelineShows() -> [Show] { [] }
    func fetchBingeReadySeasons() -> [Season] { [] }
    func delete(_ show: Show) async throws {}
    func isShowFollowed(tmdbId: Int) -> Bool { true }
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {}
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {}
}
