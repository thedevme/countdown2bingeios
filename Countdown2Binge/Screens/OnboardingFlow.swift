import SwiftUI
import RevenueCat

// MARK: - Onboarding Flow
struct OnboardingFlow: View {
    @Binding var isPresented: Bool
    let onComplete: (String, [ShowSummary]) -> Void

    @State private var currentStep: Int = 0
    @State private var selectedPlan: String = "yearly"
    @State private var viewModel = OnboardingViewModel()
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?

    private let totalSteps = 7

    var body: some View {
        ZStack {
            Color(hex: "#000000").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            if currentStep > 0 { currentStep -= 1 }
                        }
                    },
                    onSkip: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            currentStep = totalSteps - 1
                        }
                    }
                )

                // Content
                TabView(selection: $currentStep) {
                    PainSlide()
                        .tag(0)

                    AgitateSlide()
                        .tag(1)

                    SolutionSlide()
                        .tag(2)

                    AddShowsStep(viewModel: viewModel)
                        .tag(3)

                    ReviewSelectionStep(viewModel: viewModel)
                        .tag(4)

                    AllSetStep(shows: viewModel.getSelectedShows())
                        .tag(5)

                    PaywallStep(
                        followedCount: viewModel.selectedCount,
                        selectedPlan: $selectedPlan
                    )
                    .tag(6)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentStep)

                // Footer
                OnboardingFooter(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    canProceed: (currentStep != 3 || viewModel.hasSelections) && !isPurchasing,
                    selectedPlan: selectedPlan,
                    isPurchasing: isPurchasing,
                    onNext: {
                        // Skip to completion if already premium (DEBUG/TestFlight)
                        if currentStep >= 4 && PremiumManager.shared.isPremium {
                            completeOnboarding()
                            return
                        } else if currentStep < totalSteps - 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                currentStep += 1
                            }
                        } else {
                            // On paywall step - initiate purchase
                            Task {
                                await handlePurchase()
                            }
                        }
                    },
                    onRestore: {
                        Task {
                            await handleRestore()
                        }
                    }
                )
            }

            // Purchase error alert
            if let error = purchaseError {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { purchaseError = nil }

                VStack(spacing: 16) {
                    Text("alert_purchase_failed")
                        .font(.custom(.oswald.bold, size: 18))
                        .foregroundColor(.white)

                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#a1a1aa"))
                        .multilineTextAlignment(.center)

                    Button("button_ok") {
                        purchaseError = nil
                    }
                    .font(.custom(.oswald.bold, size: 16))
                    .foregroundColor(Color(hex: "#04201c"))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2dd4bf"))
                    .cornerRadius(10)
                }
                .padding(24)
                .background(Color(hex: "#1a1a1c"))
                .cornerRadius(16)
                .padding(40)
            }
        }
    }

    // MARK: - Purchase Handling

    private func handlePurchase() async {
        // Map plan ID to RevenueCat package identifier
        let packageId: String
        switch selectedPlan {
        case "yearly":
            packageId = "$rc_annual"
        case "monthly":
            packageId = "$rc_monthly"
        case "lifetime":
            packageId = "$rc_lifetime"
        default:
            // Unknown plan, complete without purchase
            completeOnboarding()
            return
        }

        isPurchasing = true
        purchaseError = nil

        do {
            let offerings = try await PremiumManager.shared.getOfferings()

            guard let currentOffering = offerings.current,
                  let package = currentOffering.package(identifier: packageId) else {
                print("OnboardingFlow: Package \(packageId) not found in offerings")
                // Package not found - complete anyway (user can purchase later)
                completeOnboarding()
                return
            }

            let success = try await PremiumManager.shared.purchase(package: package)

            if success {
                // Purchase successful
                completeOnboarding()
            } else {
                // User cancelled - still complete onboarding but as free
                selectedPlan = "free"
                completeOnboarding()
            }
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
        }
    }

    private func completeOnboarding() {
        isPurchasing = false
        let shows = viewModel.getSelectedShows()
        print("OnboardingFlow: Completing with \(shows.count) shows: \(shows.map { $0.name })")
        onComplete(selectedPlan, shows)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            isPresented = false
        }
    }

    private func handleRestore() async {
        isPurchasing = true
        purchaseError = nil

        do {
            try await PremiumManager.shared.restorePurchases()

            if PremiumManager.shared.isPremium {
                // Restore successful - user has premium
                selectedPlan = "restored"
                completeOnboarding()
            } else {
                // No purchases to restore
                isPurchasing = false
                purchaseError = String(localized: "error_no_purchases")
            }
        } catch {
            isPurchasing = false
            purchaseError = error.localizedDescription
        }
    }
}

