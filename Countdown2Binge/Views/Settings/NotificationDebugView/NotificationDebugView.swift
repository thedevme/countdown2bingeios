//
//  NotificationDebugView.swift
//  Countdown2Binge
//
//  DEBUG ONLY — every notification currently scheduled with the system, so you
//  can verify on-device that followed shows actually have alerts registered.
//
//  Reads UNUserNotificationCenter directly rather than any stored intent: the
//  question this screen answers is "what is REALLY scheduled right now", which
//  is not the same as what the app believes it scheduled.
//
//  Three sections, ordered by how much they should worry you:
//    1. shows that want notifications but have none  (something silently failed)
//    2. orphaned requests for shows no longer followed (cancellation missed one)
//    3. everything scheduled, grouped by show
//

#if DEBUG

import SwiftUI
import SwiftData
import UserNotifications

struct NotificationDebugView: View {
    let onDismiss: () -> Void

    @Query(sort: \Series.name) private var allSeries: [Series]
    @Environment(SeriesManager.self) private var seriesManager

    @State private var scheduled: [ScheduledNotification] = []
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var isLoading = true
    @State private var isRescheduling = false

    // MARK: - Derived

    private var showNotifications: [ScheduledNotification] {
        scheduled.filter(\.isShowNotification)
    }

    private var byShowId: [Int: [ScheduledNotification]] {
        Dictionary(grouping: showNotifications, by: { $0.showId ?? -1 })
            .mapValues { $0.sorted { ($0.fireDate ?? .distantFuture) < ($1.fireDate ?? .distantFuture) } }
    }

    /// Followed shows that want alerts but have nothing registered.
    private var silentShows: [Series] {
        allSeries.filter { $0.notificationsActive && (byShowId[$0.id]?.isEmpty ?? true) }
    }

    /// Scheduled requests whose show isn't followed any more.
    private var orphans: [ScheduledNotification] {
        let followed = Set(allSeries.map(\.id))
        return showNotifications.filter { !followed.contains($0.showId ?? -1) }
    }

    /// Followed shows that do have alerts, most imminent first.
    private var scheduledShows: [Series] {
        allSeries
            .filter { !(byShowId[$0.id]?.isEmpty ?? true) }
            .sorted { a, b in
                let aNext = byShowId[a.id]?.first?.fireDate ?? .distantFuture
                let bNext = byShowId[b.id]?.first?.fireDate ?? .distantFuture
                return aNext < bNext
            }
    }

    private var otherNotifications: [ScheduledNotification] {
        scheduled.filter { !$0.isShowNotification }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                summary

                if isLoading {
                    ProgressView().tint(.c2bTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    if !silentShows.isEmpty { silentSection }
                    if !orphans.isEmpty { orphanSection }
                    scheduledSection
                    if !otherNotifications.isEmpty { otherSection }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
            .padding(.bottom, 150)
        }
        .background(Color.c2bBackground)
        .navigationBarBackButtonHidden(true)
        .refreshable { await load() }
        .task { await load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(white: 0.8))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("SCHEDULED ALERTS")
                .font(.custom(.oswald.bold, size: 23))
                .foregroundColor(.c2bText)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 20) {
                stat("\(scheduled.count)", "pending")
                stat("\(scheduledShows.count)", "shows")
                stat("\(silentShows.count)", "silent")
            }

            Text("Authorization: \(authLabel)")
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(authStatus == .authorized ? .c2bTealBright : .c2bAmber)

            Text("iOS caps pending local notifications at 64 per app — anything past that is dropped silently.")
                .font(.system(size: 11))
                .foregroundColor(scheduled.count >= 64 ? .c2bAmber : .c2bMuted)

            HStack(spacing: 10) {
                Button {
                    Task {
                        isRescheduling = true
                        seriesManager.rescheduleAllNotifications()
                        try? await Task.sleep(for: .seconds(2))
                        await load()
                        isRescheduling = false
                    }
                } label: {
                    Text(isRescheduling ? "RESCHEDULING…" : "RESCHEDULE ALL")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .tracking(0.9)
                        .foregroundColor(.c2bOnTeal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .disabled(isRescheduling)

                Button {
                    Task { await load() }
                } label: {
                    Text("REFRESH")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .tracking(0.9)
                        .foregroundColor(.c2bDim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.custom(.oswald.bold, size: 26))
                .foregroundColor(.c2bTealBright)
            Text(label)
                .font(.custom(.jetbrains.regular, size: 8))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
        }
    }

    private var authLabel: String {
        switch authStatus {
        case .authorized:        return "authorized"
        case .denied:            return "DENIED — nothing will fire"
        case .notDetermined:     return "not determined"
        case .provisional:       return "provisional"
        case .ephemeral:         return "ephemeral"
        @unknown default:        return "unknown"
        }
    }

    // MARK: - Sections

    private var silentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Wants alerts · nothing scheduled", count: silentShows.count, tone: .c2bAmber)

            Text("These shows have notifications switched on but no pending request. Either scheduling failed or there's no future date to schedule against.")
                .font(.system(size: 11.5))
                .foregroundColor(.c2bMuted)

            ForEach(silentShows) { series in
                HStack(spacing: 8) {
                    Text(series.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.c2bText)
                    Spacer(minLength: 0)
                    Text(series.showState.rawValue)
                        .font(.custom(.jetbrains.regular, size: 9))
                        .foregroundColor(.c2bMuted)
                }
                .padding(11)
                .background(Color.c2bAmberWash)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.c2bAmberLine, lineWidth: 1)
                )
            }
        }
    }

    private var orphanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Orphaned · show not followed", count: orphans.count, tone: .c2bAmber)
            ForEach(orphans) { NotificationDebugRow(notification: $0) }
        }
    }

    private var scheduledSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Scheduled by show", count: scheduledShows.count, tone: .c2bTealBright)

            if scheduledShows.isEmpty {
                Text("Nothing scheduled at all.")
                    .font(.system(size: 12))
                    .foregroundColor(.c2bMuted)
            }

            ForEach(scheduledShows) { series in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(series.name)
                            .font(.custom(.oswald.bold, size: 16))
                            .foregroundColor(.c2bText)
                        Text("\(byShowId[series.id]?.count ?? 0)")
                            .font(.custom(.jetbrains.bold, size: 9))
                            .foregroundColor(.c2bTealBright)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.c2bTealSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                        Spacer(minLength: 0)
                        Text("id \(series.id)")
                            .font(.custom(.jetbrains.regular, size: 8.5))
                            .foregroundColor(.c2bMuted)
                    }

                    ForEach(byShowId[series.id] ?? []) { NotificationDebugRow(notification: $0) }
                }
            }
        }
    }

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Other", count: otherNotifications.count, tone: .c2bMuted)
            ForEach(otherNotifications) { NotificationDebugRow(notification: $0) }
        }
    }

    private func sectionHeader(_ title: String, count: Int, tone: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(tone).frame(width: 7, height: 7)
            Text(title)
                .font(.custom(.jetbrains.bold, size: 9.5))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.c2bText)
            Text("\(count)")
                .font(.custom(.jetbrains.bold, size: 9))
                .foregroundColor(tone)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Load

    private func load() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let settings = await center.notificationSettings()

        scheduled = requests
            .map(ScheduledNotification.init(request:))
            .sorted { ($0.fireDate ?? .distantFuture) < ($1.fireDate ?? .distantFuture) }
        authStatus = settings.authorizationStatus
        isLoading = false
    }
}

#endif
