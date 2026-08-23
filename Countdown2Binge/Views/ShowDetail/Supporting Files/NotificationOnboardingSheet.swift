//
//  NotificationOnboardingSheet.swift
//  Countdown2Binge
//
//  One-time notification setup shown after first follow.
//  User's choices become the default for all future follows.
//

import SwiftUI

struct NotificationOnboardingOverlay: View {
    let onSave: () -> Void

    @Environment(SeriesManager.self) private var seriesManager
    @StateObject private var settingsStore = NotificationSettingsStore.shared
    @State private var settings = NotificationSettings()

    var body: some View {
        ZStack {
            // Blurred dimmed background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.80)
                .ignoresSafeArea()
                .onTapGesture { } // Block taps

            // Centered card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.c2bTeal)

                    Text("notif_onboarding_title")
                        .font(.custom(.oswald.bold, size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("notif_onboarding_subtitle")
                        .font(.system(size: 13))
                        .foregroundColor(.c2bMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // Notification Options
                VStack(spacing: 8) {
                    // Season Premiere
                    NotificationOverlayRow(
                        title: String(localized: "notif_option_premiere"),
                        subtitle: String(localized: "notif_option_premiere_sub"),
                        isOn: $settings.seasonPremiere
                    )

                    // Finale Reminder
                    NotificationOverlayFinaleRow(
                        isOn: $settings.finaleReminder,
                        timing: $settings.finaleTiming
                    )

                    // Binge Ready
                    NotificationOverlayRow(
                        title: String(localized: "notif_option_bingeready"),
                        subtitle: String(localized: "notif_option_bingeready_sub"),
                        isOn: $settings.bingeReady
                    )

                    // New Season
                    NotificationOverlayRow(
                        title: String(localized: "notif_option_newseason"),
                        subtitle: String(localized: "notif_option_newseason_sub"),
                        isOn: $settings.newSeason
                    )
                }
                .padding(.horizontal, 16)

                // Save button
                Button {
                    Task { await saveDefaults() }
                } label: {
                    Text("notif_onboarding_save")
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
        }
    }

    private func saveDefaults() async {
        settingsStore.updateSettings(settings)
        settingsStore.markOnboardingComplete()

        // Ask the OS for notification permission now that the user has opted in.
        // Without this, `NotificationService.isAuthorized` stays false and every
        // scheduling attempt in SeriesManager silently bails.
        let granted = await NotificationService.shared.requestAuthorization()

        // The first followed show's scheduling task already ran (and bailed) before
        // authorization existed, so reschedule everything once permission is granted.
        if granted {
            seriesManager.rescheduleAllNotifications()
        }

        onSave()
    }
}

// MARK: - Settings Overlay (for editing existing global settings)

struct NotificationSettingsOverlay: View {
    let onDismiss: () -> Void

    @StateObject private var settingsStore = NotificationSettingsStore.shared
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
                // Header with close button
                ZStack {
                    Text("notif_settings_title")
                        .font(.custom(.oswald.bold, size: 20))
                        .foregroundColor(.white)

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

                // Notification Options
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
        }
        .onAppear {
            settings = settingsStore.settings
        }
    }

    private func saveSettings() {
        settingsStore.updateSettings(settings)
        onDismiss()
    }
}

// MARK: - Notification Row

struct NotificationOverlayRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom(.oswald.bold, size: 14))
                    .tracking(0.28)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.c2bTeal)
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Finale Row

struct NotificationOverlayFinaleRow: View {
    @Binding var isOn: Bool
    @Binding var timing: FinaleReminderTiming

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("notif_option_finale")
                        .font(.custom(.oswald.bold, size: 14))
                        .tracking(0.28)
                        .foregroundColor(.white)

                    Text("notif_option_finale_sub")
                        .font(.system(size: 10.5))
                        .foregroundColor(.c2bMuted)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.c2bTeal)
                    .scaleEffect(0.9)
            }

            if isOn {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(FinaleReminderTiming.allCases, id: \.self) { option in
                        Button {
                            timing = option
                        } label: {
                            Text(option.shortText)
                                .font(.custom(.jetbrains.bold, size: 9))
                                .tracking(0.45)
                                .foregroundColor(timing == option ? Color(hex: "#04201c") : .white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(timing == option ? Color.c2bTeal : Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(timing == option ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}
