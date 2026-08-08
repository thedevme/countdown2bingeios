//
//  MyListLandscapeCard.swift
//  Countdown2Binge
//
//  The "landscape" My List season card — a Wallet-style deck where earlier
//  seasons peek above a 16:9 face card. Ported 1:1 from c2b-mylist.jsx
//  `MLCardLandscape`. DESIGN-ONLY: driven by MyListSeasonDisplay (sample data),
//  not wired to SwiftData / BingeEngine.
//

import SwiftUI

struct MyListLandscapeCard: View {
    let season: MyListSeasonDisplay
    var onOpen: () -> Void = {}
    /// Marks the season's aired episodes watched. A complete season becomes fully
    /// watched → advances; a still-airing season stays (unaired episodes remain).
    var onMarkAll: (() -> Void)? = nil

    private let peek: CGFloat = 7
    private let deckTints: [Color] = [
        Color(hex: "#1b1b1e"), Color(hex: "#232326"),
        Color(hex: "#2b2b2f"), Color(hex: "#333338"),
    ]

    private var isReady: Bool { season.isReady }
    private var isDone: Bool { season.isDone }
    private var allWatched: Bool { season.allWatched }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                deck
                EpisodeTickMeter(
                    episodeCount: season.episodeCount,
                    watchedCount: season.watchedCount,
                    releasedCount: max(season.releasedCount, season.watchedCount)
                )
                .padding(.top, 9)

                detailRow
                    .padding(.top, 8)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Deck (peeking seasons + face card)

    private var deck: some View {
        let depth = season.stackDepth
        return ZStack(alignment: .top) {
            // seasons behind, peeking up like cards in a wallet (furthest first)
            ForEach(Array(stride(from: depth - 1, through: 1, by: -1)), id: \.self) { k in
                RoundedRectangle(cornerRadius: 14)
                    .fill(deckTints[min(k - 1, 3)])
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, y: -2)
                    .padding(.horizontal, CGFloat(k) * 5)
                    .offset(y: -CGFloat(k) * peek)
            }

            faceCard
        }
        .padding(.top, CGFloat(depth - 1) * peek)
    }

    private var faceCard: some View {
        Color.clear
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay(faceContent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isReady ? Color.c2bTealLine : Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: isReady ? Color.c2bTeal.opacity(0.20) : Color.black.opacity(0.5),
                    radius: isReady ? 14 : 13, y: isReady ? 10 : 10)
    }

    private var faceContent: some View {
        ZStack(alignment: .topLeading) {
            LandscapeBackdrop(url: season.backdropURL, seed: season.showTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .grayscale(isDone ? 1 : 0)
                .brightness(isDone ? -0.4 : 0)   // flat darkener removed on active cards

            // bottom scrim keeps the show name legible over bright key art
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#060808").opacity(0.85), location: 0),
                    .init(color: Color(hex: "#060808").opacity(0), location: 0.55),
                ],
                startPoint: .bottom, endPoint: .top
            )
            // top-left scrim for the S · E identity
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#060808").opacity(0.72), location: 0),
                    .init(color: Color(hex: "#060808").opacity(0), location: 0.5),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // season · episode, big and top-left — the card's identity
            VStack(alignment: .leading, spacing: 5) {
                deckNumber
                Text(season.deckSublabel)
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .tracking(1.05)
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.leading, 14)
            .padding(.top, 12)
        }
        .overlay(alignment: .topTrailing) {
            SeasonStatePip(state: season.state)
                .padding(11)
        }
        .overlay(alignment: .bottomLeading) {
            // show name lives inside the card, bottom-left
            Text(season.showTitle.uppercased())
                .font(.custom(.oswald.bold, size: 22))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                .padding(.leading, 14)
                .padding(.trailing, 14)
                .padding(.bottom, 12)
        }
    }

    private var deckNumber: some View {
        let base: Color = isReady ? .c2bTealBright : .white
        return (
            Text("S\(season.seasonNumber)")
            + Text("E").foregroundColor(base.opacity(0.55))
            + Text("\(season.upNextEpisode)")
        )
        .font(.custom(.oswald.bold, size: 38))
        .foregroundColor(base)
        .lineLimit(1)
    }

    // MARK: - Detail row

    private var detailRow: some View {
        HStack(alignment: .top, spacing: 8) {
            // timestamp on the left, directly under the indicators, with the
            // episode count (spelled out, no "nights") beneath it
            VStack(alignment: .leading, spacing: 0) {
                RuntimeClock(seconds: season.totalSeconds, numberSize: 30, unitSize: 12)
                Text("\(season.episodeCount) " + (season.episodeCount == 1 ? String(localized: "mylist_ls_word_episode") : String(localized: "mylist_ls_word_episodes")))
                    .font(.custom(.jetbrains.regular, size: 10.5))
                    .tracking(0.57)
                    .foregroundColor(.c2bMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            markAllButton
        }
    }

    private var markAllButton: some View {
        Button {
            onMarkAll?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                Text(String(localized: "mylist_ls_all"))
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(0.56)
            }
            .foregroundColor(allWatched ? .c2bOnTeal : .c2bDim)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(allWatched ? Color.c2bTeal : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(allWatched ? Color.c2bTeal : Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Landscape cards") {
    ScrollView {
        VStack(spacing: 13) {
            ForEach(MyListLandscapeSample.active) { season in
                MyListLandscapeCard(season: season)
            }
        }
        .padding(20)
    }
    .background(Color.c2bBackground)
}
