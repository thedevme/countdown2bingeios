//
//  DetailStatusBlock.swift
//  Countdown2Binge
//

import SwiftUI

struct DetailStatusBlock: View {
    let show: ShowData

    private var isReady: Bool {
        show.timelineCategory == .bingeReady
    }

    private var statusBig: String {
        if isReady {
            return "NOW"
        } else if let days = show.daysUntilFinale ?? show.daysUntilPremiere {
            return "\(days)"
        } else {
            return "TBD"
        }
    }

    private var phaseTone: Color {
        switch show.timelineCategory {
        case .airingNow: return .c2bTeal
        case .premieringSoon: return .c2bTeal.opacity(0.7)
        case .anticipated: return .c2bMuted
        case .bingeReady: return .c2bTealBright
        }
    }

    private var phaseLabel: String {
        switch show.timelineCategory {
        case .airingNow: return String(localized: "phase_now_airing")
        case .premieringSoon: return String(localized: "phase_premiering_soon")
        case .anticipated: return String(localized: "phase_anticipated")
        case .bingeReady: return String(localized: "phase_binge_ready")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 18) {
                DetailBigNumber(
                    value: statusBig,
                    isReady: isReady
                )
                .frame(minWidth: 84)

                DetailStatusInfo(
                    show: show,
                    isReady: isReady,
                    phaseTone: phaseTone,
                    phaseLabel: phaseLabel
                )

                Spacer()
            }
            .padding(20)

            DetailLifecycleMeter(category: show.timelineCategory)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.2))
        }
        .background(
            isReady
                ? LinearGradient(colors: [Color.c2bTeal.opacity(0.16), Color.c2bTeal.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.white.opacity(0.03), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isReady ? Color.c2bTealLine : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
