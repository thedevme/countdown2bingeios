//
//  ImportShowsView.swift
//  Countdown2Binge
//
//  Bulk-add shows from a pasted list. Ported from c2b-import.jsx.
//
//  Premium only — the free tier caps at three shows, so there is nothing to
//  bulk import.
//
//  Resolution is deliberately NOT a queue. Every title gets its own task and
//  they run concurrently, capped at `maxInFlight` so TMDB doesn't rate-limit a
//  long paste. Each row settles the instant its own fetch lands, so results
//  arrive out of order and one slow — or failing — title never holds up the
//  rest. Titles that can't be found are skipped, then listed at the end so the
//  user can fix a typo and paste again.
//
//  Every follow goes through SeriesManager (R3).
//

import SwiftUI
import SwiftData
import StoreKit

struct ImportShowsView: View {
    let onDismiss: () -> Void

    @Environment(SeriesManager.self) private var seriesManager
    @Environment(\.requestReview) private var requestReview

    @State private var raw: String = ""
    @State private var items: [Item] = []
    @State private var isRunning = false
    @State private var hasRun = false
    @State private var showReviewConfirm = false

    /// Concurrent lookups in flight. Enough to feel instant on a long paste,
    /// low enough that TMDB doesn't start refusing us.
    private let maxInFlight = 10

