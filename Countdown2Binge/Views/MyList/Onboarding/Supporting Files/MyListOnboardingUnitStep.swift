//
//  MyListOnboardingUnitStep.swift
//  Countdown2Binge
//
//  Q2 — "How do you measure a session?" Sets the unit every verdict is
//  spoken in, and the session size the shelf math divides remaining time
//  by. Doesn't change layout — only the verdict/pace sentence in whichever
//  preview mode Q1 picked. `MyListSessionUnit`/`MyListEpisodeBucket`/
//  `MyListTimeBucket` live in MyListVerdictEngine.swift.
//

import SwiftUI

private extension MyListSessionUnit {
    var title: String {
        switch self {
        case .episodes: return "Episodes"
        case .time: return "Time"
        case .depends: return "Depends on the night"
        }
    }

    var subtitle: String {
        switch self {
        case .episodes: return "I think in episodes per night."
        case .time: return "I think in hours."
        case .depends: return "Varies night to night."
        }
    }
}

struct MyListOnboardingUnitStep: View {
    @Binding var unit: MyListSessionUnit
    @Binding var episodeBucket: MyListEpisodeBucket
    @Binding var timeBucket: MyListTimeBucket
    let preview: MyListOnboardingPreviewState
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text("How do you measure ")
                + Text("a session?").foregroundColor(.c2bTealBright))
                .font(.custom(.oswald.medium, size: 25))
                .foregroundColor(.c2bText)
                .lineSpacing(3)
                .padding(.bottom, 8)

            Text("Every verdict is spoken in this unit. Pick a number and we can be exact; leave it vague and we'll give you a range.")
                .font(.system(size: 12.5))
                .foregroundColor(.c2bMuted)
                .lineSpacing(3)
                .padding(.bottom, 18)

            VStack(spacing: 8) {
                ForEach(MyListSessionUnit.allCases) { option in
                    MyListOnboardingOption(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: unit == option,
                        onTap: { unit = option }
                    ) {
                        followUp(for: option)
                    }
                }
            }

            Spacer(minLength: 24)

            MyListOnboardingPreviewCard(state: preview)
                .padding(.bottom, 14)

            MyListOnboardingCTA(label: "Continue", onTap: onContinue)
            MyListOnboardingSkip(onTap: onSkip)
        }
    }

    @ViewBuilder
    private func followUp(for option: MyListSessionUnit) -> some View {
        switch option {
        case .episodes:
            bucketRow(MyListEpisodeBucket.allCases, selection: $episodeBucket) { $0.label }
        case .time:
            bucketRow(MyListTimeBucket.allCases, selection: $timeBucket) { $0.label }
        case .depends:
            EmptyView()
        }
    }

    /// The shared pill-row control for both bucket kinds — discrete choices,
    /// not a stepper/slider, per spec.
    private func bucketRow<Bucket: Hashable & CaseIterable>(
        _ buckets: [Bucket], selection: Binding<Bucket>, label: @escaping (Bucket) -> String
    ) -> some View where Bucket.AllCases: RandomAccessCollection {
        HStack(spacing: 6) {
            ForEach(Array(buckets), id: \.self) { bucket in
                let isOn = selection.wrappedValue == bucket
                Button {
                    selection.wrappedValue = bucket
                } label: {
                    Text(label(bucket).uppercased())
                        .font(.custom(.jetbrains.bold, size: 10))
                        .foregroundColor(isOn ? .c2bOnTeal : .c2bMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isOn ? Color.c2bTeal : Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(isOn ? Color.clear : Color.white.opacity(0.14), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ScrollView {
        MyListOnboardingUnitStep(
            unit: .constant(.episodes),
            episodeBucket: .constant(.threeToFour),
            timeBucket: .constant(.oneHour),
            preview: MyListOnboardingPreviewState.make(answers: .defaults),
            onContinue: {}, onSkip: {}
        )
        .padding(22)
    }
    .background(Color.c2bBackground)
}
