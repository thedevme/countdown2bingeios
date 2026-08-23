//
//  ShowNotificationSettingsOverlay.swift
//  Countdown2Binge
//
//  Per-show notification settings. A master on/off switch (is this show
//  registered for notifications?) plus the four types (+ finale timing).
//  Reachable from the bell on a My List card.
//
//  Settings are edited locally, then committed on Save through SeriesManager
//  (R3). Master + per-type settings seed from the global defaults at follow.
//

import SwiftUI

struct ShowNotificationSettingsOverlay: View {
    let series: Series
    let onDismiss: () -> Void

    @Environment(SeriesManager.self) private var seriesManager
    /// Reflects ACTUAL scheduled status (set from pending notifications on open),
    /// not the stored intent — so an unscheduled show shows OFF and a single tap
    /// turns it on (no double-tap).
    @State private var enabled = false
    @State private var settings = NotificationSettings()

    var body: some View {
        ZStack {
            // Blurred dimmed background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.80)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Centered card
            VStack(spacing: 0) {
                header

                // MASTER on/off — is this show registered for notifications?
                masterRow
                    .padding(.horizontal, 16)

                // Per-type options (only meaningful when the master is on)
                if enabled {
                    VStack(spacing: 8) {
                        NotificationOverlayRow(
                            title: String(localized: "notif_option_premiere"),
                            subtitle: String(localized: "notif_option_premiere_sub"),
                            isOn: $settings.seasonPremiere
                        )

                        NotificationOverlayFinaleRow(
                            isOn: $settings.finaleReminder,
                            timing: $settings.finaleTiming
                        )

                        NotificationOverlayRow(
                            title: String(localized: "notif_option_bingeready"),
                            subtitle: String(localized: "notif_option_bingeready_sub"),
                            isOn: $settings.bingeReady
                        )

                        NotificationOverlayRow(
                            title: String(localized: "notif_option_newseason"),
                            subtitle: String(localized: "notif_option_newseason_sub"),
                            isOn: $settings.newSeason
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Save button
                Button(action: saveSettings) {
                    Text("button_save")
                        .font(.custom(.oswald.bold, size: 15))
                        .tracking(0.45)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color(hex: "#18181b"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.2), value: enabled)
        }
        .task {
            settings = series.notificationSettings
            // Real status: is this show currently scheduled?
            let scheduled = await NotificationService.shared.scheduledIdentifiers(for: series.id)
            enabled = !scheduled.isEmpty
            logNotif("👁 modal \(series.name): \(scheduled.count) scheduled → toggle \(enabled ? "ON" : "OFF")")
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .top) {
            Text(String(format: NSLocalizedString("notif_show_settings_title %@", comment: ""), series.name))
                .font(.custom(.oswald.bold, size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 44)

            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.c2bMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    // MARK: - Master row

    private var masterRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("notif_show_toggle_title")
                    .font(.custom(.oswald.bold, size: 16))
                    .tracking(0.32)
                    .foregroundColor(.white)

                Text(enabled
                     ? String(localized: "notif_show_toggle_on_sub")
                     : String(localized: "notif_show_toggle_off_sub"))
                    .font(.system(size: 12))
                    .foregroundColor(enabled ? .c2bMuted : .c2bTeal)
            }

            Spacer()

            Toggle("", isOn: $enabled)
                .labelsHidden()
                .tint(.c2bTeal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(enabled ? Color.c2bTeal.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func saveSettings() {
        // Turning the master on requires OS permission. If it hasn't been asked
        // yet, prompt now so the reschedule actually registers (otherwise it hits
        // the "not authorized" gate and silently does nothing).
        if enabled && !NotificationService.shared.isAuthorized {
            Task {
                _ = await NotificationService.shared.requestAuthorization()
                seriesManager.updateNotifications(enabled: enabled, settings: settings, for: series)
                onDismiss()
            }
        } else {
            seriesManager.updateNotifications(enabled: enabled, settings: settings, for: series)
            onDismiss()
        }
    }
}
