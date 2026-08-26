import SwiftUI
import SwiftData
import RevenueCat

// MARK: - Search Screen
struct SearchScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SeriesManager.self) private var seriesManager
    @State private var viewModel = DiscoverViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showPaywall: Bool = false
    /// Explains WHY the follow was refused, before any sales page.
    @State private var showLimitSheet: Bool = false
    @State private var selectedPlan: String = "yearly"
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var showGracePeriodAlert: Bool = false
    @State private var showNotificationOnboarding: Bool = false

    /// Badge manager for tab notifications
    var badgeManager: TabBadgeManager?

    /// Notification settings store for onboarding check
    private var notificationSettingsStore: NotificationSettingsStore { NotificationSettingsStore.shared }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Show search results or browse content
                    if !viewModel.searchText.isEmpty {
                        // Search results
                        if viewModel.isSearching && viewModel.searchResults.isEmpty {
                            ProgressView()
                                .tint(Color(hex: "#71717a"))
                                .padding(.top, 40)
                        } else if viewModel.searchResults.isEmpty {
                            Text(String(localized: "search_no_results"))
                                .monoStyle(size: 12, color: .c2bMuted)
                                .padding(.top, 40)
                        } else {
                            ShowGrid(
                                shows: viewModel.searchResults,
                                isFollowing: { viewModel.isFollowing($0) },
                                onTap: { summary in
                                    Task {
                                        await viewModel.loadShowDetail(for: summary)
                                        if let showData = viewModel.selectedShowData {
                                            navigationPath.append(showData)
                                        }
                                    }
                                },
                                onFollowTap: { show in
                                    Task { await viewModel.toggleFollow(show) }
                                }
                            )
                            .padding(.horizontal, C2BLayout.horizontalPadding)
                            .padding(.top, 20)
                        }
                    } else {
                        // Genre chips (tappable)
                        GenreChipRow(
                            genres: DiscoverViewModel.genres,
                            onGenreTap: { genre in
                                navigationPath.append(genre)
                            }
                        )
                        .padding(.top, 16)

                        // Trending Shows title
                        HStack {
                            Text("Trending Shows")
                                .displayStyle(size: 20, color: .c2bText)
                            Spacer()
                        }
                        .padding(.horizontal, C2BLayout.horizontalPadding)
                        .padding(.top, 24)

                        // Trending shows grid with infinite scroll
                        if viewModel.isLoading && viewModel.trendingShows.isEmpty {
                            ProgressView()
                                .tint(Color(hex: "#71717a"))
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(Array(viewModel.trendingShows.enumerated()), id: \.element.id) { index, show in
                                    ShowGridCard(
                                        show: show,
                                        isFollowing: viewModel.isFollowing(show),
                                        onTap: {
                                            Task {
                                                await viewModel.loadShowDetail(for: show)
                                                if let showData = viewModel.selectedShowData {
                                                    navigationPath.append(showData)
                                                }
                                            }
                                        },
                                        onFollowTap: {
                                            Task { await viewModel.toggleFollow(show) }
                                        }
                                    )
                                    .id("\(show.id)-\(viewModel.isFollowing(show))")
                                    .onAppear {
                                        // Load more when approaching the end (last 4 items)
                                        if index >= viewModel.trendingShows.count - 4 {
                                            Task {
                                                await viewModel.loadMoreTrendingShows()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, C2BLayout.horizontalPadding)
                            .padding(.top, 16)

                            // Loading indicator for pagination
                            if viewModel.isLoadingMoreTrending {
                                ProgressView()
                                    .tint(Color(hex: "#71717a"))
                                    .padding(.top, 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 150)
            }
            .scrollDismissesKeyboard(.immediately)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(String(localized: "search_heading"))
            .searchable(text: $viewModel.searchText, prompt: String(localized: "search_placeholder"))
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
                    // Load and navigate to related show
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
        .navigationDestination(for: GenreDefinition.self) { genre in
            GenreShowsScreen(
                genre: genre,
                viewModel: viewModel,
                onShowTap: { summary in
                    Task {
                        await viewModel.loadShowDetail(for: summary)
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
        }
        .task {
            viewModel.configure(with: modelContext, seriesManager: seriesManager)
            await viewModel.loadTrendingShows()
        }
        .sheet(item: Binding(
            get: { viewModel.pendingFollowShow },
            set: { _ in viewModel.clearPendingFollow() }
        )) { pendingShow in
            AddShowModal(
                show: pendingShow,
                addTimePrompt: pendingShow.addTimePrompt,
                onDone: { lastWatchedSeason in
                    // Trigger badge based on show state
                    badgeManager?.showFollowed(pendingShow)

                    // Follow + mark all seasons through the one they finished
                    Task {
                        await viewModel.handleAddShowDone(lastWatchedSeason: lastWatchedSeason)
                    }

                    // First follow — but only for someone who will actually
                    // receive notifications. Free users get every alert skipped
                    // at scheduling time, so asking them to pick which ones they
                    // want promises something the app won't deliver.
                    if PremiumManager.shared.canUseNotifications,
                       !notificationSettingsStore.hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showNotificationOnboarding = true
                        }
                    }
                }
            )
        }
        .overlay {
            // Re-checked at render: premium can lapse between the follow and
            // the half-second delay above.
            if showNotificationOnboarding, PremiumManager.shared.canUseNotifications {
                NotificationOnboardingOverlay(onSave: {
                    showNotificationOnboarding = false
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showNotificationOnboarding)
        .onChange(of: viewModel.showPremiumUpgrade) { _, show in
            if show {
                // Explain the block first. The paywall is one tap further on —
                // throwing it up unprompted left users with no idea why their
                // Follow tap did nothing.
                showLimitSheet = true
                viewModel.showPremiumUpgrade = false
            }
        }
        .sheet(isPresented: $showLimitSheet) {
            ShowLimitSheet(
                limit: PremiumManager.shared.showLimit,
                posterURLs: seriesManager.allSeries()
                    .sorted { $0.dateAdded < $1.dateAdded }
                    .map(\.posterURL),
                onUpgrade: {
                    showLimitSheet = false
                    // Let the first sheet finish dismissing before presenting
                    // the next, or the paywall never appears.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showPaywall = true
                    }
                },
                onDismiss: { showLimitSheet = false }
            )
        }
        .onChange(of: viewModel.showGracePeriodBlock) { _, show in
            if show {
                showGracePeriodAlert = true
                viewModel.showGracePeriodBlock = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            DiscoverPaywallSheet(
                selectedPlan: $selectedPlan,
                isPurchasing: $isPurchasing,
                purchaseError: $purchaseError,
                onDismiss: { showPaywall = false }
            )
        }
        .alert(
            String(localized: "grace_cannot_follow_title"),
            isPresented: $showGracePeriodAlert
        ) {
            Button(String(localized: "button_ok"), role: .cancel) {}
        } message: {
            Text("grace_cannot_follow_message")
        }
    }
}


// MARK: - Search Bar (for Onboarding)
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.c2bMuted)

            TextField(String(localized: "search_placeholder"), text: $text)
                .font(CustomFonts.ui(size: 15))
                .foregroundColor(.c2bText)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.c2bMuted)
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Segmented Tab Control
struct SegmentedTabControl: View {
    let tabs: [String: String]
    @Binding var selectedTab: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.keys.sorted()), id: \.self) { key in
                Button(action: { selectedTab = key }) {
                    Text(tabs[key] ?? key)
                        .monoStyle(
                            size: 10,
                            color: selectedTab == key ? Color(hex: "#04201c") : .c2bDim
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selectedTab == key ? Color.c2bTeal : Color.clear)
                        .cornerRadius(9)
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Genre Chip Row (tappable, scrollable)
struct GenreChipRow: View {
    let genres: [GenreDefinition]
    let onGenreTap: (GenreDefinition) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(genres) { genre in
                    Button(action: { onGenreTap(genre) }) {
                        ChipView(genre.name, isActive: false)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                    }
                }
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Genre Shows Screen
struct GenreShowsScreen: View {
    let genre: GenreDefinition
    let viewModel: DiscoverViewModel
    let onShowTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    @Environment(\.dismiss) private var dismiss

    private var shows: [ShowSummary] {
        viewModel.genreShows[genre.id] ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Shows grid
                if viewModel.isLoadingGenre && shows.isEmpty {
                    ProgressView()
                        .tint(Color(hex: "#71717a"))
                        .padding(.top, 60)
                } else if !shows.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Array(shows.enumerated()), id: \.element.id) { index, show in
                            ShowGridCard(
                                show: show,
                                isFollowing: viewModel.isFollowing(show),
                                onTap: { onShowTap(show) },
                                onFollowTap: { onFollowTap(show) }
                            )
                            .id("\(show.id)-\(viewModel.isFollowing(show))")
                            .onAppear {
                                // Load more when approaching the end (last 4 items)
                                if index >= shows.count - 4 {
                                    Task {
                                        await viewModel.loadMoreShowsForGenre(genre.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.top, 20)

                    // Loading indicator for pagination
                    if viewModel.isLoadingMoreGenre {
                        ProgressView()
                            .tint(Color(hex: "#71717a"))
                            .padding(.top, 20)
                    }
                } else {
                    Text(String(localized: "search_no_results"))
                        .monoStyle(size: 12, color: .c2bMuted)
                        .padding(.top, 60)
                }

                Spacer()
                    .frame(height: 150)
            }
        }
        .background(Color.c2bBackground)
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.c2bTeal)
                }
            }
        }
        .task {
            await viewModel.loadShowsForGenre(genre.id)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe from left edge to go back
                    if value.startLocation.x < 50 && value.translation.width > 80 {
                        dismiss()
                    }
                }
        )
    }
}

// MARK: - Genre Chip Scroll (selectable)
struct GenreChipScroll: View {
    @Binding var selectedGenre: String
    let genres: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(genres, id: \.self) { genre in
                    Button(action: { selectedGenre = genre }) {
                        ChipView(genre, isActive: selectedGenre == genre)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                    }
                }
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Genre Row Section
struct GenreRowSection: View {
    let genreName: String
    let shows: [ShowSummary]
    let isFollowing: (ShowSummary) -> Bool
    let onTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(genreName.uppercased())
                .displayStyle(size: 14, color: .c2bText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(shows.prefix(10)) { show in
                        NetworkShowThumb(
                            show: show,
                            isFollowing: isFollowing(show),
                            onTap: { onTap(show) },
                            onFollowTap: { onFollowTap(show) }
                        )
                        .id("\(show.id)-\(isFollowing(show))")
                    }
                }
            }
        }
    }
}

