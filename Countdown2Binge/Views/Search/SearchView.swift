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

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - tappable to dismiss keyboard
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }

                VStack(spacing: 0) {
                    // Search field
                    searchField
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Content
                    contentView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
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
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.white.opacity(0.5))

            TextField("Search TV shows...", text: $viewModel.searchQuery)
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
            }

            if viewModel.isSearching {
                ProgressView()
                    .tint(.white.opacity(0.5))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isSearchFocused ? Color.white.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.searchQuery.isEmpty {
            emptyQueryView
        } else if viewModel.searchResults.isEmpty && !viewModel.isSearching {
            noResultsView
        } else {
            resultsListView
        }
    }

    // MARK: - Empty Query State

    private var emptyQueryView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tv")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.15))

            VStack(spacing: 8) {
                Text("Find Your Shows")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Search for TV shows to start tracking")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Results State

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))

            VStack(spacing: 8) {
                Text("No Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results List

    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { result in
                    SearchResultRow(
                        result: result,
                        isFollowed: viewModel.isFollowed(tmdbId: result.id),
                        isLoading: viewModel.isAdding(tmdbId: result.id),
                        isLoadingDetail: viewModel.isLoadingDetail(tmdbId: result.id),
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

                    if result.id != viewModel.searchResults.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 88)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: TMDBShowSummary
    let isFollowed: Bool
    let isLoading: Bool
    let isLoadingDetail: Bool
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
                AddButton(
                    isAdded: isFollowed,
                    isLoading: isLoading,
                    action: onAdd
                )
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoadingDetail)
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

#Preview("Empty State") {
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
