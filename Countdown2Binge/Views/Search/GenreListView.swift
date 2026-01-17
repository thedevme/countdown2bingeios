//
//  GenreListView.swift
//  Countdown2Binge
//

import SwiftUI

/// A view showing shows filtered by genre with pagination.
struct GenreListView: View {
    @Bindable var viewModel: SearchViewModel
    let category: ShowCategory

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                if viewModel.isLoadingGenre && viewModel.genreShows.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 100)
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if viewModel.genreShows.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(Array(viewModel.genreShows.enumerated()), id: \.element.id) { index, show in
                            TrendingShowCard(
                                show: show,
                                logoPath: nil,
                                seasonNumber: nil,
                                isFollowed: viewModel.isFollowed(tmdbId: show.id),
                                isLoading: viewModel.isAdding(tmdbId: show.id),
                                onTap: {
                                    Task {
                                        await viewModel.selectShow(tmdbId: show.id)
                                    }
                                },
                                onAdd: {
                                    Task {
                                        await viewModel.toggleFollow(tmdbId: show.id)
                                    }
                                }
                            )
                            .onAppear {
                                // Load more when reaching the last few items
                                if index >= viewModel.genreShows.count - 4 {
                                    Task {
                                        await viewModel.loadMoreGenreShows()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)

                    // Loading indicator at bottom
                    if viewModel.isLoadingGenre && !viewModel.genreShows.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadGenreShows(genreIds: category.genreIds)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 80)

            Image(systemName: "tv")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))

            VStack(spacing: 8) {
                Text("No Shows Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Try a different category")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        GenreListView(
            viewModel: SearchViewModel(
                tmdbService: PreviewGenreTMDBService(),
                addShowUseCase: PreviewGenreAddShowUseCase(),
                repository: PreviewGenreShowRepository()
            ),
            category: .sciFiFantasy
        )
    }
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

private class PreviewGenreTMDBService: TMDBServiceProtocol {
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

private class PreviewGenreAddShowUseCase: AddShowUseCaseProtocol {
    func execute(tmdbId: Int) async throws -> Show {
        fatalError("Not implemented")
    }
}

private class PreviewGenreShowRepository: ShowRepositoryProtocol {
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
