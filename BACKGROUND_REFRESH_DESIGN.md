# Background Refresh — Phase 1 Design

## Status: ✅ PHASE 1 COMPLETE

---

## PHASE 0 — INVESTIGATION SUMMARY

| Aspect | Finding |
|--------|---------|
| BGTaskScheduler | Not implemented |
| App lifecycle | Pure SwiftUI, use `.backgroundTask` modifier |
| Registration point | Add modifier to `WindowGroup` in `body` |
| Refresh chain | `refreshAll(force:false)` → per-show cadence → TMDB → notifications |
| Notification scheduling | Already inside `refresh()`, no extra wiring needed |
| ModelContainer for background | Create `ModelContext(container)` from stored container |
| Premium gating | Already in `scheduleNotificationsForShow()` — honored automatically |

---

## PHASE 1 — DESIGN: Register + Schedule the Task

### 1. Info.plist Entries

Add both required entries:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.countdown2binge.refresh</string>
</array>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

---

### 2. Modifier Placement + Next Request Scheduling

The `.backgroundTask` modifier goes on the `WindowGroup` scene. The **first line** inside the closure schedules the next request — critical or the app never runs again.

```swift
var body: some Scene {
    WindowGroup {
        ContentView()
            .environment(seriesManager)
            .onAppear { /* existing launch code */ }
    }
    .modelContainer(modelContainer)
    .onChange(of: scenePhase) { oldPhase, newPhase in
        switch newPhase {
        case .active:
            if hasLaunched {
                Task { @MainActor in
                    await seriesManager.refreshAll()
                }
            }
        case .background:
            // Schedule FIRST request when app backgrounds
            scheduleBackgroundRefresh()
        case .inactive:
            break
        @unknown default:
            break
        }
    }
    .backgroundTask(.appRefresh("com.countdown2binge.refresh")) {
        // ═══════════════════════════════════════════════════════════════
        // CRITICAL: Schedule NEXT request FIRST — or task dies after one run
        // ═══════════════════════════════════════════════════════════════
        scheduleBackgroundRefresh()

        // Run refresh pass (see section 3 for main-actor handling)
        await performBackgroundRefresh()
    }
}
```

**`scheduleBackgroundRefresh()` helper:**

```swift
/// Schedule the next background refresh request.
/// Called: (1) inside the task handler (schedules NEXT), (2) on scenePhase .background (ensures FIRST).
private func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.countdown2binge.refresh")
    // Earliest 4 hours out — iOS decides actual timing based on usage patterns
    request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)

    do {
        try BGTaskScheduler.shared.submit(request)
        print("📅 Background refresh scheduled for ~4h from now")
    } catch BGTaskScheduler.Error.unavailable {
        print("⚠️ Background refresh unavailable on this device")
    } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
        print("⚠️ Too many pending background tasks")
    } catch {
        print("⚠️ Could not schedule background refresh: \(error)")
    }
}
```

---

### 3. Main-Actor Handling

**Problem:** `SeriesManager` is `@MainActor`. The `.backgroundTask` closure runs in a nonisolated async context.

**Solution:** Just call the `@MainActor async` function directly. Swift automatically hops to the main actor when you `await` a `@MainActor` function from a nonisolated context. No `MainActor.run` needed.

**Implementation:**

```swift
/// Perform background refresh — reuses the tested foreground path.
/// Calling a @MainActor async function automatically hops to the main actor.
private func performBackgroundRefresh() async {
    print("🌙 Background refresh starting")

    // refreshAll is @MainActor async — Swift automatically hops actors on the call
    await seriesManager.refreshAll(force: false)

    print("🌙 Background refresh completed")
}
```

**Why this works:**
- `refreshAll()` is `@MainActor async`
- Calling it with `await` from a nonisolated context automatically switches to the main actor
- The tested code path is reused unchanged

---

### 4. Cancellation Handling

