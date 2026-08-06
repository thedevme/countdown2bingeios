# Phase 1 Complete — Notification System Build

**Status:** Build Clean ✓

---

## Final `planNotifications` (pure function)

```swift
// NotificationPlanner.swift

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

    // FINALE — if enabled, reminder date (computed from finaleDate) is in future
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

    // BINGE READY — finaleDate + graceWindowDays
    if settings.bingeReady,
       let finale = dates.finaleDate {
        let bingeDate = Calendar.current.date(byAdding: .day, value: graceWindowDays, to: finale)!
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

## Schedule/Update/Cancel Logic (actor)

```swift
// NotificationScheduler — actor for thread safety

actor NotificationScheduler {
    private let center = UNUserNotificationCenter.current()

    /// Apply plans with change detection, scoped to THIS show's prefix only
    func applyPlans(_ plans: [NotificationPlan], for showId: Int) async {
        // Build map of what SHOULD exist
        let desired: [String: NotificationPlan] = Dictionary(
            uniqueKeysWithValues: plans.map { ($0.identifier, $0) }
        )

        // Get what currently exists FOR THIS SHOW ONLY
        let prefix = "show-\(showId)-"
        let pending = await center.pendingNotificationRequests()
        let existing: [String: Date] = Dictionary(uniqueKeysWithValues:
            pending
                .filter { $0.identifier.hasPrefix(prefix) }
                .compactMap { request -> (String, Date)? in
                    guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                          let date = trigger.nextTriggerDate()
                    else { return nil }
                    return (request.identifier, date)
                }
        )

        var toCancel: [String] = []
        var toAdd: [NotificationPlan] = []

        // Check each desired notification
        for plan in plans {
            if let existingDate = existing[plan.identifier] {
                // Already scheduled — check if date changed (same day = leave it)
                if !Calendar.current.isDate(existingDate, inSameDayAs: plan.fireDate) {
                    toCancel.append(plan.identifier)
                    toAdd.append(plan)
                }
            } else {
                // Not scheduled yet: add it
                toAdd.append(plan)
            }
        }

        // Check for notifications that should no longer exist (SCOPED TO THIS SHOW)
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

    /// Cancel all for a show (on unfollow)
    func cancelAll(for showId: Int) async {
        let prefix = "show-\(showId)-"
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }
        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    /// Check if newSeason already fired (dedup)
    func hasNewSeasonFired(showId: Int, seasonNumber: Int) async -> Bool {
        let identifier = "show-\(showId)-newseason-s\(seasonNumber)"
        let pending = await center.pendingNotificationRequests()
        if pending.contains(where: { $0.identifier == identifier }) { return true }
        let delivered = await center.deliveredNotifications()
        if delivered.contains(where: { $0.request.identifier == identifier }) { return true }
        return false
    }

    /// Fire immediate (for newSeason event)
    func fireImmediate(_ plan: NotificationPlan) async {
        let content = UNMutableNotificationContent()
        content.title = title(for: plan)
        content.body = body(for: plan)
        content.sound = .default
        content.userInfo = ["showId": plan.showId, "type": plan.type.rawValue]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: plan.identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
```

---

## SeriesManager Wiring

```swift
// MARK: - Notifications (Premium-gated)

/// Schedule notifications for a single show based on current dates and global settings.
private func scheduleNotificationsForShow(_ series: Series, now: Date) async {
    // Premium gate: free users get no notifications
    guard PremiumManager.shared.isPremium else { return }
    guard NotificationService.shared.isAuthorized else { return }

    let settings = NotificationSettingsStore.shared.settings
    let dateInfo = extractDateInfo(from: series, now: now)
    let plans = planNotifications(dates: dateInfo, settings: settings, now: now)
    await notificationScheduler.applyPlans(plans, for: series.id)
}

/// Detect and fire new season notifications (event-driven, fires once).
private func handleNewSeasonEvent(
    seriesId: Int,
    seriesName: String,
    oldSeasonNumbers: Set<Int>,
    newSeasonNumbers: Set<Int>,
    now: Date
) async {
    guard PremiumManager.shared.isPremium else { return }
    guard NotificationService.shared.isAuthorized else { return }

    let settings = NotificationSettingsStore.shared.settings
    guard settings.newSeason else { return }

    let addedSeasons = newSeasonNumbers.subtracting(oldSeasonNumbers)
    for seasonNumber in addedSeasons {
        let alreadyFired = await notificationScheduler.hasNewSeasonFired(
            showId: seriesId, seasonNumber: seasonNumber
        )
        guard !alreadyFired else { continue }

        let plan = NotificationPlan(
            identifier: "show-\(seriesId)-newseason-s\(seasonNumber)",
            type: .newSeason,
            showId: seriesId,
            showName: seriesName,
            fireDate: now,
            seasonNumber: seasonNumber
        )
        await notificationScheduler.fireImmediate(plan)
    }
}

/// Cancel all notifications for a show (called on unfollow).
private func cancelNotificationsForShow(_ showId: Int) async {
    await notificationScheduler.cancelAll(for: showId)
}
```

### refresh() Integration

```swift
func refresh(id: Int, force: Bool = false, now: Date = Date()) async {
    guard let s = series(id: id) else { return }
    // ... skip if fresh ...

    // Snapshot old season numbers for new-season detection
    let oldSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })
    let seriesName = s.name

    do {
        let show = try await tmdb.getShowDetails(id: id)
        SeriesMapper.update(s, from: show, in: context)
        s.lastRefreshedAt = now

        // ... hasWatched correction logic ...

        try context.save()

        // Snapshot new season numbers after update
        let newSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

        // Schedule notifications for this show (based on updated dates)
        await scheduleNotificationsForShow(s, now: now)

        // Detect and fire new-season event notifications
        await handleNewSeasonEvent(
            seriesId: id,
            seriesName: seriesName,
            oldSeasonNumbers: oldSeasonNumbers,
            newSeasonNumbers: newSeasonNumbers,
            now: now
        )
    } catch {
        // Silent: keep existing data on failure.
    }
}
```

### follow() Integration

```swift
// Schedule notifications for this show (non-blocking)
launchBackgroundTask { [container] in
    let bgContext = ModelContext(container)
    let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
    guard let series = try? bgContext.fetch(descriptor).first else { return }
    await self.scheduleNotificationsForShow(series, now: Date())
}
```

### unfollow() Integration

```swift
// Cancel notifications for this show (non-blocking)
let showId = s.id
launchBackgroundTask {
    await self.cancelNotificationsForShow(showId)
}
```

---

## Key Design Decisions Implemented

| Decision | Implementation |
|----------|----------------|
| **Premium-gated** | `guard PremiumManager.shared.isPremium` in all notification paths |
| **Global settings only** | Reads `NotificationSettingsStore.shared.settings` (no per-show) |
| **`finaleTiming` offset from finaleDate** | `settings.finaleTiming.reminderDate(before: finale)` |
| **Cancel-stale scoped to show prefix** | `$0.identifier.hasPrefix("show-\(showId)-")` |
| **`now` threaded through** | For testability in `refresh()`/`refreshAll()` |
| **4 notification types** | `premiere`, `finale`, `bingeReady`, `newSeason` (event-driven) |
| **Schedule-once / update-only-on-change** | `applyPlans()` compares desired vs existing by identifier + date |

---

## Files Modified/Created

| File | Action |
|------|--------|
| `Services/Notifications/NotificationPlanner.swift` | **Created** — pure planning + scheduler actor |
| `Services/Notifications/NotificationService.swift` | **Updated** — new `NotificationSettings` struct |
| `Services/Notifications/NotificationSettingsStore.swift` | **Updated** — global-only settings |
| `Services/Core Engine/SeriesManager.swift` | **Updated** — wired in scheduling |
| `Views/ShowDetail/NotificationOnboardingSheet.swift` | **Updated** — uses new settings structure |

---

## Next Steps (Phase 2)

- Unit tests for `planNotifications()` pure function
- Integration tests for scheduler actor
- Full-cycle test advancing `now` through show lifecycle
