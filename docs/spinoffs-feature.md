# Spinoffs Feature

## Overview

The spinoffs feature allows users to discover related shows within the same franchise (e.g., Better Call Saul when following Breaking Bad). This is a **premium feature** - free users see an upgrade prompt.

---

## Data Source: Firebase

Spinoff/franchise data is stored in **Firebase** (NOT TMDB). This gives us complete control over:
- Which shows are linked together
- Watch order recommendations (release vs chronological)
- Multi-language franchise names
- Accurate spinoff categorization (prequel, sequel, companion, remake)

### Firebase Structure

```json
{
  "franchises": {
    "breaking-bad": {
      "franchiseName": { "en": "Breaking Bad Universe", "es": "Universo Breaking Bad", ... },
      "origin": "US",
      "parentShow": {
        "title": "Breaking Bad",
        "tmdbId": 1396,
        "years": "2008-2013"
      },
      "spinoffs": [
        {
          "title": "Better Call Saul",
          "tmdbId": 60059,
          "years": "2015-2022",
          "type": "prequel",
          "status": "ended"
        },
        {
          "title": "El Camino",
          "tmdbId": 559969,
          "years": "2019",
          "type": "sequel",
          "status": "ended"
        }
      ],
      "watchOrder": {
        "release": ["Breaking Bad", "Better Call Saul", "El Camino"],
        "chronological": ["Better Call Saul", "Breaking Bad", "El Camino"]
      }
    }
  }
}
```

---

## How It Works

### 1. FranchiseService

The `FranchiseService` fetches franchise data from Firebase and builds an **O(1) lookup map**:

```swift
class FranchiseService {
    private var franchises: [Franchise] = []

    // O(1) lookup: TMDB ID → Franchise
    private var showToFranchise: [Int: Franchise] = [:]

    func fetchFranchises() async {
        // Fetch from Firebase
        let snapshot = try await database.reference().child("franchises").getData()
        franchises = parseFranchises(snapshot)
        buildLookupMap()
    }

    private func buildLookupMap() {
        showToFranchise.removeAll()
        for franchise in franchises {
            // Map parent show
            showToFranchise[franchise.parentShow.tmdbId] = franchise
            // Map all spinoffs
            for spinoff in franchise.spinoffs {
                showToFranchise[spinoff.tmdbId] = franchise
            }
        }
    }

    // O(1) lookup
    func getFranchise(forShowId tmdbId: Int) -> Franchise? {
        return showToFranchise[tmdbId]
    }
}
```

### 2. When User Follows a Show

When a user taps "Follow" on a show, `AddShowUseCase` links spinoffs:

```
User taps "Follow"
    → AddShowUseCase.execute(tmdbId)
    → Save show to database
    → saveFranchiseData(tmdbId)  ← Links spinoffs
```

#### saveFranchiseData Flow:

1. Ensure franchise data is loaded from Firebase
2. Look up if this show belongs to a franchise (O(1) lookup)
3. Collect all related TMDB IDs (parent + spinoffs, excluding self)
4. Store related IDs in the local database

```swift
private func saveFranchiseData(showId: Int) async {
    // 1. Ensure franchise data is loaded
    await franchiseService.fetchFranchises()

    // 2. Check if show is part of a franchise
    guard let franchise = franchiseService.getFranchise(forShowId: showId) else {
        return  // Not part of any franchise
    }

    // 3. Collect related IDs
    var relatedIds: [Int] = []
    relatedIds.append(franchise.parentShow.tmdbId)
    relatedIds.append(contentsOf: franchise.spinoffs.map { $0.tmdbId })
    relatedIds.removeAll { $0 == showId }  // Exclude self

    // 4. Save to local database
    try await repository.updateRelatedShowIds(showId, relatedIds: relatedIds)
}
```

### 3. Displaying Spinoffs in Show Detail

When viewing a show's detail page:

1. Get `relatedShowIds` from local database
2. Fetch each related show's data from TMDB
3. Display in horizontal scroll section

