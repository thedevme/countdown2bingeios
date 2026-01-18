//
//  ShowDetailView.swift
//  Countdown2Binge
//

import SwiftUI
import YouTubePlayerKit

// MARK: - App Colors

private enum AppColors {
    static let teal = Color(red: 0.29, green: 0.78, blue: 0.72)
    static let cardBackground = Color(red: 0x0D / 255.0, green: 0x0D / 255.0, blue: 0x0D / 255.0)
    static let cardBorder = Color(red: 0x25 / 255.0, green: 0x25 / 255.0, blue: 0x25 / 255.0)
}

// MARK: - Stretchy Header Modifier

private extension View {
    func stretchy(height: CGFloat) -> some View {
        visualEffect { content, geometry in
            let scrollOffset = geometry.frame(in: .scrollView).minY
            let stretchOffset = max(0, scrollOffset)
            let newHeight = height + stretchOffset
            let scale = newHeight / height

            return content
                .scaleEffect(x: scale, y: scale, anchor: .bottom)
                .offset(y: stretchOffset > 0 ? -stretchOffset / 2 : 0)
        }
    }
}

/// Detail view for a single TV show.
/// Displays backdrop, logo, genres, status, season picker, episodes, and actions.
struct ShowDetailView: View {
    @State private var viewModel: ShowDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showRemoveConfirmation: Bool = false