// MARK: - Show Grid
struct ShowGrid: View {
    let shows: [ShowSummary]
    let isFollowing: (ShowSummary) -> Bool
    let onTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(shows) { show in
                ShowGridCard(
                    show: show,
                    isFollowing: isFollowing(show),
                    onTap: { onTap(show) },
                    onFollowTap: { onFollowTap(show) }
                )
                .id("\(show.id)-\(isFollowing(show))")
            }
        }
    }
}

struct ShowGridCard: View {
    let show: ShowSummary
    let isFollowing: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster
            ZStack(alignment: .topLeading) {
                Button(action: onTap) {
                    AsyncImage(url: show.posterSmallURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                        .tint(Color(hex: "#71717a"))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        case .failure:
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "tv")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "#71717a"))
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                        }
                    }
                }
            }

            // Show title
            Text(show.name)
                .uiStyle(size: 12, weight: .semibold, color: .c2bText)
                .lineLimit(1)
                .padding(.top, 8)

            // Year
            Text(show.yearString ?? String(localized: "timeline_tba"))
                .monoStyle(size: 9, color: .c2bMuted)
                .padding(.top, 2)

            // Follow button
            Button(action: onFollowTap) {
                HStack(spacing: 6) {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))

                    Text(isFollowing ? String(localized: "button_following") : String(localized: "button_follow"))
                        .font(.custom(.oswald.bold, size: 13))
                        .foregroundColor(isFollowing ? .c2bTealBright : Color(hex: "#04201c"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isFollowing ? Color.c2bTeal.opacity(0.15) : Color.c2bTeal)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isFollowing ? Color.c2bTeal.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
            }
            .padding(.top, 10)
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Network List
struct NetworkList: View {
    let viewModel: DiscoverViewModel
    let onTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    var body: some View {
        VStack(spacing: 22) {
            ForEach(DiscoverViewModel.networks) { network in
                if let shows = viewModel.networkShows[network.id], !shows.isEmpty {
                    NetworkRow(
                        network: network,
                        shows: shows,
                        isFollowing: { viewModel.isFollowing($0) },
                        onTap: onTap,
                        onFollowTap: onFollowTap
                    )
                }
            }
        }
    }
}

