//
//  TimelineCards.swift
//  Countdown2Binge
//
//  Mini card mode components for Timeline screen

import SwiftUI

// MARK: - Timeline Density Toggle
enum TimelineDensity: String, CaseIterable {
    case cards
    case mini
}

struct TimelineDensityToggle: View {
    @Binding var density: TimelineDensity

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimelineDensity.allCases, id: \.self) { mode in
                let isSelected = density == mode

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        density = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .mini ? "line.3.horizontal" : "square.stack")
                            .font(.system(size: 11, weight: .semibold))

                        Text(mode.rawValue.uppercased())
                            .font(.custom(.jetbrains.bold, size: 9))
                            .tracking(0.8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(isSelected ? Color(hex: "#04201c") : .c2bDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.c2bTeal : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .frame(width: 160)
    }
}

// MARK: - Mini Premiering Card
struct MiniPremieringCard: View {
    let showData: ShowData

    private var daysUntilPremiere: Int {
        showData.daysUntilPremiere ?? 0
    }

    private var seasonNumber: String {
        String(showData.numberOfSeasons)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text("\(daysUntilPremiere)")
                    .font(.custom(.oswald.bold, size: 30))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("timeline_to_premiere")
                    .font(.custom(.jetbrains.bold, size: 6.5))
                    .tracking(0.8)
                    .foregroundColor(.c2bTealBright)
            }
            .frame(width: 48)

            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 0) {
                    Text("season_abbrev")
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)

                    Text(seasonNumber)
                        .font(.custom(.oswald.light, size: 20))
                        .foregroundColor(.white)
                }

                Text(showData.name)
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let network = showData.networks.first {
                Text(network.name.uppercased())
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.3)
                    .foregroundColor(Color(hex: "#e7e7e7"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(Color.white.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.c2bTealLine)
                .frame(width: 2),
            alignment: .leading
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Mini Anticipated Card
struct MiniAnticipatedCard: View {
    let showData: ShowData

    private var expectedYear: String {
        let nextYear = Calendar.current.component(.year, from: Date()) + 1
        return String(nextYear)
    }

    private var anticipatedSeasonNumber: String {
        String(showData.numberOfSeasons + 1)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(expectedYear)
                    .font(.custom(.oswald.bold, size: 24))
                    .foregroundColor(.c2bDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("timeline_expected")
                    .font(.custom(.jetbrains.bold, size: 6.5))
                    .tracking(0.8)
                    .foregroundColor(.c2bMuted)
            }
            .frame(width: 48)

            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 0) {
                    Text("season_abbrev")
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(Color.white.opacity(0.82))

                    Text(anticipatedSeasonNumber)
                        .font(.custom(.oswald.light, size: 20))
                        .foregroundColor(Color.white.opacity(0.82))
                }

                Text(showData.name)
                    .font(.custom(.oswald.bold, size: 17))
                    .foregroundColor(.c2bDim)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let network = showData.networks.first {
                Text(network.name.uppercased())
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.3)
                    .foregroundColor(.c2bMuted)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )
                .foregroundColor(Color.white.opacity(0.12))
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Mini Empty Section
struct MiniEmptySection: View {
    let dim: Bool

    init(dim: Bool = false) {
        self.dim = dim
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 3) {
                Text("--")
                    .font(.custom(.oswald.bold, size: dim ? 24 : 30))
                    .foregroundColor(dim ? .c2bDim : Color.white.opacity(0.4))

                Text(dim ? "timeline_expected" : "timeline_to_premiere")
                    .font(.custom(.jetbrains.bold, size: 6.5))
                    .tracking(0.8)
                    .foregroundColor(dim ? .c2bMuted : .c2bTealBright.opacity(0.5))
            }
            .frame(width: 48)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 60)
        .background(dim ? Color.white.opacity(0.02) : Color.white.opacity(0.03))
        .overlay(
            dim ?
            nil :
            Rectangle()
                .fill(Color.c2bTealLine.opacity(0.5))
                .frame(width: 2),
            alignment: .leading
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: dim ?
                    StrokeStyle(lineWidth: 1, dash: [5, 5]) :
                    StrokeStyle(lineWidth: 1)
                )
                .foregroundColor(Color.white.opacity(dim ? 0.12 : 0.08))
        )
    }
}
