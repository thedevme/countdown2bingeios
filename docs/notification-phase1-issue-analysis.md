# Phase 1 Issue Analysis

**Status:** All issues confirmed correct — no fixes needed.

---

## ISSUE 1 — Same-Day Comparison

**Concern:** The scheduler reads dates from `UNCalendarNotificationTrigger.nextTriggerDate()` (9 AM scheduled time) but compares against `plan.fireDate` (raw date). Would this cause every refresh to cancel+re-add?

**Analysis:**

```swift
// NotificationPlanner.swift, line 190
if !Calendar.current.isDate(existingDate, inSameDayAs: plan.fireDate) {
    // Date changed: cancel old, add new
    toCancel.append(plan.identifier)
    toAdd.append(plan)
}
```

**CONFIRMED ✓** — The `isDate(inSameDayAs:)` comparison absorbs the time difference. A notification scheduled for "Jan 15 at 9:00 AM" and a plan with fireDate "Jan 15 at midnight" are considered the same day → notification is left alone.

The same-day comparison is used throughout. No cancel+re-add on every refresh.

---

## ISSUE 2 — New Season Spam on Follow

**Concern:** On first follow, `oldSeasonNumbers` would be empty and ALL seasons would appear as "added" → multiple "new season!" notifications for every existing season.

**Analysis:**

### Follow Path (lines 155-162)

```swift
// follow() calls ONLY scheduleNotificationsForShow
launchBackgroundTask { [container] in
    let bgContext = ModelContext(container)
    let descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
    guard let series = try? bgContext.fetch(descriptor).first else { return }
    await self.scheduleNotificationsForShow(series, now: Date())
    // NOTE: handleNewSeasonEvent is NOT called here
}
```

`follow()` calls `scheduleNotificationsForShow()` which schedules premiere/finale/bingeReady notifications. It does **NOT** call `handleNewSeasonEvent()`.

### Refresh Path (lines 347-390)

```swift
// Snapshot old season numbers BEFORE TMDB update
let oldSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

// ... TMDB update happens ...

// Snapshot new season numbers AFTER update
let newSeasonNumbers = Set(s.regularSeasons.map { $0.seasonNumber })

// Detect new seasons
await handleNewSeasonEvent(
    seriesId: id,
    seriesName: seriesName,
    oldSeasonNumbers: oldSeasonNumbers,  // seasons that existed BEFORE update
    newSeasonNumbers: newSeasonNumbers,  // seasons that exist AFTER update
    now: now
)
```

### Flow on First Follow + Refresh

1. **`follow()`** creates Series with all seasons from ShowData, saves to DB
2. **`follow()`** calls `scheduleNotificationsForShow()` — no new-season events
3. **Later, `refresh()` runs** for this show
4. **Line 348:** `oldSeasonNumbers` = seasons from DB (all existing seasons from follow)
5. **Line 352:** TMDB fetch returns same data (no new seasons announced)
6. **Line 378:** `newSeasonNumbers` = same as old
7. **Line 384:** `handleNewSeasonEvent()` computes `addedSeasons = new - old = empty`
8. **Result:** No notifications fired

### When New Season DOES Fire

Only when:
1. User follows show at time T1
2. Between T1 and T2, a new season is announced on TMDB
3. `refresh()` runs at time T2
4. `oldSeasonNumbers` (from T1) doesn't have the new season
5. `newSeasonNumbers` (from TMDB at T2) has it
6. `addedSeasons` contains the genuinely new season → notification fires

**CONFIRMED ✓** — The architecture is correct. Follow establishes the baseline; only truly new seasons detected during subsequent refresh trigger notifications.

---

## ISSUE 3 — Context Safety

**Concern:** `refresh()` calls `scheduleNotificationsForShow()` on main context, but `follow()`'s version runs on a bgContext. Does any Series object cross into the actor?

**Analysis:**

```swift
private func scheduleNotificationsForShow(_ series: Series, now: Date) async {
    // ...

    // Extract dates into VALUE TYPE struct
    let dateInfo = extractDateInfo(from: series, now: now)  // → ShowDateInfo (struct)

    // Plan into VALUE TYPE array
    let plans = planNotifications(dates: dateInfo, settings: settings, now: now)  // → [NotificationPlan]

    // Pass ONLY value types to actor
    await notificationScheduler.applyPlans(plans, for: series.id)
    //                                     ^^^^^     ^^^^^^^^^
    //                            [NotificationPlan]    Int
}
```

**What crosses into the actor:**
- `plans`: `[NotificationPlan]` — array of structs (value types)
- `series.id`: `Int` — value type

**What does NOT cross:**
- `Series` model object — never passed to actor
- `ModelContext` — never passed to actor

**CONFIRMED ✓** — No Series model object crosses into the actor. Only value types cross. Context-safe regardless of whether called from main context or background context.

---

## Summary

| Issue | Status | Notes |
|-------|--------|-------|
| 1. Same-day comparison | ✓ Correct | `isDate(inSameDayAs:)` absorbs 9 AM vs raw time |
| 2. New season spam | ✓ Correct | Follow establishes baseline; only refresh detects new seasons |
| 3. Context safety | ✓ Correct | Only value types cross into actor |

**No fixes needed. Ready for Phase 2 tests.**