    init(viewModel: ShowDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Backdrop header with logo
                    backdropHeader

                    // Content
                    VStack(spacing: 20) {
                        // Genre tags
                        genreTags

                        // Overview and meta info
                        infoSection

                        // Add/Remove button
                        actionButton

                        // Season picker
                        if viewModel.hasMultipleSeasons {
                            seasonPicker
                        }

                        // Episode list (for followed shows with episodes)
                        if let season = viewModel.selectedSeason, !season.episodes.isEmpty {
                            episodeListSection
                        }

                        // Trailers & Clips section (placeholder)
                        trailersSection

                        // Cast & Crew section (placeholder)
                        castSection

                        // More Like This section (placeholder)
                        moreLikeThisSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .frame(width: geometry.size.width)
            }
        }
        .background(Color.black)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action placeholder
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
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
        .task {
            await viewModel.loadAdditionalContent()
        }
        .navigationDestination(item: $viewModel.selectedRecommendation) { show in
            ShowDetailView(
                viewModel: ShowDetailViewModel(
                    show: show,
                    repository: ShowRepository(modelContext: modelContext)
                )
            )
        }
        .sheet(isPresented: $viewModel.showNotificationSettings) {
            NotificationSettingsView(
                show: viewModel.show,
                isGlobalDefaults: false,
                settings: $viewModel.pendingNotificationSettings,
                onSave: {
                    // TODO: Save notification settings for this show
                },
                onSkip: {
                    // User skipped - no action needed
                }
            )
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    // MARK: - Backdrop Header

    private let headerHeight: CGFloat = 420

    private var backdropHeader: some View {
        ZStack(alignment: .bottom) {
            // Backdrop image with stretchy effect
            backdropImage
                .frame(height: headerHeight)
                .clipped()
                .stretchy(height: headerHeight)

            // Gradient overlay for logo readability
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.4),
                    .black.opacity(0.85),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            // Show logo or title
            showLogo
                .padding(.bottom, 16)
        }
        .frame(height: headerHeight)
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

    @ViewBuilder
    private var showLogo: some View {
        if let logoURL = TMDBConfiguration.imageURL(path: viewModel.show.logoPath, size: .logo) {
            AsyncImage(url: logoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 280, maxHeight: 100)
                default:
                    showTitleText
                }
            }
        } else {
            showTitleText
        }
    }

    private var showTitleText: some View {
        Text(viewModel.show.name.uppercased())
            .font(.system(size: 36, weight: .black, design: .default))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
    }

    // MARK: - Genre Tags

    private var genreTags: some View {
        Group {
            if !viewModel.show.genres.isEmpty {
                HStack(spacing: 8) {
                    ForEach(viewModel.show.genres.prefix(3)) { genre in
                        GenreTag(name: genre.name)
                    }
                }
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 12) {
            // Overview
            if let overview = viewModel.show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
            }

            // Meta info: seasons and status
            HStack(spacing: 8) {
                Text("\(viewModel.show.numberOfSeasons) \(viewModel.show.numberOfSeasons == 1 ? "SEASON" : "SEASONS")")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))

                Text("•")
                    .foregroundStyle(.white.opacity(0.3))

                Text(viewModel.statusText.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Group {
            if viewModel.isFollowed {
                Button {
                    showRemoveConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isRemoving {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("FOLLOWING")
                                .font(.system(size: 16, weight: .heavy).width(.condensed))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRemoving)
            } else {
                Button {
                    Task {
                        await viewModel.addShow()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isAdding {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "bookmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("FOLLOW")
                                .font(.system(size: 16, weight: .heavy).width(.condensed))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.teal)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isAdding)
            }
        }
    }

    // MARK: - Season Picker

    private var seasonPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.regularSeasons) { season in
                    SeasonPickerItem(
                        seasonNumber: season.seasonNumber,
                        isSelected: season.seasonNumber == viewModel.selectedSeasonNumber
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectSeason(season.seasonNumber)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Episode List Section

    private var episodeListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season header
            Text("SEASON \(viewModel.selectedSeasonNumber)")
                .font(.system(size: 14, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(.white)

            // Episodes card with large season number
            ZStack(alignment: .bottomTrailing) {
                // Large season number watermark (behind content, masked by card)
                Text("S\(viewModel.selectedSeasonNumber)")
                    .font(.system(size: 180, weight: .black, design: .default).width(.condensed))
                    .foregroundStyle(.white.opacity(0.04))
                    .offset(x: 30, y: 50)

                // Episode content
                VStack(spacing: 0) {
                    let episodes = viewModel.selectedSeason?.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber }) ?? []
                    let displayedEpisodes = viewModel.isEpisodeListExpanded ? episodes : Array(episodes.prefix(4))

                    Spacer()
                        .frame(height: 10)

                    ForEach(displayedEpisodes) { episode in
                        EpisodeRowRedesigned(episode: episode)
                    }

                    // View All Episodes link with decorative separator
                    if let season = viewModel.selectedSeason, season.episodes.count > 4 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.toggleEpisodeList()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 1)

                                Text(viewModel.isEpisodeListExpanded ? "SHOW LESS" : "VIEW ALL EPISODES")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .fixedSize()

                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 1)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0x14/255, green: 0x14/255, blue: 0x14/255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trailers Section

    @ViewBuilder
    private var trailersSection: some View {
        if !viewModel.videos.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("TRAILERS & CLIPS")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.videos.prefix(6)) { video in
                            TrailerCard(video: video)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }

    // MARK: - Cast Section

    @ViewBuilder
    private var castSection: some View {
        if !viewModel.cast.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("CAST & CREW")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.cast.prefix(10)) { castMember in
                            CastCard(castMember: castMember)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }

    // MARK: - More Like This Section

    @ViewBuilder
    private var moreLikeThisSection: some View {
        if !viewModel.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("MORE LIKE THIS")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(viewModel.recommendations.prefix(4)) { show in
                        TrendingShowCard(
                            show: show,
                            logoPath: nil,
                            seasonNumber: nil,
                            isFollowed: viewModel.isRecommendationFollowed(tmdbId: show.id),
                            isLoading: viewModel.isRecommendationAdding(tmdbId: show.id),
                            onTap: {
                                Task {
                                    await viewModel.selectRecommendation(tmdbId: show.id)
                                }
                            },
                            onAdd: {
                                Task {
                                    await viewModel.toggleRecommendationFollow(tmdbId: show.id)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }
}

// MARK: - Genre Tag

private struct GenreTag: View {
    let name: String

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .foregroundStyle(AppColors.teal)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .strokeBorder(AppColors.teal, lineWidth: 1)
            )
    }
}

// MARK: - Season Picker Item

private struct SeasonPickerItem: View {
    let seasonNumber: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("S\(seasonNumber)")
                .font(.system(size: isSelected ? 28 : 18, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Episode Row Redesigned

private struct EpisodeRowRedesigned: View {
    let episode: Episode

    private var formattedRuntime: String {
        guard let runtime = episode.runtime else { return "" }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)H \(minutes)M"
        } else {
            return "\(minutes)M"
        }
    }

    private var formattedDate: String {
        guard let date = episode.airDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Episode number
            Text(String(format: "%02d", episode.episodeNumber))
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 24)

            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !formattedRuntime.isEmpty {
                        Text(formattedRuntime)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if !formattedRuntime.isEmpty && !formattedDate.isEmpty {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    if !formattedDate.isEmpty {
                        Text(formattedDate)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Trailer Card

private struct TrailerCard: View {
    let video: TMDBVideo
    @State private var showPlayer = false

    var body: some View {
        Button {
            showPlayer = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail with play button
                ZStack {
                    if let thumbnailURL = video.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                thumbnailPlaceholder
                            }
                        }
                    } else {
                        thumbnailPlaceholder
                    }

                    // Play button overlay
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .offset(x: 2)
                        )
                }
                .frame(width: 200, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Video title
                Text(video.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPlayer) {
            YouTubePlayerFullscreen(videoKey: video.key)
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            AppColors.cardBackground
            Image(systemName: "play.rectangle")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.2))
        }
    }
}

// MARK: - YouTube Player Fullscreen

private struct YouTubePlayerFullscreen: View {
    let videoKey: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player: YouTubePlayer

    init(videoKey: String) {
        self.videoKey = videoKey
        _player = StateObject(wrappedValue: YouTubePlayer(
            source: .video(id: videoKey),
            parameters: .init(
                autoPlay: true,
                showControls: true
            ),
            configuration: .init(
                fullscreenMode: .system,
                allowsInlineMediaPlayback: false
            )
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Player fills the screen
                YouTubePlayerView(player)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()

                // Close button overlay
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.leading, 16)

                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            OrientationManager.shared.lockLandscape()
        }
        .onDisappear {
            OrientationManager.shared.lockPortrait()
        }
    }
}

// MARK: - Cast Card

private struct CastCard: View {
    let castMember: TMDBCastMember

    var body: some View {
        VStack(spacing: 8) {
            // Profile image
            if let profilePath = castMember.profilePath,
               let url = TMDBConfiguration.imageURL(path: profilePath, size: .posterSmall) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        profilePlaceholder
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                profilePlaceholder
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }

            // Name
            VStack(spacing: 2) {
                Text(castMember.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let character = castMember.character, !character.isEmpty {
                    Text(character)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 100)
    }

    private var profilePlaceholder: some View {
        ZStack {
            AppColors.cardBackground
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.3))
        }
        .overlay(
            Circle()
                .strokeBorder(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Show Detail") {
    NavigationStack {
        ShowDetailView(
            viewModel: ShowDetailViewModel(
                show: Show(
                    id: 1,
                    name: "Stranger Things",
                    overview: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces and one strange little girl.",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: Date(),
                    status: .returning,
                    genres: [
                        Genre(id: 1, name: "Sci-Fi"),
                        Genre(id: 2, name: "Horror"),
                        Genre(id: 3, name: "Mystery")
                    ],
                    networks: [],
                    seasons: [
                        Season(
                            id: 1,
                            seasonNumber: 1,
                            name: "Season 1",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 8,
                            episodes: [
                                Episode(id: 1, episodeNumber: 1, seasonNumber: 1, name: "Chapter One: The Hellfire Club", overview: nil, airDate: Date().addingTimeInterval(-86400 * 30), stillPath: nil, runtime: 78, watchedDate: nil),
                                Episode(id: 2, episodeNumber: 2, seasonNumber: 1, name: "Chapter Two: Vecna's Curse", overview: nil, airDate: Date().addingTimeInterval(-86400 * 23), stillPath: nil, runtime: 77, watchedDate: nil),
                                Episode(id: 3, episodeNumber: 3, seasonNumber: 1, name: "Chapter Three: The Monster and the Superhero", overview: nil, airDate: Date().addingTimeInterval(-86400 * 16), stillPath: nil, runtime: 63, watchedDate: nil),
                                Episode(id: 4, episodeNumber: 4, seasonNumber: 1, name: "Chapter Four: Dear Billy", overview: nil, airDate: Date().addingTimeInterval(-86400 * 9), stillPath: nil, runtime: 79, watchedDate: nil)
                            ]
                        ),
                        Season(
                            id: 2,
                            seasonNumber: 2,
                            name: "Season 2",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 9,
                            episodes: []
                        ),
                        Season(
                            id: 3,
                            seasonNumber: 3,
                            name: "Season 3",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 8,
                            episodes: []
                        ),
                        Season(
                            id: 4,
                            seasonNumber: 4,
                            name: "Season 4",
                            overview: nil,
                            posterPath: nil,
                            airDate: Date(),
                            episodeCount: 9,
                            episodes: []
                        )
                    ],
                    numberOfSeasons: 4,
                    numberOfEpisodes: 34,
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
    func isShowFollowed(tmdbId: Int) -> Bool { false }
    func markSeasonWatched(showId: Int, seasonNumber: Int) async throws {}
    func markEpisodeWatched(showId: Int, seasonNumber: Int, episodeNumber: Int, watched: Bool) async throws {}
}
