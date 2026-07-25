//
//  NotificationPickers.swift
//  Countdown2Binge
//
//  Segmented pickers for notification settings.
//

import SwiftUI

// MARK: - Lead Time Picker (1D / 3D / 7D)
struct NotificationLeadPicker: View {
    @Binding var selectedDays: Int
    var disabled: Bool = false

    private let options = [1, 3, 7]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { days in
                Button(action: {
                    if !disabled {
                        selectedDays = days
                    }
                }) {
                    Text(String(localized: "time_days_short \(days)"))
                        .font(.custom(.jetbrains.bold, size: 10))
                        .tracking(0.6)
                        .foregroundColor(selectedDays == days ? Color(hex: "#04201c") : .c2bDim)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(selectedDays == days ? Color.c2bTeal : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(
                                    selectedDays == days ? Color.c2bTeal : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
        }
    }
}

// MARK: - Digest Picker (OFF / DAILY / WEEKLY)
struct NotificationDigestPicker: View {
    @Binding var selectedOption: String
    var disabled: Bool = false

    private let options = ["off", "daily", "weekly"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if !disabled {
                        selectedOption = option
                    }
                }) {
                    Text(option.uppercased())
                        .font(.custom(.jetbrains.bold, size: 9.5))
                        .tracking(0.6)
                        .foregroundColor(selectedOption == option ? Color(hex: "#04201c") : .c2bDim)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(selectedOption == option ? Color.c2bTeal : Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(
                                    selectedOption == option ? Color.c2bTeal : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(disabled)
            }
        }
    }
}

// MARK: - Premium Badge
struct SettingsPremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 7))
                .foregroundColor(.c2bTealBright)

            Text("badge_premium")
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(0.8)
                .foregroundColor(.c2bTealBright)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(Color.c2bTeal.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
    }
}
