# Notification System Design — Phase 1 (Revised)

## Scope — Exactly 4 Types

| Type | Approach | Timing |
|------|----------|--------|
| Season Premiere | Date-scheduled | 9 AM on premiere day |
| Finale Reminder | Date-scheduled | Day-of / 1 / 2 / 7 days before (user setting) |
| Binge Ready | Date-scheduled | finaleDate + grace window (2 days), NO lead-time option |
| New Season Announced | Event-driven | Fires ONCE when season first appears |

**CUT entirely:**
- ~~New Episodes~~ — permanently out of scope
- ~~Finale Announced~~ — no user notification (but pending→airing detection kept internal for scheduling finale/bingeReady)

---

## 1. Data Types

```swift
// Input: extracted from Series
struct ShowDateInfo {
    let showId: Int
    let showName: String
    let currentSeasonNumber: Int?
    let premiereDate: Date?
    let finaleDate: Date?        // nil if pending (no confirmed finale)
}

// Output: what to schedule
struct NotificationPlan: Equatable {
    let identifier: String       // stable key: "show-123-finale-s2"
    let type: NotificationType
    let showId: Int
    let showName: String
    let fireDate: Date
    let seasonNumber: Int?
}

enum NotificationType: String, Codable, CaseIterable {
    case premiere
    case finale
    case bingeReady
    case newSeason
}
```

---

## 2. Settings Model (Global Only)

**Single global settings object. No per-show lookup.**

```swift
struct NotificationSettings: Codable, Equatable {
    var seasonPremiere: Bool = true
    var finaleReminder: Bool = true
    var finaleTiming: FinaleReminderTiming = .oneDayBefore
    var bingeReady: Bool = true
    var newSeason: Bool = true

    static let `default` = NotificationSettings()
}

// Storage: single global instance
@MainActor
final class NotificationSettingsStore: ObservableObject {
    static let shared = NotificationSettingsStore()

    private let key = "c2b_notification_settings"

    @Published var settings: NotificationSettings {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
```

**Removed:** `settings(for: showId)`, per-show overrides, `showSettings` dictionary.

---

## 3. Pure Planning Function

```swift
/// Pure, testable function. No side effects.
/// Given dates + settings + now → returns what SHOULD be scheduled.
func planNotifications(
    dates: ShowDateInfo,
    settings: NotificationSettings,
    now: Date,
    graceWindowDays: Int = 2
) -> [NotificationPlan] {
    var plans: [NotificationPlan] = []

    guard let seasonNum = dates.currentSeasonNumber else { return plans }

    // PREMIERE — if enabled, date exists, date is in future
    if settings.seasonPremiere,
       let premiere = dates.premiereDate,
       premiere > now {
        plans.append(NotificationPlan(
            identifier: "show-\(dates.showId)-premiere-s\(seasonNum)",
            type: .premiere,
            showId: dates.showId,
            showName: dates.showName,
            fireDate: premiere,
            seasonNumber: seasonNum
        ))
    }

    // FINALE — if enabled, date exists, reminder date is in future
    if settings.finaleReminder,
       let finale = dates.finaleDate {
        let reminderDate = settings.finaleTiming.reminderDate(before: finale)
        if reminderDate > now {
            plans.append(NotificationPlan(
                identifier: "show-\(dates.showId)-finale-s\(seasonNum)",
                type: .finale,
                showId: dates.showId,
                showName: dates.showName,
                fireDate: reminderDate,
                seasonNumber: seasonNum
            ))
        }
    }

    // BINGE READY — if enabled, finale date exists, binge date is in future
    // Timing: finaleDate + grace window. NO user offset.
    if settings.bingeReady,
       let finale = dates.finaleDate {
        let bingeDate = Calendar.current.date(
            byAdding: .day, value: graceWindowDays, to: finale
        )!
        if bingeDate > now {
            plans.append(NotificationPlan(
                identifier: "show-\(dates.showId)-bingeready-s\(seasonNum)",
                type: .bingeReady,
                showId: dates.showId,
                showName: dates.showName,
                fireDate: bingeDate,
                seasonNumber: seasonNum
            ))
        }
    }

    // NOTE: newSeason is event-driven, not planned here.
    // It fires once on detection in refresh/follow.

    return plans
}
```

