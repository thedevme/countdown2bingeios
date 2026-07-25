//
//  ShowDetailSpinoffsSection.swift
//  Countdown2Binge
//
//  Spinoffs tab - displays franchise universe with watch order timeline.
//

import SwiftUI

// MARK: - Parent Section

struct ShowDetailSpinoffsSection: View {
    let show: ShowData
    let franchise: Franchise?
    let onSpinoffTap: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let franchise = franchise {
                SpinoffsPremiumBanner(showTitle: show.name)
                    .padding(.bottom, 16)

                SpinoffsWatchOrderTimeline(
                    show: show,
                    franchise: franchise,
                    onSpinoffTap: onSpinoffTap
                )
            } else {
                SpinoffsEmptyState(showTitle: show.name)
            }
        }
        .padding(.top, 22)
    }
}

// MARK: - Premium Banner

struct SpinoffsPremiumBanner: View {
    let showTitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            SpinoffsPremiumIcon()

            VStack(alignment: .leading, spacing: 4) {
                Text("header_universe_premium")
                    .font(.custom(.oswald.bold, size: 15))
                    .foregroundColor(.c2bTealBright)
                    .tracking(0.3)  // 0.02em = 15 * 0.02 = 0.3

                Text(String(localized: "premium_spinoffs_track \(showTitle)"))
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4.6)  // 11.5 * 1.4 = 16.1, lineSpacing = 16.1 - 11.5 = 4.6
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(
            LinearGradient(
                colors: [Color.c2bTeal.opacity(0.14), Color.c2bTeal.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}

// MARK: - Premium Icon

struct SpinoffsPremiumIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.c2bTeal)
                .frame(width: 34, height: 34)

            Image(systemName: "mountain.2.fill")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#04201c"))
        }
    }
}

// MARK: - Watch Order Timeline

struct SpinoffsWatchOrderTimeline: View {
    let show: ShowData
    let franchise: Franchise
    let onSpinoffTap: (Int) -> Void

    private var orderedItems: [SpinoffsWatchOrderItem] {
        var items: [SpinoffsWatchOrderItem] = []

        let prequels = franchise.spinoffs.filter { $0.type == .prequel }
        for spinoff in prequels {
            if spinoff.tmdbId == show.id {
                items.append(.currentShow)
            } else {
                items.append(.spinoff(spinoff))
            }
        }

        if franchise.parentShow.tmdbId == show.id {
            items.append(.currentShow)
        } else {
            items.append(.parentShow(franchise.parentShow))
        }

        let others = franchise.spinoffs.filter { $0.type != .prequel }
        for spinoff in others {
            if spinoff.tmdbId == show.id {
                items.append(.currentShow)
            } else {
                items.append(.spinoff(spinoff))
            }
        }

        return items
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpinoffsTimelineLine()
                .padding(.leading, 10)
                .padding(.top, 10)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 0) {
                SpinoffsWatchOrderHeader()
                    .padding(.leading, -8)
                    .padding(.bottom, 16)

                VStack(spacing: 16) {
                    ForEach(Array(orderedItems.enumerated()), id: \.offset) { index, item in
                        SpinoffsWatchOrderRow(
                            item: item,
                            index: index + 1,
                            currentShow: show,
                            onSpinoffTap: onSpinoffTap
                        )
                    }
                }
            }
            .padding(.leading, 30)
        }
    }
}

// MARK: - Timeline Line

struct SpinoffsTimelineLine: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .c2bTealBright, location: 0),
                        .init(color: .c2bTeal, location: 0.6),
                        .init(color: Color.white.opacity(0.12), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2)
    }
}

// MARK: - Watch Order Header

struct SpinoffsWatchOrderHeader: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("◷")
                .font(.system(size: 10))
            Text("header_watch_order")
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1.44)  // 0.16em = 9 * 0.16 = 1.44
                .textCase(.uppercase)
        }
        .foregroundColor(.c2bTealBright)
    }
}

// MARK: - Watch Order Item Enum

enum SpinoffsWatchOrderItem {
    case currentShow
    case parentShow(FranchiseShow)
    case spinoff(SpinoffShow)

