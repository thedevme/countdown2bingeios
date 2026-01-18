//
//  NotificationSettingsView.swift
//  Countdown2Binge
//

import SwiftUI

/// View for configuring notification settings (for a show or global defaults)
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    /// The show being followed (nil for global settings)
    let show: Show?

    /// Whether this is for global defaults
    let isGlobalDefaults: Bool

    /// Binding to the notification settings
    @Binding var settings: NotificationSettings

    /// Callback when saving
    var onSave: (() -> Void)?

    /// Callback when dismissing without saving
    var onSkip: (() -> Void)?

    // Local state for time pickers
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false

    /// Whether to save these settings as defaults for all future shows
    @State private var saveAsDefault = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header (only for show-specific)
                        if let show = show {
                            showHeader(show)
                        } else {
                            globalHeader
                        }

                        // Notification options
                        VStack(spacing: 12) {
                            // Season Premiere
                            NotificationToggleCard(
                                title: "SEASON PREMIERE",
                                subtitle: "NOTIFY WHEN THE HUNT BEGINS",
                                isOn: $settings.seasonPremiere
                            )

                            // New Episodes
                            NotificationToggleCard(
                                title: "NEW EPISODES",
                                subtitle: "REAL-TIME DROP ALERTS",
                                isOn: $settings.newEpisodes
                            )

                            // Finale Reminder with timing options
                            NotificationExpandableCard(
                                title: "FINALE REMINDER",
                                subtitle: "BEFORE THE FINAL CURTAIN",
                                isOn: $settings.finaleReminder,
                                selectedTiming: $settings.finaleReminderTiming
                            )

                            // Season Binge-Ready
                            NotificationToggleCard(
                                title: "SEASON BINGE-READY",
                                subtitle: "WHEN ALL EPISODES ARE LIVE",
                                isOn: $settings.seasonBingeReady
                            )

                            // Quiet Hours
                            NotificationQuietHoursCard(
                                isOn: $settings.quietHoursEnabled,
                                startTime: $settings.quietHoursStartDate,
                                endTime: $settings.quietHoursEndDate,
                                isGlobal: isGlobalDefaults
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

                // Bottom buttons
                bottomButtons
            }
        }
    }

    // MARK: - Show Header

    private func showHeader(_ show: Show) -> some View {
        VStack(spacing: 16) {
            Text("YOU ARE NOW FOLLOWING:")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 16) {
                // Poster
                if let posterPath = show.posterPath,
                   let url = TMDBConfiguration.imageURL(path: posterPath, size: .posterSmall) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        }
                    }
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(show.name.uppercased())
                        .font(.system(size: 24, weight: .black, design: .default).width(.condensed))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    // Status badge
                    statusBadge(for: show)

                    // Countdown text
                    countdownText(for: show)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    private func statusBadge(for show: Show) -> some View {
        let (text, color) = statusInfo(for: show)
        return Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }

    private func statusInfo(for show: Show) -> (String, Color) {
        if let season = show.currentSeason {
            if let days = season.daysUntilPremiere, days > 0 {
                return ("PREMIERING SOON", Color(red: 0.45, green: 0.9, blue: 0.7))
            } else if let days = season.daysUntilFinale, days > 0 {
                return ("ENDING SOON", Color(red: 0.9, green: 0.45, blue: 0.5))
            } else if season.isBingeReady {
                return ("BINGE READY", Color(red: 0.45, green: 0.9, blue: 0.7))
            }
        }
        return ("TBD", Color.white.opacity(0.3))
    }

    private func countdownText(for show: Show) -> some View {
        var text = "NO SCHEDULE YET"
        if let season = show.currentSeason {
            if let days = season.daysUntilPremiere, days > 0 {
                text = "PREMIERES IN \(days) \(days == 1 ? "WEEK" : "WEEKS")"
            } else if let days = season.daysUntilFinale, days > 0 {
                text = "FINALE IN \(days) DAYS"
            }
        }
        return Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(.white.opacity(0.5))
    }

    // MARK: - Global Header

    private var globalHeader: some View {
        VStack(spacing: 8) {
            Text("DEFAULT NOTIFICATIONS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            Text("Applied to all new shows")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 16) {
            // Save as default toggle (only for per-show settings)
            if !isGlobalDefaults {
                Button {
                    saveAsDefault.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: saveAsDefault ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundStyle(saveAsDefault ? Color(red: 0.45, green: 0.9, blue: 0.7) : .white.opacity(0.4))

                        Text("Use as default for all shows")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
            }

            Button {
                // If saving as default, update global settings
                if saveAsDefault {
                    let appSettings = AppSettings.shared
                    appSettings.globalNotificationDefaults = settings
                    appSettings.useGlobalNotificationDefaults = true
                }
                onSave?()
                dismiss()
            } label: {
                HStack {
                    Text("SAVE NOTIFICATIONS")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1.5)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.45, green: 0.9, blue: 0.7))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .padding(.horizontal, 20)

            if !isGlobalDefaults {
                Button {
                    onSkip?()
                    dismiss()
                } label: {
                    Text("NOT NOW")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [.black.opacity(0), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }
}

// MARK: - Notification Card Components

private struct NotificationToggleCard: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .default).width(.condensed))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color(red: 0.45, green: 0.9, blue: 0.7))
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct NotificationExpandableCard: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @Binding var selectedTiming: FinaleReminderTiming

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .default).width(.condensed))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .tint(Color(red: 0.45, green: 0.9, blue: 0.7))
                    .labelsHidden()
            }

            if isOn {
                // Timing options grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(FinaleReminderTiming.allCases, id: \.self) { timing in
                        TimingButton(
                            timing: timing,
                            isSelected: selectedTiming == timing
                        ) {
                            selectedTiming = timing
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

private struct TimingButton: View {
    let timing: FinaleReminderTiming
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(timing.label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color(red: 0.45, green: 0.9, blue: 0.7) : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct NotificationQuietHoursCard: View {
    @Binding var isOn: Bool
    @Binding var startTime: Date
    @Binding var endTime: Date
    let isGlobal: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isGlobal ? "QUIET HOURS" : "QUIET HOURS (THIS SHOW)")
                        .font(.system(size: 16, weight: .bold, design: .default).width(.condensed))
                        .foregroundStyle(.white)

                    Text("MUTE ALERTS DURING SPECIFIC TIMES")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .tint(Color(red: 0.45, green: 0.9, blue: 0.7))
                    .labelsHidden()
            }

            if isOn {
                VStack(spacing: 8) {
                    TimeRow(label: "START", time: $startTime)
                    TimeRow(label: "END", time: $endTime)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

private struct TimeRow: View {
    let label: String
    @Binding var time: Date

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))

            Spacer()

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(Color(red: 0.45, green: 0.9, blue: 0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview("Show Notification Settings") {
    NotificationSettingsView(
        show: nil,
        isGlobalDefaults: false,
        settings: .constant(.default)
    )
}

#Preview("Global Defaults") {
    NotificationSettingsView(
        show: nil,
        isGlobalDefaults: true,
        settings: .constant(.default)
    )
}
