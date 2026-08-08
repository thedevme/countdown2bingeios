//
//  OnboardingFlow.swift
//  Countdown2Binge
//
//  v2 onboarding flow — 17 screens with shared shell chrome (back, progress,
//  STEP NN/NN, teal CTA). Ported from c2b-onboarding.jsx `OnboardingFlow`.
//
//  DESIGN-ONLY: selections use sample data; `onComplete` hands back the chosen
//  plan + followed shows (as ShowSummary) for you to persist. The first-run
//  timeline walkthrough is shown separately by ContentView, so it is not a step
//  here.
//

import SwiftUI

// MARK: - Shell chrome

struct OBShell<Content: View>: View {
    let step: Int
    let total: Int
    var onBack: () -> Void
    var onSkip: (() -> Void)?
    var ctaLabel: String?
    var ctaDisabled: Bool = false
    var onCta: (() -> Void)?
    var secondary: String?
    var onSecondary: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // top bar: back · progress · skip
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#cccccc"))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .opacity(step == 0 ? 0 : 1)
                .disabled(step == 0)

                HStack(spacing: 5) {
                    ForEach(0..<total, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.c2bTeal : Color.white.opacity(0.12))
                            .frame(height: 3)
                    }
                }

                if let onSkip {
                    Button(action: onSkip) {
                        Text("SKIP")
                            .font(.custom(.jetbrains.regular, size: 9.5))
                            .tracking(1.33)
                            .foregroundColor(.c2bMuted)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 30, height: 1)
                }
            }
            .padding(.top, 50).padding(.horizontal, 22).padding(.bottom, 6)

            Text("STEP \(String(format: "%02d", step + 1)) / \(String(format: "%02d", total))")
                .font(.custom(.jetbrains.bold, size: 9))
                .tracking(1.98)
                .foregroundColor(.c2bMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22).padding(.top, 4)

            GeometryReader { proxy in
                ScrollView {
                    content()
                        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 14)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }

            if let ctaLabel {
                VStack(spacing: 14) {
                    if let secondary {
                        Button(action: { onSecondary?() }) {
                            Text(secondary.uppercased())
                                .font(.custom(.jetbrains.regular, size: 11))
                                .tracking(1.32)
                                .foregroundColor(.c2bDim)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(action: { if !ctaDisabled { onCta?() } }) {
                        Text(ctaLabel)
                            .font(.custom(.oswald.bold, size: 17))
                            .tracking(0.51)
                            .foregroundColor(ctaDisabled ? .c2bMuted : .c2bOnTeal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ctaDisabled ? Color.white.opacity(0.07) : Color.c2bTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .disabled(ctaDisabled)
                }
                .padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 26)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Flow

struct OnboardingFlow: View {
    @Binding var isPresented: Bool
    var onComplete: (_ plan: String, _ shows: [ShowSummary]) -> Void

    @State private var step = 0
    @State private var followed: Set<Int> = []
    @State private var genres: Set<String> = []
    @State private var services: Set<String> = []
    @State private var behavior: String?
    @State private var tired: String?
    @State private var showSystemPrompt = false
    @State private var selectedPlan = "yearly"

    private let data = OnboardingDataLoader.shared
    private let total = 18
    /// Bare, full-screen timeline walkthrough sits between "Add Shows" and "Four States".
    private let walkthroughStep = 10
    /// Final step is the RevenueCat paywall (full-screen, its own chrome).
    private let paywallStep = 17
    private var size: Int { followed.count }

    var body: some View {
        ZStack {
            if step == paywallStep {
                PaywallView(
                    selectedPlan: $selectedPlan,
                    onDismiss: { finish(selectedPlan) },
                    onContinueFree: { finish("free") },
                    showContinueFree: true
                )
            } else if step == walkthroughStep {
                ZStack {
                    Color.black.ignoresSafeArea()
                    TimelineWalkthrough(isPresented: walkthroughBinding)
                }
            } else {
                OBShell(
                    step: step,
                    total: total,
                    onBack: { back() },
                    onSkip: step >= total - 1 ? nil : { skip() },
                    ctaLabel: meta.label,
                    ctaDisabled: meta.disabled,
                    onCta: meta.onCta,
                    secondary: meta.secondary,
                    onSecondary: meta.secondary != nil ? { next() } : nil
                ) {
                    stepContent
                }
            }

            if showSystemPrompt {
                OBSystemPermission(
                    onAllow: { showSystemPrompt = false; next() },
                    onDeny: { showSystemPrompt = false; next() }
                )
            }
        }
    }

    /// Drives the bare walkthrough step: closing it advances to "Four States".
    private var walkthroughBinding: Binding<Bool> {
        Binding(get: { step == walkthroughStep }, set: { presented in if !presented { next() } })
    }

    // MARK: Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: OBWelcomeSlide()
        case 1: OBProblemSlide()
        case 2: OBAgitateSlide()
        case 3: OBSolutionSlide()
        case 4: OBGenresSlide(picked: $genres)
        case 5: OBServicesSlide(picked: $services)
        case 6: OBBehaviorSlide(answer: $behavior)
        case 7: OBStatSlide(behavior: behavior)
        case 8: OBReflectionSlide(genres: genres, services: services, behavior: behavior)
        case 9: OBAddShowsSlide(followed: $followed)
        // 10: timeline walkthrough · 17: paywall — both handled in body
        case 11: OBBucketsSlide()
        case 12: OBReviewSlide(count: max(size, 3))
        case 13: OBNotifPrimeSlide()
        case 14: OBSummarySlide(count: max(size, 3))
        case 15: OBCommitmentSlide(answer: $tired)
        case 16: OBPriceAnchorSlide(services: services)
        default: EmptyView()
        }
    }

    // MARK: Step metadata (CTA labels come from JSON/localized strings)

    private struct StepMeta {
        var label: String?
        var disabled = false
        var secondary: String?
        var onCta: (() -> Void)?
    }

    private var meta: StepMeta {
        var m = StepMeta(label: ctaLabel(step), secondary: secondaryLabel(step), onCta: next)
        switch step {
        case 4: m.disabled = genres.isEmpty
        case 5: m.disabled = services.isEmpty
        case 6: m.disabled = behavior == nil
        case 9: m.disabled = size == 0
        case 13: m.onCta = { showSystemPrompt = true }
        case 15: m.disabled = tired == nil
        default: break
        }
        return m
    }

    private func ctaLabel(_ step: Int) -> String? {
        switch step {
        case 0: return data.welcomeSlide?.buttonText
        case 1: return data.problemSlide?.buttonText
        case 2: return data.agitateSlide?.buttonText
        case 3: return data.solutionSlide?.buttonText
        case 4: return data.genresQuestion?.buttonText
        case 5: return data.servicesQuestion?.buttonText
        case 6: return data.behaviorQuestion?.buttonText
        case 7: return data.statSlide?.buttonText
        case 8: return data.reflectionSlide?.buttonText
        case 9: return size > 0
            ? String(format: NSLocalizedString("onboarding_add_shows_button %lld", comment: ""), size)
            : "ADD THREE TO START"
        case 11: return data.bucketsSlide?.buttonText
        case 12: return data.reviewPromptSlide?.buttonText
        case 13: return data.notifPrimingSlide?.buttonText
        case 14: return data.journeySummarySlide?.buttonText
        case 15: return data.commitmentQuestion?.buttonText
        case 16: return data.priceAnchorSlide?.buttonText
        default: return nil
        }
    }

    private func secondaryLabel(_ step: Int) -> String? {
        switch step {
        case 12: return data.reviewPromptSlide?.buttonTextAlt
        case 13: return data.notifPrimingSlide?.buttonTextAlt
        default: return nil
        }
    }

    // MARK: Navigation

    private func next() { withAnimation(.easeInOut(duration: 0.25)) { step = min(total - 1, step + 1) } }
    private func back() { withAnimation(.easeInOut(duration: 0.25)) { step = max(0, step - 1) } }
    private func skip() { step == 0 ? finish("free") : withAnimation { step = total - 1 } }

    private func finish(_ plan: String) {
        let shows = OnboardingData.popular.filter { followed.contains($0.id) }.map { $0.summary }
        onComplete(plan, shows)
        withAnimation { isPresented = false }
    }
}

#Preview {
    struct Wrapper: View {
        @State private var show = true
        var body: some View {
            OnboardingFlow(isPresented: $show) { plan, shows in
                print("plan=\(plan) shows=\(shows.count)")
            }
            .preferredColorScheme(.dark)
        }
    }
    return Wrapper()
}