    /// One pasted title and where it has got to.
    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        var state: ImportItemState = .waiting
    }

    // MARK: - Derived

    private var parsedTitles: [String] { ImportTitleParser.parse(raw) }

    private var addedCount: Int {
        items.filter {
            if case .added = $0.state { return true }
            return false
        }.count
    }

    private var missedTitles: [String] {
        items.filter { $0.state == .notFound || $0.state == .failed }.map(\.title)
    }

    private var isComplete: Bool {
        hasRun && !isRunning
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Text(String(localized: "import_intro"))
                    .font(.system(size: 13.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .padding(.bottom, 16)

                if !hasRun {
                    pasteField
                }

                if !items.isEmpty {
                    resultsList
                        .padding(.top, hasRun ? 0 : 20)
                }

                if isComplete, !missedTitles.isEmpty {
                    missedSection
                        .padding(.top, 18)
                }

                actionButton
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
            .padding(.bottom, 150)
        }
        .background(Color.c2bBackground)
        .navigationBarBackButtonHidden(true)
        // Same confirm step as everywhere else — "Rate" is the one signal we
        // own, and it retires every future prompt.
        .alert(String(localized: "review_prompt_title"), isPresented: $showReviewConfirm) {
            Button(String(localized: "review_prompt_rate")) {
                ReviewPrompt.markRated()
                requestReview()
            }
            Button(String(localized: "review_prompt_later"), role: .cancel) { }
        } message: {
            Text(String(localized: "review_prompt_message"))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(white: 0.8))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(String(localized: "import_title"))
                .font(.custom(.oswald.bold, size: 25))
                .foregroundColor(.c2bText)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Paste field

    private var pasteField: some View {
        VStack(spacing: 0) {
            TextEditor(text: $raw)
                .font(.system(size: 14))
                .foregroundColor(.c2bText)
                .scrollContentBackground(.hidden)
                .frame(height: 158)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .overlay(alignment: .topLeading) {
                    if raw.isEmpty {
                        Text(String(localized: "import_placeholder"))
                            .font(.system(size: 14))
                            .foregroundColor(.c2bMuted)
                            .lineSpacing(6)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }

            HStack(spacing: 10) {
                Text(countLabel)
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .tracking(0.85)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !raw.isEmpty {
                    Button(String(localized: "button_clear")) { raw = "" }
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.85)
                        .textCase(.uppercase)
                        .foregroundColor(.c2bDim)
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(raw.isEmpty ? Color.white.opacity(0.10) : Color.c2bTealLine, lineWidth: 1)
        )
    }

    private var countLabel: String {
        let n = parsedTitles.count
        return n == 0
            ? String(localized: "import_nothing_pasted")
            : String(localized: "import_titles_found \(n)")
    }

    // MARK: - Results

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resultsHeader)
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1.44)
                .textCase(.uppercase)
                .foregroundColor(.c2bTealBright)

            ForEach(items) { item in
                ImportResultRow(title: item.title, state: item.state)
            }
        }
    }

    private var resultsHeader: String {
        isComplete
            ? String(localized: "import_added_count \(addedCount)")
            : String(localized: "import_adding_count \(addedCount) \(items.count)")
    }

    /// Skipped titles, gathered at the end — usually a typo the user can fix.
    private var missedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "import_missed_count \(missedTitles.count)"))
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1.44)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)

            MissedTitleChips(titles: missedTitles)

            Text(String(localized: "import_missed_hint"))
                .font(.system(size: 11.5))
                .foregroundColor(.c2bMuted)
                .lineSpacing(2)
        }
    }

    // MARK: - Action

    @ViewBuilder
    private var actionButton: some View {
        if isComplete {
            VStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text(String(localized: "import_view_timeline"))
                        .font(.custom(.oswald.bold, size: 16))
                        .tracking(0.48)
                        .foregroundColor(.c2bOnTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(String(localized: "import_another")) {
                    raw = ""
                    items = []
                    hasRun = false
                }
                .font(.custom(.jetbrains.regular, size: 10))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
                .buttonStyle(.plain)
            }
        } else if !hasRun {
            Button {
                Task { await runImport() }
            } label: {
                Text(parsedTitles.isEmpty
                     ? String(localized: "import_cta_empty")
                     : String(localized: "import_cta_add \(parsedTitles.count)"))
                    .font(.custom(.oswald.bold, size: 16))
                    .tracking(0.48)
                    .foregroundColor(parsedTitles.isEmpty ? .c2bMuted : .c2bOnTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(parsedTitles.isEmpty ? Color.white.opacity(0.07) : Color.c2bTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(parsedTitles.isEmpty)
        }
    }

    // MARK: - Import

    /// Fan every title out at once, `maxInFlight` at a time. Not a queue: as
    /// soon as one finishes the next starts, and each row updates on its own.
    private func runImport() async {
        let titles = parsedTitles
        guard !titles.isEmpty else { return }

        items = titles.map { Item(title: $0) }
        hasRun = true
        isRunning = true

        await withTaskGroup(of: (Int, ImportItemState).self) { group in
            var next = 0

            func addTask(_ index: Int) {
                let title = titles[index]
                items[index].state = .searching
                group.addTask { @MainActor in
                    (index, await resolve(title: title))
                }
            }

            while next < titles.count && next < maxInFlight {
                addTask(next)
                next += 1
            }

            for await (index, state) in group {
                items[index].state = state
                if next < titles.count {
                    addTask(next)
                    next += 1
                }
            }
        }

        isRunning = false

        // A finished import is a good moment to ask: the user just got a pile of
        // shows in one action and can see it worked. Its own one-time trigger,
        // separate from the search cadence — a bulk import never shifts the
        // 1/5/10 counter, and search follows never consume this ask.
        if addedCount > 0, ReviewPrompt.registerBulkImportAndShouldAsk() {
            try? await Task.sleep(for: .seconds(1.2))
            showReviewConfirm = true
        }
    }

    /// Search, pick a plausible match, follow. Any failure settles this row
    /// only — the rest of the import carries on.
    @MainActor
    private func resolve(title: String) async -> ImportItemState {
        do {
            let response = try await TMDBService().searchShows(query: title)
            // Best match, not first match: TMDB ranks by popularity, so a
            // typed "Shogun" can come back with "Abarenbo Shogun" above the
            // show actually meant. No plausible match is a miss, reported at
            // the end — never a silently-added wrong show.
            guard let index = ImportTitleParser.bestMatchIndex(
                candidates: response.results.map(\.name),
                query: title
            ) else {
                return .notFound
            }
            let match = response.results[index]

            let result = try await seriesManager.follow(id: match.id, source: .bulkImport)
            switch result {
            case .alreadyFollowing(let series):
                return .alreadyFollowing(matchedTitle: series.name)
            default:
                let series = seriesManager.series(id: match.id)
                return .added(
                    posterURL: series?.posterURL,
                    matchedTitle: series?.name ?? match.name,
                    network: series?.networks.first?.name ?? ""
                )
            }
        } catch {
            return .failed
        }
    }
}

// MARK: - Chips

/// The titles we couldn't place, one dashed chip per line. A miss list is
/// normally short, and stacking keeps long titles readable.
private struct MissedTitleChips: View {
    let titles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.c2bDim)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 999))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Color.white.opacity(0.16),
                                    style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
            }
        }
    }
}