    var isCurrentShow: Bool {
        if case .currentShow = self { return true }
        return false
    }
}

// MARK: - Watch Order Row

struct SpinoffsWatchOrderRow: View {
    let item: SpinoffsWatchOrderItem
    let index: Int
    let currentShow: ShowData
    let onSpinoffTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            SpinoffsNumberCircle(index: index, isActive: item.isCurrentShow)
                .offset(x: -30, y: item.isCurrentShow ? 4 : 12)

            Group {
                switch item {
                case .currentShow:
                    SpinoffsCurrentShowCard(show: currentShow)
                case .parentShow(let parent):
                    SpinoffsRelatedShowCard(
                        title: parent.title,
                        tag: "MAIN SERIES",
                        description: "The original series that started it all.",
                        posterPath: parent.posterPath,
                        onTap: { onSpinoffTap(parent.tmdbId) }
                    )
                case .spinoff(let spinoff):
                    SpinoffsRelatedShowCard(
                        title: spinoff.title,
                        tag: spinoff.type.label,
                        description: spinoff.type.description,
                        posterPath: spinoff.posterPath,
                        onTap: { onSpinoffTap(spinoff.tmdbId) }
                    )
                }
            }
            .offset(x: -19)
        }
    }
}

// MARK: - Number Circle

struct SpinoffsNumberCircle: View {
    let index: Int
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.c2bTealBright : Color(hex: "#0a0a0b"))
                .frame(width: 22, height: 22)

            if !isActive {
                Circle()
                    .stroke(Color.c2bTealLine, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }

            Text("\(index)")
                .font(.custom(.oswald.bold, size: 12))
                .foregroundColor(isActive ? Color(hex: "#04201c") : .c2bTealBright)
                .textCase(.uppercase)
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Current Show Card

struct SpinoffsCurrentShowCard: View {
    let show: ShowData

    private var posterURL: URL? {
        guard let path = show.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    var body: some View {
        HStack(spacing: 12) {
            SpinoffsPosterImage(url: posterURL)
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 5) {
                Text(show.name.uppercased())
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bTealBright)
                    .lineLimit(1)

                Text("season_you_are_here")
                    .font(.custom(.jetbrains.bold, size: 8))
                    .foregroundColor(.c2bTeal)
                    .tracking(0.8)  // 0.1em = 8 * 0.1 = 0.8
                    .textCase(.uppercase)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.c2bTeal.opacity(0.08))
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}

// MARK: - Related Show Card

struct SpinoffsRelatedShowCard: View {
    let title: String
    let tag: String
    let description: String
    let posterPath: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                SpinoffsCardImageHeader(title: title, tag: tag, posterPath: posterPath)
                SpinoffsCardFooter(description: description)
            }
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Image Header

struct SpinoffsCardImageHeader: View {
    let title: String
    let tag: String
    let posterPath: String?

    private var imageURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.c2bSurface)
                default:
                    Rectangle()
                        .fill(Color.c2bSurface)
                        .overlay(
                            ProgressView()
                                .tint(.c2bMuted)
                        )
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.1)],
                startPoint: .bottom,
                endPoint: .center
            )

            // Tag chip at top left
            SpinoffsTagChip(tag: tag)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(11)

            // Title at bottom
            Text(title.uppercased())
                .font(.custom(.oswald.bold, size: 22))
                .foregroundColor(.white)
                .tracking(0.22)  // 0.01em = 22 * 0.01 = 0.22
                .lineLimit(2)
                .lineSpacing(-2)
                .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Tag Chip

struct SpinoffsTagChip: View {
    let tag: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.c2bTealBright)
                .frame(width: 5, height: 5)

            Text(tag)
                .font(.custom(.jetbrains.bold, size: 8))
                .foregroundColor(.c2bTealBright)
                .tracking(0.96)  // 0.12em = 8 * 0.12 = 0.96
                .textCase(.uppercase)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color(hex: "#080808").opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}

// MARK: - Card Footer