// MARK: - Onboarding Flow with Default Binding
struct OnboardingFlowPreview: View {
    @State private var showOnboarding = true

    var body: some View {
        OnboardingFlow(
            isPresented: $showOnboarding,
            onComplete: { plan, shows in
                print("Completed with plan: \(plan), shows: \(shows.map { $0.name })")
            }
        )
    }
}

// MARK: - Onboarding Header
struct OnboardingHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Back button
                Button(action: onBack) {
                    DirectionalIcon(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#cccccc"))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .opacity(currentStep == 0 ? 0 : 1)

                // Progress bars
                HStack(spacing: 5) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index <= currentStep ? Color(hex: "#2dd4bf") : Color.white.opacity(0.12))
                            .frame(height: 3)
                    }
                }

                // Skip button
                if currentStep < totalSteps - 2 {
                    Button(action: onSkip) {
                        Text("button_skip")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                            .foregroundColor(Color(hex: "#71717a"))
                            .textCase(.uppercase)
                            .tracking(1.6)
                    }
                    .frame(width: 34)
                } else {
                    Spacer()
                        .frame(width: 34)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 50)

            // Step indicator
            Text("STEP \(String(format: "%02d", currentStep + 1)) / \(String(format: "%02d", totalSteps))")
                .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                .foregroundColor(Color(hex: "#71717a"))
                .textCase(.uppercase)
                .tracking(1.6)
                .padding(.top, 4)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Onboarding Footer
struct OnboardingFooter: View {
    let currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let selectedPlan: String
    var isPurchasing: Bool = false
    let onNext: () -> Void
    var onRestore: (() -> Void)? = nil

    private var buttonText: String {
        if isPurchasing {
            return "PROCESSING..."
        }

        switch currentStep {
        case 0, 1:
            return "CONTINUE"
        case 2:
            return "LET'S SET YOU UP →"
        case 3:
            return followedText
        case 4:
            return "CONFIRM SELECTION"
        case 5:
            return "CONTINUE"
        case 6:
            return paywallButtonText
        default:
            return "CONTINUE"
        }
    }

    private var paywallButtonText: String {
        switch selectedPlan {
        case "lifetime":
            return "PURCHASE LIFETIME"
        default:
            return "START 7-DAY FREE TRIAL"
        }
    }

    private var followedText: String {
        canProceed ? "CONTINUE" : "FOLLOW AT LEAST ONE"
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onNext) {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#04201c")))
                            .scaleEffect(0.8)
                    }
                    Text(buttonText)
                        .font(.custom(.oswald.bold, size: 17))
                        .foregroundColor(canProceed ? Color(hex: "#04201c") : Color(hex: "#71717a"))
                        .textCase(.uppercase)
                        .tracking(0.17)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed ? Color(hex: "#2dd4bf") : Color.white.opacity(0.07))
                .cornerRadius(15)
            }
            .disabled(!canProceed || isPurchasing)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)

            // Legal text for paywall
            if currentStep == totalSteps - 1 {
                VStack(spacing: 8) {
                    if selectedPlan != "lifetime" {
                        Text("premium_trial_legal")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                            .foregroundColor(Color(hex: "#71717a"))
                            .textCase(.uppercase)
                            .tracking(1.6)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Text("link_terms")
                                .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                                .foregroundColor(Color(hex: "#a1a1aa"))
                                .textCase(.uppercase)
                                .tracking(1.6)
                        }

                        Text("·")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                            .foregroundColor(Color(hex: "#71717a"))

                        Button(action: {}) {
                            Text("link_privacy")
                                .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                                .foregroundColor(Color(hex: "#a1a1aa"))
                                .textCase(.uppercase)
                                .tracking(1.6)
                        }

                        Text("·")
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                            .foregroundColor(Color(hex: "#71717a"))

                        Button(action: { onRestore?() }) {
                            Text("link_restore")
                                .font(.custom(.jetbrains.bold, size: CustomFont.size.sm))
                                .foregroundColor(Color(hex: "#a1a1aa"))
                                .textCase(.uppercase)
                                .tracking(1.6)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: "#000000")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .offset(y: -80)
        )
    }
}

// MARK: - Pain Slide
struct PainSlide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Illustration
                PainIllustration()
                    .padding(.vertical, 26)

                Text("onboarding_pain_label")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)

                Text("onboarding_pain_title")
                    .font(.custom(.oswald.bold, size: CustomFont.size.display))
                    .textCase(.uppercase)
                    .tracking(0.42)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("onboarding_pain_description")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }
}

