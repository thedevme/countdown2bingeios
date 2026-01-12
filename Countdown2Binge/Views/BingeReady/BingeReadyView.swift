//
//  BingeReadyView.swift
//  Countdown2Binge
//

import SwiftUI
import SwiftData

/// The Binge Ready screen showing all seasons ready to watch.
struct BingeReadyView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: BingeReadyViewModel
    @State private var selectedItem: BingeReadyItem?
    @State private var selectedSeasons: [Int: Int] = [:] // showId -> seasonNumber
    @State private var showDeleteConfirmation: Show?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                if viewModel.isLoading && !viewModel.hasItems {
                    loadingView
                } else if !viewModel.hasItems {
                    emptyStateView
                } else {
                    bingeReadyContent
                }
            }
            .navigationTitle("Binge Ready")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.loadSeasons()
            }
            .navigationDestination(item: $selectedItem) { item in
                ShowDetailView(
                    viewModel: ShowDetailViewModel(
                        show: item.show,
                        repository: ShowRepository(modelContext: modelContext)
                    )
                )
            }
            .confirmationDialog(
                "Mark as Watched",
                isPresented: .init(
                    get: { viewModel.itemToMarkWatched != nil },
                    set: { if !$0 { viewModel.cancelMarkWatched() } }
                ),
                titleVisibility: .visible
            ) {
                Button("Mark Watched") {
                    Task {
                        await viewModel.confirmMarkWatched()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelMarkWatched()
                }
            } message: {
                if let item = viewModel.itemToMarkWatched {
                    Text("Mark \(item.show.name) Season \(item.season.seasonNumber) as watched?")
                }
            }
        }
    }

    // MARK: - Content

    private var bingeReadyContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Summary header
                summaryHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Card stacks grouped by show
                VStack(spacing: 40) {
                    ForEach(viewModel.groupedByShow) { group in
                        SeasonCardStack(
                            seasons: group.seasons,
                            showName: group.show.name,
                            selectedSeasonNumber: selectedSeasonBinding(for: group),
                            onMarkAllComplete: { seasonNumber in
                                Task {
                                    await viewModel.markSeasonWatched(
                                        showId: group.show.id,
                                        seasonNumber: seasonNumber
                                    )
                                }
                            },
                            onDeleteShow: {
                                showDeleteConfirmation = group.show
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            "Remove Show",
            isPresented: .init(
                get: { showDeleteConfirmation != nil },
                set: { if !$0 { showDeleteConfirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let show = showDeleteConfirmation {
                    Task {
                        await viewModel.deleteShow(show)
                    }
                }
                showDeleteConfirmation = nil
            }
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = nil
            }
        } message: {
            if let show = showDeleteConfirmation {
                Text("Stop following \(show.name)?")
            }
        }
    }

    private func selectedSeasonBinding(for group: BingeReadyShowGroup) -> Binding<Int> {
        Binding(
            get: {
                selectedSeasons[group.show.id] ?? group.seasons.first?.seasonNumber ?? 1
            },
            set: { newValue in
                selectedSeasons[group.show.id] = newValue
            }
        )
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 24) {
            SummaryItem(
                value: "\(viewModel.itemCount)",
                label: viewModel.itemCount == 1 ? "SEASON" : "SEASONS"
            )

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 32)

            SummaryItem(
                value: "\(viewModel.totalEpisodes)",
                label: "EPISODES"
            )

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white.opacity(0.6))
                .scaleEffect(1.2)

            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70).opacity(0.4))
            }

            VStack(spacing: 10) {
                Text("Nothing to Binge Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))

                Text("When seasons finish airing, they'll\nappear here ready to watch")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Summary Item

private struct SummaryItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Preview

#Preview("With Items") {
    BingeReadyView(
        viewModel: BingeReadyViewModel(
            repository: MockBingeRepository()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    BingeReadyView(
        viewModel: BingeReadyViewModel(
            repository: MockEmptyBingeRepository()
        )
    )
    .preferredColorScheme(.dark)
}

// MARK: - Mock Repositories for Preview

private class MockBingeRepository: ShowRepositoryProtocol {
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

private class MockEmptyBingeRepository: ShowRepositoryProtocol {
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
