//
//  ShowAlertRow.swift
//  Countdown2Binge
//
//  One alert on the sheet's spine: type badge, season, status, then the
//  notification exactly as it will appear on the lock screen.
//
//  Showing the real title and body is the point of this screen — "you will get
//  this message, on this date" is more useful than a switch labelled "Finale".
//

import SwiftUI

struct ShowAlertRow: View {
    let item: ShowAlertItem
    /// Draws the connecting spine below this row. Off for the last one.
    let showsConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            spine
            card
        }
        .opacity(item.isMuted ? 0.55 : 1)
    }

    // MARK: - Spine

    private var spine: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(item.isMuted ? Color.white.opacity(0.18) : Color.c2bTealBright)
                .frame(width: 11, height: 11)
                .padding(.top, 7)

            if showsConnector {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.c2bTeal.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .padding(.top, 4)
            }
        }
        .frame(width: 11)
        .padding(.trailing, 14)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(item.type.alertBadgeLabel)
                    .font(.custom(.jetbrains.bold, size: 8))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bOnTeal)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(item.isMuted ? Color.c2bMuted : Color.c2bTealBright)
                    .clipShape(RoundedRectangle(cornerRadius: 999))

                if let season = item.seasonNumber {
                    (
                        Text(String(localized: "season_abbrev"))
                            .font(.custom(.oswald.bold, size: 12))
                        + Text("\(season)")
                            .font(.custom(.oswald.light, size: 12))
                    )
                    .foregroundColor(.c2bDim)
                }

                Spacer(minLength: 8)

                Text(statusLabel)
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .tracking(0.68)
                    .textCase(.uppercase)
                    .foregroundColor(statusColor)
                    .lineLimit(1)
            }
            .padding(.bottom, 9)

            Text(item.title)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(.c2bText)

            Text(item.body)
                .font(.system(size: 12))
                .foregroundColor(.c2bDim)
                .lineSpacing(2)
                .padding(.top, 4)

            Text(footnote)
                .font(.custom(.jetbrains.regular, size: 8.5))
                .tracking(0.51)
                .foregroundColor(.c2bMuted)
                .padding(.top, 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Status

    private var statusLabel: String {
        switch item.status {
        case .scheduled(let date):
            return relative(date)
        case .alreadySent:
            return String(localized: "alert_status_sent")
        case .awaitingDate:
            return String(localized: "alert_status_awaiting")
        case .turnedOff:
            return String(localized: "alert_status_off")
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .scheduled:    return .c2bTealBright
        case .alreadySent:  return .c2bMuted
        case .awaitingDate: return .c2bAmber
        case .turnedOff:    return .c2bMuted
        }
    }

    /// The line under the message — the exact fire date, or why there isn't one.
    private var footnote: String {
        switch item.status {
        case .scheduled(let date):
            return date.formatted(date: .abbreviated, time: .shortened)
        case .alreadySent:
            return String(localized: "alert_note_sent")
        case .awaitingDate:
            return String(localized: "alert_note_awaiting")
        case .turnedOff:
            return String(localized: "alert_note_off")
        }
    }

    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        ShowAlertRow(
            item: ShowAlertItem(
                type: .newSeason, seasonNumber: 2,
                title: "New season announced",
                body: "Cold Harvest Season 2 is official. We'll count down from here.",
                status: .alreadySent
            ),
            showsConnector: true
        )
        ShowAlertRow(
            item: ShowAlertItem(
                type: .finale, seasonNumber: 2,
                title: "Finale is coming",
                body: "The Cold Harvest S2 finale airs soon — last episode before it's bingeable.",
                status: .awaitingDate
            ),
            showsConnector: true
        )
        ShowAlertRow(
            item: ShowAlertItem(
                type: .bingeReady, seasonNumber: 2,
                title: "Ready to binge 🍿",
                body: "All of Cold Harvest Season 2 is out. Start to finish, whenever you want.",
                status: .turnedOff
            ),
            showsConnector: false
        )
    }
    .padding()
    .background(Color.c2bBackground)
}