struct NetworkRow: View {
    let network: NetworkDefinition
    let shows: [ShowSummary]
    let isFollowing: (ShowSummary) -> Bool
    let onTap: (ShowSummary) -> Void
    let onFollowTap: (ShowSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Network header
            HStack(spacing: 11) {
                // Network logo placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#1a1a1c"))
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: network.color), lineWidth: 1)
                        )

                    Text(String(network.name.prefix(1)))
                        .displayStyle(size: 16, color: Color(hex: network.color))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(network.name.uppercased())
                        .displayStyle(size: 18, color: .c2bText)

                    Text(String(localized: "network_show_count \(shows.count)"))
                        .monoStyle(size: 8.5, color: .c2bMuted)
                }

                Spacer()
            }

            // Show thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(shows.prefix(5)) { show in
                        NetworkShowThumb(
                            show: show,
                            isFollowing: isFollowing(show),
                            onTap: { onTap(show) },
                            onFollowTap: { onFollowTap(show) }
                        )
                        .id("\(show.id)-\(isFollowing(show))")
                    }
                }
            }
        }
    }
}

struct NetworkShowThumb: View {
    let show: ShowSummary
    let isFollowing: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topLeading) {
                Button(action: onTap) {
                    AsyncImage(url: show.posterSmallURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#1a1a1c"))
                                .frame(width: 92, height: 138)
                                .overlay(
                                    ProgressView()
                                        .tint(Color(hex: "#71717a"))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 92, height: 138)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#1a1a1c"))
                                .frame(width: 92, height: 138)
                                .overlay(
                                    Image(systemName: "tv")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "#71717a"))
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#1a1a1c"))
                                .frame(width: 92, height: 138)
                        }
                    }
                }

                // Follow button
                Button(action: onFollowTap) {
                    ZStack {
                        Circle()
                            .fill(isFollowing ? Color.c2bTeal : Color.black.opacity(0.6))
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isFollowing ? Color(hex: "#04201c") : .white)
                    }
                }
                .padding(6)
            }

            Text(show.name)
                .uiStyle(size: 11.5, weight: .semibold, color: .c2bText)
                .lineLimit(1)
        }
        .frame(width: 92)
    }
}

