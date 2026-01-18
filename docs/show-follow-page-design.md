# Show Follow Page - Design Spec

A reimagined show detail page designed specifically for **binge watchers**. This page treats seasons as complete units and provides data that helps users plan their viewing commitment.

---

## Design Philosophy

Binge watchers don't think episode-by-episode. They think:
- "When can I start?"
- "How much time will this take?"
- "Is this season worth it?"
- "How does it compare to previous seasons?"

This page answers those questions with clear, visual data.

---

## Page Sections

### 1. Header

**Purpose:** Quick identification and at-a-glance stats.

**What it shows:**
- Show backdrop/poster art
- Show title
- Quick stats row (compact, scannable)

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              [BACKDROP IMAGE]                       │
│                                                     │
│   ┌──────────────────────────────────────────┐     │
│   │  BREAKING BAD                            │     │
│   │                                          │     │
│   │  5 Seasons · 62 Eps · 47h · 9.4 · AMC   │     │
│   └──────────────────────────────────────────┘     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Data required:**
- Backdrop image URL
- Show title
- Total season count
- Total episode count
- Total runtime (calculated from all episodes)
- Overall show rating (average of all seasons)
- Network name

---

### 2. Current Season Card (The Wait Tracker)

**Purpose:** Show the status of the current/upcoming season and when it will be binge-ready.

**What it shows:**
- Current season number
- Airing progress (X of Y episodes aired)
- Days/weeks until binge-ready
- Finale date

**Visual - Season Airing:**
```
┌─────────────────────────────────────────────────────┐
│  SEASON 5                                           │
│                                                     │
│  ████████████░░░░░░░░░░░░  6 of 12 aired           │
│                                                     │
│  BINGE READY IN                                     │
│  ┌────────────────────────────────────────┐        │
│  │           6 WEEKS                      │        │
│  │         March 15, 2026                 │        │
│  └────────────────────────────────────────┘        │
│                                                     │
│  You've been waiting since: Jan 5 (43 days)        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Visual - Season Binge Ready:**
```
┌─────────────────────────────────────────────────────┐
│  SEASON 5                                           │
│                                                     │
│  ████████████████████████  12 of 12 aired          │
│                                                     │
│  ┌────────────────────────────────────────┐        │
│  │         ✓ BINGE READY                  │        │
│  │       Season complete                   │        │
│  └────────────────────────────────────────┘        │
│                                                     │
│  Finished airing: March 15, 2026                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Visual - Waiting for Season:**
```
┌─────────────────────────────────────────────────────┐
│  SEASON 5                                           │
│                                                     │
│  ░░░░░░░░░░░░░░░░░░░░░░░░  Not yet airing          │
│                                                     │
│  PREMIERES IN                                       │
│  ┌────────────────────────────────────────┐        │
│  │          47 DAYS                       │        │
│  │        March 1, 2026                   │        │
│  └────────────────────────────────────────┘        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Data required:**
- Current season number
- Episode count (total for season)
- Episodes aired count
- Premiere date
- Finale date (actual or estimated)
- Days until premiere/finale

---

### 3. Runtime as Commitment

**Purpose:** Translate raw minutes into relatable time commitments so users can plan their binge.

**What it shows:**
- Total season runtime in hours/minutes
- Relatable comparisons (nights, weekends, flights)
- Helps users mentally allocate time

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│  YOUR COMMITMENT                                    │
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │                                         │       │
│  │         9 hours 42 minutes              │       │
│  │                                         │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
│  That's roughly:                                    │
│                                                     │
│  🌙  5 nights (2 episodes per night)               │
│  🛋  A full Saturday                                │
│  ✈️  2.5 cross-country flights                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Calculation logic:**
- Nights: total_runtime / (avg_episode_length * 2)
- "Full day": if runtime > 8 hours
- Flights: total_runtime / 4 hours

**Data required:**
- Total season runtime (sum of all episode runtimes)
- Average episode runtime

---

### 4. Season Comparison (The Collection)

**Purpose:** Let users compare all seasons at a glance - ratings, length, and episode count.

**What it shows:**
- All seasons in a visual list
- Rating bar for each
- Episode count
- Total runtime per season
- Indicators for best/longest/current

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│  THE COLLECTION                                     │
│                                                     │
│  S1  ████████░░  8.2   │  8 eps  │  6h 40m         │
│  S2  █████████░  8.9   │ 10 eps  │  8h 15m   BEST  │
│  S3  ████████░░  8.4   │ 10 eps  │  8h 30m         │
│  S4  █████████░  8.7   │ 10 eps  │  9h 42m  LONGEST│
│  S5  █████████░  8.8   │ 12 eps  │ 10h 15m  CURRENT│
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Badges:**
- `BEST` - Highest rated season
- `LONGEST` - Most runtime
- `CURRENT` - Currently airing or most recent
- `SHORTEST` - Least runtime (optional)

**Data required:**
- All seasons with:
  - Season number
  - Average rating
  - Episode count
  - Total runtime

---

### 5. Season "Card" Stats

**Purpose:** A compact, trading-card style view of a single season with all key stats.

**What it shows:**
- Season number
- Rating
- Episode count
- Total runtime
- Premiere and finale dates
- Brief description or notable info

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  SEASON 5                                           │
│  ───────────────────────────────────────────────    │
│                                                     │
│     RATING          EPISODES         TIME          │
│  ┌─────────┐      ┌─────────┐     ┌─────────┐     │
│  │   9.6   │      │   16    │     │   13h   │     │
│  └─────────┘      └─────────┘     └─────────┘     │
│                                                     │
│     PREMIERED                    FINALE            │
│  ┌─────────────────┐      ┌─────────────────┐     │
│  │   Jul 15, 2012  │      │   Sep 29, 2013  │     │
│  └─────────────────┘      └─────────────────┘     │
│                                                     │
│  ───────────────────────────────────────────────    │
│                                                     │
│  "The final season, split into two parts.          │
│   Universally considered peak television."         │
│                                                     │
│  🏆 #1 rated season of the series                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Data required:**
- Season number
- Season rating
- Episode count
- Total runtime
- Premiere date
- Finale date
- Season overview/description (optional)
- Ranking among other seasons

---

### 6. Binge Types

**Purpose:** Categorize the season by how long it takes to binge, giving users an instant sense of commitment level.

**What it shows:**
- A category label based on runtime
- Visual indicator of where this season falls

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│  BINGE TYPE                                         │
│                                                     │
│  ⚡ Quick Hit      under 4 hours                    │
│  📺 Evening Fill   4-6 hours                        │
│  🍿 Day Trip       6-9 hours                        │
│  🛋  Weekend Binge  9-14 hours        ← THIS SEASON │
│  🏔  Epic Journey   14+ hours                       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Categories:**
| Type | Runtime | Icon |
|------|---------|------|
| Quick Hit | < 4 hours | ⚡ |
| Evening Fill | 4-6 hours | 📺 |
| Day Trip | 6-9 hours | 🍿 |
| Weekend Binge | 9-14 hours | 🛋 |
| Epic Journey | 14+ hours | 🏔 |

**Data required:**
- Total season runtime

---

### 7. Season Rankings

**Purpose:** Show which seasons are the best-rated, helping users know what to expect or revisit.

**What it shows:**
- Top 3 (or all) seasons ranked by rating
- Medal/trophy indicators
- Current season callout if applicable

**Visual:**
```
┌─────────────────────────────────────────────────────┐
│  SEASON RANKINGS                                    │
│                                                     │
│  🥇  S2  ──────────────────  9.1   Fan Favorite    │
│                                                     │
│  🥈  S5  ──────────────────  8.9   Current         │
│                                                     │
│  🥉  S4  ──────────────────  8.7                   │
│                                                     │
│  ─────────────────────────────────────────────     │
│                                                     │
│      S1  ──────────────────  8.2                   │
│      S3  ──────────────────  7.9                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Labels:**
- `Fan Favorite` - Highest rated
- `Current` - Currently airing
- `Most Watched` - If we have view data
- `Underrated` - High rating, low vote count (optional)

