//
//  ShowDetailSpinoffsSection.swift
//  Countdown2Binge
//
//  Spinoffs tab content for show detail - displays franchise universe.
//

import SwiftUI

// MARK: - Spinoffs Section (Premium Feature)

struct ShowDetailSpinoffsSection: View {
    let show: ShowData
    let franchise: Franchise?
    let onSpinoffTap: (Int) -> Void  // TMDB ID of spinoff

    private var hasSpinoffs: Bool {
        franchise != nil && !franchise!.spinoffs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let franchise = franchise, !franchise.spinoffs.isEmpty {
                // Premium banner
                SpinoffsPremiumBanner(showTitle: show.name)
                    .padding(.bottom, 16)

                // Watch order timeline
                SpinoffsWatchOrderTimeline(
                    show: show,
                    franchise: franchise,
                    onSpinoffTap: onSpinoffTap
                )
            } else {
                // Empty state
                SpinoffsEmptyState()
            }
        }
        .padding(.top, 22)
    }
}

// MARK: - Premium Banner

private struct SpinoffsPremiumBanner: View {
    let showTitle: String

    var body: some View {
        HStack(spacing: 11) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.c2bTeal)
                    .frame(width: 34, height: 34)

                Image(systemName: "crown.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#04201c"))
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("UNIVERSE — PREMIUM")
                    .font(.custom(.oswald.bold, size: 15))
                    .foregroundColor(.c2bTealBright)
                    .tracking(0.3)

                Text("Track every spin-off & prequel connected to \(showTitle).")
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(2)
            }

            Spacer()
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

// MARK: - Watch Order Timeline

private struct SpinoffsWatchOrderTimeline: View {
    let show: ShowData
    let franchise: Franchise
    let onSpinoffTap: (Int) -> Void

    // Build ordered list: prequels → main show → others
    private var orderedItems: [WatchOrderItem] {
        var items: [WatchOrderItem] = []

        // Prequels first
        let prequels = franchise.spinoffs.filter { $0.type == .prequel }
        for spinoff in prequels {
            items.append(.spinoff(spinoff))
        }

        // Main show
        items.append(.mainShow)

        // Other spinoffs (sequel, companion, spinoff, remake)
        let others = franchise.spinoffs.filter { $0.type != .prequel }
        for spinoff in others {
            items.append(.spinoff(spinoff))
        }

        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(.c2bTealBright)

                Text("RECOMMENDED WATCH ORDER")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .foregroundColor(.c2bTealBright)
                    .tracking(1.4)
            }
            .padding(.leading, 22)
            .padding(.bottom, 16)

            // Timeline
            ZStack(alignment: .leading) {
                // Vertical line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.c2bTealBright, .c2bTeal, Color.white.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 40)

                // Items
                VStack(spacing: 16) {
                    ForEach(Array(orderedItems.enumerated()), id: \.offset) { index, item in
                        WatchOrderItemRow(
                            item: item,
                            index: index + 1,
                            show: show,
                            onSpinoffTap: onSpinoffTap
                        )
                    }
                }
                .padding(.leading, 30)
            }
        }
    }
}

// MARK: - Watch Order Item

private enum WatchOrderItem {
    case mainShow
    case spinoff(SpinoffShow)
}

private struct WatchOrderItemRow: View {
    let item: WatchOrderItem
    let index: Int
    let show: ShowData
    let onSpinoffTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Number circle
            ZStack {
                Circle()
                    .fill(isMainShow ? Color.c2bTealBright : Color(hex: "#0a0a0b"))
                    .frame(width: 22, height: 22)

                if !isMainShow {
                    Circle()
                        .stroke(Color.c2bTealLine, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }

                Text("\(index)")
                    .font(.custom(.oswald.bold, size: 12))
                    .foregroundColor(isMainShow ? Color(hex: "#04201c") : .c2bTealBright)
            }
            .offset(x: -41)

            // Content
            if isMainShow {
                MainShowCard(show: show)
                    .offset(x: -30)
            } else if case .spinoff(let spinoff) = item {
                SpinoffCard(spinoff: spinoff, onTap: { onSpinoffTap(spinoff.tmdbId) })
                    .offset(x: -30)
            }
        }
    }

    private var isMainShow: Bool {
        if case .mainShow = item { return true }
        return false
    }
}

// MARK: - Main Show Card (You Are Here)

private struct MainShowCard: View {
    let show: ShowData

