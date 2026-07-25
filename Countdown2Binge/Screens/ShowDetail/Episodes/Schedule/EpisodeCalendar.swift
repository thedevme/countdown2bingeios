//
//  EpisodeCalendar.swift
//  Countdown2Binge
//
//  Monthly calendar view showing episode air dates.
//  Supports navigation between months and episode selection.
//

import SwiftUI

struct EpisodeCalendar: View {
    let season: SeasonDisplayModel
    let startDate: Date?  // Calculated start date for rewatch plan
    @Binding var monthOffset: Int
    @Binding var selectedEpisode: EpisodeDisplayModel?
    @Binding var showStartSelected: Bool

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    private var today: Date { Date() }

    private var displayMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: today) ?? today
    }

    private var year: Int {
        calendar.component(.year, from: displayMonth)
    }

    private var month: Int {
        calendar.component(.month, from: displayMonth)
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayMonth)?.count ?? 30
    }

    private var firstWeekday: Int {
        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        return calendar.component(.weekday, from: firstOfMonth) - 1 // 0-indexed Sunday
    }

    private var nextEpisodeNumber: Int? {
        let released = season.episodes.filter { $0.hasAired }
        return released.count < season.totalEpisodes ? released.count + 1 : nil
    }

    /// Day number of the start date in current month (nil if not in this month)
    private var startDayInMonth: Int? {
        guard let start = startDate else { return nil }
        let startYear = calendar.component(.year, from: start)
        let startMonth = calendar.component(.month, from: start)
        guard startYear == year && startMonth == month else { return nil }
        return calendar.component(.day, from: start)
    }

    // Map day numbers to episodes
    private var episodesByDay: [Int: EpisodeDisplayModel] {
        var map: [Int: EpisodeDisplayModel] = [:]
        for episode in season.episodes {
            guard let airDate = episode.airDate else { continue }
            let epYear = calendar.component(.year, from: airDate)
            let epMonth = calendar.component(.month, from: airDate)
            let epDay = calendar.component(.day, from: airDate)
            if epYear == year && epMonth == month {
                map[epDay] = episode
            }
        }
        return map
    }

    private var todayDay: Int? {
        let todayYear = calendar.component(.year, from: today)
        let todayMonth = calendar.component(.month, from: today)
        if todayYear == year && todayMonth == month {
            return calendar.component(.day, from: today)
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            monthHeader

            // Weekday headers
            weekdayHeaders
                .padding(.bottom, 3)

            // Calendar grid
            calendarGrid
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button(action: { monthOffset -= 1 }) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .overlay(
                        DirectionalIcon(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                Text(monthNames[month - 1])
                    .font(.custom(CustomFont.oswald.bold, size: 16))
                    .tracking(0.6)
                    .foregroundColor(.c2bText)

                Text(String(year))
                    .font(.custom(CustomFont.oswald.bold, size: 16))
                    .tracking(0.6)
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            Button(action: { monthOffset += 1 }) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .overlay(
                        DirectionalIcon(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.custom(CustomFont.jetbrains.regular, size: 8))
                    .tracking(0.8)
                    .foregroundColor(.c2bMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    /// Fixed cell size for consistent grid
    private let cellSize: CGFloat = 44
    private let cellSpacing: CGFloat = 5

    /// Total cells in grid (always 6 rows × 7 columns = 42 for consistent sizing)
    private let totalCells = 42

    /// Number of trailing empty cells needed after the days
    private var trailingEmptyCells: Int {
        let usedCells = firstWeekday + daysInMonth
        return max(0, totalCells - usedCells)
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: cellSpacing), count: 7)

        return LazyVGrid(columns: columns, spacing: cellSpacing) {
            // Leading empty cells for padding
            ForEach(0..<firstWeekday, id: \.self) { index in
                emptyCellView
                    .id("leading-\(index)")
            }

            // Day cells
            ForEach(1...daysInMonth, id: \.self) { day in
                let episode = episodesByDay[day]
                let isToday = todayDay == day
                let isStartDay = startDayInMonth == day && episode == nil
                let isSelected = selectedEpisode?.number == episode?.number || (showStartSelected && isStartDay)
                let isNext = episode?.number == nextEpisodeNumber

                EpisodeCalendarCell(
                    dayNumber: day,
                    episode: episode,
                    isToday: isToday,
                    isStartDay: isStartDay,
                    isSelected: isSelected,
                    isNextEpisode: isNext,
                    onSelect: {
                        if let ep = episode {
                            selectedEpisode = ep
                            showStartSelected = false
                        } else if isStartDay {
                            selectedEpisode = nil
                            showStartSelected = true
                        }
                    }
                )
                .frame(height: cellSize)
            }

            // Trailing empty cells to fill remaining rows
            ForEach(0..<trailingEmptyCells, id: \.self) { index in
                emptyCellView
                    .id("trailing-\(index)")
            }
        }
        .frame(height: (cellSize * 6) + (cellSpacing * 5)) // Fixed height for 6 rows
    }

    private var emptyCellView: some View {
        EpisodeCalendarCell(
            dayNumber: nil,
            episode: nil,
            isToday: false,
            isStartDay: false,
            isSelected: false,
            isNextEpisode: false,
            onSelect: {}
        )
        .frame(height: cellSize)
    }
}

// MARK: - Preview

#Preview {
    let episodes = (1...8).map { num in
        EpisodeDisplayModel(
            id: "\(num)",
            number: num,
            seasonNumber: 2,
            title: "Episode \(num)",
            description: "Description for episode \(num)",
            runtime: 45 + (num * 2),
            airDate: Date().addingTimeInterval(Double((num - 4) * 7 * 86400)),
            isWatched: num < 3,
            hasAired: num <= 4,
            isFinale: num == 8
        )
    }

    let season = SeasonDisplayModel(
        id: "s2",
        number: 2,
        name: "Season 2",
        episodes: episodes,
        isCurrent: true,
        airDate: Date().addingTimeInterval(-21 * 86400)
    )

    return ScrollView {
        EpisodeCalendar(
            season: season,
            startDate: Date().addingTimeInterval(86400 * 3), // Start in 3 days
            monthOffset: .constant(0),
            selectedEpisode: .constant(nil),
            showStartSelected: .constant(false)
        )
        .padding(22)
    }
    .background(Color.c2bBackground)
}
