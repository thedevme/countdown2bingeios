//
//  TastePreferencesEditorView.swift
//  Countdown2Binge
//
//  Edit taste preferences after onboarding. Works in onboarding-option-ID space
//  and saves through the SAME path onboarding uses
//  (TastePreferencesStore.applyFromOnboarding), so resolution/refinement stays in
//  one place. Saving invalidates cached recommendations so rails refetch.
//

import SwiftUI

struct TastePreferencesEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let data = OnboardingDataLoader.shared
    private let store = TastePreferencesStore.shared

    @State private var genres: Set<String> = []
    @State private var services: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if let q = data.genresQuestion {
                    section(title: String(localized: "settings_taste_genres"), allIDs: q.options.map(\.id), selection: $genres) {
                        chips(options: q.options, selection: $genres)
                    }
                }

                if let q = data.servicesQuestion {
                    section(title: String(localized: "settings_taste_services"), allIDs: q.options.map(\.id), selection: $services) {
                        chips(options: q.options, selection: $services)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(Color.c2bBackground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { saveBar }
        .onAppear(perform: seedFromStore)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "settings_taste_title"))
                .font(.custom(.oswald.bold, size: 27))
                .tracking(0.54)
                .foregroundColor(.white)
            Text(String(localized: "settings_taste_desc"))
                .font(.system(size: 14))
                .foregroundColor(.c2bDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func section(title: String, allIDs: [String], selection: Binding<Set<String>>,
                         @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.custom(.jetbrains.bold, size: 10))
                    .tracking(1.2)
                    .foregroundColor(.c2bMuted)
                Spacer()
                Button {
                    let all = Set(allIDs)
                    if all.isSubset(of: selection.wrappedValue) {
                        selection.wrappedValue.subtract(all)
                    } else {
                        selection.wrappedValue.formUnion(all)
                    }
                } label: {
                    Text(String(localized: Set(allIDs).isSubset(of: selection.wrappedValue) ? "onboarding_clear_all" : "onboarding_select_all"))
                        .font(.custom(.jetbrains.bold, size: 10))
                        .tracking(1.0)
                        .foregroundColor(.c2bTeal)
                }
                .buttonStyle(.plain)
            }
            content()
        }
    }

    private func chips(options: [QuestionOption], selection: Binding<Set<String>>) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                let on = selection.wrappedValue.contains(option.id)
                Button {
                    if on { selection.wrappedValue.remove(option.id) }
                    else { selection.wrappedValue.insert(option.id) }
                } label: {
                    Text(option.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(on ? .c2bOnTeal : .c2bDim)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(on ? Color.c2bTeal : Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(on ? Color.c2bTeal : Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var saveBar: some View {
        Button(action: save) {
            Text(String(localized: "settings_taste_save"))
                .font(.custom(.oswald.bold, size: 17))
                .tracking(0.51)
                .foregroundColor(.c2bOnTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.c2bTeal)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
    }

    // MARK: - Load / Save

    private func seedFromStore() {
        let prefs = store.preferences
        // Reverse-map TMDB IDs → onboarding option IDs to pre-select chips.
        genres = Set(TasteCatalog.genres.filter { prefs.genreIDs.contains($0.tmdbId) }.map(\.onboardingId))
        services = Set(TasteCatalog.providers.compactMap { provider in
            guard let fallback = provider.fallbackTmdbId, prefs.providerIDs.contains(fallback) else { return nil }
            return provider.onboardingId
        })
    }

    private func save() {
        store.applyFromOnboarding(genreOptionIDs: genres, serviceOptionIDs: services)
        RecommendationService.shared.invalidate()
        dismiss()
    }
}
