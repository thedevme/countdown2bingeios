//
//  MyLibraryStatusCard.swift
//  Countdown2Binge
//
//  Status card showing iCloud sync state (ON/OFF). Premium-only — the
//  screen doesn't render this at all for free users (see MyLibraryScreen).
//

import SwiftUI

struct MyLibraryStatusCard: View {
    let isPremium: Bool
    let syncedCount: Int

    private var isOn: Bool { isPremium }

    var body: some View {
        HStack(spacing: 14) {
            // Cloud icon
            ZStack {
                Circle()
                    .fill(isOn ? Color.c2bTeal.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)

                Image(systemName: isOn ? "icloud.fill" : "icloud")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isOn ? .c2bTeal : .white.opacity(0.4))
            }

            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text(isOn ? "ICLOUD IS ON" : "ICLOUD IS OFF")
                    .font(.custom(.oswald.bold, size: 15))
                    .foregroundColor(.white)
                    .tracking(0.5)

                Text(isOn ? subtitleOn : subtitleOff)
                    .font(.custom(.jetbrains.regular, size: 9))
                    .foregroundColor(.c2bTeal)
                    .tracking(0.5)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isOn ? Color.c2bTeal.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var subtitleOn: String {
        "\(syncedCount) SHOWS • EVERY SEASON & EPISODE"
    }

    private var subtitleOff: String {
        "PREMIUM REQUIRED • NOTHING BACKED UP"
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            MyLibraryStatusCard(isPremium: true, syncedCount: 14)
            MyLibraryStatusCard(isPremium: false, syncedCount: 0)
        }
        .padding()
    }
}
