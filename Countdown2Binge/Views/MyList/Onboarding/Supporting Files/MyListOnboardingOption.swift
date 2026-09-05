//
//  MyListOnboardingOption.swift
//  Countdown2Binge
//
//  Reusable radio-style option row for the My List onboarding questions
//  (design ref: "My List Onboarding.html", `.opt`). Used as-is by Q1, and
//  with a follow-up control slotted in by Q2/Q3 — the design nests the
//  stepper/slider/day-picker INSIDE the chosen option, revealed only once
//  it's selected, so `followUp` is a ViewBuilder rather than a separate row.
//

import SwiftUI

struct MyListOnboardingOption<FollowUp: View>: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void
    /// Q1 has no follow-up at all — plain `EmptyView` would still show the
    /// divider line since that only checks `isSelected`, so this is set
    /// `false` by the `FollowUp == EmptyView` convenience init below.
    var hasFollowUp = true
    @ViewBuilder var followUp: () -> FollowUp

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    radio

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.custom(.oswald.medium, size: 14.5))
                            .foregroundColor(.c2bText)

                        Text(subtitle)
                            .font(.system(size: 11.5))
                            .foregroundColor(isSelected ? .c2bDim : .c2bMuted)
                    }

                    Spacer(minLength: 0)
                }

                if isSelected && hasFollowUp {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                        followUp()
                            .padding(.top, 11)
                    }
                    .padding(.top, 11)
                }
            }
            .padding(13)
            .background(isSelected ? Color.c2bTealSoft : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.c2bTeal : Color.white.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var radio: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.c2bTeal : Color.clear)
            if !isSelected {
                Circle()
                    .stroke(Color.white.opacity(0.24), lineWidth: 2)
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.c2bOnTeal)
            }
        }
        .frame(width: 19, height: 19)
        .padding(.top, 1)
    }
}

extension MyListOnboardingOption where FollowUp == EmptyView {
    init(title: String, subtitle: String, isSelected: Bool, onTap: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, isSelected: isSelected, onTap: onTap, hasFollowUp: false, followUp: { EmptyView() })
    }
}

#Preview {
    VStack(spacing: 8) {
        MyListOnboardingOption(
            title: "Straight through",
            subtitle: "I finish one show before starting another.",
            isSelected: false,
            onTap: {}
        )
        MyListOnboardingOption(
            title: "Jump around",
            subtitle: "I've got several going at once.",
            isSelected: true,
            onTap: {}
        )
    }
    .padding(20)
    .background(Color.c2bBackground)
}
