//
//  SearchView.swift
//  Countdown2Binge
//

import SwiftUI

/// The main search screen for finding and adding TV shows.
struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool

    // App's teal accent color
    private let accentColor = Color(red: 0.22, green: 0.85, blue: 0.66)

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }

                ScrollView {
                    VStack(spacing: 0) {
                        // Page title
                        Text("SEARCH")
                            .font(.system(size: 36, weight: .heavy, design: .default).width(.condensed))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)

                        // Search field
                        searchField
                            .padding(.bottom, 20)

                        // Content based on search state
                        if viewModel.searchQuery.isEmpty {
                            landingContent
                        } else if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                            noResultsView
                        } else {
                            searchResultsContent
                        }
                    }
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.immediately)
                .contentMargins(.horizontal, 16, for: .scrollContent)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $viewModel.selectedShow) { show in
                ShowDetailView(
                    viewModel: ShowDetailViewModel(
                        show: show,
                        repository: ShowRepository(modelContext: modelContext)
                    )
                )
            }
        }
        .onChange(of: viewModel.searchQuery) {
            Task {
                await viewModel.search()
            }
        }
        .task {
            await viewModel.loadTrendingShows()
            await viewModel.loadAiringShows()
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.white.opacity(0.5))

            TextField("Search shows to binge", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            } else {
                // Filter button
                Button {
                    // TODO: Show filter options
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filter options")
            }

            if viewModel.isSearching {
                ProgressView()
                    .tint(.white.opacity(0.5))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSearchFocused ? Color.white.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
    }

    // MARK: - Landing Content (Empty Query State)

    // Responsive horizontal padding for smaller screens
    private var horizontalPadding: CGFloat {
        UIScreen.main.bounds.width < 380 ? 12 : 20
    }

    private var landingContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Category filter chips
            categoryChips

            // Trending Shows Section
            if !viewModel.trendingShows.isEmpty {
                trendingShowsSection
            }

            // Airing Now Section
            if !viewModel.airingShows.isEmpty {
                airingShowsSection
            }

            // Empty state if nothing to show
            if viewModel.trendingShows.isEmpty && viewModel.airingShows.isEmpty && !viewModel.isLoadingTrending {
                emptyLandingView
            }
        }
        .padding(.bottom, 25)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BROWSE BY CATEGORY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Skip "All" category (index 0) - only show specific genres
                    ForEach(Array(ShowCategory.allCases.dropFirst()), id: \.self) { category in
                        NavigationLink {
                            GenreListView(viewModel: viewModel, category: category)
                        } label: {
                            CategoryChipLabel(
                                title: category.rawValue,
                                accentColor: accentColor
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(category.rawValue) category")
                        .accessibilityHint("Double tap to browse \(category.rawValue) shows")
                    }
                }
            }
        }
    }

    // MARK: - Trending Shows Section

    private var trendingShowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("TRENDING SHOWS")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("SEE ALL") {
                    // TODO: Navigate to full trending list
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accentColor)
                .accessibilityLabel("See all trending shows")
            }

            // Grid of trending shows
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(viewModel.trendingShows.prefix(4), id: \.show.id) { item in
                    TrendingShowCard(
                        show: item.show,
                        logoPath: item.logoPath,
                        seasonNumber: 1,
                        isFollowed: viewModel.isFollowed(tmdbId: item.show.id),
                        isLoading: viewModel.isAdding(tmdbId: item.show.id),
                        onTap: {
                            isSearchFocused = false
                            Task {
                                await viewModel.selectShow(tmdbId: item.show.id)
                            }
                        },
                        onAdd: {
                            Task {
                                await viewModel.addShow(tmdbId: item.show.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Airing Shows Section

    private var airingShowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("ENDING SOON")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                NavigationLink {
                    AiringNowListView(viewModel: viewModel)
                } label: {
                    Text("SEE ALL")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .accessibilityLabel("See all shows ending soon")
            }

            // Airing show cards
            VStack(spacing: 12) {
                ForEach(viewModel.airingShows.prefix(3), id: \.show.id) { item in
                    AiringShowCard(
                        show: item.show,
                        daysLeft: item.daysLeft,
                        isFollowed: viewModel.isFollowed(tmdbId: item.show.id),
                        isLoading: viewModel.isAdding(tmdbId: item.show.id),
                        onTap: {
                            Task {
                                await viewModel.selectShow(tmdbId: item.show.id)
                            }
                        },
                        onAdd: {
                            Task {
                                await viewModel.addShow(tmdbId: item.show.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty Landing View

    private var emptyLandingView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "tv")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.15))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Find Your Shows")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Search for TV shows to start tracking")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .accessibilityElement(children: .combine)

            Spacer()
        }
    }

    // MARK: - No Results State

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 80)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("No Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .accessibilityElement(children: .combine)

            Spacer()
        }
    }

    // MARK: - Search Results Content

    private var searchResultsContent: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            ForEach(viewModel.searchResults) { result in
                TrendingShowCard(
                    show: result,
                    logoPath: nil,
                    seasonNumber: nil,
                    isFollowed: viewModel.isFollowed(tmdbId: result.id),
                    isLoading: viewModel.isAdding(tmdbId: result.id),
                    onTap: {
                        isSearchFocused = false
                        Task {
                            await viewModel.selectShow(tmdbId: result.id)
                        }
                    },
                    onAdd: {
                        Task {
                            await viewModel.addShow(tmdbId: result.id)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Chip Label (for NavigationLink)

private struct CategoryChipLabel: View {
    let title: String
    let accentColor: Color

    private let backgroundColor = Color(red: 0x27/255, green: 0x27/255, blue: 0x2A/255)
    private let borderColor = Color(red: 0x32/255, green: 0x32/255, blue: 0x34/255)

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(height: 40)
            .padding(.horizontal, 18)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: TMDBShowSummary
    let isFollowed: Bool
    let isLoading: Bool
    let isLoadingDetail: Bool
    let accentColor: Color
    let onTap: () -> Void
    let onAdd: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Poster
                ZStack {
                    posterImage
                        .frame(width: 56, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if isLoadingDetail {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.black.opacity(0.5))
                            .frame(width: 56, height: 84)

                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if let year = extractYear(from: result.firstAirDate) {
                            Text(year)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        if let rating = result.voteAverage, rating > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                            }
                            .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                // Add button
                addButton
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoadingDetail)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(isFollowed ? .white.opacity(0.6) : accentColor)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: isFollowed ? "checkmark" : "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(isFollowed ? "Added" : "Add")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isFollowed ? .white.opacity(0.6) : accentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .strokeBorder(isFollowed ? .white.opacity(0.2) : accentColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isFollowed)
    }

    @ViewBuilder
    private var posterImage: some View {
        if let url = TMDBConfiguration.imageURL(path: result.posterPath, size: .posterSmall) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.08)

            Image(systemName: "tv")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.2))
        }
    }

    private func extractYear(from dateString: String?) -> String? {
        guard let dateString, dateString.count >= 4 else { return nil }
        return String(dateString.prefix(4))
    }
}

// MARK: - Preview

#Preview("Search Landing") {
    SearchView(
        viewModel: SearchViewModel(
            tmdbService: MockTMDBService(),
            addShowUseCase: MockAddShowUseCase(),
            repository: MockShowRepository()
        )
    )
    .preferredColorScheme(.dark)
}

// MARK: - Mock Types for Preview

private class MockTMDBService: TMDBServiceProtocol {
    func searchShows(query: String, page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
    }

    func getShowDetails(id: Int) async throws -> Show {
        fatalError("Not implemented")
    }

    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> Season {
        fatalError("Not implemented")
    }

    func getTrendingShows() async throws -> [TMDBShowSummary] {
        []
    }

    func getAiringShows(page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
    }

    func getShowsByGenre(genreIds: [Int], page: Int) async throws -> TMDBSearchResponse {
        TMDBSearchResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
    }

    func getShowLogo(id: Int) async -> String? {
        nil
    }
}

private class MockAddShowUseCase: AddShowUseCaseProtocol {
    func execute(tmdbId: Int) async throws -> Show {
        fatalError("Not implemented")
    }
}

private class MockShowRepository: ShowRepositoryProtocol {
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