struct PainIllustration: View {
    var body: some View {
        ZStack {
            // Poster with "Season Ended" stamp
            Image("severance")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 225)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .rotationEffect(.degrees(-4))
                .grayscale(0.6)
                .brightness(-0.2)
                .overlay(
                    Text("status_season_ended")
                        .font(.custom(.oswald.bold, size: CustomFont.size.body))
                        .foregroundColor(Color(hex: "#dd524c"))
                        .textCase(.uppercase)
                        .tracking(0.15)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#dd524c"), lineWidth: 3)
                        )
                        .rotationEffect(.degrees(-8))
                )

            // Notification badge
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#dd524c"))
                            .frame(width: 30, height: 30)
                            .shadow(color: Color(hex: "#dd524c").opacity(0.5), radius: 8, x: 0, y: 3)

                        Text("!")
                            .font(.custom(.oswald.bold, size: CustomFont.size.body))
                            .foregroundColor(.white)
                            .textCase(.uppercase)
                    }
                    .rotationEffect(.degrees(6))
                    .offset(x: 30, y: -30)
                }
                Spacer()
            }
        }
        .frame(height: 130)
    }
}

// MARK: - Agitate Slide
struct AgitateSlide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Illustration
                AgitateIllustration()
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)

                Text("onboarding_agitate_label")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)

                Text("onboarding_agitate_title")
                    .font(.custom(.oswald.bold, size: 35))
                    .textCase(.uppercase)
                    .tracking(0.35)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("onboarding_agitate_description")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }
}

struct AgitateIllustration: View {
    private let platforms = [
        ("NETFLIX", "#E50914", -70.0, 0.0, -8.0),
        ("MAX", "#5A35E0", 44.0, -16.0, 6.0),
        ("PRIME", "#1FB6FF", -20.0, 26.0, -3.0),
        ("HULU", "#1CE783", 78.0, 30.0, 9.0),
        ("APPLE TV+", "#A1A1AA", -84.0, 44.0, 5.0),
        ("DISNEY+", "#1FA2FF", 30.0, 58.0, -7.0)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<platforms.count, id: \.self) { index in
                let platform = platforms[index]
                Text(platform.0)
                    .font(.custom(.oswald.bold, size: 14))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .tracking(0.14)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#141416").opacity(0.9))
                    .cornerRadius(9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color(hex: platform.1), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: platform.1).opacity(0.3), radius: 9, x: 0, y: 3)
                    .offset(x: platform.2, y: platform.3)
                    .rotationEffect(.degrees(platform.4))
            }
        }
        .frame(height: 130)
    }
}

// MARK: - Solution Slide
struct SolutionSlide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Illustration
                SolutionIllustration()
                    .padding(.vertical, 26)

                Text("onboarding_solution_label")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)

                Text("onboarding_solution_title")
                    .font(.custom(.oswald.bold, size: CustomFont.size.display))
                    .textCase(.uppercase)
                    .tracking(0.42)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("onboarding_solution_description")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }
}

