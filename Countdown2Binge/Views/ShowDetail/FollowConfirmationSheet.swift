//
//  FollowConfirmationSheet.swift
//  Countdown2Binge
//
//  Modal shown after following a show with timeline placement info.
//

import SwiftUI

struct FollowConfirmationSheet: View {
    let show: ShowData
    let onSave: () -> Void

    private var phaseInfo: FollowPhaseInfo {
        switch show.showState {
        case .bingeReady:
            return FollowPhaseInfo(
                key: "ready",
                badge: String(localized: "phase_series_complete"),
                tone: Color.c2bTealBright,
                stat: String(localized: "phase_stat_now"),
                statUnit: String(localized: "phase_binge_ready"),
                line: String(localized: "phase_ready_description \(show.currentSeason?.episodeCount ?? show.numberOfEpisodes)")
            )
        case .airing:
            let days = show.daysUntilFinale ?? 0
            return FollowPhaseInfo(
                key: "airing",
                badge: String(localized: "phase_now_airing"),
                tone: Color.c2bTeal,
                stat: "\(max(0, days))",
                statUnit: String(localized: "phase_days_to_finale"),
                line: String(localized: "phase_airing_description")
            )
        case .pending:
            // Pending = airing but no confirmed finale date
            return FollowPhaseInfo(
                key: "airing",
                badge: String(localized: "phase_now_airing"),
                tone: Color.c2bTeal,
                stat: String(localized: "phase_stat_tbd"),
                statUnit: String(localized: "phase_finale_tbd"),
                line: String(localized: "phase_airing_description")
            )
        case .premieringSoon:
            let days = show.daysUntilPremiere ?? 0
            return FollowPhaseInfo(
                key: "premiering",
                badge: String(localized: "phase_premiering_soon"),
                tone: Color.c2bTeal,
                stat: "\(max(0, days))",
                statUnit: String(localized: "phase_days_to_premiere"),
                line: String(localized: "phase_premiering_description")
            )
        case .anticipated:
            return FollowPhaseInfo(
                key: "anticipated",
                badge: String(localized: "phase_anticipated"),
                tone: Color.c2bMuted,
                stat: String(localized: "phase_stat_tbd"),
                statUnit: String(localized: "phase_no_date"),
                line: String(localized: "phase_anticipated_description")
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero Section
            FollowConfirmHero(show: show)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Section Title
                Text("follow_added_to_timeline")
                    .font(.custom(.oswald.bold, size: 20))
                    .tracking(0.4)
                    .foregroundColor(.white)
                    .padding(.bottom, 14)

                // Timeline Stepper
                FollowTimelineStepper(activePhase: phaseInfo.key)
                    .padding(.bottom, 16)

                // Status Card
                FollowStatusCard(info: phaseInfo)

                // Save Button
                Button(action: onSave) {
                    Text("button_save")
                        .font(.custom(.oswald.bold, size: 16))
                        .tracking(0.48)
                        .foregroundColor(Color(hex: "#04201c"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.c2bTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 20)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .background(Color(hex: "#0e0e0f"))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .presentationBackground(Color(hex: "#0e0e0f"))
    }
}

// MARK: - Phase Info
private struct FollowPhaseInfo {
    let key: String
    let badge: String
    let tone: Color
    let stat: String
    let statUnit: String
    let line: String

    var isDim: Bool { key == "anticipated" }
}

// MARK: - Hero Section
private struct FollowConfirmHero: View {
    let show: ShowData

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image
            BackdropView(
                url: show.backdropURL ?? show.posterURL,
                height: 150
            )

            // Gradient
            LinearGradient(
                colors: [Color(hex: "#0e0e0f"), Color(hex: "#0e0e0f").opacity(0.2), Color(hex: "#0e0e0f").opacity(0.5)],
                startPoint: .bottom,
                endPoint: .top
            )

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Badge
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#04201c"))

                    Text("follow_added_badge")
                        .font(.custom(.jetbrains.bold, size: 8.5))
                        .tracking(1.02)
                        .foregroundColor(Color(hex: "#04201c"))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Color.c2bTeal)
                .clipShape(Capsule())

                // Title
                Text(show.name.uppercased())
                    .font(.custom(.oswald.bold, size: 26))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 10, y: 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
        .frame(height: 150)
    }
}

// MARK: - Timeline Stepper
private struct FollowTimelineStepper: View {
    let activePhase: String

    // Stages from left to right: anticipated -> premiering -> airing -> ready
    private let stages = [
        ("anticipated", "ANTICIPATED"),
        ("premiering", "PREMIERING"),
        ("airing", "NOW AIRING"),
        ("ready", "SERIES COMPLETE")
    ]

    private var activeIndex: Int {
        stages.firstIndex { $0.0 == activePhase } ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nodes and line
            GeometryReader { geo in
                let nodeSpacing = geo.size.width / CGFloat(stages.count)

                ZStack {
                    // Background line
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 2)
                        .padding(.horizontal, nodeSpacing / 2)

                    // Active line (from left to active node)
                    HStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.c2bTeal, .c2bTealBright],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(activeIndex) * nodeSpacing, height: 2)
                        Spacer()
                    }
                    .padding(.horizontal, nodeSpacing / 2)

                    // Nodes
                    HStack(spacing: 0) {
                        ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                            let isOn = index <= activeIndex
                            let isNow = index == activeIndex

                            Circle()
                                .fill(isOn ? (isNow ? Color.c2bTealBright : Color.c2bTeal) : Color(hex: "#1a1a1c"))
                                .frame(width: isNow ? 15 : 11, height: isNow ? 15 : 11)
                                .overlay(
                                    Circle()
                                        .stroke(isOn ? Color.clear : Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .shadow(color: isNow ? Color.c2bTeal.opacity(0.4) : .clear, radius: 8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 20)

            // Labels
            HStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    let isNow = index == activeIndex

                    Text(stage.1)
                        .font(.custom(.jetbrains.regular, size: 7.5))
                        .tracking(0.38)
                        .foregroundColor(isNow ? .c2bTealBright : .c2bMuted)
                        .fontWeight(isNow ? .bold : .regular)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Status Card
private struct FollowStatusCard: View {
    let info: FollowPhaseInfo

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Circle()
                .fill(info.isDim ? Color.white.opacity(0.06) : Color.c2bTeal.opacity(0.16))
                .frame(width: 46, height: 46)
                .overlay(
                    Circle()
                        .stroke(info.isDim ? Color.white.opacity(0.12) : Color.c2bTealLine, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(info.tone)
                        .frame(width: 12, height: 12)
                        .shadow(color: info.isDim ? .clear : Color.c2bTeal.opacity(0.4), radius: 8)
                )

            // Text
            VStack(alignment: .leading, spacing: 5) {
                Text(info.badge.uppercased())
                    .font(.custom(.oswald.bold, size: 21))
                    .foregroundColor(info.isDim ? .c2bDim : .white)

                Text(info.line)
                    .font(.system(size: 12))
                    .foregroundColor(.c2bMuted)
                    .lineSpacing(1.4)
            }

            Spacer()

            // Stat
            VStack(spacing: 5) {
                Text(info.stat)
                    .font(.custom(.oswald.bold, size: info.stat == String(localized: "phase_stat_now") || info.stat == String(localized: "phase_stat_tbd") ? 24 : 36))
                    .foregroundColor(info.key == "ready" ? .c2bTealBright : (info.isDim ? .c2bMuted : .white))

                Text(info.statUnit.uppercased())
                    .font(.custom(.jetbrains.bold, size: 7.5))
                    .tracking(0.75)
                    .foregroundColor(.c2bDim)
            }
            .frame(minWidth: 56)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            info.isDim
                ? AnyShapeStyle(Color.white.opacity(0.03))
                : AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.c2bTeal.opacity(0.14), Color.c2bTeal.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(info.isDim ? Color.white.opacity(0.09) : Color.c2bTealLine, lineWidth: 1)
        )
    }
}
