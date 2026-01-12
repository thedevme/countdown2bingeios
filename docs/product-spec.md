# Countdown2Binge – Product Spec

## What this app is
Countdown2Binge is a TV show tracking app focused on **when a season is ready to binge**, not just what episode airs next. It helps users track favorite shows, know exactly when a season finishes, and plan binge time around their real schedule.

The core value is removing mental overhead:
users should never need to remember dates, finales, or season status.

---

## Target user
- Watches TV in seasons, not weekly
- Prefers to binge once a season is complete
- Wants calm, intentional planning (not notification spam)
- Likely already uses TV apps but finds them noisy or cluttered

---

## Core features (non-negotiable)
- Track followed TV shows
- Know when a season is:
  - Airing
  - Finished
  - Ready to binge
- Clear countdowns to:
  - Finale
  - Next episode (secondary)
- Timeline-style home screen showing:
  - Airing now
  - Premiering soon
  - Anticipated / TBD
- Ability to plan binges around dates (calendar-aware later)
- My Show Reactions:
  - Quick reactions per episode or season
  - Lightweight, personal (not social media)

---

## What this app is NOT
- Not a social network
- Not a recommendation engine
- Not a “what should I watch” app
- Not focused on episode-by-episode reminders

---

## Design principles
- Calm, minimal, intentional
- Timeline-driven, not list-driven
- Design-forward, premium feel
- No clutter, no gamification
- Visual hierarchy over density
- Motion is subtle and purposeful

---

## Technical constraints
- iOS first (Swift / SwiftUI)
- Android later (shared concepts, not shared code)
- Uses TMDB for show data
- Offline-friendly for followed shows
- Testable architecture (manager-based, not view-model heavy)

---

## Success criteria
The app feels:
- Quiet
- Trustworthy
- Predictable
- Helpful without demanding attention

Users should feel relief, not urgency.