struct SolutionIllustration: View {
    private let items = [
        ("Ready in 4 days", true),
        ("Airing now", true),
        ("Premieres soon", false)
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<items.count, id: \.self) { index in
                HStack(spacing: 14) {
                    Circle()
                        .fill(items[index].1 ? Color(hex: "#2dd4bf") : Color(hex: "#0a0a0b"))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color(hex: "#2dd4bf").opacity(items[index].1 ? 0.0 : 0.5),
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    items[index].1 ? Color(hex: "#2dd4bf").opacity(0.14) : Color.clear,
                                    lineWidth: 10
                                )
                        )

                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 40)
                        .overlay(
                            HStack {
                                Text(items[index].0)
                                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                                    .foregroundColor(Color(hex: "#a1a1aa"))
                                    .textCase(.uppercase)
                                    .tracking(1.6)
                                    .padding(.leading, 14)
                                Spacer()
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Add Shows Step
struct AddShowsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedShow: ShowSummary?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("onboarding_add_shows_label")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .padding(.top, 12)

                Text("onboarding_add_shows_title")
                    .font(.custom(.oswald.bold, size: 36))
                    .textCase(.uppercase)
                    .tracking(0.36)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                Text("onboarding_add_shows_description")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(3)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)

                // Search bar
                SearchBar(text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                ))
                .padding(.bottom, 16)

                // Loading state
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "#2dd4bf"))
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let error = viewModel.error {
                    // Error state
                    VStack(spacing: 12) {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#a1a1aa"))
                            .multilineTextAlignment(.center)

                        Button("button_try_again") {
                            Task {
                                await viewModel.loadTrendingShows()
                            }
                        }
                        .font(.custom(.oswald.bold, size: 14))
                        .foregroundColor(Color(hex: "#2dd4bf"))
                    }
                    .padding(.vertical, 40)
                } else {
                    // Show grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                        ForEach(viewModel.displayedShows) { show in
                            OnboardingShowCard(
                                show: show,
                                isFollowing: viewModel.isSelected(show),
                                onTap: {
                                    selectedShow = show
                                },
                                onFollowTap: {
                                    viewModel.toggleSelection(show)
                                }
                            )
                            .id("\(show.id)-\(viewModel.isSelected(show))")
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 140)
        }
        .task {
            await viewModel.loadTrendingShows()
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(
                summary: show,
                isFollowing: viewModel.isSelected(show),
                onFollowTap: {
                    viewModel.toggleSelection(show)
                },
                onDismiss: {
                    selectedShow = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct OnboardingShowCard: View {
    let show: ShowSummary
    let isFollowing: Bool
    let onTap: () -> Void
    let onFollowTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster with follow button overlay
            ZStack(alignment: .topLeading) {
                // Tappable poster area
                Button(action: onTap) {
                    AsyncImage(url: show.posterSmallURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                                .overlay(
                                    ProgressView()
                                        .tint(Color(hex: "#71717a"))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "tv")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "#71717a"))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color(hex: "#1a1a1c"))
                                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                }

                // Follow button (top-left)
                Button(action: onFollowTap) {
                    ZStack {
                        Circle()
                            .fill(isFollowing ? Color.c2bTeal : Color.black.opacity(0.6))
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFollowing ? Color(hex: "#04201c") : .white)
                    }
                }
                .padding(7)
            }

            // Title
            Text(show.name)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(Color(hex: "#f4f4f5"))
                .lineLimit(1)
                .padding(.top, 9)

            // Year
            Text(show.yearString ?? "TBA")
                .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                .foregroundColor(isFollowing ? Color(hex: "#5eead4") : Color(hex: "#71717a"))
                .textCase(.uppercase)
                .tracking(1.6)
                .padding(.top, 4)
        }
        .padding(9)
        .background(
            isFollowing ? Color(hex: "#2dd4bf").opacity(0.06) : Color.white.opacity(0.03)
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    isFollowing ? Color(hex: "#2dd4bf").opacity(0.40) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Review Selection Step
struct ReviewSelectionStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("onboarding_review_title")
                            .font(.custom(.oswald.bold, size: 40))
                            .textCase(.uppercase)
                            .tracking(0.40)
                            .foregroundColor(Color(hex: "#f4f4f5"))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // Show count badge
                    Text(String(localized: "onboarding_shows_count \(viewModel.selectedCount)"))
                        .font(.custom(.oswald.bold, size: 14))
                        .foregroundColor(Color(hex: "#04201c"))
                        .textCase(.uppercase)
                        .tracking(0.14)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#2dd4bf"))
                        .cornerRadius(999)
                }
                .padding(.top, 12)
                .padding(.bottom, 16)

                Text("onboarding_review_description")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 20)

                // Show cards
                VStack(spacing: 12) {
                    ForEach(viewModel.getSelectedShows()) { show in
                        ReviewShowCard(
                            show: show,
                            onRemove: {
                                viewModel.toggleSelection(show)
                            }
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }
}

struct ReviewShowCard: View {
    let show: ShowSummary
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: show.posterSmallURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                        .overlay(
                            ProgressView()
                                .tint(Color(hex: "#71717a"))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                        .overlay(
                            Image(systemName: "tv")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#71717a"))
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(show.name.uppercased())
                    .font(.custom(.oswald.bold, size: CustomFont.size.subheading))
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .textCase(.uppercase)
                    .tracking(0.18)
                    .lineLimit(1)

                Text(show.yearString ?? "TBA")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                    .foregroundColor(Color(hex: "#71717a"))
                    .textCase(.uppercase)
                    .tracking(1.6)
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 40, height: 40)

                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        .frame(width: 40, height: 40)

                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#cfcfcf"))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - All Set Step
struct AllSetStep: View {
    let shows: [ShowSummary]

    private var followedCount: Int {
        shows.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Split image with checkmark
                if shows.count >= 2 {
                    GeometryReader { geometry in
                        ZStack {
                            HStack(spacing: 0) {
                                AsyncImage(url: shows[0].posterURL) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle()
                                            .fill(Color(hex: "#1a1a1c"))
                                    }
                                }
                                .frame(width: (geometry.size.width - 44) * 0.5, height: 240)
                                .clipped()

                                AsyncImage(url: shows[1].posterURL) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle()
                                            .fill(Color(hex: "#1a1a1c"))
                                    }
                                }
                                .frame(width: (geometry.size.width - 44) * 0.5, height: 240)
                                .clipped()
                            }
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Checkmark overlay
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#2dd4bf"))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(hex: "#2dd4bf").opacity(0.4), radius: 16, x: 0, y: 6)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color(hex: "#04201c"))
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .frame(height: 240)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }

                // Title
                Text("onboarding_all_set_title")
                    .font(.custom(.oswald.bold, size: 44))
                    .textCase(.uppercase)
                    .tracking(0.44)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                // Description
                Text(String(localized: "onboarding_all_set_description \(followedCount)"))
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)

                // Following label
                Text("onboarding_following")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)

                // Show grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(shows) { show in
                        AllSetShowCard(show: show)
                    }
                }
                .padding(.horizontal, 22)

                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
    }
}

