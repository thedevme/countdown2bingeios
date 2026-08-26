//
//  ShowAlertsSheet.swift
//  Countdown2Binge
//
//  "Your alerts" — what this show will actually notify you about, and when.
//  Design ported from the prototype's notification modal; the content is the
//  app's own four NotificationTypes and the exact copy the planner delivers.
//
//  View mode is a timeline of the four alerts in the order a season moves
//  through them: announced → premieres → finale approaching → fully out. Each
//  row shows the real notification title and body, so the answer to "what will
//  I get?" is the message itself rather than a switch labelled "Finale".
//
//  Edit mode writes the per-show settings and reschedules through
//  SeriesManager (R3). Nothing here writes notifications directly.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ShowAlertsSheet: View {
    let series: Series
    let onDismiss: () -> Void

    @Environment(SeriesManager.self) private var seriesManager

    @State private var isEditing = false
    @State private var settings: NotificationSettings
    @State private var scheduledDates: [String: Date] = [:]   // identifier → fire date

    init(series: Series, onDismiss: @escaping () -> Void) {
        self.series = series
        self.onDismiss = onDismiss
        self._settings = State(initialValue: series.notificationSettings)
    }

    private var seasonNumber: Int? { series.currentSeason?.seasonNumber }

    private var enabledCount: Int {
        [settings.newSeason, settings.seasonPremiere,
         settings.finaleReminder, settings.bingeReady].filter { $0 }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            grabber
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if isEditing { editContent } else { viewContent }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            primaryButton
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        // Fills the sheet. Previously this was a bare VStack with a custom
        // rounded background and `.presentationBackground(.clear)`, which left
        // the card painting but the content collapsed to nothing.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: "#0e0e0f"))
        .task { await loadScheduled() }
    }

    // MARK: - Chrome

    private var grabber: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 40, height: 4)
            .padding(.top, 10)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15))
                .foregroundColor(.c2bTealBright)
                .frame(width: 34, height: 34)
                .background(Color.c2bTeal.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.c2bTealLine, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(isEditing
                     ? String(localized: "alerts_sheet_title_edit")
                     : String(localized: "alerts_sheet_title"))
                    .font(.custom(.oswald.bold, size: 19))
                    .foregroundColor(.c2bText)

                Text(subtitle)
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .tracking(0.85)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.c2bMuted)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var subtitle: String {
        let season = seasonNumber.map { "S\($0)" } ?? ""
        let count = String(localized: "alerts_sheet_count \(enabledCount) \(4)")
        return [series.name, season, count]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    // MARK: - View mode

    private var viewContent: some View {
        let items = alertItems
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                ShowAlertRow(item: item, showsConnector: index < items.count - 1)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Edit mode

    private var editContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "alerts_section_this_show \(series.name)"))
                .font(.custom(.jetbrains.regular, size: 8.5))
                .tracking(0.85)
                .textCase(.uppercase)
                .foregroundColor(.c2bMuted)
                .padding(.top, 6)
                .padding(.bottom, 2)

            toggleRow(.newSeason,  isOn: $settings.newSeason)
            toggleRow(.premiere,   isOn: $settings.seasonPremiere)
            toggleRow(.finale,     isOn: $settings.finaleReminder)
            toggleRow(.bingeReady, isOn: $settings.bingeReady)

            Text(String(localized: "alerts_edit_footnote"))
                .font(.system(size: 11.5))
                .foregroundColor(.c2bMuted)
                .lineSpacing(2)
                .padding(.top, 6)
        }
    }

    private func toggleRow(_ type: NotificationType, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(type.alertBadgeLabel)
                    .font(.custom(.oswald.bold, size: 14))
                    .tracking(0.42)
                    .foregroundColor(isOn.wrappedValue ? .c2bText : .c2bMuted)

                Text(title(for: type))
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            SettingsToggle(isOn: isOn)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(isOn.wrappedValue ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var primaryButton: some View {
        Button {
            if isEditing {
                commit()
            }
            withAnimation(.easeOut(duration: 0.2)) { isEditing.toggle() }
        } label: {
            Text(isEditing
                 ? String(localized: "alerts_button_done")
                 : String(localized: "alerts_button_edit"))
                .font(.custom(.oswald.bold, size: 15))
                .tracking(0.45)
                .textCase(.uppercase)
                .foregroundColor(.c2bOnTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.c2bTeal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    /// One row per notification type, in season order.
    private var alertItems: [ShowAlertItem] {
        NotificationType.allCases
            .sorted { $0.alertSortIndex < $1.alertSortIndex }
            .map { type in
                ShowAlertItem(
                    type: type,
                    seasonNumber: seasonNumber,
                    title: title(for: type),
                    body: body(for: type),
                    status: status(for: type)
                )
            }
    }

    /// Real pending request first; then the reasons one might be absent.
    private func status(for type: NotificationType) -> ShowAlertItem.Status {
        guard isEnabled(type) else { return .turnedOff }

        if let date = scheduledDates[identifier(for: type)] {
            return date > Date() ? .scheduled(date) : .alreadySent
        }

        // Nothing pending. Either its date has passed, or there's no date yet.
        switch type {
        case .newSeason:
            // Event-driven: fires once on detection, never sits pending.
            return series.currentSeason != nil ? .alreadySent : .awaitingDate
        case .premiere:
            guard let premiere = series.currentSeason?.premiereDate else { return .awaitingDate }
            return premiere <= Date() ? .alreadySent : .awaitingDate
        case .finale, .bingeReady:
            guard let finale = series.currentSeason?.finaleDate else { return .awaitingDate }
            return finale <= Date() ? .alreadySent : .awaitingDate
        }
    }

    private func isEnabled(_ type: NotificationType) -> Bool {
        guard series.notificationsEnabled else { return false }
        switch type {
        case .newSeason:  return settings.newSeason
        case .premiere:   return settings.seasonPremiere
        case .finale:     return settings.finaleReminder
        case .bingeReady: return settings.bingeReady
        }
    }

    /// Matches NotificationPlanner's scheme: show-{id}-{kind}-s{n}
    private func identifier(for type: NotificationType) -> String {
        let kind: String
        switch type {
        case .newSeason:  kind = "newseason"
        case .premiere:   kind = "premiere"
        case .finale:     kind = "finale"
        case .bingeReady: kind = "bingeready"
        }
        return "show-\(series.id)-\(kind)-s\(seasonNumber ?? 0)"
    }

    // The delivered copy, so the sheet can't drift from the notification.
    private func title(for type: NotificationType) -> String {
        switch type {
        case .premiere:   return String(localized: "notif_premiere_title")
        case .finale:     return String(localized: "notif_finale_title")
        case .bingeReady: return String(localized: "notif_bingeready_title")
        case .newSeason:  return String(localized: "notif_newseason_title")
        }
    }

    private func body(for type: NotificationType) -> String {
        switch type {
        case .premiere:   return String(localized: "notif_premiere_body \(series.name)")
        case .finale:     return String(localized: "notif_finale_body \(series.name)")
        case .bingeReady: return String(localized: "notif_bingeready_body \(series.name)")
        case .newSeason:  return String(localized: "notif_newseason_body \(series.name) \(seasonNumber ?? 0)")
        }
    }

    private func loadScheduled() async {
        let prefix = "show-\(series.id)-"
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        var map: [String: Date] = [:]
        for request in pending where request.identifier.hasPrefix(prefix) {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate() {
                map[request.identifier] = date
            }
        }
        scheduledDates = map
    }

    /// Save through SeriesManager, which reschedules this show's alerts (R3).
    private func commit() {
        seriesManager.updateNotifications(
            enabled: series.notificationsEnabled,
            settings: settings,
            for: series
        )
        Task { await loadScheduled() }
    }
}