**Data required:**
- All seasons with ratings
- Vote counts (optional, for "most watched")

---

## Full Page Layout

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                 [HEADER]                            │
│         Show art + title + quick stats             │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│            [CURRENT SEASON CARD]                    │
│         Wait Tracker / Binge Ready status          │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│          [RUNTIME AS COMMITMENT]                    │
│          Time investment breakdown                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│              [BINGE TYPE]                           │
│         Quick category indicator                    │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│           [SEASON RANKINGS]                         │
│         Best seasons at a glance                   │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│        [SEASON COMPARISON - THE COLLECTION]         │
│          All seasons compared                       │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│           [SEASON CARD STATS]                       │
│      Detailed view of selected season              │
│         (expandable or tappable)                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Data Model Requirements

To build this page, each **Show** needs:

```
Show
├── title
├── backdropPath
├── posterPath
├── network
├── overallRating (computed: avg of all season ratings)
├── totalEpisodes (computed: sum of all season episodes)
├── totalRuntime (computed: sum of all episode runtimes)
└── seasons[]
    ├── seasonNumber
    ├── rating
    ├── episodeCount
    ├── airedEpisodeCount
    ├── totalRuntime (computed: sum of episode runtimes)
    ├── premiereDate
    ├── finaleDate
    ├── state (anticipated/premiering/airing/bingeReady/watched)
    └── episodes[]
        ├── episodeNumber
        ├── runtime
        └── airDate
```

---

## Computed Values

| Value | Calculation |
|-------|-------------|
| `totalShowRuntime` | Sum of all episode runtimes across all seasons |
| `totalShowEpisodes` | Sum of all episode counts across all seasons |
| `overallShowRating` | Average of all season ratings (weighted by episode count optional) |
| `seasonTotalRuntime` | Sum of all episode runtimes in that season |
| `daysUntilBingeReady` | finaleDate - today |
| `daysWaiting` | today - premiereDate (if currently airing) |
| `bingeType` | Based on seasonTotalRuntime thresholds |
| `bestSeason` | Season with highest rating |
| `longestSeason` | Season with highest totalRuntime |

---

## Design Notes

### Color Usage
- Use the app's existing state colors:
  - Airing → Soft teal
  - Premiering → Warm rose
  - Binge Ready → Fresh green
  - Watched → Muted gray
  - Anticipated → Cool slate blue

### Typography
- Large, bold numbers for key stats (runtime, days, ratings)
- Smaller muted text for labels and descriptions
- Consistent with app's existing type scale

### Spacing
- Generous padding between sections
- Cards should feel distinct but cohesive
- Scrollable page with clear section breaks

### Interactions
- Tap on a season in "The Collection" → expand to Season Card Stats
- Tap "Mark as Watched" when binge complete
- Pull to refresh for updated episode counts

---

## Future Enhancements (Not in V1)

- **Your Journey** - Personal stats (when you started following, time invested)
- **Gap History** - How long between each season historically
- **Show Health** - Renewal status, trending up/down
- **Binge Calculator** - "At X eps/night, finish in Y days"
- **Episode Checklist** - Collapsible list within Season Card
