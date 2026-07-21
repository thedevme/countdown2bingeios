//
//  DiscoverScreen.swift
//  Countdown2Binge
//
//  Discover tab - browse new, recent & upcoming shows.
//

import SwiftUI
import SwiftData

struct DiscoverScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DiscoverViewModel()
    @State private var selectedTab: DiscoverTab = .soonerLater
    @State private var selectedNetwork: String = "all"
    @State private var navigationPath = NavigationPath()

    enum DiscoverTab {
        case soonerLater
        case byNetwork
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DISCOVER")
                            .font(.custom(.oswald.bold, size: 32))
                            .foregroundColor(.c2bText)

                        Text("NEW, RECENT & UPCOMING \u{00B7} FOLLOW BEFORE THEY DROP")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(.c2bMuted)
                            .tracking(1.0)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 20)

                    // Tab switcher
                    DiscoverTabSwitcher(selectedTab: $selectedTab)
                        .padding(.horizontal, C2BLayout.horizontalPadding)
                        .padding(.bottom, 16)

                    // Network filter chips
                    DiscoverNetworkChips(
                        selectedNetwork: $selectedNetwork,
                        networks: DiscoverViewModel.networks
                    )
                    .padding(.bottom, 24)

                    // Content based on selected tab
                    if selectedTab == .soonerLater {
                        DiscoverTimelineContent(
                            viewModel: viewModel,
                            selectedNetwork: selectedNetwork,
                            onShowTap: { show in
                                Task {
                                    await viewModel.loadShowDetail(for: show)
                                    if let showData = viewModel.selectedShowData {
                                        navigationPath.append(showData)
                                    }
                                }
                            },
                            onFollowTap: { show in
                                Task { await viewModel.toggleFollow(show) }
                            }
                        )
                    } else {
                        DiscoverNetworkContent(
                            viewModel: viewModel,
                            selectedNetwork: selectedNetwork,
                            onShowTap: { show in
                                Task {
                                    await viewModel.loadShowDetail(for: show)
                                    if let showData = viewModel.selectedShowData {
                                        navigationPath.append(showData)
                                    }
                                }
                            },
                            onFollowTap: { show in
                                Task { await viewModel.toggleFollow(show) }
                            }
                        )
                    }

                    Spacer()
                        .frame(height: 150)
                }
            }
            .background(Color.c2bBackground)
            .navigationDestination(for: ShowData.self) { showData in
                ShowDetailView(
                    show: showData,
                    cast: viewModel.selectedShowCast,
                    videos: viewModel.selectedShowVideos,
                    recommendations: viewModel.selectedShowRecommendations,
                    isFollowing: viewModel.isFollowing(ShowSummary(
                        id: showData.id,
                        name: showData.name,
                        overview: showData.overview,
                        posterPath: showData.posterPath,
                        backdropPath: showData.backdropPath,
                        firstAirDate: nil,
                        voteAverage: showData.voteAverage,
                        genreIds: showData.genres.map { $0.id }
                    )),
                    isLoadingFollow: viewModel.isLoadingFollow(for: showData.id),
                    onFollowTap: {
                        Task { await viewModel.toggleFollowSelectedShow() }
                    },
                    onRelatedTap: { recommendation in
                        Task {
                            let summary = ShowSummary(
                                id: recommendation.id,
                                name: recommendation.name,
                                overview: recommendation.overview,
                                posterPath: recommendation.posterPath,
                                backdropPath: recommendation.backdropPath,
                                firstAirDate: recommendation.firstAirDate,
                                voteAverage: recommendation.voteAverage,
                                genreIds: recommendation.genreIds
                            )
                            await viewModel.loadShowDetail(for: summary)
                            if let newShowData = viewModel.selectedShowData {
                                navigationPath.append(newShowData)
                            }
                        }
                    },
                    onDismiss: {
                        navigationPath.removeLast()
                        viewModel.clearSelectedShow()
                    }
                )
            }
        }
        .task {
            viewModel.configure(with: modelContext)
            // Fire off both loads - they update UI as data arrives
            async let cacheTask: () = viewModel.loadDiscoverFromCache()
            async let networkTask: () = viewModel.loadAllNetworks()
            _ = await (cacheTask, networkTask)
        }
        .sheet(item: Binding(
            get: { viewModel.pendingFollowShow },
            set: { _ in viewModel.clearPendingFollow() }
        )) { pendingShow in
            FollowConfirmationSheet(
                show: pendingShow,
                onSave: {
                    Task {
                        await viewModel.confirmPendingFollow()
                    }
                }
            )
        }
    }
}

// MARK: - Show with Network Info (for non-cached use)
struct ShowWithNetwork: Identifiable {
    let show: ShowSummary
    let network: NetworkDefinition

    var id: Int { show.id }
}

#Preview {
    DiscoverScreen()
        .preferredColorScheme(.dark)
}
