//
//  FollowConfirmationSheet.swift
//  Countdown2Binge
//
//  Modal shown after following a show with notification settings.
//

import SwiftUI

struct FollowConfirmationSheet: View {
    let show: ShowData
    let onSave: () -> Void
    let onSkip: () -> Void

    @StateObject private var settingsStore = NotificationSettingsStore.shared
    @State private var settings: ShowNotificationSettings
    @State private var useAsDefault = false

    private var statusBadge: (text: String, color: Color) {
        switch show.timelineCategory {
        case .bingeReady:
            return (String(localized: "badge_binge_ready"), .c2bTealBright)
        case .airingNow:
            return (String(localized: "badge_airing"), .c2bTeal)
        case .premieringSoon:
            return (String(localized: "badge_premiering"), .c2bTeal)
        case .anticipated:
            return ("TBD", .c2bMuted)
        }
    }

    private var scheduledText: String {
        let count = [settings.seasonPremiere, settings.newEpisodes, settings.finaleReminder].filter { $0 }.count
        if count == 0 {
            return String(localized: "notif_none_scheduled")
        }
        return String(localized: "notif_count_scheduled \(count)")
    }

    init(show: ShowData, onSave: @escaping () -> Void, onSkip: @escaping () -> Void = {}) {
        self.show = show
        self.onSave = onSave
        self.onSkip = onSkip
        // Initialize with global defaults
        self._settings = State(initialValue: NotificationSettingsStore.shared.defaults)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    // Show Header
                    FollowNotificationHeader(
                        show: show,
                        badge: statusBadge,
                        scheduledText: scheduledText
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Notification Options
                    VStack(spacing: 10) {
                        // Season Premiere
                        NotificationOptionRow(
                            title: String(localized: "notif_option_premiere"),
                            subtitle: String(localized: "notif_option_premiere_sub"),
                            isOn: $settings.seasonPremiere
                        )

                        // New Episodes
                        NotificationOptionRow(
                            title: String(localized: "notif_option_episodes"),
                            subtitle: String(localized: "notif_option_episodes_sub"),
                            isOn: $settings.newEpisodes
                        )

                        // Finale Reminder
                        NotificationFinaleRow(
                            isOn: $settings.finaleReminder,
                            timing: $settings.finaleTiming
                        )
                    }
                    .padding(.horizontal, 20)

                    // Use as Default
                    Button(action: { useAsDefault.toggle() }) {
                        HStack(spacing: 12) {
                            Image(systemName: useAsDefault ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18))
                                .foregroundColor(useAsDefault ? .c2bTeal : .c2bMuted)

                            Text("notif_use_as_default")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            // Fixed bottom buttons
            VStack(spacing: 0) {
                // Save Button
                Button(action: saveNotifications) {
                    HStack(spacing: 10) {
                        Text("notif_save_button")
                            .font(.custom(.oswald.bold, size: 16))
                            .tracking(0.48)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "#04201c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.c2bTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Not Now
                Button(action: onSkip) {
                    Text("notif_not_now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.c2bMuted)
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(Color(hex: "#0e0e0f"))
        .presentationDetents([.height(580), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .presentationBackground(Color(hex: "#0e0e0f"))
    }

    private func saveNotifications() {
        // Save settings for this show
        settingsStore.saveSettings(settings, for: show.id)

        // Update defaults if checkbox is checked
        if useAsDefault {
            settingsStore.setAsDefault(settings)
        }

        // Schedule actual notifications
        Task {
            await NotificationService.shared.scheduleNotifications(for: show, settings: settings)
        }

        onSave()
    }
}

// MARK: - Show Header

private struct FollowNotificationHeader: View {
    let show: ShowData
    let badge: (text: String, color: Color)
    let scheduledText: String

    var body: some View {
        HStack(spacing: 14) {
            // Poster
            CachedAsyncImage(url: show.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.c2bSurface)
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(show.name.uppercased())
                    .font(.custom(.oswald.bold, size: 20))
                    .foregroundColor(.white)
                    .lineLimit(2)

                // Badge
                Text(badge.text)
                    .font(.custom(.jetbrains.bold, size: 9))
                    .tracking(0.9)
                    .foregroundColor(badge.color == .c2bMuted ? .white.opacity(0.7) : Color(hex: "#04201c"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badge.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Scheduled count
                Text(scheduledText)
                    .font(.system(size: 12))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()
        }
    }
}

// MARK: - Notification Option Row

private struct NotificationOptionRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(.oswald.bold, size: 15))
                    .tracking(0.3)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.c2bTeal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Finale Reminder Row

private struct NotificationFinaleRow: View {
    @Binding var isOn: Bool
    @Binding var timing: FinaleReminderTiming

    var body: some View {
        VStack(spacing: 14) {
            // Header row with toggle
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("notif_option_finale")
                        .font(.custom(.oswald.bold, size: 15))
                        .tracking(0.3)
                        .foregroundColor(.white)

                    Text("notif_option_finale_sub")
                        .font(.system(size: 11.5))
                        .foregroundColor(.c2bMuted)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.c2bTeal)
            }

            // Timing picker (2x2 grid)
            if isOn {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(FinaleReminderTiming.allCases, id: \.self) { option in
                        FinaleTimingButton(
                            timing: option,
                            isSelected: timing == option,
                            onTap: { timing = option }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Finale Timing Button

private struct FinaleTimingButton: View {
    let timing: FinaleReminderTiming
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(timing.shortText)
                .font(.custom(.jetbrains.bold, size: 10))
                .tracking(0.5)
                .foregroundColor(isSelected ? Color(hex: "#04201c") : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.c2bTeal : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}
