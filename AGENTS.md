# Countdown2Binge — Codex Instructions

> Engine rules are LOCKED. Each fixes a specific bug that returns if broken.
> If a compile error would be "fixed" by breaking a rule, the CALLER is wrong —
> fix the caller, not the rule. If a rule truly must change, STOP and ask the
> human. Never revert an engine rule silently.
> (Rules 1, 2, 3, 9 are also hard-enforced by a PreToolUse hook.)

## ENGINE RULES (show / season / episode code)

**R1 — State is computed by BingeEngine only, never by a DTO.**
`ShowData` / `SeasonData` / `EpisodeData` are display DTOs for search & discovery
ONLY. They must not compute lifecycle state. Forbidden on a DTO:
`lifecycleState`, `timelineCategory`, `isBingeReady`, `anticipatedSeason`,
state-carrying `currentSeason`, or any date/finale math. All state comes from
`Series` computed properties → `BingeEngine`: `series.showState`,
`series.appearsOnTimeline`, `series.bingeReadySeason`, `series.daysUntilPremiere`,
`series.daysUntilFinale`. WHY: two state sources = drift; the refactor deleted the
second one.

**R2 — No state-carrying model→DTO converters.**
`toShowData()` / `toSeasonData()` / `toEpisodeData()` are forbidden. Never convert
a `Series` to `ShowData` so a view can read state — rewire the view to read
`Series`. WHY: the converter is how DTO-state drift sneaks back.

**R3 — All mutations go through SeriesManager. Nothing else writes.**
`SeriesManager` is the single write funnel (follow/unfollow/refresh/markWatched/
toggleEpisodeWatched/markAiredEpisodesWatched/archive/resolveSpinoffs). Never
write `Episode.hasWatched` / `Season.hasWatched` from a view or a model method.
Never add `markAllWatched()`-type mutators onto the models. WHY: scattered writes
change state with no save/sync and no single place to reason about it.

