//
//  DetailNotifyToggle.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailNotifyToggle: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "bell")
                .font(.system(size: 19))
                .foregroundColor(isEnabled ? .c2bTealBright : .c2bMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text("notif_binge_ready_alert")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("notif_ping_when_out")
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bMuted)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .c2bTeal))
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
