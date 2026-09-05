//
//  MyListRailCard.swift
//  Countdown2Binge
//
//  The actual "big card" from "My List Cards.html" (`.bc`/`.deck`/`.face`/
//  `.plate`) — one page inside a section's horizontal rail. Same wallet-deck
//  stack as MyListLandscapeCard (peek, tints, depth clamp — untouched), but
//  a different face: an "episodes left" pill over the art instead of an S/E
//  numeral, a "Next · S1E2 · Title" line, position+percent beside the big
//  clock, and a segmented meter with a "+N" overflow block past 10 ticks.
//

import SwiftUI

struct MyListRailCard: View {
    let season: MyListSeasonDisplay
    /// The section's own tone (tier.tone / a straight-through override) —
    /// the "episodes left" pill and the "Next" line match it, same as the
    /// section header, instead of always being teal regardless of section.
    var tone: Color = .c2bTealBright
    /// Straight Through's "Upcoming" cards hide this — checking off an
    /// episode there updates the show's most-recent-activity timestamp,
    /// which is exactly what promotes a show to "Next," so the card being
    /// tapped would jump to a different section mid-interaction. "Next"
    /// itself, and every Jump Around tier, keep the checkoff.
    var showsNextEpisodeCheckoff: Bool = true
    var onOpen: () -> Void = {}
    var onMarkAll: (() -> Void)? = nil
    var onToggleEpisode: ((EpisodeTick) -> Void)? = nil
    var notificationsOn: Bool = true
    var onBell: (() -> Void)? = nil

    @State private var forceAllWatched = false
    @State private var sweeping = false

    /// The stack's total vertical footprint is FIXED — `deckLayers()` /
    /// `.deck{padding-top:14px}` in the design — so every card in a rail is
    /// the same height no matter how many seasons queue behind it. Peek
    /// spacing between layers shrinks as depth grows to still fit inside
    /// this one constant reserve, instead of the reserve growing with depth.
    /// 22, not the design's 14 — at 14, 4 layers are only 3.5pt apart
    /// vertically, so almost nothing of each layer's flat top shows; you
    /// only see compressed corner-arc tips, which don't read as evenly
    /// tapered even when the horizontal insets actually are.
    private let deckReserve: CGFloat = 22
    /// Ticks beyond this collapse into one "+N" block, same as the design's
    /// MTR_MAX — a 20-episode season shouldn't shrink every tick to a hairline.
    private let meterMax = 10

    private var isReady: Bool { season.isReady }
    private var episodesLeft: Int { max(0, season.episodeCount - season.watchedCount) }
    private var percentWatched: Int {
        season.episodeCount > 0 ? Int((Double(season.watchedCount) / Double(season.episodeCount) * 100).rounded()) : 0
    }

    private var displayTicks: [EpisodeTick] {
        guard forceAllWatched else { return season.ticks }
        return season.ticks.map { tick in
            tick.aired
                ? EpisodeTick(id: tick.id, number: tick.number, watched: true, aired: true)
                : tick
        }
    }

