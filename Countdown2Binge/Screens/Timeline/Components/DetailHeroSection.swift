//
//  DetailHeroSection.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailHeroSection: View {
    let show: ShowData
    let onDismiss: () -> Void
    var onShare: (() -> Void)? = nil
    var onUnfollow: (() -> Void)? = nil
    var isArchived: Bool = false
    var onArchive: (() -> Void)? = nil

    private var phaseInfo: (label: String, tone: Color) {
        switch show.timelineCategory {
        case .airingNow: return ("Now Airing", .c2bTeal)
        case .premieringSoon: return ("Premiering Soon", .c2bTeal.opacity(0.7))
        case .anticipated: return ("Anticipated", .c2bMuted)
        case .bingeReady: return ("Binge Ready", .c2bTealBright)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AsyncImage(url: show.backdropURL ?? show.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.width * 0.95)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(Color.c2bSurface)
                            .frame(width: geo.size.width, height: geo.size.width * 0.95)
                    }
                }

                LinearGradient(
                    colors: [.black.opacity(0.25), .clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                DetailTopBar(
                    onDismiss: onDismiss,
                    onShare: onShare,
                    show: show,
                    onUnfollow: onUnfollow,
                    isArchived: isArchived,
                    onArchive: onArchive
                )

                DetailTitleArea(
                    show: show,
                    phaseLabel: phaseInfo.label,
                    phaseTone: phaseInfo.tone
                )
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
    }
}
