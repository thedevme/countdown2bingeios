//
//  DetailPrimaryButton.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailPrimaryButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    var icon: String? = nil
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(style == .primary ? Color(hex: "#04201c") : .c2bTealBright)
                }
                Text(title)
                    .font(.custom(.oswald.bold, size: style == .primary && icon == nil ? 16 : 15))
                    .foregroundColor(style == .primary ? Color(hex: "#04201c") : .white)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, style == .primary && icon == nil ? 16 : 15)
            .background(style == .primary ? Color.c2bTeal : Color.white.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .secondary ? Color.white.opacity(0.14) : Color.clear, lineWidth: 1)
            )
        }
    }
}
