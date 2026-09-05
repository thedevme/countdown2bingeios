//
//  MyListOnboardingContainer.swift
//  Countdown2Binge
//
//  The whole onboarding experience — intro + all three questions — lives in
//  ONE overlay card. Paging between them is a real `TabView` (native swipe/
//  slide, page-dots hidden since the progress header is its own indicator),
//  not a system sheet or full-screen presentation.
//
//  Finishing — however it happens — persists the answers to
//  MyListPreferencesStore, which is what the real My List screen reads.
//  Skip and Maybe Later persist the spec's literal defaults (Jump around ·
//  Depends · No schedule), not whatever was half-picked before skipping.
//

import SwiftUI

struct MyListOnboardingContainer: View {
    /// Called once the whole thing is done, however it ends — Maybe Later,
    /// Skip on any question, or finishing Q3.
    let onFinish: () -> Void

    private enum Page: Int, CaseIterable {
        case intro, scope, unit, days
    }

    @State private var page: Page = .intro

    // Answers, mirroring MyListAnswers.defaults until changed.
    @State private var scope: MyListWatchScope = .jumpAround
    @State private var unit: MyListSessionUnit = .depends
    @State private var episodeBucket: MyListEpisodeBucket = .threeToFour
    @State private var timeBucket: MyListTimeBucket = .oneHour
    @State private var selectedDays: Set<Int> = []

    private var currentAnswers: MyListAnswers {
        MyListAnswers(
            scope: scope, unit: unit,
            episodeBucket: episodeBucket, timeBucket: timeBucket,
            selectedDays: selectedDays
        )
    }

    /// The "so this card now reads" preview — recomputed from every answer
    /// currently set, not just the question being viewed, and driven by the
    /// same MyListVerdictEngine the real list uses.
    private var preview: MyListOnboardingPreviewState {
        MyListOnboardingPreviewState.make(answers: currentAnswers)
    }

    /// Reserved space above/below the card — measured from the raw screen
    /// edge, since the backdrop ignores the safe area. Top just needs to
    /// clear the status bar; bottom needs to clear the floating native tab
    /// bar plus the home indicator, hence the bigger number.
    private let topMargin: CGFloat = 64
    private let bottomMargin: CGFloat = 110

    var body: some View {
        GeometryReader { screen in
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.black.opacity(0.55)
            }
            .ignoresSafeArea()
            .overlay {
                card(availableHeight: max(0, screen.size.height - topMargin - bottomMargin))
                    .padding(.horizontal, 22)
                    .padding(.top, topMargin)
                    .padding(.bottom, bottomMargin)
            }
        }
        .ignoresSafeArea()
    }

    private func card(availableHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Always rendered, never conditionally inserted — see prior note
            // in git history: an appearing/disappearing header changes the
            // card's total height, which made intro → Q1 both slide AND
            // resize at once. Hiding it via opacity keeps height constant.
            MyListOnboardingProgressHeader(
                stepIndex: max(0, page.rawValue - 1),
                totalSteps: Page.allCases.count - 1,
                onBack: goBack
            )
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .opacity(page == .intro ? 0 : 1)
            .allowsHitTesting(page != .intro)

            TabView(selection: $page) {
                MyListOnboardingPage {
                    MyListOnboardingIntroContent(
                        onGetStarted: goNext,
                        // Same as Skip — defaults, then straight to the real
                        // list (which now IS the "so this is what it looks
                        // like" moment; no separate preview screen to drift
                        // out of sync with it).
                        onMaybeLater: skip
                    )
                    .padding(.horizontal, 22)
                    .padding(.top, 26)
                    .padding(.bottom, 22)
                }
                .tag(Page.intro)

                MyListOnboardingPage {
                    MyListOnboardingScopeStep(scope: $scope, preview: preview, onContinue: goNext, onSkip: skip)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 22)
                }
                .tag(Page.scope)

                MyListOnboardingPage {
                    MyListOnboardingUnitStep(
                        unit: $unit,
                        episodeBucket: $episodeBucket,
                        timeBucket: $timeBucket,
                        preview: preview,
                        onContinue: goNext,
                        onSkip: skip
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
                .tag(Page.unit)

                MyListOnboardingPage {
                    MyListOnboardingDaysStep(
                        selectedDays: $selectedDays,
                        preview: preview,
                        onContinue: finish,
                        onSkip: skip
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
                }
                .tag(Page.days)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
        }
        .frame(height: availableHeight)
        .background(Color.c2bCard)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.c2bTealLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.72), radius: 40, x: 0, y: 26)
    }

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            page = Page(rawValue: page.rawValue + 1) ?? page
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            page = Page(rawValue: page.rawValue - 1) ?? page
        }
    }

    /// Completing Q3 — persists whatever was actually answered.
    private func finish() {
        MyListPreferencesStore.shared.answers = currentAnswers
        onFinish()
    }

    /// Skip, on any question — the spec's literal defaults, not whatever was
    /// half-picked before skipping.
    private func skip() {
        MyListPreferencesStore.shared.answers = .defaults
        onFinish()
    }
}

#Preview {
    MyListOnboardingContainer(onFinish: {})
}