    private var posterURL: URL? {
        guard let path = show.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(path)")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 60)
                        .clipped()
                        .cornerRadius(7)
                default:
                    Rectangle()
                        .fill(Color.c2bSurface)
                        .frame(width: 40, height: 60)
                        .cornerRadius(7)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(show.name)
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bTealBright)
                    .lineLimit(1)

                Text("MAIN SERIES · YOU ARE HERE")
                    .font(.custom(.jetbrains.bold, size: 8))
                    .foregroundColor(.c2bTeal)
                    .tracking(0.8)
            }

            Spacer()
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

// MARK: - Spinoff Card

private struct SpinoffCard: View {
    let spinoff: SpinoffShow
    let onTap: () -> Void

    @State private var posterURL: URL?

    private var typeLabel: String {
        switch spinoff.type {
        case .prequel: return "PREQUEL"
        case .sequel: return "SEQUEL"
        case .companion: return "COMPANION"
        case .remake: return "REMAKE"
        case .spinoff: return "SPIN-OFF"
        }
    }

    private var statusLabel: String {
        switch spinoff.status {
        case .ended: return "Ended"
        case .returning: return "Returning"
        case .upcoming: return "Upcoming"
        case .inProduction: return "In Production"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image header with tag
            ZStack(alignment: .topLeading) {
                // Backdrop placeholder (would need to fetch from TMDB)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.c2bSurface, Color.c2bBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        // Show title as fallback
                        Text(spinoff.title)
                            .font(.custom(.oswald.bold, size: 20))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding()
                    )

                // Tag chip
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.c2bTealBright)
                        .frame(width: 5, height: 5)

                    Text(typeLabel)
                        .font(.custom(.jetbrains.bold, size: 8))
                        .foregroundColor(.c2bTealBright)
                        .tracking(1.0)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .background(.ultraThinMaterial)
                .cornerRadius(999)
                .overlay(
                    Capsule()
                        .stroke(Color.c2bTealLine, lineWidth: 1)
                )
                .padding(11)
            }
            .cornerRadius(16, corners: [.topLeft, .topRight])

            // Content
            VStack(alignment: .leading, spacing: 13) {
                // Title and years
                VStack(alignment: .leading, spacing: 4) {
                    Text(spinoff.title)
                        .font(.custom(.oswald.bold, size: 18))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(spinoff.years)
                            .font(.custom(.jetbrains.regular, size: 10))
                            .foregroundColor(.c2bMuted)

                        Text("·")
                            .foregroundColor(.c2bMuted)

                        Text(statusLabel)
                            .font(.custom(.jetbrains.regular, size: 10))
                            .foregroundColor(spinoff.status == .returning ? .c2bTealBright : .c2bMuted)
                    }
                }

                // Follow button
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 12))

                        Text("FOLLOW SPIN-OFF")
                            .font(.custom(.oswald.bold, size: 13))
                            .tracking(0.3)
                    }
                    .foregroundColor(Color(hex: "#04201c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.c2bTeal)
                    .cornerRadius(12)
                }
            }
            .padding(15)
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Empty State

private struct SpinoffsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 32))
                .foregroundColor(.c2bMuted)

            Text("No spin-offs or prequels")
                .font(.custom(.oswald.bold, size: 18))
                .foregroundColor(.c2bDim)

            Text("This show isn't part of a connected universe yet.")
                .font(.system(size: 13))
                .foregroundColor(.c2bMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(Color.white.opacity(0.14))
        )
    }
}

// MARK: - Detail Tab Enum

enum ShowDetailTab: String, CaseIterable {
    case episodes = "Episodes"
    case spinoffs = "Spin-offs"
}

// MARK: - Tab Switcher

struct ShowDetailTabSwitcher: View {
    @Binding var selectedTab: ShowDetailTab
    let spinoffCount: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ShowDetailTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Text(tab.rawValue.uppercased())
                            .font(.custom(.jetbrains.bold, size: 10))
                            .tracking(0.6)

                        // Badge for spinoffs count
                        if tab == .spinoffs && spinoffCount > 0 {
                            Text("\(spinoffCount)")
                                .font(.custom(.jetbrains.bold, size: 8.5))
                                .foregroundColor(selectedTab == tab ? Color(hex: "#04201c") : Color(hex: "#04201c"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(selectedTab == tab ? Color(hex: "#04201c").opacity(0.25) : Color.c2bTealBright)
                                .cornerRadius(999)
                        }
                    }
                    .foregroundColor(selectedTab == tab ? Color(hex: "#04201c") : .c2bDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(selectedTab == tab ? Color.c2bTeal : Color.clear)
                    .cornerRadius(9)
                }
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
