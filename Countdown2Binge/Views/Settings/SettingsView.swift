//
//  SettingsView.swift
//  Countdown2Binge
//

import SwiftUI

/// Settings page for app preferences
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = AppSettings.shared

    @State private var showNotificationSettings = false
    @State private var notificationSettings: NotificationSettings = .default

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                List {
                    // MARK: - App Settings Section
                    Section {
                        // Sound toggle
                        SettingsToggleRow(
                            icon: "music.note",
                            title: "Sound",
                            isOn: $settings.soundEnabled
                        )

                        // Haptics toggle
                        SettingsToggleRow(
                            icon: "waveform",
                            title: "Haptics",
                            isOn: $settings.hapticsEnabled
                        )

                        // Reminders (global notification defaults)
                        Button {
                            notificationSettings = settings.globalNotificationDefaults
                            showNotificationSettings = true
                        } label: {
                            Label {
                                Text("Reminders")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            } icon: {
                                SettingsIconBadge(icon: "bell.fill")
                            }
                            .badge(
                                Text("\(Image(systemName: "chevron.right"))")
                                    .foregroundStyle(settingsTeal)
                                    .fontWeight(.bold)
                            )
                        }
                        .buttonStyle(.plain)

                        // Widget guide
                        SettingsChevronDownRow(
                            icon: "square.text.square",
                            title: "Widget guide"
                        )

                        // Unlock all features
                        SettingsChevronDownRow(
                            icon: "heart.fill",
                            title: "Unlock all features"
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.08))

                    // MARK: - Get in Touch Section
                    Section {
                        Link(destination: URL(string: "mailto:support@countdown2binge.com")!) {
                            SettingsLinkRowContent(
                                icon: "paperplane.fill",
                                title: "Email"
                            )
                        }

                        Link(destination: URL(string: "https://twitter.com/thedevme")!) {
                            SettingsLinkRowContent(
                                icon: "bubble.right.fill",
                                title: "Twitter"
                            )
                        }

                        Link(destination: URL(string: "https://apps.apple.com/app/id123456789?action=write-review")!) {
                            SettingsLinkRowContent(
                                icon: "star.fill",
                                title: "Rate in App Store"
                            )
                        }
                    } header: {
                        Text("Get in touch")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(nil)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.08))

                    // MARK: - Other Stuff Section
                    Section {
                        SettingsChevronRow(
                            icon: "person.2.fill",
                            title: "Credits"
                        )

                        Link(destination: URL(string: "https://designtoswiftui.com/privacy")!) {
                            SettingsLinkRowContent(
                                icon: "doc.plaintext.fill",
                                title: "Privacy policy"
                            )
                        }

                        Link(destination: URL(string: "https://designtoswiftui.com/terms")!) {
                            SettingsLinkRowContent(
                                icon: "doc.text.magnifyingglass",
                                title: "Terms of use"
                            )
                        }

                        Link(destination: URL(string: "https://www.themoviedb.org")!) {
                            SettingsLinkRowContent(
                                icon: "powerplug.fill",
                                title: "API provided by themoviedb.org"
                            )
                        }
                    } header: {
                        Text("Other stuff")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(nil)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Color.white.opacity(0.08))
                }
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView(
                show: nil,
                isGlobalDefaults: true,
                settings: $notificationSettings,
                onSave: {
                    settings.globalNotificationDefaults = notificationSettings
                    settings.useGlobalNotificationDefaults = true
                }
            )
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Title
            VStack(spacing: 6) {
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Rectangle()
                    .fill(settingsTeal)
                    .frame(width: 60, height: 2)
                    .clipShape(Capsule())
            }

            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Settings Row Components

private let settingsTeal = Color(red: 0x2B/255, green: 0xAF/255, blue: 0xA9/255)

private struct SettingsIconBadge: View {
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(settingsTeal.opacity(0.25))
                .frame(width: 34, height: 34)

            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(settingsTeal)
        }
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            } icon: {
                SettingsIconBadge(icon: icon)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(settingsTeal)
                .labelsHidden()
        }
    }
}

private struct SettingsChevronRow: View {
    let icon: String
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        } icon: {
            SettingsIconBadge(icon: icon)
        }
        .badge(
            Text("\(Image(systemName: "chevron.right"))")
                .foregroundStyle(settingsTeal)
                .fontWeight(.bold)
        )
    }
}

private struct SettingsChevronDownRow: View {
    let icon: String
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        } icon: {
            SettingsIconBadge(icon: icon)
        }
        .badge(
            Text("\(Image(systemName: "chevron.down"))")
                .foregroundStyle(settingsTeal)
                .fontWeight(.bold)
        )
    }
}

private struct SettingsLinkRowContent: View {
    let icon: String
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        } icon: {
            SettingsIconBadge(icon: icon)
        }
        .badge(
            Text("\(Image(systemName: "arrow.up.right"))")
                .foregroundStyle(settingsTeal)
                .fontWeight(.bold)
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
