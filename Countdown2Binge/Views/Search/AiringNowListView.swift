//
//  AiringNowListView.swift
//  Countdown2Binge
//

import SwiftUI

/// A view showing all currently airing shows.
struct AiringNowListView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                if viewModel.isLoadingAiring && viewModel.airingShows.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 100)
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.airingShows.enumerated()), id: \.element.show.id) { index, item in
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
                                        await viewModel.toggleFollow(tmdbId: item.show.id)
                                    }
                                }
                            )
                            .onAppear {
                                // Load more when reaching the last few items
                                if index >= viewModel.airingShows.count - 3 {
                                    Task {
                                        await viewModel.loadMoreAiringShows()
                                    }
                                }
                            }
                        }

                        // Loading indicator at bottom
                        if viewModel.isLoadingAiring && !viewModel.airingShows.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Ending Soon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AiringNowListView(
            viewModel: SearchViewModel(
                tmdbService: PreviewTMDBService(),
                addShowUseCase: PreviewAddShowUseCase(),
                repository: PreviewShowRepository()
            )
        )
    }
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

private class PreviewTMDBService: TMDBServiceProtocol {
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

private class PreviewAddShowUseCase: AddShowUseCaseProtocol {
    func execute(tmdbId: Int) async throws -> Show {
        fatalError("Not implemented")
    }
}

private class PreviewShowRepository: ShowRepositoryProtocol {
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
