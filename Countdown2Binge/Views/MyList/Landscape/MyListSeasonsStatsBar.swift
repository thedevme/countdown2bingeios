//
//  MyListSeasonsStatsBar.swift
//  Countdown2Binge
//
//  Summary bar above the Ready grid — how many seasons are binge-ready, across
//  how many shows, and the total watch-time left. Ported from c2b-mylist.jsx
//  `MLSeasonsView` header block (Ready tab).
//

import SwiftUI

struct MyListSeasonsStatsBar: View {
    /// Total binge-ready (complete-unwatched) seasons across the shown shows.
    let seasonCount: Int
    /// How many shows those seasons span.
    let showCount: Int
    /// Total watch-time left across the shown (current) seasons, in seconds.
    let secondsLeft: Int

    var body: some View {
        HStack(spacing: 13) {
            Text(String(format: "%02d", seasonCount))
                .font(.custom(.oswald.bold, size: 42))
                .foregroundColor(.c2bTealBright)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("mylist_ls_stats_title %lld", comment: ""), showCount))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.c2bText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "mylist_ls_fully_released"))
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(0.8)
                    .foregroundColor(.c2bMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 11) {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 34)
                VStack(alignment: .trailing, spacing: 4) {
                    RuntimeClock(seconds: secondsLeft, numberSize: 20, unitSize: 9)
                    Text(String(localized: "mylist_ls_left_to_watch"))
                        .font(.custom(.jetbrains.regular, size: 8.5))
                        .tracking(0.75)
                        .foregroundColor(.c2bMuted)
                }
            }
            .fixedSize()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(Color.c2bTeal.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        MyListSeasonsStatsBar(seasonCount: 5, showCount: 3, secondsLeft: 2887 * 40)
        MyListSeasonsStatsBar(seasonCount: 1, showCount: 1, secondsLeft: 3736 * 8)
    }
    .padding(20)
    .background(Color.c2bBackground)
}