struct SpinoffsCardFooter: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(description)
                .font(.system(size: 12.5))
                .foregroundColor(.c2bDim)
                .lineSpacing(6.25)  // 12.5 * 1.5 = 18.75, lineSpacing = 18.75 - 12.5 = 6.25

            SpinoffsFollowButton()
        }
        .padding(.horizontal, 15)
        .padding(.top, 13)
        .padding(.bottom, 15)
    }
}

// MARK: - Follow Button

struct SpinoffsFollowButton: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 14))

            Text("show_detail_follow_spinoff")
                .font(.system(size: 13, weight: .bold))
                .tracking(0.39)  // 0.03em = 13 * 0.03 = 0.39
                .textCase(.uppercase)
        }
        .foregroundColor(Color(hex: "#04201c"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Color.c2bTeal)
        .cornerRadius(12)
    }
}

// MARK: - Poster Image

struct SpinoffsPosterImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Rectangle()
                    .fill(Color.c2bSurface)
            }
        }
    }
}

// MARK: - Empty State

struct SpinoffsEmptyState: View {
    let showTitle: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                .font(.system(size: 26))
                .foregroundColor(.c2bMuted)
                .opacity(0.7)

            Text("empty_no_spinoffs")
                .font(.custom(.oswald.bold, size: 17))
                .foregroundColor(.c2bDim)
                .tracking(0.34)  // 0.02em = 17 * 0.02 = 0.34
                .textCase(.uppercase)
                .padding(.top, 12)

            Text(String(localized: "empty_no_spinoffs_message \(showTitle)"))
                .font(.system(size: 12))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(6)  // 12 * 1.5 = 18, lineSpacing = 18 - 12 = 6
                .padding(.top, 6)
        }
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(Color.white.opacity(0.14))
        )
    }
}

// MARK: - SpinoffType Extension

extension SpinoffShow.SpinoffType {
    var label: String {
        switch self {
        case .prequel: return "PREQUEL"
        case .sequel: return "SEQUEL"
        case .companion: return "COMPANION"
        case .remake: return "REMAKE"
        case .spinoff: return "SPIN-OFF"
        }
    }

    var description: String {
        switch self {
        case .prequel: return "A prequel series set before the events of the main show."
        case .sequel: return "A sequel continuing the story after the main series."
        case .companion: return "A companion series running alongside the main show."
        case .remake: return "A reimagining of the original series."
        case .spinoff: return "A spin-off exploring characters from the main series."
        }
    }
}

// MARK: - Tab Enum

enum ShowDetailTab: String, CaseIterable {
    case episodes = "tab_episodes"
    case spinoffs = "tab_spinoffs"
}

// MARK: - Tab Switcher

struct ShowDetailTabSwitcher: View {
    @Binding var selectedTab: ShowDetailTab
    let spinoffCount: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ShowDetailTab.allCases, id: \.self) { tab in
                ShowDetailTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badgeCount: tab == .spinoffs ? spinoffCount : 0,
                    onTap: { selectedTab = tab }
                )
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Tab Button

struct ShowDetailTabButton: View {
    let tab: ShowDetailTab
    let isSelected: Bool
    let badgeCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(LocalizedStringKey(tab.rawValue))
                    .font(.custom(.jetbrains.bold, size: 10))
                    .tracking(0.6)
                    .textCase(.uppercase)

                if badgeCount > 0 {
                    ShowDetailTabBadge(count: badgeCount, isSelected: isSelected)
                }
            }
            .foregroundColor(isSelected ? Color(hex: "#04201c") : .c2bDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isSelected ? Color.c2bTeal : Color.clear)
            .cornerRadius(9)
        }
    }
}

// MARK: - Tab Badge

struct ShowDetailTabBadge: View {
    let count: Int
    let isSelected: Bool

    var body: some View {
        Text("\(count)")
            .font(.custom(.jetbrains.bold, size: 8.5))
            .foregroundColor(Color(hex: "#04201c"))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isSelected ? Color(hex: "#04201c").opacity(0.25) : Color.c2bTealBright)
            .cornerRadius(999)
    }
}
