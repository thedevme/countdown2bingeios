//
//  EpisodeCalendarCell.swift
//  Countdown2Binge
//
//  Individual day cell in the episode calendar.
//  Handles various states: aired, next, locked, finale, start-today, empty.
//

import SwiftUI

struct EpisodeCalendarCell: View {
    let dayNumber: Int?
    let episode: EpisodeDisplayModel?
    let isToday: Bool
    let isStartDay: Bool
    let isSelected: Bool
    let isNextEpisode: Bool
    let onSelect: () -> Void

    var body: some View {
        if let day = dayNumber {
            if let ep = episode {
                episodeCell(day: day, episode: ep)
            } else if isStartDay {
                startDayCell(day: day)
            } else {
                regularDayCell(day: day)
            }
        } else {
            // Empty cell for padding
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Episode Cell

    private func episodeCell(day: Int, episode: EpisodeDisplayModel) -> some View {
        let aired = episode.hasAired
        let isFinale = episode.isFinale
        let isNext = isNextEpisode

        return Button(action: onSelect) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 9)
                    .fill(cellBackground(aired: aired, isFinale: isFinale))

                // Border
                RoundedRectangle(cornerRadius: 9)
                    .stroke(cellBorder(aired: aired, isFinale: isFinale, isNext: isNext), lineWidth: 1.5)

                // Selection glow
                if isSelected {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white, lineWidth: 1.5)
                        .shadow(color: Color.white.opacity(0.15), radius: 3)
                } else if isNext {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.clear, lineWidth: 0)
                        .shadow(color: Color.c2bTeal.opacity(0.18), radius: 3)
                }

                // Icons (top-right)
                VStack {
                    HStack {
                        Spacer()
                        if !aired && !isFinale {
                            // Lock icon
                            Image(systemName: "lock.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(4)
                        } else if isFinale && !aired {
                            // Star icon
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.c2bTealBright)
                                .padding(3)
                        }
                    }
                    Spacer()
                }

                // Content
                VStack(spacing: 1) {
                    Text("\(day)")
                        .font(.custom(CustomFont.jetbrains.regular, size: 7.5))
                        .foregroundColor(aired ? Color(hex: "#04201c").opacity(0.7) : .c2bMuted)

                    Text("\(episode.number)")
                        .font(.custom(CustomFont.oswald.bold, size: 13))
                        .foregroundColor(episodeNumberColor(aired: aired, isFinale: isFinale, isNext: isNext))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func cellBackground(aired: Bool, isFinale: Bool) -> Color {
        if aired {
            return .c2bTeal
        } else if isFinale {
            return Color.c2bTeal.opacity(0.14)
        } else {
            return Color.white.opacity(0.05)
        }
    }

    private func cellBorder(aired: Bool, isFinale: Bool, isNext: Bool) -> Color {
        if aired {
            return .c2bTeal
        } else if isNext {
            return .c2bTealBright
        } else if isFinale {
            return .c2bTealLine
        } else {
            return Color.white.opacity(0.1)
        }
    }

    private func episodeNumberColor(aired: Bool, isFinale: Bool, isNext: Bool) -> Color {
        if aired {
            return Color(hex: "#04201c")
        } else if isFinale || isNext {
            return .c2bTealBright
        } else {
            return .c2bText
        }
    }

    // MARK: - Start Day Cell

    private func startDayCell(day: Int) -> some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? Color.c2bTeal.opacity(0.22) : Color.c2bTeal.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.c2bTealBright, lineWidth: 1.5)
                    )

                VStack(spacing: 0) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.c2bTealBright)
                        .padding(.top, 3)

                    Text("\(day)")
                        .font(.custom(CustomFont.jetbrains.regular, size: 9.5))
                        .foregroundColor(.c2bTealBright)
                        .padding(.top, 1)

                    Text("label_start")
                        .font(.custom(CustomFont.jetbrains.bold, size: 5))
                        .tracking(0.4)
                        .foregroundColor(.c2bTealBright)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Regular Day Cell

    private func regularDayCell(day: Int) -> some View {
        ZStack {
            if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            }

            Text("\(day)")
                .font(.custom(CustomFont.jetbrains.regular, size: 10))
                .foregroundColor(isPastDay ? Color.white.opacity(0.18) : .c2bMuted)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var isPastDay: Bool {
        // This would need actual date comparison logic
        false
    }
}

// MARK: - Preview

#Preview {
    let episode = EpisodeDisplayModel(
        id: "1",
        number: 3,
        seasonNumber: 2,
        title: "Episode 3",
        description: "Test",
        runtime: 45,
        airDate: Date(),
        isWatched: false,
        hasAired: true,
        isFinale: false
    )

    let lockedEpisode = EpisodeDisplayModel(
        id: "2",
        number: 4,
        seasonNumber: 2,
        title: "Episode 4",
        description: "Test",
        runtime: 45,
        airDate: Date().addingTimeInterval(86400 * 7),
        isWatched: false,
        hasAired: false,
        isFinale: false
    )

    let finaleEpisode = EpisodeDisplayModel(
        id: "3",
        number: 8,
        seasonNumber: 2,
        title: "Finale",
        description: "Test",
        runtime: 45,
        airDate: Date().addingTimeInterval(86400 * 28),
        isWatched: false,
        hasAired: false,
        isFinale: true
    )

    return HStack(spacing: 8) {
        // Aired
        EpisodeCalendarCell(
            dayNumber: 15,
            episode: episode,
            isToday: false,
            isStartDay: false,
            isSelected: false,
            isNextEpisode: false,
            onSelect: {}
        )
        .frame(width: 44, height: 44)

        // Next (locked)
        EpisodeCalendarCell(
            dayNumber: 22,
            episode: lockedEpisode,
            isToday: false,
            isStartDay: false,
            isSelected: false,
            isNextEpisode: true,
            onSelect: {}
        )
        .frame(width: 44, height: 44)

        // Finale
        EpisodeCalendarCell(
            dayNumber: 29,
            episode: finaleEpisode,
            isToday: false,
            isStartDay: false,
            isSelected: true,
            isNextEpisode: false,
            onSelect: {}
        )
        .frame(width: 44, height: 44)

        // Start day
        EpisodeCalendarCell(
            dayNumber: 1,
            episode: nil,
            isToday: true,
            isStartDay: true,
            isSelected: false,
            isNextEpisode: false,
            onSelect: {}
        )
        .frame(width: 44, height: 44)

        // Regular day
        EpisodeCalendarCell(
            dayNumber: 10,
            episode: nil,
            isToday: false,
            isStartDay: false,
            isSelected: false,
            isNextEpisode: false,
            onSelect: {}
        )
        .frame(width: 44, height: 44)
    }
    .padding()
    .background(Color.c2bBackground)
}
