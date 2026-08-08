//
//  TastePreferencesStore.swift
//  Countdown2Binge
//
//  Persists TastePreferences. UserDefaults is the authoritative LOCAL source of
//  truth (so onboarding on a device with no iCloud account can never lose or
//  silently discard the answers); NSUbiquitousKeyValueStore is the cross-device
//  MIRROR. Same KVS mechanism as CloudSettingsStore — not a new one.
//
//  Write order: UserDefaults first, then mirror to KVS. External KVS changes are
//  adopted back into UserDefaults. On init: read UserDefaults; seed from KVS only
//  if local is empty.
//

import Foundation

@MainActor
@Observable
final class TastePreferencesStore {
    static let shared = TastePreferencesStore()

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default
    private static let key = "tastePreferences.v1"

    /// The live preferences. Setting mirrors to both stores.
    private(set) var preferences: TastePreferences {
        didSet { persist(preferences) }
    }

    /// Bumped whenever preferences change so caches can invalidate.
    private(set) var revision: Int = 0

    private init() {
        // Local is authoritative; fall back to the iCloud mirror only if local is empty.
        if let local = Self.decode(defaults.data(forKey: Self.key)) {
            preferences = local
        } else if let mirrored = Self.decode(cloud.data(forKey: Self.key)) {
            preferences = mirrored
            defaults.set(cloud.data(forKey: Self.key), forKey: Self.key) // adopt into local
        } else {
            preferences = .empty
        }

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.adoptFromCloud() }
        }
    }

    // MARK: - Mutations

    /// Replace preferences wholesale (Settings editor, onboarding completion).
    func update(_ prefs: TastePreferences) {
        guard prefs != preferences else { return }
        preferences = prefs
        revision &+= 1
    }

    /// Resolve onboarding's string option IDs into TMDB IDs and persist.
    /// Genres map synchronously (fixed table). Providers use the offline fallback
    /// immediately so nothing is lost, then refine against the live catalog.
    func applyFromOnboarding(genreOptionIDs: Set<String>,
                             serviceOptionIDs: Set<String>,
                             region: String = TastePreferences.defaultRegion) {
        let genres = TasteCatalog.tmdbGenreIDs(for: genreOptionIDs)
        let fallbackProviders = TasteCatalog.fallbackProviderIDs(for: serviceOptionIDs)
        update(TastePreferences(
            genreIDs: genres,
            providerIDs: fallbackProviders,
            watchRegion: region,
            completedPreferenceStep: true
        ))

        // Refine provider IDs against the live /watch/providers/tv catalog.
        Task { [weak self] in
            let resolved = await WatchProviderCatalog.shared.resolveProviderIDs(
                serviceOptionIDs: serviceOptionIDs, region: region
            )
            guard let self, !resolved.isEmpty else { return }
            var refined = self.preferences
            refined.providerIDs = resolved
            self.update(refined)
        }
    }

    func reset() {
        update(.empty)
    }

    // MARK: - Persistence

    private func persist(_ prefs: TastePreferences) {
        let data = try? JSONEncoder().encode(prefs)
        defaults.set(data, forKey: Self.key)      // authoritative local write first
        cloud.set(data, forKey: Self.key)         // cross-device mirror
        cloud.synchronize()
    }

    private func adoptFromCloud() {
        guard let mirrored = Self.decode(cloud.data(forKey: Self.key)),
              mirrored != preferences else { return }
        preferences = mirrored // didSet re-persists locally, keeping them aligned
        revision &+= 1
    }

    private static func decode(_ data: Data?) -> TastePreferences? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(TastePreferences.self, from: data)
    }
}
