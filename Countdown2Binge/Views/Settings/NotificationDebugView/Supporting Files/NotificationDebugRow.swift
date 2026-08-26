//
//  NotificationDebugRow.swift
//  Countdown2Binge
//
//  DEBUG ONLY — one scheduled notification, shown with everything needed to
//  tell whether it's the right one: event kind, season, fire date, and the raw
//  identifier for cross-checking against the console log.
//

#if DEBUG

import SwiftUI

struct NotificationDebugRow: View {
    let notification: ScheduledNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(notification.kindLabel)
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bOnTeal)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.c2bTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                if let season = notification.seasonNumber {
                    Text("S\(season)")
                        .font(.custom(.oswald.bold, size: 12))
                        .foregroundColor(.c2bDim)
                }

                Spacer(minLength: 0)

                if notification.isStale {
                    Text("STALE")
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(0.8)
                        .foregroundColor(.c2bAmber)
                }
            }

            Text(notification.fireDateLabel)
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(notification.isStale ? .c2bAmber : .c2bTealBright)

            Text(notification.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.c2bText)
                .lineLimit(1)

            if !notification.body.isEmpty {
                Text(notification.body)
                    .font(.system(size: 11))
                    .foregroundColor(.c2bDim)
                    .lineLimit(2)
            }

            Text(notification.id)
                .font(.custom(.jetbrains.regular, size: 8.5))
                .foregroundColor(.c2bMuted)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(notification.isStale ? Color.c2bAmberLine : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#endif