The `.backgroundTask` modifier uses cooperative Task cancellation. When iOS needs to stop (time's up), it cancels the Task. We check `Task.isCancelled` between shows.

**Modify `refreshAll()` to support cancellation:**

```swift
/// Refresh every followed show. Call on launch / background refresh.
/// Checks Task.isCancelled between shows for graceful background-task expiration.
/// `now` parameter for testability (defaults to current date).
func refreshAll(force: Bool = false, now: Date = Date()) async {
    for s in allSeries() {
        // Check cancellation before each show (supports background task expiration)
        guard !Task.isCancelled else {
            print("🛑 Refresh cancelled by system")
            return
        }
        await refresh(id: s.id, force: force, now: now)
    }
}
```

**Why this is safe:**
- Each `refresh()` saves independently (line 420: `try context.save()`)
- Partial completion is fine — unprocessed shows get caught next run
- Foreground calls won't be cancelled (or if they are, stopping gracefully is correct)
- No half-written state — the per-show save pattern already handles this

---

### 5. Summary of Changes

| File | Change |
|------|--------|
| **Info.plist** | Add `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes.fetch` |
| **Countdown2BingeApp.swift** | Add `.backgroundTask` modifier, `scheduleBackgroundRefresh()`, `performBackgroundRefresh()`, handle `.background` scenePhase |
| **SeriesManager.swift** | Add `Task.isCancelled` check in `refreshAll()` loop |

---

### 6. Full Countdown2BingeApp.swift Design

```swift
import SwiftUI
import SwiftData
import BackgroundTasks  // ← NEW

@main
struct Countdown2BingeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasLaunched = false
    @State private var seriesManager: SeriesManager

    let modelContainer: ModelContainer

    init() {
        // ... existing init unchanged ...
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(seriesManager)
                .onAppear {
                    // ... existing onAppear unchanged ...
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                if hasLaunched {
                    Task { @MainActor in
                        await seriesManager.refreshAll()
                    }
                }
            case .background:
                // Schedule background refresh when app enters background
                scheduleBackgroundRefresh()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
        // ═══════════════════════════════════════════════════════════════════
        // BACKGROUND REFRESH — iOS runs this when it decides (usage-based)
        // ═══════════════════════════════════════════════════════════════════
        .backgroundTask(.appRefresh("com.countdown2binge.refresh")) {
            // FIRST: Schedule the NEXT request (critical — or dies after one run)
            scheduleBackgroundRefresh()

            // Run the refresh pass
            await performBackgroundRefresh()
        }
    }

    // MARK: - Background Refresh

    /// Schedule the next background refresh request.
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.countdown2binge.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)  // ~4 hours minimum

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Background refresh scheduled")
        } catch {
            print("⚠️ Could not schedule background refresh: \(error)")
        }
    }

    /// Perform background refresh — reuses the tested foreground path.
    /// Calling a @MainActor async function automatically hops to the main actor.
    private func performBackgroundRefresh() async {
        print("🌙 Background refresh starting")

        // refreshAll is @MainActor async — Swift automatically hops actors on the call
        await seriesManager.refreshAll(force: false)

        print("🌙 Background refresh completed")
    }
}
```

---

### 7. Honest Limitation (document in code)

```swift
// ═══════════════════════════════════════════════════════════════════
// BACKGROUND REFRESH — iOS runs this when it decides (usage-based)
//
// LIMITATION: iOS controls background execution based on app usage patterns.
// For users who rarely open the app, iOS may deprioritize or skip runs.
// This improves coverage for regular users; it does not guarantee updates
// for fully-dormant users. That gap is an iOS platform constraint, not a bug.
// A future server+push solution would close it.
// ═══════════════════════════════════════════════════════════════════
```

---

## PHASE 2 — THE BACKGROUND WORK (pending)

*Design after Phase 1 approval.*

---

## PHASE 3 — TESTS + MANUAL VERIFICATION (pending)

*Design after Phase 2 approval.*

---

## Manual Verification Steps (for Craig)

### Simulator Testing

1. Build and run the app in Xcode
2. Background the app (press Home)
3. Pause execution in Xcode debugger
4. In the LLDB console, run:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.countdown2binge.refresh"]
   ```
5. Resume execution — observe console logs for "🌙 Background refresh starting/completed"

### Device Testing

1. Install on device
2. Follow some shows
3. Background the app
4. Wait several hours (iOS decides timing)
5. Observe: notifications appear, data updates when reopening

---

**Status: AWAITING APPROVAL TO BUILD**