---

## 4. Date Extraction from Series

```swift
/// Extract notification-relevant dates from Series.
/// Uses BingeEngine for currentSeason and conservative finale detection.
func extractDateInfo(from series: Series, now: Date) -> ShowDateInfo {
    let facts = series.regularSeasons.map { season in
        BingeEngine.SeasonFact(
            seasonNumber: season.seasonNumber,
            episodes: season.episodeFacts,
            hasWatched: season.hasWatched
        )
    }

    let currentSeason = BingeEngine.currentSeason(seasons: facts, now: now)

    let premiereDate: Date? = {
        guard let num = currentSeason?.seasonNumber,
              let season = series.regularSeasons.first(where: { $0.seasonNumber == num })
        else { return nil }
        return season.episodes.compactMap { $0.airDate }.min()
    }()

    // Conservative finale: only if BingeEngine confirms it
    let finaleDate: Date? = {
        guard let num = currentSeason?.seasonNumber,
              let season = series.regularSeasons.first(where: { $0.seasonNumber == num })
        else { return nil }
        return BingeEngine.finaleEpisode(from: season.episodeFacts)?.airDate
    }()

    return ShowDateInfo(
        showId: series.id,
        showName: series.name,
        currentSeasonNumber: currentSeason?.seasonNumber,
        premiereDate: premiereDate,
        finaleDate: finaleDate
    )
}
```

---

## 5. Schedule-Once / Update-Only-On-Change Logic

**Key insight:** Don't rebuild all notifications on every refresh. Only touch what changed.

```swift
/// Manages scheduling with change detection.
/// Returns the set of notification identifiers currently scheduled for a show.
actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    /// Get all scheduled notification identifiers for a show
    func scheduledIdentifiers(for showId: Int) async -> Set<String> {
        let pending = await center.pendingNotificationRequests()
        return Set(pending
            .filter { $0.identifier.hasPrefix("show-\(showId)-") }
            .map { $0.identifier }
        )
    }

    /// Get the fire date for a scheduled notification (nil if not scheduled)
    func scheduledFireDate(for identifier: String) async -> Date? {
        let pending = await center.pendingNotificationRequests()
        guard let request = pending.first(where: { $0.identifier == identifier }),
              let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let nextDate = trigger.nextTriggerDate()
        else { return nil }
        return nextDate
    }

    /// Apply a set of plans, only changing what's different
    func applyPlans(
        _ plans: [NotificationPlan],
        for showId: Int,
        settings: NotificationSettings
    ) async {
        // Build map of what SHOULD exist: identifier → fireDate
        let desired: [String: Date] = Dictionary(
            uniqueKeysWithValues: plans.map { ($0.identifier, $0.fireDate) }
        )

        // Get what currently exists
        let pending = await center.pendingNotificationRequests()
        let existing: [String: Date] = Dictionary(uniqueKeysWithValues:
            pending
                .filter { $0.identifier.hasPrefix("show-\(showId)-") }
                .compactMap { request -> (String, Date)? in
                    guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                          let date = trigger.nextTriggerDate()
                    else { return nil }
                    return (request.identifier, date)
                }
        )

        // Compare and act
        var toCancel: [String] = []
        var toAdd: [NotificationPlan] = []

        // Check each desired notification
        for plan in plans {
            if let existingDate = existing[plan.identifier] {
                // Already scheduled — check if date changed
                if !Calendar.current.isDate(existingDate, inSameDayAs: plan.fireDate) {
                    // Date changed: cancel old, add new
                    toCancel.append(plan.identifier)
                    toAdd.append(plan)
                }
                // Same date: leave it alone
            } else {
                // Not scheduled yet: add it
                toAdd.append(plan)
            }
        }

        // Check for notifications that should no longer exist
        // (e.g., show state changed, setting disabled)
        for identifier in existing.keys {
            if desired[identifier] == nil {
                toCancel.append(identifier)
            }
        }

        // Execute changes
        if !toCancel.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: toCancel)
        }

        for plan in toAdd {
            await scheduleOne(plan)
        }
    }

    /// Schedule a single notification
    private func scheduleOne(_ plan: NotificationPlan) async {
        let content = UNMutableNotificationContent()
        content.title = title(for: plan)
        content.body = body(for: plan)
        content.sound = .default
        content.userInfo = [
            "showId": plan.showId,
            "type": plan.type.rawValue
        ]

        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: plan.fireDate
        )
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Fire an immediate notification (for newSeason)
    func fireImmediate(_ plan: NotificationPlan) async {
        let content = UNMutableNotificationContent()
        content.title = title(for: plan)
        content.body = body(for: plan)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func title(for plan: NotificationPlan) -> String {
        switch plan.type {
        case .premiere:
            return String(localized: "notif_premiere_title")
        case .finale:
            return String(localized: "notif_finale_title")
        case .bingeReady:
            return String(localized: "notif_bingeready_title")
        case .newSeason:
            return String(localized: "notif_newseason_title")
        }
    }

    private func body(for plan: NotificationPlan) -> String {
        switch plan.type {
        case .premiere:
            return String(localized: "notif_premiere_body \(plan.showName)")
        case .finale:
            return String(localized: "notif_finale_body \(plan.showName)")
        case .bingeReady:
            return String(localized: "notif_bingeready_body \(plan.showName)")
        case .newSeason:
            return String(localized: "notif_newseason_body \(plan.showName) \(plan.seasonNumber ?? 0)")
        }
    }
}
```

