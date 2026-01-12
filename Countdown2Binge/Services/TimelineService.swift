//
//  TimelineService.swift
//  Countdown2Binge
//
//  Groups shows into timeline categories for display.
//

import Foundation

/// Timeline categories for displaying shows
enum TimelineCategory: String, CaseIterable, Identifiable {
    case bingeReady = "Binge Ready"
    case airingNow = "Airing Now"
    case premieringSoon = "Premiering Soon"
    case anticipated = "Anticipated"

    var id: String { rawValue }

    /// Display order (lower = higher priority)
    var displayOrder: Int {
        switch self {
        case .bingeReady: return 0
        case .airingNow: return 1
        case .premieringSoon: return 2
        case .anticipated: return 3
        }
    }
}

/// Information about a show's timeline status
struct TimelineEntry: Identifiable, Equatable {
    let show: Show
    let category: TimelineCategory
    let countdown: CountdownInfo?

    var id: Int { show.id }

    static func == (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
        lhs.show.id == rhs.show.id && lhs.category == rhs.category
    }
}

/// Countdown information for a show
struct CountdownInfo: Equatable {
    enum CountdownType {
        case toFinale
        case toPremiere
    }

    let type: CountdownType
    let days: Int
    let targetDate: Date

    /// Human-readable description
    var description: String {
        switch type {
        case .toFinale:
            return days == 1 ? "Finale in 1 day" : "Finale in \(days) days"
        case .toPremiere:
            return days == 1 ? "Premieres in 1 day" : "Premieres in \(days) days"
        }
    }

    /// Short description for compact display
    var shortDescription: String {
        "\(days)d"
    }
}

/// Protocol for timeline grouping service
protocol TimelineServiceProtocol {
    func categorize(_ show: Show) -> TimelineCategory
    func createEntry(for show: Show) -> TimelineEntry
    func groupByCategory(_ shows: [Show]) -> [TimelineCategory: [TimelineEntry]]
    func sortedCategories(from grouped: [TimelineCategory: [TimelineEntry]]) -> [(category: TimelineCategory, entries: [TimelineEntry])]
}

/// Service for grouping and sorting shows by timeline
final class TimelineService: TimelineServiceProtocol {

    /// Determines which timeline category a show belongs to
    func categorize(_ show: Show) -> TimelineCategory {
        let state = show.lifecycleState

        switch state {
        case .cancelled:
            return .bingeReady

        case .completed:
            // If inProduction is true, show is coming back but no season data yet
            // Show in Anticipated (TBD) so user knows more is expected
            if show.inProduction {
                return .anticipated
            }
            return .bingeReady

        case .airing:
            return .airingNow

        case .anticipated:
            // Check if we have a known premiere date
            if show.daysUntilPremiere != nil {
                return .premieringSoon
            }
            // Show in TBD - we have upcoming season but no premiere date
            return .anticipated
        }
    }

    /// Creates a timeline entry with countdown info for a show
    func createEntry(for show: Show) -> TimelineEntry {
        let category = categorize(show)
        let countdown = calculateCountdown(for: show, in: category)
        return TimelineEntry(show: show, category: category, countdown: countdown)
    }

    /// Groups shows by timeline category
    func groupByCategory(_ shows: [Show]) -> [TimelineCategory: [TimelineEntry]] {
        var grouped: [TimelineCategory: [TimelineEntry]] = [:]

        for category in TimelineCategory.allCases {
            grouped[category] = []
        }

        for show in shows {
            let entry = createEntry(for: show)
            grouped[entry.category, default: []].append(entry)
        }

        // Sort entries within each category
        for category in TimelineCategory.allCases {
            grouped[category] = sortEntries(grouped[category] ?? [], in: category)
        }

        return grouped
    }

    /// Returns categories in display order with their entries
    func sortedCategories(from grouped: [TimelineCategory: [TimelineEntry]]) -> [(category: TimelineCategory, entries: [TimelineEntry])] {
        TimelineCategory.allCases
            .sorted { $0.displayOrder < $1.displayOrder }
            .compactMap { category in
                guard let entries = grouped[category], !entries.isEmpty else {
                    return nil
                }
                return (category: category, entries: entries)
            }
    }

    // MARK: - Private Helpers

    private func calculateCountdown(for show: Show, in category: TimelineCategory) -> CountdownInfo? {
        switch category {
        case .bingeReady:
            // No countdown for binge-ready shows
            return nil

        case .airingNow:
            // Countdown to finale
            guard let days = show.daysUntilFinale,
                  let finaleDate = show.currentSeason?.finaleDate else {
                return nil
            }
            return CountdownInfo(type: .toFinale, days: max(0, days), targetDate: finaleDate)

        case .premieringSoon:
            // Countdown to premiere
            guard let days = show.daysUntilPremiere,
                  let premiereDate = show.upcomingSeason?.airDate ?? show.currentSeason?.airDate else {
                return nil
            }
            return CountdownInfo(type: .toPremiere, days: max(0, days), targetDate: premiereDate)

        case .anticipated:
            // No countdown for anticipated shows without dates
            return nil
        }
    }

    private func sortEntries(_ entries: [TimelineEntry], in category: TimelineCategory) -> [TimelineEntry] {
        switch category {
        case .bingeReady:
            // Sort by name alphabetically
            return entries.sorted { $0.show.name < $1.show.name }

        case .airingNow:
            // Sort by finale date (soonest first), then by name
            return entries.sorted { lhs, rhs in
                if let lhsDays = lhs.countdown?.days, let rhsDays = rhs.countdown?.days {
                    if lhsDays != rhsDays {
                        return lhsDays < rhsDays
                    }
                }
                return lhs.show.name < rhs.show.name
            }

        case .premieringSoon:
            // Sort by premiere date (soonest first), then by name
            return entries.sorted { lhs, rhs in
                if let lhsDays = lhs.countdown?.days, let rhsDays = rhs.countdown?.days {
                    if lhsDays != rhsDays {
                        return lhsDays < rhsDays
                    }
                }
                return lhs.show.name < rhs.show.name
            }

        case .anticipated:
            // Sort by name alphabetically
            return entries.sorted { $0.show.name < $1.show.name }
        }
    }
}
