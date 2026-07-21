import SwiftUI

struct WalkthroughSheet: View {
    @Binding var step: Int
    let totalSteps: Int
    let walkthroughSteps: [WalkthroughStep]
    let buckets: [TimelineBucket]
    let allShows: [String]
    let landedShows: Set<String>
    let showLocations: [String: String]  // Track where shows have moved
    let dismissedShow: String?  // Show sliding off to the right
    @Binding var flyingShows: [String: FlyingPoster]
    let isAnimating: Bool
    let airingNamespace: Namespace.ID
    let premieringNamespace: Namespace.ID
    let anticipatedNamespace: Namespace.ID
    let onStart: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var position = ScrollPosition(edge: .top)
    @State private var showExplanation: Bool = true

    private var activeStep: WalkthroughStep? {
        step >= 0 && step < walkthroughSteps.count ? walkthroughSteps[step] : nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                // Header
                HStack {
                    Text("Quick tour")
                        .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                        .foregroundColor(Color(hex: "#2dd4bf"))
                        .textCase(.uppercase)
                        .tracking(1.6)

                    Spacer()

                    Button(action: onClose) {
                        Text("Skip")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                            .foregroundColor(Color(hex: "#71717a"))
                            .textCase(.uppercase)
                            .tracking(1.6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

                // Title & explanation (intro only)
                VStack(alignment: .leading, spacing: 8) {
                    if step < 0 {
                        // Step -1: Intro
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR TIMELINE, SORTED FOR YOU.")
                                .font(.custom(.oswald.bold, size: CustomFont.size.heading))
                                .textCase(.uppercase)
                                .tracking(0.26)
                                .foregroundColor(Color(hex: "#f4f4f5"))
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Every show you follow is grouped into three stages by how close it is to bingeable — and shows move up on their own as time passes. Step through to see where each one lands.")
                                .font(.system(size: 13.5, weight: .regular, design: .default))
                                .foregroundColor(Color(hex: "#a1a1aa"))
                                .lineSpacing(2)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(minHeight: step < 0 ? 96 : 0, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // Pile
                ShowPile(
                    allShows: allShows,
                    landedShows: landedShows,
                    flyingShows: flyingShows,
                    buckets: buckets,
                    airingNamespace: airingNamespace,
                    premieringNamespace: premieringNamespace,
                    anticipatedNamespace: anticipatedNamespace
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Timeline board
                ScrollView {
                    TimelineBoard(
                        buckets: buckets,
                        step: step,
                        landedShows: landedShows,
                        showLocations: showLocations,
                        dismissedShow: dismissedShow,
                        airingNamespace: airingNamespace,
                        premieringNamespace: premieringNamespace,
                        anticipatedNamespace: anticipatedNamespace
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, step >= 0 ? 200 : 0)
                }
                .scrollPosition($position)
                .animation(.easeOut(duration: 0.4), value: position)
                .onChange(of: step) { oldValue, newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        switch newValue {
                        case 0:
                            // Now Airing
                            position.scrollTo(edge: .top)
                        case 1:
                            // Premiering Soon
                            position.scrollTo(id: "section-premiering", anchor: .top)
                        case 2:
                            // Anticipated
                            position.scrollTo(id: "section-anticipated", anchor: .top)
                        case 3:
                            // A Date Is Set - show Anticipated → Premiering transition
                            position.scrollTo(id: "section-anticipated", anchor: .top)
                        case 4:
                            // It Premieres - show Premiering → Airing transition
                            position.scrollTo(id: "section-premiering", anchor: .top)
                        case 5:
                            // The Finale Airs - show Airing → Binge Ready transition
                            position.scrollTo(edge: .top)
                        default:
                            break
                        }
                    }
                }

                // Footer
                HStack(spacing: 12) {
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(index == step ? Color.c2bTeal : Color.white.opacity(0.2))
                                .frame(width: index == step ? 18 : 6, height: 6)
                                .animation(.spring(response: 0.3), value: step)
                        }
                    }

                    Spacer()

                    // CTA button
                    Button(action: step < 0 ? onStart : onNext) {
                        Text(buttonText)
                            .font(.custom(.oswald.bold, size: 14))
                            .foregroundColor(Color(hex: "#04201c"))
                            .textCase(.uppercase)
                            .tracking(0.14)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 13)
                            .background(isAnimating ? Color.c2bTeal.opacity(0.5) : Color.c2bTeal)
                            .cornerRadius(13)
                    }
                    .disabled(isAnimating && step >= 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            // Floating explanation card overlay - hide during animation
            if let currentStep = activeStep, showExplanation {
                WalkthroughExplanationCard(
                    label: currentStep.label,
                    tone: currentStep.tone,
                    hint: currentStep.hint,
                    note: currentStep.note,
                    currentStep: step + 1,
                    totalSteps: totalSteps
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 84)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: showExplanation)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 780)
        .background(Color(hex: "#0c0c0e"))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 26,
                topTrailingRadius: 26
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 26,
                topTrailingRadius: 26
            )
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 30, x: 0, y: -20)
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                // Hide immediately when animation starts
                showExplanation = false
            } else {
                // Show after extra 1 second delay when animation ends
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showExplanation = true
                }
            }
        }
    }

    private var buttonText: String {
        if step < 0 {
            return "SHOW ME →"
        } else if step < totalSteps - 1 {
            return "NEXT →"
        } else {
            return "GOT IT — LET'S GO"
        }
    }
}
