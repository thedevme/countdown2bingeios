# Countdown2Binge

Countdown2Binge is an iOS app built for people who prefer to **binge full TV seasons** instead of tracking weekly episodes.

The app automatically tracks the lifecycle of TV shows and tells users **exactly when a season is ready to binge**, so they never have to remember dates, statuses, or check streaming apps manually.

---

## Core Idea

Most TV apps show you *what* you’re watching.

Countdown2Binge focuses on **when you should watch**.

The app:
- Tracks real-world show states automatically
- Moves shows through their lifecycle without user input
- Surfaces shows only when they’re relevant
- Clearly communicates when a season is binge‑ready

---

## Platform

- iOS only (MVP)
- iPhone only
- Portrait only
- Dark mode only
- iOS 17+

---

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Persistence:** SwiftData
- **Show Data:** TMDB API
- **Subscriptions / IAP:** RevenueCat
- **Crash Reporting:** Firebase Crashlytics
- **Backup:** iCloud
- **CI/CD:** Xcode Cloud

---

## App Structure

The app is built around two independent systems:

### 1. Show Lifecycle (Automatic)
- Data-driven from TMDB
- User never moves shows manually
- Handles airing, completed, anticipated, cancelled states

### 2. User Watch Tracking (Manual)
- Lives in the Binge Ready tab
- Tracks what the user has watched
- Purely for personal satisfaction

These systems are intentionally separate.

---

## Repository Structure

```
Countdown2Binge/
├── App/
├── Models/
├── Services/
├── UseCases/
├── ViewModels/
├── Views/
├── Resources/
├── Utilities/
├── docs/
│   ├── product-spec.md
│   ├── architecture.md
│   ├── state-machine.md
│   └── build-order.md
├── CLAUDE.md
├── README.md
└── .gitignore
```

---

## Documentation

All project documentation lives in `/docs`.

Key files:
- **Product Specification** – source of truth for all behavior
- **Architecture** – system design and data flow
- **State Machine** – show lifecycle rules
- **Build Order** – step-by-step execution plan

Claude Code is instructed to always consult these documents.

---

## Development Workflow

This project follows the **PSB system**:

1. **Plan**
   - Product spec
   - Architecture
   - State machine
2. **Setup**
   - Project structure
   - CI/CD
   - Tooling
3. **Build**
   - Core logic first
   - Tests before UI
   - UI after logic is stable
   - Monetization last

No phases are skipped.

---

## Testing

- **BDD** for user-facing behavior
- **TDD** for core logic
- Full lifecycle tests for show state transitions
- Xcode Cloud runs tests on every push

---

## Monetization

- 7-day free trial
- Premium subscription via RevenueCat
- Free tier limited to one show
- Ads (banner + interstitial) removable with Premium

---

## Status

🚧 Actively in development  
📱 Targeting TestFlight beta first

---

## Notes

- No accounts required
- Offline-first
- No manual refresh
- Calm, intentional UX
- Gesture-driven interactions are a core differentiator

---

If you’re reading this in the future:  
The goal was never “more features” — it was **less thinking for the user**.
