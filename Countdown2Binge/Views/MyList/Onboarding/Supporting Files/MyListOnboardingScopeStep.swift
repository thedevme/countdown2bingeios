//
//  MyListOnboardingScopeStep.swift
//  Countdown2Binge
//
//  Q1 — "How do you usually watch?" The only question that changes the
//  screen's shape: straight through (one hero, whole-show clock) vs. jump
//  around (shelves, current-season clock). `MyListWatchScope` itself lives
//  in MyListVerdictEngine.swift — the engine and this UI share one
//  definition of what scope means.
//

import SwiftUI

extension MyListWatchScope {
    var title: String {
        switch self {
        case .straightThrough: return "Straight through"
        case .jumpAround: return "Jump around"
        }
    }

    var subtitle: String {
        switch self {
        case .straightThrough: return "One show at a time, finish it, move on."
        case .jumpAround: return "A few going at once, pick by mood."
        }
    }
}

struct MyListOnboardingScopeStep: View {
    @Binding var scope: MyListWatchScope
    let preview: MyListOnboardingPreviewState
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text("How do you ")
                + Text("usually watch?").foregroundColor(.c2bTealBright))
                .font(.custom(.oswald.medium, size: 25))
                .foregroundColor(.c2bText)
                .lineSpacing(3)
                .padding(.bottom, 8)

            Text("This is the only answer that changes the shape of the screen — one focused card, or everything grouped into shelves.")
                .font(.system(size: 12.5))
                .foregroundColor(.c2bMuted)
                .lineSpacing(3)
                .padding(.bottom, 18)

            VStack(spacing: 8) {
                ForEach(MyListWatchScope.allCases) { option in
                    MyListOnboardingOption(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: scope == option,
                        onTap: { scope = option }
                    )
                }
            }

            Spacer(minLength: 24)

            MyListOnboardingPreviewCard(state: preview)
                .padding(.bottom, 14)

            MyListOnboardingCTA(label: "Continue", onTap: onContinue)
            MyListOnboardingSkip(onTap: onSkip)
        }
    }
}

#Preview {
    ScrollView {
        MyListOnboardingScopeStep(
            scope: .constant(.jumpAround),
            preview: MyListOnboardingPreviewState.make(answers: .defaults),
            onContinue: {}, onSkip: {}
        )
        .padding(22)
    }
    .background(Color.c2bBackground)
}
