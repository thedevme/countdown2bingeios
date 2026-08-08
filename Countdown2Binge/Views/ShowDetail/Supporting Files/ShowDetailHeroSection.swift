//
//  ShowDetailHeroSection.swift
//  Countdown2Binge
//
//  Hero section for show detail view with backdrop, navigation bar, network chip, and title.
//

import SwiftUI
import UIKit

extension UIScreen {
    /// Non-deprecated replacement for `UIScreen.main.bounds.width` (iOS 26):
    /// reads the active window scene's screen, with a sensible fallback.
    static var activeWidth: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 393
    }
}

struct ShowDetailHeroSection: View {
    let show: ShowData
    let isFollowing: Bool
    let onDismiss: () -> Void

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
                // Backdrop image
                BackdropView(
                    url: show.backdropURL ?? show.posterURL,
                    width: geo.size.width,
                    height: geo.size.width * 1.025
                )

                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.15), .clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Custom (smaller) back button only — the network chip now lives in
                // the nav bar toolbar, so pass networkName: nil here.
                ShowDetailTopBar(
                    isFollowing: isFollowing,
                    networkName: nil,
                    onDismiss: onDismiss
                )

                // Title area
                ShowDetailTitleArea(
                    show: show,
                    isFollowing: isFollowing,
                    phaseLabel: phaseInfo.label,
                    phaseTone: phaseInfo.tone
                )
            }
        }
        .frame(height: UIScreen.activeWidth * 1.025)
    }
}

// MARK: - Title Area
struct ShowDetailTitleArea: View {
    let show: ShowData
    let isFollowing: Bool
    let phaseLabel: String
    let phaseTone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Not tracking badge (only when not following)
            if !isFollowing {
                ShowDetailNotTrackingBadge()
                    .padding(.bottom, 10)
            }

            // Title
            Text(show.name.uppercased())
                .font(.custom(.oswald.bold, size: 32))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 2)

            // Metadata line
            Text("\(seasonLabel) · \(show.primaryNetwork?.name ?? "Unknown") · \(show.genres.first?.name ?? "")")
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
