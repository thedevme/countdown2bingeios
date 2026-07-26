//
//  FullTimelineView.swift
//  Countdown2Binge
//
//  Full timeline showing all shows in three sections:
//  - Now Playing (sorted by finale date, soonest first)
//  - Premiering Soon (sorted by premiere date, soonest first)
//  - Anticipated (sorted by year)
//

import SwiftUI

struct FullTimelineView: View {
    let viewModel: TimelineViewModel
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss

    // Persisted expand/collapse states for full timeline
    @AppStorage("full_timeline_now_playing_expanded") private var nowPlayingExpanded = true
    @AppStorage("full_timeline_premiering_expanded") private var premieringExpanded = true
    @AppStorage("full_timeline_anticipated_expanded") private var anticipatedExpanded = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                // Now Playing Section
                nowPlayingSection
                    .padding(.bottom, 24)

                // Premiering Soon Section
                premieringSoonSection
                    .padding(.bottom, 24)

                // Anticipated Section
                anticipatedSection

                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color.c2bBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                DirectionalIcon(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(22)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("header_full_timeline")
                    .font(.custom(.oswald.bold, size: 20))
                    .foregroundColor(.white)
                    .tracking(1.2)

                Text(String(localized: "timeline_shows_tracked \(viewModel.trackedCount)"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .foregroundColor(.c2bMuted)
                    .tracking(0.8)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, C2BLayout.horizontalPadding)
    }

    // MARK: - Now Playing Section

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            sectionHeader(
                title: String(localized: "timeline_now_playing"),
                count: viewModel.airingNowShows.count,
                tone: .c2bTeal,
                subtitle: String(localized: "timeline_finale_countdown"),
                isExpanded: $nowPlayingExpanded
            )

            // Cards
            VStack(spacing: nowPlayingExpanded ? 16 : 10) {
                if viewModel.airingNowShows.isEmpty {
                    if nowPlayingExpanded {
                        TimelineEmptySection()
                    } else {
                        MiniEmptySection(dim: false)
                    }
                } else {
                    ForEach(viewModel.airingNowShows, id: \.id) { show in
                        Button(action: { navigationPath.append(show) }) {
                            if nowPlayingExpanded {
                                NowPlayingCard(showData: show)
                            } else {
                                MiniNowPlayingCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }

    // MARK: - Premiering Soon Section

    private var premieringSoonSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            sectionHeader(
                title: String(localized: "header_premiering_soon"),
                count: viewModel.premieringSoonShows.count,
                tone: .c2bTeal,
                subtitle: String(localized: "timeline_upcoming_seasons"),
                isExpanded: $premieringExpanded
            )

            // Cards
            VStack(spacing: premieringExpanded ? 16 : 10) {
                if viewModel.premieringSoonShows.isEmpty {
                    if premieringExpanded {
                        TimelineEmptySection()
                    } else {
                        MiniEmptySection(dim: false)
                    }
                } else {
                    ForEach(viewModel.premieringSoonShows, id: \.id) { show in
                        Button(action: { navigationPath.append(show) }) {
                            if premieringExpanded {
                                PremieringCard(showData: show)
                            } else {
                                MiniPremieringCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }

    // MARK: - Anticipated Section

    private var anticipatedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            sectionHeader(
                title: String(localized: "header_anticipated"),
                count: viewModel.anticipatedShows.count,
                tone: .c2bMuted,
                subtitle: String(localized: "timeline_waiting_dates"),
                isExpanded: $anticipatedExpanded
            )

            // Cards
            VStack(spacing: anticipatedExpanded ? 16 : 10) {
                if viewModel.anticipatedShows.isEmpty {
                    if anticipatedExpanded {
                        TimelineEmptySection()
                    } else {
                        MiniEmptySection(dim: true)
                    }
                } else {
                    ForEach(viewModel.anticipatedShows, id: \.id) { show in
                        Button(action: { navigationPath.append(show) }) {
                            if anticipatedExpanded {
                                AnticipatedCard(showData: show)
                            } else {
                                MiniAnticipatedCard(showData: show)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, count: Int, tone: Color, subtitle: String, isExpanded: Binding<Bool>) -> some View {
        Button(action: { withAnimation { isExpanded.wrappedValue.toggle() }}) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(tone)
                        .frame(width: 8, height: 8)

                    Text(title)
                        .font(.custom(.oswald.bold, size: 16))
                        .foregroundColor(.white)

                    Text("\(count)")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .foregroundColor(tone == .c2bMuted ? .c2bDim : .c2bTealBright)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            tone == .c2bMuted ?
                            Color.white.opacity(0.06) :
                            Color.c2bTeal.opacity(0.12)
                        )
                        .cornerRadius(C2BLayout.chipRadius)

                    Spacer()

                    Text(isExpanded.wrappedValue ? String(localized: "button_hide") : String(localized: "button_show"))
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .foregroundColor(.c2bMuted)
                        .tracking(0.6)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.c2bMuted)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                }

                Text(subtitle)
                    .font(.custom(.jetbrains.regular, size: 8))
                    .foregroundColor(.c2bDim)
                    .tracking(0.8)
                    .padding(.leading, 17)
            }
            .padding(.horizontal, C2BLayout.horizontalPadding)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Now Playing Card (similar to PremieringCard but shows days to finale)

struct NowPlayingCard: View {
    let showData: ShowData

    private var daysUntilFinale: Int? {
        showData.daysUntilFinale
    }

    private var displayName: String {
        showData.name
    }

    private var posterURL: URL? {
        showData.posterURL
    }

    private var seasonNumber: String {
        String(showData.numberOfSeasons)
    }

    private var platformString: String {
        showData.networks.first?.name ?? ""
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: Countdown section
            HStack {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 0) {
                        if let days = daysUntilFinale {
                            Text("\(days)")
                                .font(.custom(.oswald.bold, size: CustomFont.size.xl7))
                                .foregroundColor(.white)
                                .tracking(-5)
                                .rotationEffect(.degrees(-90))
                                .padding(-30)
                        } else {
                            Text("timeline_tbd")
                                .font(.custom(.oswald.bold, size: 40))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                                .padding(-20)
                        }

                        Text("time_days")
                            .font(.custom(.oswald.bold, size: CustomFont.size.xl2))
                            .foregroundColor(Color.c2bTealBright)
                            .textCase(.uppercase)
                            .tracking(1.6)
                            .padding(-5)

                        Text("timeline_to_finale")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.xs))
                            .foregroundColor(Color(hex: "#52525b"))
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                }
                .padding(-7)
                .frame(width: 110, height: 140)
            }
            .padding(-20)

            // Right: Poster
            ZStack(alignment: .topTrailing) {
                if let url = posterURL {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(hex: "#1a1a1c"))
                    }
                    .frame(height: 140)
                    .clipped()
                    .overlay(Color.black.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .fill(Color(hex: "#5eead4").opacity(0.3))
                            .frame(width: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                }

                // Overlay content
                VStack(alignment: .leading, spacing: 0) {
                    // Top: Platform badge
                    HStack {
                        Spacer()

                        Text(platformString.uppercased())
                            .font(.custom(.jetbrains.bold, size: 9))
                            .foregroundColor(Color(hex: "#e7e7e7"))
                            .tracking(0.54)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#080808").opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }

                    Spacer()

                    // Bottom: Season + Show name
                    HStack(alignment: .bottom, spacing: 8) {
                        HStack(spacing: 0) {
                            Text("season_abbrev")
                                .font(.custom(.oswald.bold, size: 28))
                                .foregroundColor(.white)
                            Text(seasonNumber)
                                .font(.custom(.oswald.light, size: 28))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                        Text(displayName.uppercased())
                            .font(.custom(.oswald.bold, size: 19))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(10)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .contentShape(Rectangle())
    }
}
