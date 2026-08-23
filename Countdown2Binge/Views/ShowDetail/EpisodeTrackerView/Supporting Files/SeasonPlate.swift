//
//  SeasonPlate.swift
//  Countdown2Binge
//
//  Molecule — the 74pt plate that heads a season card: a big outlined season
//  numeral on the left, season name + watch rollup on the right.
//  Ported from c2b-timeline.jsx `EpisodeTracker`'s "season plate".
//
//  Renders bare — the surrounding SeasonAccordionRow owns the card's surface,
//  corner radius and border.
//
//  The numeral is stroke-only (the prototype's `-webkit-text-stroke`), which
//  SwiftUI's Text can't do — hence the small TextKit-backed helper below.
//

import SwiftUI
import UIKit

struct SeasonPlate: View {
    let seasonNumber: Int
    let watchedCount: Int
    let totalEpisodes: Int
    /// All released episodes are watched — plate goes bright.
    let isComplete: Bool
    /// The season the show is on right now — gets the CURRENT marker.
    var isCurrent: Bool = false

    /// S1, S2, S13 — not zero-padded.
    private var numeral: String {
        String(localized: "season_abbrev") + "\(seasonNumber)"
    }

    private var subtitle: String {
        isComplete
            ? String(localized: "binge_status_complete")
            : String(localized: "binge_watched_count \(watchedCount) \(totalEpisodes)")
    }

    var body: some View {
        HStack(spacing: 8) {
            StrokedText(
                numeral,
                fontName: CustomFont.oswaldBold.rawValue,
                fontSize: 56,
                strokeColor: UIColor(isComplete ? Color.c2bTealBright.opacity(0.8)
                                                : Color.c2bTeal.opacity(0.55)),
                strokeWidth: 1.6
            )
            .padding(.leading, 12)
            // minWidth, not a fixed width: keeps single-digit seasons aligned
            // across cards while letting S10+ grow instead of clipping.
            .frame(minWidth: 74, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(String(localized: "season_number \(seasonNumber)"))
                        .font(.custom(.oswald.bold, size: 17))
                        .tracking(0.85)
                        .foregroundColor(isComplete ? .c2bTealBright : .c2bText)

                    if isCurrent {
                        Text(String(localized: "detail_current"))
                            .font(.custom(.jetbrains.regular, size: 7.5))
                            .tracking(0.9)
                            .textCase(.uppercase)
                            .foregroundColor(.c2bTealBright)
                    }
                }

                Text(subtitle)
                    .font(.custom(.jetbrains.regular, size: 8.5))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(.c2bDim)
            }

            Spacer(minLength: 0)
        }
        .padding(.trailing, 16)
        .frame(height: 74)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stroke-only text

/// Outline-only text. `NSAttributedString.strokeWidth` renders unfilled glyphs
/// when positive — the AppKit/UIKit equivalent of `-webkit-text-stroke`.
/// `strokeWidth` here is in points and converted to the percentage-of-font-size
/// value the attribute expects.
private struct StrokedText: UIViewRepresentable {
    let text: String
    let fontName: String
    let fontSize: CGFloat
    let strokeColor: UIColor
    let strokeWidth: CGFloat

    init(
        _ text: String,
        fontName: String,
        fontSize: CGFloat,
        strokeColor: UIColor,
        strokeWidth: CGFloat
    ) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let font = UIFont(name: fontName, size: fontSize)
            ?? .systemFont(ofSize: fontSize, weight: .bold)

        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .strokeColor: strokeColor,
                // Positive => stroke without fill, as a % of the font size.
                .strokeWidth: (strokeWidth / fontSize) * 100,
                .foregroundColor: UIColor.clear
            ]
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        uiView.intrinsicContentSize
    }
}

#Preview {
    VStack(spacing: 14) {
        SeasonPlate(seasonNumber: 13, watchedCount: 0, totalEpisodes: 10, isComplete: false)
        SeasonPlate(seasonNumber: 7, watchedCount: 10, totalEpisodes: 10, isComplete: true)
        SeasonPlate(seasonNumber: 2, watchedCount: 4, totalEpisodes: 8, isComplete: false)
    }
    .padding()
    .background(Color.c2bBackground)
}
