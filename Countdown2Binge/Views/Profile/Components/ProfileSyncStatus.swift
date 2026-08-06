//
//  ProfileSyncStatus.swift
//  Countdown2Binge
//
//  iCloud sync status badge and upgrade prompt.
//

import SwiftUI

struct ProfileSyncStatus: View {
    let isPremium: Bool
    let showCount: Int
    let lastSyncedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text("profile_shows_synced")
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)

                Spacer()

                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isPremium ? .c2bTealBright : .c2bMuted)

                    Text(isPremium ? "profile_icloud_on" : "profile_icloud_off")
                        .font(.custom(.jetbrains.bold, size: 8))
                        .tracking(1.2)
                        .foregroundColor(isPremium ? .c2bTealBright : .c2bMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isPremium
                        ? Color.c2bTeal.opacity(0.12)
                        : Color.white.opacity(0.05)
                )
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(
                            isPremium ? Color.c2bTealLine : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            }

            // Upgrade prompt (free users only)
            if !isPremium {
                Text("profile_sync_upgrade_hint")
                    .font(.system(size: 12))
                    .foregroundColor(.c2bDim)
                    .lineSpacing(4)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(13)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(
                                style: StrokeStyle(lineWidth: 1, dash: [5])
                            )
                            .foregroundColor(Color.white.opacity(0.14))
                    )
            }
        }
    }
}

struct ProfileSyncFooter: View {
    let isPremium: Bool
    let showCount: Int
    let lastSyncedAt: Date?

    private var syncText: String {
        if isPremium {
            if let lastSync = lastSyncedAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                let relativeTime = formatter.localizedString(for: lastSync, relativeTo: Date())
                return String(localized: "profile_sync_status_premium \(showCount) \(relativeTime)")
            }
            return String(localized: "profile_sync_status_premium_no_sync \(showCount)")
        } else {
            return String(localized: "profile_sync_status_free \(showCount)")
        }
    }

    var body: some View {
        Text(syncText)
            .font(.custom(.jetbrains.regular, size: 8.5))
            .tracking(1.0)
            .textCase(.uppercase)
            .foregroundColor(.c2bMuted)
    }
}

#Preview {
    VStack(spacing: 30) {
        ProfileSyncStatus(isPremium: true, showCount: 12, lastSyncedAt: Date().addingTimeInterval(-120))
        ProfileSyncStatus(isPremium: false, showCount: 12, lastSyncedAt: nil)

        ProfileSyncFooter(isPremium: true, showCount: 12, lastSyncedAt: Date().addingTimeInterval(-120))
        ProfileSyncFooter(isPremium: false, showCount: 12, lastSyncedAt: nil)
    }
    .padding(20)
    .background(Color.c2bBackground)
    .preferredColorScheme(.dark)
}
