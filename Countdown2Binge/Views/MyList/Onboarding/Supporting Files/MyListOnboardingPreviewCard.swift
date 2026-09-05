//
//  MyListOnboardingPreviewCard.swift
//  Countdown2Binge
//
//  "So this card now reads" — must visibly change on every tap (the flow's
//  core rule). Q1 swaps the whole layout between a mini hero and a mini
//  shelf row — the biggest visual change in the flow, per spec. Q2/Q3
//  rewrite the verdict/pace sentence within whichever layout is showing.
//

import SwiftUI

struct MyListOnboardingPreviewCard: View {
    let state: MyListOnboardingPreviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("SO THIS CARD NOW READS")
                .font(.custom(.jetbrains.bold, size: 8))
                .tracking(1.2)
                .foregroundColor(.c2bMuted)

            switch state.scope {
            case .straightThrough:
                heroMini
            case .jumpAround:
                shelfMini
            }
        }
        .padding(13)
        .background(Color.c2bTealWash)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
        // The mode swap is the biggest visual change in the flow — make it
        // read as one, not a cross-fade that could pass for a text change.
        .animation(.easeInOut(duration: 0.22), value: state.scope)
    }

    // MARK: - Straight Through: mini hero

    private var heroMini: some View {
        HStack(spacing: 11) {
            poster(width: 46, height: 66)

            VStack(alignment: .leading, spacing: 6) {
                Text(state.showTitle.uppercased())
                    .font(.custom(.oswald.bold, size: 14))
                    .foregroundColor(.c2bText)
                    .lineLimit(1)

                verdictCapsule

                Text(state.verdict.paceText + " · " + state.metaText)
                    .font(.system(size: 10))
                    .foregroundColor(.c2bMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(clockText)
                .font(.custom(.oswald.bold, size: 15))
                .foregroundColor(.c2bText)
        }
    }

    // MARK: - Jump Around: mini shelf row

    private var shelfMini: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(state.verdict.shelfTier.label)
                    .font(.custom(.oswald.bold, size: 11))
                    .foregroundColor(.c2bTealBright)

                Text("· \(state.verdict.rawHoursText)")
                    .font(.custom(.jetbrains.bold, size: 9))
                    .foregroundColor(.c2bMuted)

                if let suffix = state.verdict.shelfDateSuffix {
                    Text("· \(suffix)")
                        .font(.custom(.jetbrains.bold, size: 9))
                        .foregroundColor(.c2bTealBright)
                }
            }

            HStack(spacing: 11) {
                poster(width: 46, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.showTitle.uppercased())
                        .font(.custom(.oswald.bold, size: 13))
                        .foregroundColor(.c2bText)
                        .lineLimit(1)

                    verdictCapsule
                }

                Spacer(minLength: 8)

                Text(clockText)
                    .font(.custom(.oswald.bold, size: 14))
                    .foregroundColor(.c2bText)
            }

            Text(state.verdict.paceText + " · " + state.metaText)
                .font(.system(size: 10))
                .foregroundColor(.c2bMuted)
                .lineLimit(1)
        }
    }

    // MARK: - Shared pieces

    @ViewBuilder
    private func poster(width: CGFloat, height: CGFloat) -> some View {
        if let asset = state.posterAssetName {
            Image(asset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            LandscapeBackdrop(url: nil, seed: state.showTitle)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var verdictCapsule: some View {
        Text(state.verdict.verdictText)
            .font(.custom(.oswald.medium, size: 11))
            .foregroundColor(.c2bOnTeal)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.c2bTeal)
            .clipShape(Capsule())
    }

    private var clockText: String {
        let secs = state.scope == .straightThrough ? 227_520 : 21_420
        let h = secs / 3600
        let m = (secs % 3600) / 60
        return "\(h)h \(m)m"
    }
}

#Preview {
    VStack(spacing: 14) {
        MyListOnboardingPreviewCard(state: .make(answers: .init(
            scope: .straightThrough, unit: .episodes, episodeBucket: .fivePlus,
            timeBucket: .oneHour, selectedDays: [4, 5, 6]
        )))
        MyListOnboardingPreviewCard(state: .make(answers: .defaults))
    }
    .padding(20)
    .background(Color.c2bBackground)
}
