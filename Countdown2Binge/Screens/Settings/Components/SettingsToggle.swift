//
//  SettingsToggle.swift
//  Countdown2Binge
//
//  Custom toggle switch for settings rows.
//

import SwiftUI

struct SettingsToggle: View {
    @Binding var isOn: Bool
    var disabled: Bool = false

    var body: some View {
        Button(action: {
            if !disabled {
                isOn.toggle()
            }
        }) {
            RoundedRectangle(cornerRadius: 999)
                .fill(isOn ? Color.c2bTeal : Color.white.opacity(0.14))
                .frame(width: 46, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn ? 9 : -9)
                        .animation(.easeInOut(duration: 0.2), value: isOn)
                )
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
    }
}
