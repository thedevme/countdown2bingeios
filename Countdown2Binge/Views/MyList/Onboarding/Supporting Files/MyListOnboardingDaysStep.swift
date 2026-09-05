//
//  MyListOnboardingDaysStep.swift
//  Countdown2Binge
//
//  Q3 — "When do you watch?" Converts a session count into a calendar date.
//  Doesn't change layout — only whether the verdict/shelf can name a day at
//  all. Design ref: personalization-flow spec — day picker + three
//  shortcuts (Weekends only / Most nights / No set schedule).
//

import SwiftUI

struct MyListOnboardingDaysStep: View {
    /// Monday = 0 ... Sunday = 6, matching MyListVerdictEngine.
    @Binding var selectedDays: Set<Int>
    let preview: MyListOnboardingPreviewState
    let onContinue: () -> Void
    let onSkip: () -> Void

    private let dayInitials = ["M", "T", "W", "T", "F", "S", "S"]
    private static let weekend: Set<Int> = [4, 5, 6]        // Fri, Sat, Sun
    private static let mostNights: Set<Int> = [6, 0, 1, 2, 3] // Sun–Thu

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text("When do you ")
                + Text("watch?").foregroundColor(.c2bTealBright))
                .font(.custom(.oswald.medium, size: 25))
                .foregroundColor(.c2bText)
                .lineSpacing(3)
                .padding(.bottom, 8)

            Text("Pick your nights and we can name the day you'll finish. Leave it open and we'll give you a rough duration instead.")
                .font(.system(size: 12.5))
                .foregroundColor(.c2bMuted)
                .lineSpacing(3)
                .padding(.bottom, 18)

            dayPicker
                .padding(.bottom, 12)

            shortcuts

            Spacer(minLength: 24)

            MyListOnboardingPreviewCard(state: preview)
                .padding(.bottom, 14)

            MyListOnboardingCTA(label: "See my list", onTap: onContinue)
            MyListOnboardingSkip(onTap: onSkip)
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { day in
                let isOn = selectedDays.contains(day)
                Button {
                    if isOn { selectedDays.remove(day) } else { selectedDays.insert(day) }
                } label: {
                    Text(dayInitials[day])
                        .font(.custom(.jetbrains.bold, size: 10))
                        .foregroundColor(isOn ? .c2bOnTeal : .c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isOn ? Color.c2bTeal : Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isOn ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var shortcuts: some View {
        HStack(spacing: 6) {
            shortcutButton("Weekends only", isOn: selectedDays == Self.weekend) {
                selectedDays = Self.weekend
            }
            shortcutButton("Most nights", isOn: selectedDays == Self.mostNights) {
                selectedDays = Self.mostNights
            }
            shortcutButton("No set schedule", isOn: selectedDays.isEmpty) {
                selectedDays = []
            }
        }
    }

    private func shortcutButton(_ title: String, isOn: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title.uppercased())
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(0.6)
                .foregroundColor(isOn ? .c2bTealBright : .c2bMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isOn ? Color.c2bTealSoft : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOn ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        MyListOnboardingDaysStep(
            selectedDays: .constant([4, 5, 6]),
            preview: MyListOnboardingPreviewState.make(answers: .init(
                scope: .jumpAround, unit: .episodes, episodeBucket: .threeToFour,
                timeBucket: .oneHour, selectedDays: [4, 5, 6]
            )),
            onContinue: {}, onSkip: {}
        )
        .padding(22)
    }
    .background(Color.c2bBackground)
}
