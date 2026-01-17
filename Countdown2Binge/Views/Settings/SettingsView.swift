//
//  SettingsView.swift
//  Countdown2Binge
//

import SwiftUI

/// Settings page for app preferences
struct SettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    // MARK: - Timeline Section
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Countdown Display")
                                    .foregroundStyle(.white)
                                Text("Show days or episodes until finale on timeline")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Picker("Countdown Display", selection: $settings.countdownDisplayMode) {
                                ForEach(CountdownDisplayMode.allCases, id: \.self) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                            .accessibilityLabel("Countdown display mode")
                            .accessibilityHint("Choose between showing days or episodes until finale")
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("TIMELINE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.5))
                            .accessibilityAddTraits(.isHeader)
                    }

                    // MARK: - Binge Ready Section
                    Section {
                        Toggle(isOn: $settings.showAiringSeasonsInBingeReady) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show Airing Seasons")
                                    .foregroundStyle(.white)
                                Text("Include currently airing seasons in Binge Ready")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .tint(Color(red: 0.45, green: 0.90, blue: 0.70))
                        .listRowBackground(Color.white.opacity(0.05))
                        .accessibilityLabel("Show airing seasons in Binge Ready")
                        .accessibilityHint("When enabled, currently airing seasons will appear in the Binge Ready list")
                    } header: {
                        Text("BINGE READY")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.5))
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text("SETTINGS")
                        .font(.system(size: 36, weight: .heavy, design: .default).width(.condensed))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
