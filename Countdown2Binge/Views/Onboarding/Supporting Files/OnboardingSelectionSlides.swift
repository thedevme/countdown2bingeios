//
//  OnboardingSelectionSlides.swift
//  Countdown2Binge
//
//  v2 onboarding — Add Shows · Four States · Review prompt.
//  Copy loads from Localizable.strings (Add Shows keys) and OnboardingSlides.json
//  (buckets, review) via OnboardingDataLoader.
//

import SwiftUI
import Combine

private let selectionData = OnboardingDataLoader.shared

// MARK: - 10 Add your shows (no JSON slide entry — uses localized keys directly)

struct OBAddShowsSlide: View {
    /// Preferences drafted from the in-flow genre/service picks.
    let preferences: TastePreferences
    /// The shows the user chooses to follow (real TMDB shows).
    @Binding var selected: [ShowSummary]

    @State private var query = ""
    @State private var feed: [ShowSummary] = []
    @State private var searchResults: [ShowSummary] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var relaxationLabel: String?
    @State private var searchTask: Task<Void, Never>?

    // Pagination cursors — the taste feed and the title search paginate
    // independently so infinite scroll continues wherever the user is browsing.
    @State private var feedPage = 1
    @State private var feedLevel: DiscoverQuery.Relaxation = .full
    @State private var feedReachedEnd = false
    @State private var searchPage = 1
    @State private var searchTotalPages = 1

