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
        }
    }

    // MARK: - Content

    private var bingeReadyContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Summary header
                summaryHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                // Season list
                ForEach(viewModel.bingeReadyItems) { item in
                    BingeReadyRow(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }

                    if item.id != viewModel.bingeReadyItems.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 100)
                    }
                }
            }
            .padding(.bottom, 40)
        }
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

// MARK: - Binge Ready Row

private struct BingeReadyRow: View {
    let item: BingeReadyItem

    var body: some View {
        HStack(spacing: 14) {
            // Poster
            posterImage
                .frame(width: 68, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Show name
                Text(item.show.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Season
                Text("Season \(item.season.seasonNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                // Episode count and status
                HStack(spacing: 12) {
                    Label("\(item.season.episodeCount) episodes", systemImage: "play.rectangle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    if let finaleDate = item.season.finaleDate {
                        Text("Finished \(formatRelativeDate(finaleDate))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            // Binge ready indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.45, green: 0.90, blue: 0.70))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var posterImage: some View {
        // Try season poster first, fall back to show poster
        let posterPath = item.season.posterPath ?? item.show.posterPath

        if let url = TMDBConfiguration.imageURL(path: posterPath, size: .posterSmall) {
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

            Text(String(item.show.name.prefix(1)))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.2))
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
}

private class MockEmptyBingeRepository: ShowRepositoryProtocol {
    func save(_ show: Show) async throws {}
    func fetchAllShows() -> [Show] { [] }
    func fetchShow(byTmdbId id: Int) -> Show? { nil }
    func fetchTimelineShows() -> [Show] { [] }
    func fetchBingeReadySeasons() -> [Season] { [] }
    func delete(_ show: Show) async throws {}
    func isShowFollowed(tmdbId: Int) -> Bool { false }
}
