//
//  MyListResultsShelfHeader.swift
//  Countdown2Binge
//
//  A section's header row: the 38×38 tier mark, an Anton label + why-line,
//  and an OUTLINED (stroke-only) count numeral — `.sechd .ct b` in the
//  design uses `-webkit-text-stroke`, the same treatment as season plates,
//  not a filled number. Design ref: "My List Cards.html" — `.sechd`.
//

import SwiftUI
import UIKit

extension MyListShelfTier {
    var tone: Color {
        switch self {
        case .oneSitting: return .c2bTealBright
        case .weekend: return Color(hex: "#A3D65C")
        case .month: return .c2bAmber
        case .commitment: return Color(hex: "#A78BFA")
        }
    }

    /// The section surface's own tinted background — `sec.wash` in the design.
    var wash: Color {
        switch self {
        case .oneSitting: return Color(hex: "#17181a")
        case .weekend: return Color(hex: "#141517")
        case .month: return Color(hex: "#111214")
        case .commitment: return Color(hex: "#0f1012")
        }
    }
}

/// Measures the title+why text block so the tier icon can be sized to match
/// it exactly, instead of a fixed 38pt guess.
private struct TextBlockHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 38
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MyListResultsShelfHeader: View {
    let tier: MyListShelfTier
    let count: Int
    /// Straight Through's "Next"/"Upcoming" get their own label/why text,
    /// their own dedicated icons (not the tier marks), and their own tones
    /// (`#86E7D5`/`#A38CF3` — not `tier.tone`) — set these to override
    /// `tier.label`/`tier.why`/`tier.assetName`/`tier.tone` for that case.
    var labelOverride: String? = nil
    var whyOverride: String? = nil
    var iconOverride: String? = nil
    var toneOverride: Color? = nil
    /// Present only for the editable "Upcoming" section in Straight
    /// Through — shows a reorder affordance. No-op target for now.
    var isEditable: Bool = false
    var onEdit: () -> Void = {}

    /// Icon side length — pinned to the title+why block's own measured
    /// height, so the mark always spans exactly from the top of the title
    /// to the bottom of the subtitle, whatever their content.
    @State private var textBlockHeight: CGFloat = 38

    private var effectiveTone: Color { toneOverride ?? tier.tone }

    var body: some View {
        HStack(spacing: 11) {
            // Both the tier badges and the Next/Upcoming marks (next_v1/
            // upcoming_v1) are full-color art, not tintable templates —
            // rendered as-is regardless of which one this section uses.
            Image(iconOverride ?? tier.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: textBlockHeight, height: textBlockHeight)

            VStack(alignment: .leading, spacing: 5) {
                Text(labelOverride ?? tier.label)
                    .font(.custom(.oswald.bold, size: 21))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundColor(effectiveTone)
                    .lineLimit(1)

                Text(whyOverride ?? tier.why)
                    .font(.system(size: 11.5))
                    .foregroundColor(.c2bDim)
                    .lineLimit(1)
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: TextBlockHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(TextBlockHeightKey.self) { textBlockHeight = $0 }

            Spacer(minLength: 8)

            VStack(spacing: 3) {
                StrokedText(
                    "\(count)",
                    fontName: CustomFont.oswaldBold.rawValue,
                    fontSize: 36,
                    strokeColor: UIColor(effectiveTone),
                    strokeWidth: 1.5
                )
                .frame(width: 42, height: 28)

                Text(count == 1 ? "SHOW" : "SHOWS")
                    .font(.custom(.jetbrains.bold, size: 7.5))
                    .tracking(1.4)
                    .foregroundColor(.c2bMuted)
            }

            if isEditable && count > 1 {
                Button(action: onEdit) {
                    // ml-upcoming — a template (single-color) reorder-list
                    // glyph, not the section badge. Tinted to match the title.
                    Image("ml-upcoming")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(effectiveTone)
                        .padding(7)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.white.opacity(0.13), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 13)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        ForEach(MyListShelfTier.allCases) { tier in
            MyListResultsShelfHeader(tier: tier, count: 3)
        }
    }
    .padding(20)
    .background(Color.c2bBackground)
}
