# Backend API Options for Countdown2Binge

## Overview

This document outlines options for building a custom backend API to replace direct TMDB calls. The goals are:

1. **Reduce API calls** - One call returns all show data (vs 8+ TMDB calls per show)
2. **Own the data** - Build a database over time for resilience
3. **Custom structure** - Shape the API to match app needs exactly
4. **Add TVmaze** - Supplement with premiere/schedule data

---

## Current Problem

TMDB requires multiple calls to get complete show data:

```
GET /tv/{id}                    → show basics
GET /tv/{id}/season/1           → season 1 episodes
GET /tv/{id}/season/2           → season 2 episodes
GET /tv/{id}/season/3           → ...repeat per season
GET /tv/{id}/credits            → cast
GET /tv/{id}/videos             → trailers
GET /tv/{id}/images             → logos
```

A show with 5 seasons = **8+ API calls** to load one detail screen.

---

## Solution Architecture

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────┐
│   iOS App   │ ──→  │    YOUR API      │ ──→  │    TMDB     │
└─────────────┘      │   (proxy/cache)  │      └─────────────┘
                     │        ↓         │
                     │   Your Database  │ ←── TVmaze (daily cron)
                     │   (PostgreSQL)   │
                     └──────────────────┘
```

**Flow:**
1. App requests show #12345
2. Your API checks database → not found
3. Fetches from TMDB → stores in your DB → returns to app
4. Next request → returns cached data instantly
5. Daily cron fetches TVmaze schedule for upcoming premieres

---

## Options Comparison

| | Supabase | Railway | DIY Droplet |
|--|----------|---------|-------------|
| **Monthly Cost** | $0-25 | $15-25 | $6-12 |
| **Write API Code** | No (auto-generated) | Yes | Yes |
| **API Control** | Low-Medium | High | Total |
| **Database** | Included (Postgres) | Add-on (Postgres) | You install |
| **Server Management** | None | None | You manage |
| **Effort** | Low | Medium | High |
| **Flexibility** | Limited | High | Total |

---

## Option 1: Supabase

### What It Is
Firebase alternative with PostgreSQL, auto-generated REST API, and Edge Functions.

### Pricing
| Plan | Cost | Database | Notes |
|------|------|----------|-------|
| Free | $0/mo | 500 MB | Pauses after 1 week inactive |
| Pro | $25/mo | 8 GB | Production ready |

### Pros
- Auto-generated API from database tables (no code)
- Edge Functions for custom logic
- Built-in auth if needed later
- Quick to set up

### Cons
- API response format is Supabase's format (PostgREST)
- Less control over API structure
- Edge Functions are Deno/TypeScript only
- Vendor lock-in concerns

### Best For
"I want a database with an API and don't want to write backend code"

---

## Option 2: Railway

### What It Is
Platform-as-a-Service for deploying any backend (Node.js, Python, Go, etc.)

### Pricing
| Plan | Cost | Includes |
|------|------|----------|
| Hobby | $5/mo | $5 usage credit |
| Pro | $20/mo | $20 usage credit |

**Usage rates:**
- RAM: $10/GB/month
- CPU: $20/vCPU/month
- Egress: $0.05/GB

**Realistic total:** $15-25/mo for API + PostgreSQL

### Pros
- Full control over API routes and response shapes
- Use any language/framework
- Easy deployment (git push)
- No server management

### Cons
- More code to write than Supabase
- Usage-based billing (no hard cap by default)
- Costs add up with multiple services

### Best For
"I want to write my own API but not manage servers"

---

## Option 3: DIY Droplet (DigitalOcean/Linode)

### What It Is
Virtual private server you manage yourself.

### Pricing
| Provider | Cost | Specs |
|----------|------|-------|
| DigitalOcean | $6/mo | 1 GB RAM, 25 GB SSD |
| Linode | $5/mo | 1 GB RAM, 25 GB SSD |
| Hetzner | $4/mo | 2 GB RAM, 20 GB SSD |

### You Manage
- Ubuntu/Linux server
- Node.js/Python runtime
- PostgreSQL installation
- Nginx reverse proxy
- SSL certificates (Let's Encrypt)
- Firewall (UFW)
- Backups
- Security updates

### Pros
- Cheapest option ($6/mo for everything)
- 100% control over everything
- No vendor lock-in
- Run multiple projects on one server

### Cons
- You fix it when it breaks (even at 2am)
- Security responsibility is yours
- Setup takes longer
- Need Linux/terminal comfort

### Best For
"I want full control and I'm comfortable with Linux"

---

## Recommended: Railway

For Countdown2Binge, **Railway** offers the best balance:

1. **Control** - Define exact API response shapes
2. **Simplicity** - No server management
3. **Cost** - ~$20/mo is reasonable
4. **Flexibility** - Easy to add Redis, workers, etc.

### Proposed API Structure

```
GET  /shows/search?q=severance     → search shows
GET  /shows/{id}                   → full show + seasons + episodes + cast
GET  /shows/trending               → trending shows
GET  /shows/upcoming               → premieres from TVmaze
POST /shows/{id}/refresh           → force refresh from TMDB
```

### Single Response Example

```json
{
  "id": 12345,
  "name": "Severance",
  "overview": "...",
  "status": "Returning Series",
  "images": {
    "poster": "https://...",
    "backdrop": "https://...",
    "logo": "https://..."
  },
  "networks": [{"id": 350, "name": "Apple TV+"}],
  "genres": [{"id": 18, "name": "Drama"}],
  "seasons": [
    {
      "number": 1,
      "episodeCount": 9,
      "episodes": [
        {
          "number": 1,
          "name": "Good News About Hell",
          "airDate": "2022-02-18",
          "runtime": 57,
          "overview": "..."
        }
      ]
    }
  ],
  "cast": [...],
  "videos": [...],
  "_meta": {
    "cachedAt": "2026-07-27T12:00:00Z",
    "source": "cache"
  }
}
```

---

## Database Schema

```sql
-- Main shows table (denormalized)
CREATE TABLE shows (
  id INT PRIMARY KEY,              -- TMDB ID
  name TEXT NOT NULL,
  overview TEXT,
  poster_path TEXT,
  backdrop_path TEXT,
  logo_path TEXT,
  status TEXT,
  first_air_date DATE,
  vote_average DECIMAL(3,1),
  networks JSONB,
  genres JSONB,
  created_by JSONB,
  number_of_seasons INT,
  number_of_episodes INT,
  in_production BOOLEAN,
  seasons JSONB,                   -- All seasons + episodes
  cast JSONB,
  videos JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Upcoming premieres (from TVmaze)
CREATE TABLE upcoming (
  id SERIAL PRIMARY KEY,
  tvmaze_id INT,
  tmdb_id INT,
  name TEXT,
  premiere_date DATE,
  network TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_shows_updated ON shows(updated_at);
CREATE INDEX idx_upcoming_date ON upcoming(premiere_date);
```

---

## TVmaze Integration

### Why TVmaze
- Free, no API key required
- Purpose-built for TV schedules
- `/schedule/full` returns ALL future episodes in one call

### License: CC BY-SA 4.0
- Commercial use allowed
- Must attribute TVmaze
- Data fetched server-side, transformed, stored as your own

### Daily Sync (GitHub Actions)

```yaml
name: Sync Upcoming Shows
on:
  schedule:
    - cron: '0 5 * * *'  # 5am UTC daily
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - run: curl -X POST https://your-api.railway.app/sync/upcoming
```

---

## iOS App Changes

### Before (TMDBService.swift)
```swift
let details = try await tmdb.getShowDetails(id: 12345)
let season1 = try await tmdb.getSeasonDetails(id: 12345, season: 1)
let season2 = try await tmdb.getSeasonDetails(id: 12345, season: 2)
let credits = try await tmdb.getCredits(id: 12345)
let videos = try await tmdb.getVideos(id: 12345)
// 5+ calls...
```

### After (ShowService.swift)
```swift
class ShowService {
    static let shared = ShowService()
    private let baseURL = "https://your-api.railway.app"

    func getShow(id: Int) async throws -> ShowData {
        let url = URL(string: "\(baseURL)/shows/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ShowData.self, from: data)
    }

    func search(query: String) async throws -> [ShowSummary] {
        let url = URL(string: "\(baseURL)/shows/search?q=\(query)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ShowSummary].self, from: data)
    }

    func getUpcoming() async throws -> [UpcomingShow] {
        let url = URL(string: "\(baseURL)/shows/upcoming")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([UpcomingShow].self, from: data)
    }
}
```

---

## Implementation Timeline

### Phase 1: Setup (Week 1)
- [ ] Create Railway account
- [ ] Set up PostgreSQL database
- [ ] Create basic Node.js/Express API
- [ ] Deploy and test connectivity

### Phase 2: Core API (Week 2)
- [ ] Implement `/shows/{id}` with TMDB fetching
- [ ] Add caching logic (check DB first)
- [ ] Implement `/shows/search`
- [ ] Test with iOS app

### Phase 3: TVmaze (Week 3)
- [ ] Add TVmaze sync endpoint
- [ ] Set up GitHub Actions cron
- [ ] Implement `/shows/upcoming`
- [ ] Cross-reference TMDB IDs

### Phase 4: Migration (Week 4)
- [ ] Update iOS app to use new API
- [ ] Keep TMDB as fallback initially
- [ ] Monitor and tune performance
- [ ] Full cutover

---

## Cost Summary

| Option | Monthly | Annual |
|--------|---------|--------|
| Supabase Pro | $25 | $300 |
| Railway (realistic) | $20 | $240 |
| DIY Droplet | $6 | $72 |

**Recommendation:** Start with Railway at ~$20/mo. Migrate to DIY later if you want to cut costs after learning the patterns.

---

## Next Steps

1. Decide: Railway vs DIY
2. Set up the chosen platform
3. Build the API skeleton
4. Migrate one endpoint at a time
5. Add TVmaze after core TMDB proxy works