struct AllSetShowCard: View {
    let show: ShowSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster
            AsyncImage(url: show.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .tint(Color(hex: "#71717a"))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .overlay(
                            Image(systemName: "tv")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#71717a"))
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(hex: "#1a1a1c"))
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

            // Title
            Text(show.name)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(Color(hex: "#f4f4f5"))
                .lineLimit(1)
        }
    }
}

// MARK: - Paywall Step
struct PaywallStep: View {
    let followedCount: Int
    @Binding var selectedPlan: String

    private let plans = [
        ("yearly", "Pro Yearly", "$9.99", "/yr", "Best value · save 44%", true),
        ("monthly", "Pro Monthly", "$1.49", "/mo", "Billed monthly", false),
        ("lifetime", "Pro Lifetime", "$29.99", "", "One-time purchase", false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("onboarding_choose_plan")
                    .font(.custom(.jetbrains.bold, size: CustomFont.size.base))
                    .foregroundColor(Color(hex: "#2dd4bf"))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .padding(.top, 12)

                Text("onboarding_never_miss")
                    .font(.custom(.oswald.bold, size: CustomFont.size.title))
                    .textCase(.uppercase)
                    .tracking(0.34)
                    .foregroundColor(Color(hex: "#f4f4f5"))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                Text(String(localized: "paywall_tracking_shows \(followedCount)"))
                    .font(.system(size: 13.5, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "#a1a1aa"))
                    .lineSpacing(3)
                    .padding(.bottom, 18)

                // Plan cards
                VStack(spacing: 11) {
                    ForEach(0..<plans.count, id: \.self) { index in
                        PlanCard(
                            id: plans[index].0,
                            name: plans[index].1,
                            price: plans[index].2,
                            period: plans[index].3,
                            note: plans[index].4,
                            isBest: plans[index].5,
                            isSelected: selectedPlan == plans[index].0,
                            onSelect: { selectedPlan = plans[index].0 }
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 140)
        }
    }
}

struct PlanCard: View {
    let id: String
    let name: String
    let price: String
    let period: String
    let note: String
    let isBest: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color(hex: "#2dd4bf") : Color.white.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#2dd4bf"))
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#04201c"))
                    }
                }

                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.custom(.oswald.bold, size: CustomFont.size.subheading))
                            .foregroundColor(Color(hex: "#f4f4f5"))
                            .textCase(.uppercase)
                            .tracking(0.18)

                        if isBest {
                            Text("paywall_best")
                                .font(.custom(.jetbrains.bold, size: 8))
                                .foregroundColor(Color(hex: "#04201c"))
                                .textCase(.uppercase)
                                .tracking(1.6)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#5eead4"))
                                .cornerRadius(5)
                        }
                    }

                    Text(note)
                        .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                        .foregroundColor(id == "free" ? Color(hex: "#71717a") : Color(hex: "#2dd4bf"))
                        .textCase(.uppercase)
                        .tracking(1.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Price
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Text(price)
                            .font(.custom(.oswald.bold, size: CustomFont.size.xl2))
                            .foregroundColor(Color(hex: "#f4f4f5"))
                            .textCase(.uppercase)
                            .tracking(0.22)
                        Text(period)
                            .font(.custom(.jetbrains.bold, size: CustomFont.size.label))
                            .foregroundColor(Color(hex: "#71717a"))
                            .textCase(.uppercase)
                            .tracking(1.6)
                    }
                }
            }
            .padding(16)
            .background(
                isSelected ? Color(hex: "#2dd4bf").opacity(0.08) : Color.white.opacity(0.03)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color(hex: "#2dd4bf") : Color.white.opacity(0.09),
                        lineWidth: 1.5
                    )
            )
        }
    }
}
