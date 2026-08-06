//
//  SettingsGroup.swift
//  Countdown2Binge
//
//  Container for grouping settings rows.
//

import SwiftUI

struct SettingsGroup<Content: View>: View {
    var label: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label = label {
                Text(label.uppercased())
                    .font(.custom(.jetbrains.regular, size: 9))
                    .tracking(1.44)
                    .foregroundColor(.c2bMuted)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 10)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.bottom, 22)
    }
}