**R4 — Views read via `@Query<Series>`. Never a stored array on the manager.**
Views observe SwiftData with `@Query private var allSeries: [Series]` and filter
in Swift computed vars. No stored `series` array + `reloadSeries()` — it goes
stale. Lifecycle filters run on the fetched array, never inside a `#Predicate`
(BingeEngine can't run in a predicate). WHY: `@Query` is live; a hand array isn't.

**R5 — Conservative finale detection. Never guess a finale.**
Finale logic lives only in `BingeEngine.finaleEpisode`: (1) typed `.finale` wins;
(2) typed episodes but no `.finale` → finale UNKNOWN → season is `.pending`;
(3) no typed episodes at all → fall back to last-by-number. Never use
`episodes.last`/`max(episodeNumber)` as a finale in a view or model. WHY: a wrong
finale flips a still-airing show to "binge ready" early.

**R6 — Five ShowStates. `pending` is load-bearing; never collapse it.**
`anticipated → premieringSoon → (airing | pending) → bingeReady`. `pending` =
premiered, no confirmed finale (no countdown). `airing` = premiered WITH finale
(real countdown). Never render a finale countdown for `pending` (`daysUntilFinale`
is nil → show "Airing", no number). WHY: pending exists to avoid counting down to
an unknown date.

**R7 — Binge Ready = date-complete ∩ unwatched, single latest per show.**
The surface shows only `series.bingeReadySeason` — the single latest season that
is complete-by-date AND unwatched. One row per show. No plural
`bingeReadySeasons()`. Production status (cancelled/ended) does NOT remove a show
from Binge Ready. WHY: the dedup rule — older unwatched seasons are reached by
drilling in.

**R8 — Two axes. Never blend them.**
Show state (Axis 1) = air dates only, zero watch influence → `series.showState`.
User state (Axis 2) = `hasWatched`/archive, marks only. "Complete" is ambiguous —
always pick an axis: date-complete = `season.isBingeReadyByDate`; watch-complete =
`season.hasWatched`. Never a blended `isComplete`. WHY: blending the axes is the
root confusion the design separated.

**R9 — Sync is premium-gated and intentional. Don't "fix" it to native.**
Manual CloudKit (`CloudKitManager`, `CKRecord`), gated on premium. `isSynced` on
`Series` is correct. `cloudKitDatabase: .none` is CORRECT — do NOT switch to
`.automatic` / native SwiftData+CloudKit (it would sync free users). Only premium
syncs; downgrade removes iCloud data; re-adding re-pushes; free users cap at 3
shows. WHY: native auto-sync can't be premium-gated.

**When a rule blocks you:** rewire the caller to obey it (read `Series` directly,
or route the write through `SeriesManager`). Do not break the rule to compile.

---

## View Naming (hook-enforced)

- Screen-level files are named `*View.swift` — NEVER `*Screen.swift`.
  (`TimelineView`, `MyListView`, `SettingsView`.) Creating a `*Screen.swift`
  file is blocked.
- The top-level folder is `Views/`.

## Component Reuse Workflow (do this EVERY time a component is needed)

Before creating ANY component, follow this sequence. Do not skip step 1.

1. **SEARCH first.** Look in `Components/` (shared) and the target view's
   `Supporting Files/` for an existing component that already does the job
   (a poster tile, a section header, a badge, a button). CLI's default failure
   is creating a new one without looking — always look first.
2. **Reuse if one fits.** Use the existing component. Do NOT create a second
   poster/header/tile that duplicates one that already exists. One `PosterTile`,
   reused — not `TimelinePoster`, `MyListPoster`, `BingePoster`.
3. **Only if nothing fits, create it — with the right NAME:**
   - If it could be reused by other views → GENERIC name (`PosterTile`,
     `SectionHeader`, `CountdownBadge`), placed in `Components/`.
   - If it is genuinely specific to ONE view and nothing reusable applies →
     a view-prefixed name is OK (`TimelineHeader`), placed in that view's
     `Supporting Files/`. Prefix ONLY after confirming nothing reusable exists.
     (A warning fires on prefixed component names as a reminder to check first.)
4. **Place it** (see Component Placement below) and **wire it into the view.**

Do not reflexively prefix every component with the view name. The prefix is for
the genuinely view-specific case, not the default.

## Component Placement

- Shared components (used in multiple views) → `Components/`
- View-specific components (one view only) → `[View]/Supporting Files/`

## Folder Structure

Screen with supporting files:

```
Screens/
└── [ParentScreen]/
    └── [FeatureName]/
        ├── [FeatureName].swift              (main view)
        ├── [FeatureName]ViewModel.swift     (state & logic, if needed)
        └── Supporting Files/
            ├── [Component1].swift
            └── [Component2].swift
```

Example — CloudSyncView:

```
Screens/Settings/CloudSyncView/
├── CloudSyncView.swift
├── CloudSyncViewModel.swift
└── Supporting Files/
    ├── CloudSyncStatusCard.swift
    ├── CloudSyncUpsellCard.swift
    ├── CloudSyncShowGrid.swift
    └── CloudSyncShowTile.swift
```

Example — PendingCardView:

```
Screens/Timeline/Components/PendingCardView/
├── PendingCardView.swift
└── Supporting Files/
    └── PendingCard.swift
```

## Model & Service Changes

```
Models/SwiftData/Series.swift        (SwiftData models — obey R1–R8)
Services/Core Engine/SeriesManager.swift   (mutations — the write funnel, R3)
Services/Core Engine/BingeEngine.swift     (all lifecycle rules — R1, R5, R6)
```

## Naming Conventions

- Views: `[Feature]View.swift`
- ViewModels: `[Feature]ViewModel.swift`
- Components: descriptive names (e.g. `CloudSyncStatusCard.swift`)
- Supporting files go in a `Supporting Files/` subfolder

## Shared Components

```
Components/
├── StatusBadge.swift             ← generic badge ("✓ SYNCED", "🔒 LOCAL ONLY")
├── CircleXButton.swift           ← X button for edit modes
└── PosterTileEditable.swift      ← poster + badge + X + jiggle
```

## Build Order (visual components)

Build smallest to largest:
1. Atoms — badges, buttons, icons
2. Molecules — cards, tiles (combine atoms)
3. Organisms — grids, lists (combine molecules)
4. ViewModel — state & logic
5. View — assembles everything