---

## 6. New Season Fires Exactly Once — Proof

```swift
/// Called from refresh() to handle newSeason event notification.
/// Fires ONCE when the season first appears, never again.
func handleNewSeasonEvent(
    series: Series,
    oldSeasonNumbers: Set<Int>,
    newSeasonNumbers: Set<Int>,
    settings: NotificationSettings,
    scheduler: NotificationScheduler
) async {
    guard settings.newSeason else { return }

    // Seasons that exist NOW but did NOT exist BEFORE this refresh
    let addedSeasons = newSeasonNumbers.subtracting(oldSeasonNumbers)

    for seasonNum in addedSeasons {
        let identifier = "show-\(series.id)-newseason-s\(seasonNum)"

        // Check if we've already fired this notification
        // (handles edge case: app killed mid-refresh, re-runs)
        let alreadyFired = await scheduler.scheduledIdentifiers(for: series.id)
            .contains(identifier)

        // Also check delivered notifications to be safe
        let delivered = await UNUserNotificationCenter.current()
            .deliveredNotifications()
            .contains { $0.request.identifier == identifier }

        if alreadyFired || delivered {
            continue  // Already fired, skip
        }

        // Fire immediately (event-driven, not date-scheduled)
        let plan = NotificationPlan(
            identifier: identifier,
            type: .newSeason,
            showId: series.id,
            showName: series.name,
            fireDate: Date(),
            seasonNumber: seasonNum
        )
        await scheduler.fireImmediate(plan)
    }
}
```

**Why it fires exactly once:**

1. **First refresh that sees the new season:** `addedSeasons` contains the new season number → fires notification
2. **Second refresh:** `oldSeasonNumbers` now includes the season (from the previous refresh's "after" state, which becomes this refresh's "before" state) → `addedSeasons` is empty → nothing fires
3. **Edge case (app killed):** We also check `scheduledIdentifiers` and `deliveredNotifications` to avoid double-fire

---

## 7. Premium Gate

