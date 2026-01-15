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
                            Picker("", selection: $settings.countdownDisplayMode) {
                                ForEach(CountdownDisplayMode.allCases, id: \.self) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("TIMELINE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.5))
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
                    } header: {
                        Text("BINGE READY")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
