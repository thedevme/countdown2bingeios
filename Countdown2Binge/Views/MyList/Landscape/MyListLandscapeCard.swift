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
                .brightness(isDone ? -0.6 : -0.48)   // JSX: brightness .4 (done) / .52

            // left-weighted scrim so the identity reads over any key art
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#060808").opacity(0.92), location: 0),
                    .init(color: Color(hex: "#060808").opacity(0.55), location: 0.52),
                    .init(color: Color(hex: "#060808").opacity(0.28), location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )

            // season, big and left — the card's identity
            VStack(alignment: .leading, spacing: 5) {
                deckNumber
                Text(season.deckSublabel)
                    .font(.custom(.jetbrains.regular, size: 7.5))
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
    }

    private var deckNumber: some View {
        let base: Color = isReady ? .c2bTealBright : .white
        return (
            Text("S\(season.seasonNumber)")
            + Text("E").foregroundColor(base.opacity(0.55))
            + Text("\(season.upNextEpisode)")
        )
        .font(.custom(.oswald.bold, size: 30))
        .foregroundColor(base)
        .lineLimit(1)
    }

    // MARK: - Detail row

    private var detailRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    seasonBadge
                    Text(season.showTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.c2bText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 9, weight: .semibold))
                    Text("\(season.episodeCount) eps · ~\(season.nightsText)")
                }
                .font(.custom(.jetbrains.regular, size: 9.5))
                .tracking(0.57)
                .foregroundColor(.c2bMuted)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.top, 7)

                Text(season.note)
                    .font(.custom(.jetbrains.regular, size: 9.5))
                    .tracking(0.57)
                    .foregroundColor(isReady ? .c2bTealBright : .c2bMuted)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RuntimeClock(seconds: season.totalSeconds, numberSize: 30, unitSize: 12)
                .padding(.leading, 10)

            markAllButton
        }
    }

    private var seasonBadge: some View {
        let tint: Color = isReady ? .c2bTealBright : .c2bDim
        return (
            Text("S").font(.custom(.oswald.bold, size: 14))
            + Text("\(season.seasonNumber)").font(.custom(.oswald.light, size: 14))
        )
        .foregroundColor(tint)
    }

    private var markAllButton: some View {
        Button {
            onMarkAll?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                Text("ALL")
                    .font(.custom(.jetbrains.bold, size: 7))
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