```swift
/// Main entry point from refresh() and follow().
func scheduleNotificationsForShow(
    series: Series,
    oldSeasonNumbers: Set<Int>,
    newSeasonNumbers: Set<Int>,
    now: Date = Date()
) async {
    // ═══════════════════════════════════════════════════════════════
    // PREMIUM GATE — free users get no notifications
    // ═══════════════════════════════════════════════════════════════
    guard await PremiumManager.shared.isPremium else { return }

    // ═══════════════════════════════════════════════════════════════
    // PERMISSION CHECK
    // ═══════════════════════════════════════════════════════════════
    guard await NotificationService.shared.isAuthorized else { return }

    // ═══════════════════════════════════════════════════════════════
    // GLOBAL SETTINGS (no per-show lookup)
    // ═══════════════════════════════════════════════════════════════
    let settings = await NotificationSettingsStore.shared.settings

    let scheduler = NotificationScheduler()

    // ═══════════════════════════════════════════════════════════════
    // DATE-SCHEDULED NOTIFICATIONS (premiere, finale, bingeReady)
    // Schedule-once / update-only-on-change
    // ═══════════════════════════════════════════════════════════════
    let dates = extractDateInfo(from: series, now: now)
    let plans = planNotifications(dates: dates, settings: settings, now: now)
    await scheduler.applyPlans(plans, for: series.id, settings: settings)

    // ═══════════════════════════════════════════════════════════════
    // EVENT-DRIVEN: New Season (fires once on detection)
    // ═══════════════════════════════════════════════════════════════
    await handleNewSeasonEvent(
        series: series,
        oldSeasonNumbers: oldSeasonNumbers,
        newSeasonNumbers: newSeasonNumbers,
        settings: settings,
        scheduler: scheduler
    )
}
```

---

## 8. Refresh Integration (with `now` threaded)

```swift
func refresh(id: Int, force: Bool = false, now: Date = Date()) async {
    guard let s = series(id: id) else { return }

    if !force, let last = s.lastRefreshedAt,
       now.timeIntervalSince(last) < refreshInterval {
        return
    }

    // ═══════════════════════════════════════════════════════════════
    // BEFORE UPDATE: snapshot for change detection
    // ═══════════════════════════════════════════════════════════════
    let oldSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

    // ═══════════════════════════════════════════════════════════════
    // APPLY UPDATE
    // ═══════════════════════════════════════════════════════════════
    do {
        let show = try await tmdb.getShowDetails(id: id)
        SeriesMapper.update(s, from: show, in: context)
        s.lastRefreshedAt = now

        // ... existing hasWatched recalculation (uses `now`) ...

        // ═══════════════════════════════════════════════════════════
        // SCHEDULE NOTIFICATIONS (premium-gated, change-detection)
        // ═══════════════════════════════════════════════════════════
        let newSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

        await scheduleNotificationsForShow(
            series: s,
            oldSeasonNumbers: oldSeasonNumbers,
            newSeasonNumbers: newSeasonNumbers,
            now: now
        )

        try context.save()
    } catch { }
}
```

---

## 9. Follow Integration

```swift
func follow(showData: ShowData) throws -> FollowResult {
    // ... existing follow logic ...

    let newSeries = SeriesMapper.makeSeries(from: showData, in: context)
    newSeries.lastRefreshedAt = .now
    try context.save()

    // Schedule notifications immediately on follow
    let seriesId = newSeries.id
    let seasonNumbers = Set(newSeries.regularSeasons.map { $0.seasonNumber })

    launchBackgroundTask { [container] in
        let bgContext = ModelContext(container)
        let descriptor = FetchDescriptor<Series>(
            predicate: #Predicate { $0.id == seriesId }
        )
        guard let series = try? bgContext.fetch(descriptor).first else { return }

        await scheduleNotificationsForShow(
            series: series,
            oldSeasonNumbers: [],  // no prior seasons on fresh follow
            newSeasonNumbers: seasonNumbers,
            now: Date()
        )
    }

    // ... rest of follow ...
}
```

---

## Summary of Changes from Prior Design

| Item | Prior | Now |
|------|-------|-----|
| Notification types | 5 (+ newEpisodes) | 4 exactly |
| finaleAnnounced | User notification | CUT (internal only) |
| newEpisodes | In scope | CUT permanently |
| Settings | Per-show with fallback | Global only |
| Premium gate | Question | Required check |
| Rebuild strategy | Full rebuild every refresh | Schedule-once, update-only-on-change |
| `now` parameter | Used `Date()` directly | Threaded through for testability |
| New Season fires | Unclear | Exactly once, proven |

---

## Awaiting Approval

Ready to build when approved. Tests are Phase 2, separate.
