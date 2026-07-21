//
//  DetailTitleArea.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailTitleArea: View {
    let show: ShowData
    let phaseLabel: String
    let phaseTone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DetailPhaseLabel(label: phaseLabel, tone: phaseTone)

            Text(show.name.uppercased())
                .font(.custom(.oswald.bold, size: 32))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.top, 10)

            Text("\(seasonLabel) \u{00B7} \(show.primaryNetwork?.name ?? "Unknown") \u{00B7} \(show.genres.first?.name ?? "")")
                .font(.custom(.jetbrains.regular, size: 10))
                .foregroundColor(.c2bDim)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
    }

    private var seasonLabel: String {
        "Season \(show.numberOfSeasons)"
    }
}
