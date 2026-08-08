//
//  DetailHeroSection.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailHeroSection: View {
    let show: ShowData

    private var phaseInfo: (label: String, tone: Color) {
        switch show.showState {
        case .airing, .pending: return ("Now Airing", .c2bTeal)
        case .premieringSoon: return ("Premiering Soon", .c2bTeal.opacity(0.7))
        case .anticipated: return ("Anticipated", .c2bMuted)
        case .bingeReady: return ("Binge Ready", .c2bTealBright)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                BackdropView(
                    url: show.backdropURL ?? show.posterURL,
                    width: geo.size.width,
                    height: geo.size.width * 0.95
                )

                LinearGradient(
                    colors: [.black.opacity(0.25), .clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                DetailTitleArea(
                    show: show,
                    phaseLabel: phaseInfo.label,
                    phaseTone: phaseInfo.tone
                )
            }
        }
        .frame(height: UIScreen.activeWidth * 0.95)
    }
}
