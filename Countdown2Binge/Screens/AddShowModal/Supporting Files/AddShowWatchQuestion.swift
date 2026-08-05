//
//  AddShowWatchQuestion.swift
//  Countdown2Binge
//
//  "Did you watch Season X?" question with radio button options.
//

import SwiftUI

enum WatchAnswer: String, CaseIterable {
    case finished
    case started
    case notWatched
}

struct AddShowWatchQuestion: View {
    let seasonNumber: Int
    @Binding var selectedAnswer: WatchAnswer?

    private var nextSeason: Int { seasonNumber + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.c2bTeal)

                Text("watch_question_title \(seasonNumber)")
                    .font(.custom(.jetbrains.bold, size: 11))
                    .tracking(1.1)
                    .foregroundColor(.c2bMuted)
            }

            // Radio options
            VStack(spacing: 10) {
                WatchOptionRow(
                    title: String(localized: "watch_option_finished \(seasonNumber)"),
                    subtitle: String(localized: "watch_option_finished_subtitle \(nextSeason)"),
                    isSelected: selectedAnswer == .finished,
                    onTap: { selectedAnswer = .finished }
                )

                WatchOptionRow(
                    title: String(localized: "watch_option_started \(seasonNumber)"),
                    subtitle: String(localized: "watch_option_started_subtitle \(seasonNumber)"),
                    isSelected: selectedAnswer == .started,
                    onTap: { selectedAnswer = .started }
                )

                WatchOptionRow(
                    title: String(localized: "watch_option_not_watched \(seasonNumber)"),
                    subtitle: String(localized: "watch_option_not_watched_subtitle \(nextSeason)"),
                    isSelected: selectedAnswer == .notWatched,
                    onTap: { selectedAnswer = .notWatched }
                )
            }
        }
    }
}

// MARK: - Radio Option Row

private struct WatchOptionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Radio circle
                Circle()
                    .stroke(isSelected ? Color.c2bTeal : Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.c2bTeal : Color.clear)
                            .frame(width: 12, height: 12)
                    )

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.c2bMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.c2bTeal.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var answer: WatchAnswer? = nil

        var body: some View {
            AddShowWatchQuestion(
                seasonNumber: 3,
                selectedAnswer: $answer
            )
            .padding(20)
            .background(Color.c2bBackground)
        }
    }

    return PreviewWrapper()
}
