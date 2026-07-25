//
//  BingeClock.swift
//  Countdown2Binge
//
//  Countdown timer showing days, hours, minutes, seconds until finale.
//

import SwiftUI

struct BingeClock: View {
    let days: Int

    @State private var hours: Int = 7
    @State private var minutes: Int = 32
    @State private var seconds: Int = 36
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Text("timeline_countdown_finale")
                    .font(.custom(.oswald.bold, size: 17))
                    .tracking(0.68)
                    .foregroundColor(.white)

                Circle()
                    .stroke(Color.c2bMuted, lineWidth: 1)
                    .frame(width: 15, height: 15)
                    .overlay(
                        Text("i")
                            .font(.custom(.jetbrains.regular, size: 9))
                            .foregroundColor(.c2bMuted)
                    )
            }

            // Clock cells
            HStack(spacing: 6) {
                ClockCell(value: "\(days)", label: String(localized: "time_days"))
                ClockSeparator()
                ClockCell(value: String(format: "%02d", hours), label: String(localized: "time_hours"))
                ClockSeparator()
                ClockCell(value: String(format: "%02d", minutes), label: String(localized: "time_minutes"))
                ClockSeparator()
                ClockCell(value: String(format: "%02d", seconds), label: String(localized: "time_seconds"))
            }
        }
        .padding(.top, 20)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            tick()
        }
    }

    private func tick() {
        seconds -= 1
        if seconds < 0 {
            seconds = 59
            minutes -= 1
        }
        if minutes < 0 {
            minutes = 59
            hours -= 1
        }
        if hours < 0 {
            hours = 23
        }
    }
}

// MARK: - Clock Cell

private struct ClockCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 7) {
            Text(value)
                .font(.custom(.oswald.bold, size: 40))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
                .cornerRadius(12)

            Text(label.uppercased())
                .font(.custom(.jetbrains.bold, size: 8.5))
                .tracking(1.19)
                .foregroundColor(.c2bMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Clock Separator

private struct ClockSeparator: View {
    var body: some View {
        Text(":")
            .font(.custom(.oswald.bold, size: 30))
            .foregroundColor(.c2bTeal)
            .padding(.horizontal, 2)
            .offset(y: -10)
    }
}
