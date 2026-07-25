//
//  CountdownHeader.swift
//  Countdown2Binge
//
//  Teal gradient card showing days until binge-ready.
//  Displays countdown, finale date, and episodes remaining.
//

import SwiftUI

struct CountdownHeader: View {
    let daysRemaining: Int
    let finaleDate: Date?
    let releasedCount: Int
    let totalEpisodes: Int

    private var remainingCount: Int { totalEpisodes - releasedCount }

    var body: some View {
        HStack(spacing: 14) {
            // Days countdown
            VStack(spacing: 6) {
                Text("\(daysRemaining)")
                    .font(.custom(CustomFont.oswald.bold, size: 40))
                    .foregroundColor(.c2bTealBright)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("time_days")
                    .font(.custom(CustomFont.jetbrains.bold, size: 7.5))
                    .tracking(1.4)
                    .foregroundColor(.c2bMuted)
            }
            .frame(minWidth: 54)

            // Info text
            VStack(alignment: .leading, spacing: 5) {
                Text(String(localized: "show_detail_binge_ready_date \(formattedFinaleDate)"))
                    .font(.custom(CustomFont.jetbrains.bold, size: 9))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bTeal)

                Text(String(localized: "season_progress \(releasedCount) \(totalEpisodes) \(remainingCount)"))
                    .font(.system(size: 13))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [
                    Color.c2bTeal.opacity(0.12),
                    Color.c2bTeal.opacity(0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var formattedFinaleDate: String {
        guard let date = finaleDate else { return String(localized: "date_tba") }
        return date.localizedWeekdayDate
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CountdownHeader(
            daysRemaining: 14,
            finaleDate: Date().addingTimeInterval(86400 * 14),
            releasedCount: 4,
            totalEpisodes: 8
        )

        CountdownHeader(
            daysRemaining: 3,
            finaleDate: Date().addingTimeInterval(86400 * 3),
            releasedCount: 7,
            totalEpisodes: 8
        )
    }
    .padding(22)
    .background(Color.c2bBackground)
}
