//
//  MyListWatchedGrid.swift
//  Countdown2Binge
//
//  Poster grid of shows (Watched or Archived) — tap a poster and an inline panel
//  drops in under that row listing the show's seasons as landscape cards.
//  Ported from c2b-mylist.jsx `MLWatchedGrid`; reused for the Archived tab.
//

import SwiftUI

enum ShowGridVariant { case watched, archived }

/// One show's worth of data for the grid.
struct WatchedShow: Identifiable {
    let id: Int
    let series: Series
    let title: String
    let posterURL: URL?
    /// Seasons to reveal in the expanded panel, newest first.
    let seasons: [MyListSeasonDisplay]
    let episodeCount: Int
    let watchTimeSeconds: Int

    var seasonCount: Int { seasons.count }
}

struct MyListWatchedGrid: View {
    let shows: [WatchedShow]
    var variant: ShowGridVariant = .watched
    var onOpenSeries: (Series) -> Void = { _ in }

    @State private var openId: Int?

    private let columns = 3
    private var totalSeasons: Int { shows.reduce(0) { $0 + $1.seasonCount } }
    private var totalSeconds: Int { shows.reduce(0) { $0 + $1.watchTimeSeconds } }
    private var rows: [[WatchedShow]] { shows.chunked(into: columns) }
    private var openShow: WatchedShow? { shows.first { $0.id == openId } }

    var body: some View {
        VStack(spacing: 20) {
            totalsHeader

            LazyVStack(spacing: 13) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(row) { show in
                            tile(show)
                        }
                        ForEach(0..<(columns - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }

                    if let open = openShow, row.contains(where: { $0.id == open.id }) {
                        panel(open)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    // MARK: - Totals header

    private var headerBigNumber: Int { variant == .watched ? totalSeasons : shows.count }

    private var headerTitle: String {
        switch variant {
        case .watched:
            return String(format: NSLocalizedString("mylist_ls_finished %lld", comment: ""), shows.count)
        case .archived:
            return String(localized: "mylist_ls_setaside")
        }
    }

    private var headerClockLabel: String {
        variant == .watched
            ? String(localized: "mylist_ls_clock_watched")
            : String(localized: "mylist_ls_clock_archived")
    }

    private var totalsHeader: some View {
        HStack(spacing: 13) {
            Text(String(format: "%02d", headerBigNumber))
                .font(.custom(.oswald.bold, size: 30))
                .foregroundColor(.c2bDim)

            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.c2bText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "mylist_ls_tap_seasons"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.8)
                    .foregroundColor(.c2bMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 11) {
                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 34)
                VStack(alignment: .trailing, spacing: 4) {
                    RuntimeClock(seconds: totalSeconds, numberSize: 20, unitSize: 9, tone: .c2bDim)
                    Text(headerClockLabel)
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.75)
                        .foregroundColor(.c2bMuted)
                }
            }
            .fixedSize()
        }
        .padding(.vertical, 13).padding(.horizontal, 15)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.09), lineWidth: 1))
    }

    // MARK: - Poster tile

    private func tile(_ show: WatchedShow) -> some View {
        let on = openId == show.id
        return Button {
            withAnimation(.easeInOut(duration: 0.24)) { openId = on ? nil : show.id }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .overlay(
                        PosterView(url: show.posterURL, cornerRadius: 0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .grayscale(on ? 0 : (variant == .archived ? 1 : 0.55))
                            .brightness(on ? -0.28 : (variant == .watched ? -0.2 : -0.4))
                    )
                    .overlay(
                        LinearGradient(colors: [Color(hex: "#060808").opacity(0.95), .clear],
                                       startPoint: .bottom, endPoint: .center)
                    )
                    .overlay(alignment: .bottomLeading) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(show.seasonCount)")
                                .font(.custom(.oswald.bold, size: 15))
                                .foregroundColor(on ? .c2bTealBright : .white)
                            Text(show.seasonCount == 1 ? String(localized: "mylist_ls_word_season") : String(localized: "mylist_ls_word_seasons"))
                                .font(.custom(.jetbrains.regular, size: 8))
                                .tracking(0.7)
                                .foregroundColor(.c2bMuted)
                        }
                        .padding(.horizontal, 8).padding(.bottom, 7)
                    }
                    .overlay(alignment: .topTrailing) {
                        ZStack {
                            Circle().fill(Color(hex: "#080808").opacity(0.72))
                                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                                .frame(width: 18, height: 18)
                            Image(systemName: variant == .watched ? "checkmark" : "archivebox.fill")
                                .font(.system(size: variant == .watched ? 9 : 8, weight: .heavy))
                                .foregroundColor(.c2bDim)
                        }
                        .padding(7)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(on ? Color.c2bTealLine : Color.white.opacity(0.1), lineWidth: 1)
                    )

                Text(show.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(on ? .c2bText : .c2bDim)
                    .lineLimit(1)
                    .padding(.top, 8)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Expanded panel

    private func panel(_ show: WatchedShow) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.c2bText)
                        .lineLimit(1)
                    Text("\(show.seasonCount) " + (show.seasonCount == 1 ? String(localized: "mylist_ls_word_season") : String(localized: "mylist_ls_word_seasons")) + " · \(show.episodeCount) " + (show.episodeCount == 1 ? String(localized: "mylist_ls_word_episode") : String(localized: "mylist_ls_word_episodes")))
                        .font(.custom(.jetbrains.regular, size: 9))
                        .tracking(0.68)
                        .foregroundColor(.c2bMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                RuntimeClock(seconds: show.watchTimeSeconds, numberSize: 17, unitSize: 8, tone: .c2bDim)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { openId = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.c2bMuted)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15).padding(.vertical, 13)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
            }

            if show.seasons.isEmpty {
                Text(String(localized: "mylist_ls_no_seasons"))
                    .font(.system(size: 14))
                    .foregroundColor(.c2bMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
            } else {
                VStack(spacing: 18) {
                    ForEach(show.seasons) { season in
                        MyListLandscapeCard(season: season, onOpen: { onOpenSeries(show.series) })
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 16)
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