    private let tmdb = TMDBService()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 13), count: 2)

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Empty query → the preference-filtered suggestion rail. Typing → plain title
    /// search (explicit intent), which uses the untouched /search/tv path.
    private var results: [ShowSummary] { trimmedQuery.isEmpty ? feed : searchResults }

    /// Re-seed the rail if the drafted preferences change.
    private var preferenceKey: String {
        "\(preferences.genreIDs)-\(preferences.providerIDs)-\(preferences.watchRegion)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "onboarding_add_shows_label_v2"))
                .font(.custom(.jetbrains.regular, size: 10))
                .tracking(2.0)
                .foregroundColor(.c2bTeal)

            (Text(String(localized: "onboarding_add_shows_title_v2") + " ")
                + Text(String(localized: "onboarding_add_shows_accent")).foregroundColor(.c2bTeal))
                .font(.custom(.oswald.bold, size: 36))
                .foregroundColor(.white)
                .padding(.top, 10)

            Text(String(localized: "onboarding_add_shows_desc_v2"))
                .font(.system(size: 14))
                .foregroundColor(.c2bDim)
                .lineSpacing(3)
                .padding(.top, 8)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.c2bMuted)
                TextField("", text: $query, prompt: Text(String(localized: "onboarding_search_placeholder")).foregroundColor(.c2bMuted))
                    .font(.system(size: 15))
                    .foregroundColor(.c2bText)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.top, 16)

            // Honest label when the suggestion rail had to broaden.
            if trimmedQuery.isEmpty, let relaxationLabel {
                Text(relaxationLabel.uppercased())
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.9)
                    .foregroundColor(.c2bMuted)
                    .padding(.top, 12)
            }

            if isLoading && results.isEmpty {
                ProgressView()
                    .tint(.c2bTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else {
                LazyVGrid(columns: columns, spacing: 13) {
                    ForEach(results) { show in
                        OBAddShowTile(show: show, following: isSelected(show)) { toggle(show) }
                            .onAppear {
                                // Reached the last tile → pull the next page.
                                if show.id == results.last?.id { Task { await loadMore() } }
                            }
                    }
                }
                .padding(.top, 16)

                if isLoadingMore {
                    ProgressView()
                        .tint(.c2bTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: preferenceKey) { await loadFeed() }
        .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
    }

    // MARK: - Selection

    private func isSelected(_ show: ShowSummary) -> Bool {
        selected.contains { $0.id == show.id }
    }

    private func toggle(_ show: ShowSummary) {
        if let idx = selected.firstIndex(where: { $0.id == show.id }) {
            selected.remove(at: idx)
        } else {
            selected.append(show)
        }
    }

    // MARK: - Loading (same RecommendationService path the app uses)

    private func loadFeed() async {
        isLoading = true
        feedPage = 1
        feedReachedEnd = false
        let result = await RecommendationService.shared.feed(for: preferences, minResults: 10)
        feed = result.shows
        feedLevel = result.level
        relaxationLabel = result.relaxationLabel
        isLoading = false
    }

    /// Infinite scroll: append the next page of whichever list is showing — the
    /// taste feed (empty query) or the title search (typed query). De-dupes by id
    /// so tiles never collide, and stops cleanly at the end of each source.
    private func loadMore() async {
        guard !isLoadingMore else { return }

        if trimmedQuery.isEmpty {
            guard !feedReachedEnd else { return }
            isLoadingMore = true
            let next = feedPage + 1
            let more = await RecommendationService.shared.morePage(
                for: preferences, page: next, level: feedLevel)
            let seen = Set(feed.map(\.id))
            let fresh = more.filter { !seen.contains($0.id) }
            if more.isEmpty {
                feedReachedEnd = true
            } else {
                feed.append(contentsOf: fresh)
                feedPage = next
            }
            isLoadingMore = false
        } else {
            guard searchPage < searchTotalPages else { return }
            isLoadingMore = true
            let next = searchPage + 1
            if let response = try? await tmdb.searchShows(query: trimmedQuery, page: next) {
                let seen = Set(searchResults.map(\.id))
                let fresh = response.results.map { $0.toShowSummary() }
                    .filter { !seen.contains($0.id) }
                searchResults.append(contentsOf: fresh)
                searchPage = next
                searchTotalPages = response.totalPages
            }
            isLoadingMore = false
        }
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { searchResults = []; searchPage = 1; searchTotalPages = 1; return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            guard let response = try? await tmdb.searchShows(query: q, page: 1),
                  !Task.isCancelled else { return }
            searchResults = response.results.map { $0.toShowSummary() }
            searchPage = 1
            searchTotalPages = response.totalPages
        }
    }
}

private struct OBAddShowTile: View {
    let show: ShowSummary
    let following: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                PosterView(url: show.posterURL, cornerRadius: 11)
                    .overlay(alignment: .topLeading) {
                        if following {
                            ZStack {
                                Circle().fill(Color.c2bTeal).frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(.c2bOnTeal)
                            }
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            .padding(7)
                        }
                    }
                Text(show.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .padding(.top, 9)
                Text(following ? "✓ " + String(localized: "onboarding_following") : String(localized: "onboarding_tap_to_follow"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.72)
                    .foregroundColor(following ? .c2bTealBright : .c2bMuted)
                    .padding(.top, 4)
            }
            .padding(9)
            .background(following ? Color.c2bTeal.opacity(0.06) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(following ? Color.c2bTealLine : Color.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 12 Four states

struct OBBucketsSlide: View {
    private var slide: OnboardingSlide? { selectionData.bucketsSlide }
    private var buckets: [BucketInfo] { selectionData.allBuckets }

    @State private var lit = 3
    private let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    private func color(for id: String) -> Color {
        switch id {
        case "bingeReady": return .c2bTealBright
        case "nowAiring": return .c2bTeal
        case "premieringSoon": return Color.c2bTeal.opacity(0.6)
        default: return Color.white.opacity(0.34)
        }
    }

    var body: some View {
        OBSlide(eyebrow: slide?.label, title: slide?.headline, accent: slide?.headlineAccent) {
            VStack(spacing: 9) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { i, bucket in
                    let on = lit == i
                    let tint = color(for: bucket.id)
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(tint)
                            .frame(width: 11, height: 11)
                            .overlay(Circle().stroke(on ? Color.c2bTeal.opacity(0.16) : Color.clear, lineWidth: 5))
                            .padding(.top, 4)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(bucket.title)
                                .font(.custom(.oswald.bold, size: 18))
                                .foregroundColor(bucket.id == "anticipated" ? .c2bText : tint)
                            Text(bucket.description)
                                .font(.system(size: 12.5))
                                .foregroundColor(.c2bMuted)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 15).padding(.vertical, 13)
                    .background(on ? Color.c2bTeal.opacity(0.07) : Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.4), value: lit)
                }
            }
            .padding(.top, 22)
        }
        .onReceive(timer) { _ in
            if !buckets.isEmpty { lit = (lit - 1 + buckets.count) % buckets.count }
        }
    }
}

// MARK: - 13 Review prompt

struct OBReviewSlide: View {
    let count: Int
    private var slide: OnboardingSlide? { selectionData.reviewPromptSlide }

    var body: some View {
        VStack(spacing: 0) {
            if let label = slide?.label {
                Text(label)
                    .font(.custom(.jetbrains.regular, size: 10))
                    .tracking(2.0)
                    .foregroundColor(.c2bTeal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 20)

            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.c2bTealBright)
                }
            }
            .padding(.bottom, 22)

            (Text((slide?.headline ?? "") + "\n") + Text(slide?.headlineAccent ?? "").foregroundColor(.c2bTeal))
                .font(.custom(.oswald.bold, size: 34))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            if let body = slide?.body {
                Text(body)
                    .font(.system(size: 14.5))
                    .foregroundColor(.c2bDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
                    .padding(.top, 18)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}