    var body: some View {
        // NOT a Button — a Button wrapping the whole card competes with the
        // nested checkoff/mark-all/bell Buttons for the tap and wins,
        // swallowing them (confirmed: tapping the checkoff row opened the
        // show instead of checking off the episode). A tap gesture on the
        // card only fires for taps outside those nested buttons' own
        // hit-testing, which is the standard fix for "big tappable card,
        // a few independently-tappable controls inside it."
        let depth = season.stackDepth
        ZStack(alignment: .top) {
            // The floating peek layers — deliberately OUTSIDE the bordered
            // card below. In the design, `.face` (the poster) owns its own
            // border; `.layer` (these) never had one. Wrapping ONE border
            // around deck+plate together (the previous structure) traced
            // the full card width right through the deck area, showing up
            // as an extra wide curve above the actual tapered layers —
            // the real bug, not the background, not the taper amount.
            MyListRailCardDeck(depth: depth, reserve: deckReserve)

            VStack(alignment: .leading, spacing: 0) {
                face
                plate
                    .background(Color.c2bCard)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            // Only reserve peek space when there's an actual stack to fill
            // it — a show with just this one season left had nothing
            // rendering in that strip, just a dead gap above the poster.
            .padding(.top, depth > 1 ? deckReserve : 0)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: onOpen)
    }

    // MARK: - Face: art + network badge + episodes-left pill

    private var face: some View {
        ZStack(alignment: .topTrailing) {
            LandscapeBackdrop(url: season.backdropURL, seed: season.showTitle)
                .brightness(-0.3)
                .saturation(0.95)

            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#101012"), location: 0.04),
                    .init(color: Color(hex: "#101012").opacity(0.52), location: 0.46),
                    .init(color: Color(hex: "#101012").opacity(0.34), location: 1),
                ],
                startPoint: .bottom, endPoint: .top
            )

            if let network = season.network {
                Text(network)
                    .font(.custom(.jetbrains.bold, size: 7))
                    .tracking(0.6)
                    .foregroundColor(Color(white: 0.91))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(11)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text(episodesLeft == 0
                 ? String(localized: "mylist_ls_state_watched")
                 : String(episodesLeft == 1 ? "1 episode left" : "\(episodesLeft) episodes left"))
                .font(.custom(.oswald.medium, size: 10))
                .tracking(0.3)
                .foregroundColor(tone)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.72))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(tone.opacity(0.4), lineWidth: 1))
                .padding(11)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Plate: title, statline, clock, next-episode checkoff, meter

    private var plate: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(season.showTitle.uppercased())
                .font(.custom(.oswald.medium, size: 20))
                .tracking(0.2)
                .foregroundColor(.c2bText)
                .lineLimit(1)

            // Its own line, full width — sharing a row with the clock (the
            // old layout) truncated this the moment a season count or
            // percent pushed it past the available space.
            Text("Season \(season.seasonNumber) of \(season.seasonNumber + max(0, season.remainingSeasons - 1)) · \(percentWatched)% watched")
                .font(.custom(.jetbrains.regular, size: 8.5))
                .tracking(1)
                .foregroundColor(.c2bMuted)
                .lineLimit(1)
                .padding(.top, 13)

            // Right-justified, sitting just above the ticks so the meter
            // still runs the full card width underneath it. Reads straight
            // off `season.watchTimeSeconds`, which is what's LEFT to watch
            // (not the season's fixed total) — checking off the next
            // episode below visibly decrements it.
            Text(clockText)
                .font(.custom(.oswald.bold, size: 24))
                .foregroundColor(.c2bText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 6)

            nextEpisodeRow
                .padding(.top, 11)

            meter
                .padding(.top, 11)

            HStack(spacing: 10) {
                markAllButton
                if PremiumManager.shared.isPremium {
                    bellButton
                }
            }
            .padding(.top, 11)
        }
        .padding(.horizontal, 15)
        .padding(.top, 13)
        .padding(.bottom, 15)
    }

    /// The next unwatched episode, straight from the rail card — no need to
    /// open the show to check off a single episode. Tapping it marks
    /// through this one episode (same cumulative semantics as tapping a
    /// tick in the full episode list), which is exactly "just this one"
    /// since everything before it is already watched by definition.
    @ViewBuilder
    private var nextEpisodeRow: some View {
        if showsNextEpisodeCheckoff, episodesLeft > 0, let tick = upNextTick {
            Button {
                onToggleEpisode?(tick)
            } label: {
                HStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(tone.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("NEXT · S\(season.seasonNumber)E\(season.upNextEpisode)")
                            .font(.custom(.jetbrains.bold, size: 9.5))
                            .tracking(0.8)
                            .foregroundColor(tone)
                        Text(season.nextEpisodeTitle ?? String(localized: "mylist_ls_deck_upnext"))
                            .font(.custom(.oswald.medium, size: 14))
                            .foregroundColor(.c2bText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(tone.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tone.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var upNextTick: EpisodeTick? {
        displayTicks.first { $0.number == season.upNextEpisode }
    }

    private var clockText: String {
        let h = season.watchTimeSeconds / 3600
        let m = (season.watchTimeSeconds % 3600) / 60
        let s = season.watchTimeSeconds % 60
        return "\(h)h:\(String(format: "%02d", m))m:\(String(format: "%02d", s))s"
    }

    // MARK: - Meter (ticks + "+N" overflow)

    private var meter: some View {
        HStack(alignment: .center, spacing: 3) {
            let ticks = displayTicks
            if ticks.count <= meterMax {
                ForEach(ticks) { tick in tickCell(on: tick.watched) }
            } else {
                let shown = ticks.prefix(meterMax - 1)
                let restDone = max(0, displayTicks.filter(\.watched).count - shown.count)
                ForEach(Array(shown)) { tick in tickCell(on: tick.watched) }
                Text("+\(ticks.count - shown.count)")
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .foregroundColor(restDone > 0 ? tone : .c2bDim)
                    .frame(width: 27, height: 21)
                    .background(restDone > 0 ? tone.opacity(0.18) : Color.white.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 1.5)
                            .stroke(restDone > 0 ? tone.opacity(0.4) : Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }
        }
        .frame(height: 21)
    }

    /// Watched and unwatched ticks are the SAME size — only the color
    /// differs. They used to grow taller when watched (7pt → 21pt), which
    /// read as an inconsistent, growing-in-place glitch rather than a
    /// steady progress meter.
    private func tickCell(on: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(on ? tone : Color.white.opacity(0.14))
            .frame(maxWidth: .infinity)
            .frame(height: 7)
    }

    // MARK: - Actions

    private var markAllButton: some View {
        Button {
            sweepThenMarkAll()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                Text(String(localized: "mylist_ls_all"))
                    .font(.custom(.jetbrains.bold, size: 8.5))
                    .tracking(0.56)
            }
            .foregroundColor(season.allWatched ? .c2bOnTeal : .c2bDim)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(season.allWatched ? Color.c2bTeal : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(season.allWatched ? Color.c2bTeal : Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(sweeping)
    }

    private var bellButton: some View {
        Button {
            onBell?()
        } label: {
            Image(systemName: notificationsOn ? "bell.fill" : "bell.slash.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(notificationsOn ? .c2bTeal : .c2bDim)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func sweepThenMarkAll() {
        guard !sweeping else { return }
        let hasUnfilled = season.ticks.contains { $0.aired && !$0.watched }
        guard hasUnfilled else { onMarkAll?(); return }

        sweeping = true
        forceAllWatched = true

        let visible = Double(min(season.ticks.count, 10))
        let total = visible * 0.04 + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            onMarkAll?()
            sweeping = false
            forceAllWatched = false
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 13) {
            ForEach(MyListLandscapeSample.active) { season in
                MyListRailCard(season: season)
            }
        }
        .padding(20)
    }
    .background(Color.c2bBackground)
}
