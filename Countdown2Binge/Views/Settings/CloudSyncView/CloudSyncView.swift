//
//  CloudSyncView.swift
//  Countdown2Binge
//
//  iCloud sync management screen showing all followed shows
//  with their sync status. Premium users can edit sync state.
//

import SwiftUI
import SwiftData

struct CloudSyncView: View {
    @Query(sort: \Series.dateAdded, order: .reverse) private var allSeries: [Series]
    @Environment(SeriesManager.self) private var seriesManager
    @Environment(\.dismiss) private var dismiss

    private var premiumManager: PremiumManager { PremiumManager.shared }

    @State private var viewModel = CloudSyncViewModel()

    // Computed from @Query (auto-updates)
    private var syncedCount: Int { allSeries.filter { $0.isSynced }.count }

    #if DEBUG
    @State private var previewAsPremium = true
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                #if DEBUG
                // Debug toggle
                debugToggle
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 16)
                #endif

                // Status card
                CloudSyncStatusCard(
                    isPremium: effectivePremium,
                    syncedCount: syncedCount
                )
                .padding(.horizontal, C2BLayout.horizontalPadding)
                .padding(.bottom, 16)

                // Upsell card (free only)
                if !effectivePremium {
                    CloudSyncUpsellCard {
                        // TODO: Navigate to paywall
                    }
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 16)
                }

                // Section header
                CloudSyncSectionHeader(
                    isEditMode: viewModel.isEditMode,
                    isPremium: effectivePremium
                )
                .padding(.horizontal, C2BLayout.horizontalPadding)
                .padding(.bottom, 12)

                // Show grid
                CloudSyncShowGrid(
                    shows: allSeries,
                    isPremium: effectivePremium,
                    isEditMode: viewModel.isEditMode,
                    onRemove: { series in
                        viewModel.removeFromCloud(series: series, seriesManager: seriesManager)
                    }
                )
                .padding(.horizontal, C2BLayout.horizontalPadding)
                .padding(.bottom, 24)

                // Footer text
                footerText
                    .padding(.horizontal, C2BLayout.horizontalPadding)
                    .padding(.bottom, 100)
            }
        }
        .background(Color.c2bBackground)
        .gesture(
            // Long press to enter edit mode (premium only)
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if effectivePremium && !viewModel.isEditMode {
                        viewModel.toggleEditMode()
                    }
                }
        )
        .onAppear {
            viewModel.configure(premiumManager: premiumManager)
        }
    }

    // MARK: - Effective Premium (respects debug toggle)

    private var effectivePremium: Bool {
        #if DEBUG
        return previewAsPremium
        #else
        return premiumManager.isPremium
        #endif
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                DirectionalIcon(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(22)
            }

            Spacer()

            Text("CLOUD SYNC")
                .font(.custom(.oswald.bold, size: 20))
                .foregroundColor(.white)
                .tracking(1.2)

            Spacer()

            // Done button (edit mode) or placeholder
            if viewModel.isEditMode {
                Button(action: { viewModel.exitEditMode() }) {
                    Text("DONE")
                        .font(.custom(.oswald.bold, size: 14))
                        .foregroundColor(.c2bTeal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.c2bTeal.opacity(0.15))
                        .cornerRadius(8)
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, C2BLayout.horizontalPadding)
    }

    // MARK: - Debug Toggle

    #if DEBUG
    private var debugToggle: some View {
        HStack {
            Text(previewAsPremium ? "PREVIEW AS PREMIUM" : "PREVIEW AS FREE")
                .font(.custom(.jetbrains.regular, size: 9))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            Spacer()

            Toggle("", isOn: $previewAsPremium)
                .labelsHidden()
                .tint(.c2bTeal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    #endif

    // MARK: - Footer

    private var footerText: some View {
        Text(effectivePremium ? premiumFooter : freeFooter)
            .font(.custom(.jetbrains.regular, size: 10))
            .foregroundColor(.white.opacity(0.35))
            .multilineTextAlignment(.center)
            .tracking(0.3)
    }

    private var premiumFooter: String {
        "Removing a show from iCloud deletes its backup on every device. It stays on this device until you unfollow it."
    }

    private var freeFooter: String {
        "Without Premium your shows live only on this device — reinstall or switch phones and they're gone."
    }
}

#Preview {
    ZStack {
        Color.c2bBackground.ignoresSafeArea()
        Text("Preview requires app context")
            .foregroundColor(.white.opacity(0.5))
    }
}
