//
//  SettingsRow.swift
//  Countdown2Binge
//
//  Row component for settings lists.
//

import SwiftUI

// MARK: - Settings Row with Chevron
struct SettingsRowChevron: View {
    var icon: String? = nil
    var iconColor: Color = Color(white: 0.81)
    let title: String
    var subtitle: String? = nil
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                if let icon = icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 30, height: 30)

                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11.5))
                            .foregroundColor(.c2bMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.c2bMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                VStack {
                    Spacer()
                    if !isLast {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row with Toggle
struct SettingsRowToggle: View {
    var icon: String? = nil
    var iconColor: Color = Color(white: 0.81)
    let title: String
    var subtitle: String? = nil
    var isLast: Bool = false
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 13) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.c2bMuted)
                }
            }

            Spacer()

            SettingsToggle(isOn: $isOn, disabled: disabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            VStack {
                Spacer()
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                }
            }
        )
    }
}

// MARK: - Settings Row Action (no chevron)
struct SettingsRowAction: View {
    var icon: String? = nil
    var iconColor: Color = Color(white: 0.81)
    let title: String
    var subtitle: String? = nil
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                if let icon = icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 30, height: 30)

                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11.5))
                            .foregroundColor(.c2bMuted)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                VStack {
                    Spacer()
                    if !isLast {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row Danger (Sign Out)
struct SettingsRowDanger: View {
    let title: String
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#ff6b6b"))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                VStack {
                    Spacer()
                    if !isLast {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row with Custom Right Content
struct SettingsRowCustom<RightContent: View>: View {
    var icon: String? = nil
    var iconColor: Color = Color(white: 0.81)
    let title: String
    var subtitle: String? = nil
    var isLast: Bool = false
    @ViewBuilder var rightContent: RightContent

    var body: some View {
        HStack(spacing: 13) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.c2bMuted)
                }
            }

            Spacer()

            rightContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            VStack {
                Spacer()
                if !isLast {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                }
            }
        )
    }
}
