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
import StoreKit

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

    /// Steps remaining after the current one.
    private var remaining: Int { max(total - step - 1, 0) }
    /// 0…1 progress used for the track fill and glowing thumb.
    private var progress: CGFloat { CGFloat(step + 1) / CGFloat(total) }

    var body: some View {
        VStack(spacing: 0) {
            // top bar: back · progress slider · N TO GO.
            // The first screen (step 0) shows no chrome at all — just the content.
            if step > 0 {
                HStack(spacing: 16) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#cccccc"))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    progressSlider

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(remaining)")
                            .font(.custom(.oswald.bold, size: 32))
                            .foregroundColor(.white)
                        Text(String(localized: "onboarding_nav_to_go"))
                            .font(.custom(.jetbrains.regular, size: 8))
                            .tracking(1.5)
                            .foregroundColor(.c2bMuted)
                    }
                    .fixedSize()
                }
                .padding(.top, 50).padding(.horizontal, 22).padding(.bottom, 12)
            } else {
                Color.clear.frame(height: 50)
            }

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
                    if step == 0, let onSkip {
                        Button(action: onSkip) {
                            Text(String(localized: "onboarding_nav_skip"))
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
                            .textCase(.uppercase)
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

    // MARK: - Progress slider (glowing teal thumb over a rounded track)

    private var progressSlider: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = max(9, min(w - 9, w * progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.c2bTeal.opacity(0.35), Color.c2bTeal],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: x, height: 6)

                Circle()
                    .fill(Color.c2bTeal)
                    .frame(width: 18, height: 18)
                    .shadow(color: Color.c2bTeal.opacity(0.85), radius: 7)
                    .shadow(color: Color.c2bTeal.opacity(0.5), radius: 14)
                    .offset(x: x - 9)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
        .frame(height: 44)
    }
}

// MARK: - Flow

struct OnboardingFlow: View {
    @Binding var isPresented: Bool
    var onComplete: (_ plan: String, _ shows: [ShowSummary]) -> Void

    /// System App Store rating prompt, triggered by the review step.

    @State private var step = 0
    @State private var followed: [ShowSummary] = []
    @State private var genres: Set<String> = []
    @State private var services: Set<String> = []
    @State private var behavior: String?
    @State private var tired: String?
    @State private var showSystemPrompt = false
    @State private var selectedPlan = "yearly"

    private let data = OnboardingDataLoader.shared
    private let total = 17
    /// Bare, full-screen timeline walkthrough sits between "Add Shows" and "Four States".
    private let walkthroughStep = 10
    /// Final step is the RevenueCat paywall (full-screen, its own chrome).
    private let paywallStep = 16
    private var size: Int { followed.count }

    /// Preferences drafted from the in-flow selections, used to seed the add-shows
    /// suggestion rail through the SAME RecommendationService path the app uses.
    private var draftPreferences: TastePreferences {
        TastePreferences(
            genreIDs: TasteCatalog.tmdbGenreIDs(for: genres),
            providerIDs: TasteCatalog.fallbackProviderIDs(for: services),
            watchRegion: TastePreferences.defaultRegion,
            completedPreferenceStep: true
        )
    }

    var body: some View {
        ZStack {
            if step == paywallStep {
                PaywallView(
                    selectedPlan: $selectedPlan,
                    // X / dismiss: keep the purchased plan only if they actually
                    // bought; otherwise fall through to free (no premium without purchase).
                    onDismiss: { finish(PremiumManager.shared.isPremium ? selectedPlan : "free") },
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
        case 9: OBAddShowsSlide(preferences: draftPreferences, selected: $followed)
        // 10: timeline walkthrough · 17: paywall — both handled in body
        case 11: OBBucketsSlide()
        // The App Store rating slide that used to sit here was removed:
        // Guideline 5.6.3 forbids requesting a rating during onboarding.
        // Rating is now asked later, from real usage — see ReviewPrompt.
        case 12: OBNotifPrimeSlide()
        case 13: OBSummarySlide(count: max(size, 3))
        case 14: OBCommitmentSlide(answer: $tired)
        case 15: OBPriceAnchorSlide(services: services)
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
        case 12: m.onCta = { showSystemPrompt = true }
        case 14: m.disabled = tired == nil
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
        case 12: return data.notifPrimingSlide?.buttonText
        case 13: return data.journeySummarySlide?.buttonText
        case 14: return data.commitmentQuestion?.buttonText
        case 15: return data.priceAnchorSlide?.buttonText
        default: return nil
        }
    }

    private func secondaryLabel(_ step: Int) -> String? {
        switch step {
        case 12: return data.notifPrimingSlide?.buttonTextAlt
        default: return nil
        }
    }

    // MARK: Navigation

    private func next() { withAnimation(.easeInOut(duration: 0.25)) { step = min(total - 1, step + 1) } }
    private func back() { withAnimation(.easeInOut(duration: 0.25)) { step = max(0, step - 1) } }
    private func skip() { step == 0 ? finish("free") : withAnimation { step = total - 1 } }

    private func finish(_ plan: String) {
        // Persist the taste layer (previously discarded) so it can drive every
        // recommendation surface. Genres map synchronously; providers resolve via
        // the live catalog with an offline fallback.
        TastePreferencesStore.shared.applyFromOnboarding(
            genreOptionIDs: genres,
            serviceOptionIDs: services
        )
        onComplete(plan, followed)
        withAnimation { isPresented = false }
    }
}

#Preview {
    struct Wrapper: View {
        @State private var show = true
        var body: some View {
            OnboardingFlow(isPresented: $show) { plan, shows in
            }
            .preferredColorScheme(.dark)
        }
    }
    return Wrapper()
}