```swift
// In ShowDetailViewModel
func loadRelatedShows() async {
    // 1. Get stored related IDs
    let relatedIds = show.relatedShowIds
    guard !relatedIds.isEmpty else { return }

    // 2. Fetch show data for each
    var shows: [ShowData] = []
    for tmdbId in relatedIds {
        if let show = try? await tmdbService.getShowDetails(tmdbId) {
            shows.append(show)
        }
    }

    // 3. Update UI
    spinoffShows = shows
}
```

---

## Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    APP LAUNCH                                 │
├──────────────────────────────────────────────────────────────┤
│  FranchiseService.fetchFranchises()                          │
│     └─► Fetches from Firebase                                │
│     └─► Builds O(1) lookup map                               │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    USER FOLLOWS SHOW                          │
├──────────────────────────────────────────────────────────────┤
│  AddShowUseCase.execute(tmdbId: 60059)  // Better Call Saul  │
│     │                                                         │
│     ├─► Save show to database                                │
│     │                                                         │
│     └─► saveFranchiseData(60059)                             │
│            │                                                  │
│            ├─► getFranchise(60059) → "breaking-bad"          │
│            │                                                  │
│            ├─► Related IDs: [1396]  (Breaking Bad)           │
│            │   (El Camino removed - it's a movie)            │
│            │                                                  │
│            └─► Store relatedShowIds in database              │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    VIEW SHOW DETAIL                           │
├──────────────────────────────────────────────────────────────┤
│  ShowDetailView loads                                         │
│     │                                                         │
│     ├─► Get relatedShowIds: [1396]                           │
│     │                                                         │
│     ├─► Fetch TMDB details for each                          │
│     │                                                         │
│     └─► Display in "Related" section (premium only)          │
│            • Breaking Bad poster                              │
│            • "Follow" button                                  │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Storage

### Local Database (SwiftData)

Related show IDs are stored in the `FollowedShow` model:

```swift
@Model
class FollowedShow {
    var tmdbId: Int
    var followedAt: Date

    // Spinoff links
    var relatedShowIds: [Int] = []

    var hasSpinoffs: Bool {
        !relatedShowIds.isEmpty
    }
}
```

---

## Premium Gating

The spinoffs section is a **premium feature**:

```swift
// In ShowDetailView
if PremiumManager.shared.canViewSpinoffs {
    ShowDetailRelatedSection(
        recommendations: spinoffShows,
        onTap: onRelatedTap
    )
} else if !spinoffShows.isEmpty {
    // Show upgrade prompt for free users
    ShowDetailRelatedUpgradePrompt()
}
```

Free users see a blurred/locked section with an upgrade prompt.

---

## Supported Franchises

Currently tracked franchises include:

| Franchise | Parent Show | Spinoffs |
|-----------|-------------|----------|
| Breaking Bad | Breaking Bad | Better Call Saul, El Camino |
| Game of Thrones | Game of Thrones | House of the Dragon, A Knight of the Seven Kingdoms |
| Walking Dead | The Walking Dead | Fear TWD, World Beyond, Dead City, Daryl Dixon, The Ones Who Live |
| Yellowstone | Yellowstone | 1883, 1923, The Madison, 6666 |
| Star Wars TV | The Mandalorian | Book of Boba Fett, Obi-Wan, Andor, Ahsoka, The Acolyte, Skeleton Crew |
| Money Heist | La Casa de Papel | Money Heist: Korea, Berlin |
| Kingdom | Kingdom | Kingdom: Ashin of the North |

---

## Key Points

1. **Firebase is the source** - Spinoff data comes from Firebase, not TMDB
2. **TMDB ID is the key** - All lookups and storage use TMDB IDs
3. **O(1) lookups** - Map built on app launch for instant franchise detection
4. **Local storage** - Related IDs cached in SwiftData after following
5. **Premium feature** - Free users see upgrade prompt
