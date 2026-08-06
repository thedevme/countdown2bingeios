//
//  AddShowModal.swift
//  Countdown2Binge
//
//  Modal shown after following a show. Displays timeline placement
//  and optionally asks about watch progress for back-catalog shows.
//

import SwiftUI

struct AddShowModal: View {
    let show: ShowData
    let addTimePrompt: AddTimeWatchedPrompt?
    let onDone: (WatchAnswer?) -> Void

    @State private var selectedAnswer: WatchAnswer? = nil

    // Phase info based on show state
    private var phaseInfo: PhaseInfo {
        switch show.showState {
        case .bingeReady:
            return PhaseInfo(
                key: "ready",
                title: String(localized: "phase_series_complete"),
                description: String(localized: "phase_ready_description \(show.currentSeason?.episodeCount ?? show.numberOfEpisodes)"),
                stat: String(localized: "phase_stat_now"),
                statLabel: String(localized: "phase_binge_ready"),
                isDimmed: false
            )
        case .airing:
            let days = show.daysUntilFinale ?? 0
            return PhaseInfo(
                key: "airing",
                title: String(localized: "phase_now_airing"),
                description: String(localized: "phase_airing_description"),
                stat: "\(max(0, days))",
                statLabel: String(localized: "phase_days_to_finale"),
                isDimmed: false
            )
        case .pending:
            // Pending = airing but no confirmed finale date
            return PhaseInfo(
                key: "airing",
                title: String(localized: "phase_now_airing"),
                description: String(localized: "phase_airing_description"),
                stat: String(localized: "phase_stat_tbd"),
                statLabel: String(localized: "phase_finale_tbd"),
                isDimmed: false
            )
        case .premieringSoon:
            let days = show.daysUntilPremiere ?? 0
            return PhaseInfo(
                key: "premiering",
                title: String(localized: "phase_premiering_soon"),
                description: String(localized: "phase_premiering_description"),
                stat: "\(max(0, days))",
                statLabel: String(localized: "phase_days_to_premiere"),
                isDimmed: false
            )
        case .anticipated:
            return PhaseInfo(
                key: "anticipated",
                title: String(localized: "phase_anticipated"),
                description: String(localized: "phase_anticipated_description"),
                stat: String(localized: "phase_stat_tbd"),
                statLabel: String(localized: "phase_no_date"),
                isDimmed: true
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section
                AddShowHero(
                    showName: show.name,
                    backdropURL: show.backdropURL,
                    posterURL: show.posterURL
                )

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Section title
                    Text("add_show_timeline_section_title")
                        .font(.custom(.oswald.bold, size: 18))
                        .tracking(0.4)
                        .foregroundColor(.white)
                        .padding(.bottom, 16)

                    // Timeline stepper
                    AddShowTimelineStepper(activePhase: phaseInfo.key)
                        .padding(.bottom, 18)

                    // Status card
                    AddShowStatusCard(
                        title: phaseInfo.title,
                        description: phaseInfo.description,
                        stat: phaseInfo.stat,
                        statLabel: phaseInfo.statLabel,
                        isDimmed: phaseInfo.isDimmed
                    )

                    // Watch question (conditional)
                    if let prompt = addTimePrompt {
                        AddShowWatchQuestion(
                            seasonNumber: prompt.seasonNumber,
                            selectedAnswer: $selectedAnswer
                        )
                        .padding(.top, 24)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            // Save button pinned to bottom - disabled until question answered
            let canSave = addTimePrompt == nil || selectedAnswer != nil

            Button {
                onDone(selectedAnswer)
            } label: {
                Text("button_save")
                    .font(.custom(.oswald.bold, size: 16))
                    .tracking(0.5)
                    .foregroundColor(canSave ? Color(hex: "#04201c") : Color(hex: "#04201c").opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color.c2bTeal : Color.c2bTeal.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave)
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(Color(hex: "#0e0e0f"))
        }
        .background(Color(hex: "#0e0e0f"))
        .ignoresSafeArea(edges: .top)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .presentationBackground(Color(hex: "#0e0e0f"))
    }
}

// MARK: - Phase Info

private struct PhaseInfo {
    let key: String
    let title: String
    let description: String
    let stat: String
    let statLabel: String
    let isDimmed: Bool
}

// MARK: - Preview

#Preview("Anticipated with Watch Question") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AddShowModal(
                show: ShowData(
                    id: 1,
                    name: "Vice Coast",
                    overview: "A show about vice",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: nil,
                    status: .returning,
                    genres: [],
                    networks: [],
                    createdBy: nil,
                    seasons: [],
                    numberOfSeasons: 3,
                    numberOfEpisodes: 24,
                    inProduction: true,
                    voteAverage: nil
                ),
                addTimePrompt: AddTimeWatchedPrompt(
                    seriesId: 1,
                    seasonNumber: 3,
                    seasonName: "Season 3"
                ),
                onDone: { _ in }
            )
        }
}

#Preview("Now Airing - No Question") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AddShowModal(
                show: ShowData(
                    id: 2,
                    name: "House of the Dragon",
                    overview: "A show about dragons",
                    posterPath: nil,
                    backdropPath: nil,
                    logoPath: nil,
                    firstAirDate: Date(),
                    status: .returning,
                    genres: [],
                    networks: [],
                    createdBy: nil,
                    seasons: [],
                    numberOfSeasons: 2,
                    numberOfEpisodes: 18,
                    inProduction: true,
                    voteAverage: nil
                ),
                addTimePrompt: nil,
                onDone: { _ in }
            )
        }
}
