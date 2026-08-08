//
//  CatchUpSeasonPicker.swift
//  Countdown2Binge
//
//  The "Where did you leave off?" catch-up question from the follow modal.
//  Ported from c2b-followmodal.jsx. A collapsible season picker: tap the last
//  season you finished — everything before is marked watched, everything after
//  becomes your catch-up list.
//
//  Two layouts by season count: ≤12 prior seasons shows the full grid; >12
//  (e.g. Reacher) makes the grid scroll with an "S1–SN · scroll" hint.
//
//  DESIGN-ONLY: driven by inputs / local state. Wire `lastDoneSeason` to your
//  SeriesManager mark-watched flow when hooking up.
//

import SwiftUI

struct CatchUpSeasonPicker: View {
    /// Number of fully-aired (ended) seasons the user could have finished. A
    /// currently-airing / upcoming season is NOT counted (it can't be "finished"),
    /// so pass the count of seasons whose finale has already aired.
    let airedSeasonCount: Int
    /// 0 = haven't started; n = finished through Season n.
    @Binding var lastDoneSeason: Int

    @State private var expanded = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 6)

    /// The ended seasons the user could have finished.
    private var priorSeasons: [Int] { Array(1...max(1, airedSeasonCount)) }
    private var priorCount: Int { priorSeasons.count }
    private var behind: Int { max(0, airedSeasonCount - lastDoneSeason) }
    private var nextLabel: String { "Season \(airedSeasonCount + 1)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            description
            pickerCard
            resolutionCard
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.c2bTealBright)
            Text("WHERE DID YOU LEAVE OFF?")
                .font(.custom(.jetbrains.regular, size: 9.5))
                .tracking(1.52)
                .foregroundColor(.c2bText)
        }
    }

    private var description: some View {
        Text("Tap the last season you finished. Everything before it is marked watched, and anything after becomes your catch-up list.")
            .font(.system(size: 12.5))
            .foregroundColor(.c2bMuted)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 10)
            .padding(.bottom, 13)
    }

    // MARK: Collapsible picker

    private var pickerCard: some View {
        VStack(spacing: 0) {
            summaryRow
            if expanded {
                expandedGrid
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(expanded ? Color.c2bTealLine : Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var summaryRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
        } label: {
            HStack(spacing: 11) {
                Group {
                    if lastDoneSeason > 0 {
                        Text("\(Text("S").font(.custom(.oswald.bold, size: 22)))\(Text("\(lastDoneSeason)").font(.custom(.oswald.light, size: 22)))")
                            .foregroundColor(.c2bTealBright)
                    } else {
                        Text("—").font(.custom(.oswald.bold, size: 22)).foregroundColor(.c2bMuted)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(lastDoneSeason > 0 ? "Watched through Season \(lastDoneSeason)" : "Haven't started")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.c2bText)
                    Text("\(priorCount) \(priorCount == 1 ? "SEASON" : "SEASONS") OUT · TAP TO CHANGE")
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(1.02)
                        .foregroundColor(.c2bMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.c2bDim)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var expandedGrid: some View {
        VStack(spacing: 11) {
            grid
                .padding(.top, 13)

            HStack(spacing: 8) {
                pillButton(title: "NONE", active: lastDoneSeason == 0) { lastDoneSeason = 0 }
                pillButton(title: "ALL CAUGHT UP", active: lastDoneSeason == priorCount) { lastDoneSeason = priorCount }
                Spacer(minLength: 0)
                Text("S1–S\(priorCount)")
                    .font(.custom(.jetbrains.regular, size: 8))
                    .tracking(0.64)
                    .foregroundColor(.c2bMuted)
            }
        }
        .padding(.horizontal, 14).padding(.bottom, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    /// Full grid of season boxes — the modal itself scrolls, so no internal cap.
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(priorSeasons.reversed(), id: \.self) { n in
                seasonBox(n)
            }
        }
    }

    private func seasonBox(_ n: Int) -> some View {
        let watched = n <= lastDoneSeason
        let marked = n == lastDoneSeason
        return Button {
            lastDoneSeason = (n == lastDoneSeason) ? n - 1 : n
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(marked ? Color.c2bTeal : (watched ? Color.c2bTeal.opacity(0.16) : Color.white.opacity(0.04)))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(marked ? Color.c2bTeal : (watched ? Color.c2bTealLine : Color.white.opacity(0.1)), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 1) {
                        Text("\(Text("S").font(.custom(.oswald.bold, size: 11)))\(Text("\(n)").font(.custom(.oswald.light, size: 11)))")
                            .foregroundColor(marked ? .c2bOnTeal : (watched ? .c2bTealBright : .c2bDim))
                        if watched {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(marked ? .c2bOnTeal : .c2bTeal)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private func pillButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(0.8)
                .foregroundColor(active ? (title == "NONE" ? .c2bText : .c2bOnTeal) : .c2bMuted)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(pillBackground(title: title, active: active))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(pillBorder(title: title, active: active), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func pillBackground(title: String, active: Bool) -> Color {
        guard active else { return Color.white.opacity(0.05) }
        return title == "NONE" ? Color.white.opacity(0.14) : Color.c2bTeal
    }

    private func pillBorder(title: String, active: Bool) -> Color {
        guard active else { return Color.white.opacity(0.12) }
        return title == "NONE" ? Color.white.opacity(0.35) : Color.c2bTeal
    }

    // MARK: Resolution

    private var resolutionCard: some View {
        HStack(spacing: 11) {
            Text("\(behind)")
                .font(.custom(.oswald.bold, size: 26))
                .foregroundColor(behind > 0 ? .c2bAmber : .c2bTealBright)
            VStack(alignment: .leading, spacing: 4) {
                Text(behind > 0
                     ? (behind == 1 ? "SEASON TO CATCH UP ON" : "SEASONS TO CATCH UP ON")
                     : "ALL CAUGHT UP")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(1.08)
                    .foregroundColor(behind > 0 ? .c2bAmber : .c2bTealBright)
                Text(behind > 0
                     ? "We'll add \(behind == 1 ? "it" : "them") to My List so you finish before \(nextLabel) lands."
                     : "Nothing to rewatch — you're ready for \(nextLabel).")
                    .font(.system(size: 12.5))
                    .foregroundColor(.c2bMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(behind > 0 ? Color.c2bAmber.opacity(0.10) : Color.c2bTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(behind > 0 ? Color.c2bAmberLine : Color.c2bTealLine, lineWidth: 1)
        )
        .padding(.top, 13)
    }
}

// MARK: - Previews

private struct CatchUpPreviewHost: View {
    let aired: Int
    @State private var lastDone: Int
    init(aired: Int, lastDone: Int = 0) {
        self.aired = aired
        _lastDone = State(initialValue: lastDone)
    }
    var body: some View {
        CatchUpSeasonPicker(airedSeasonCount: aired, lastDoneSeason: $lastDone)
            .padding(20)
    }
}

#Preview("Few seasons") {
    ScrollView { CatchUpPreviewHost(aired: 2, lastDone: 1) }
        .background(Color(hex: "#0e0e0f"))
}

#Preview("Grey's — many seasons") {
    ScrollView { CatchUpPreviewHost(aired: 22, lastDone: 9) }
        .background(Color(hex: "#0e0e0f"))
}
