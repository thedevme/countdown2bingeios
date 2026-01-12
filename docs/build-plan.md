# Countdown2Binge iOS — Build Plan v3 (Vertical Slices)

A sequential execution checklist optimized for **early TestFlight builds**.

**Philosophy:** Working features with basic UI first. Polish later.

---

## Quick Reference: All Milestones

| Step | Milestone |
|------|-----------|
| 58 | ✓ State Machine Tests Pass |
| 74 | ✓ TMDB Fetches Data |
| 82 | ✓ Repository Works |
| 84 | ✓ Add Show Flow Complete |
| 148 | ✓ Basic UI Displays |
| 158 | ✓ Runs on Device |
| **172** | **🚀 ALPHA 1 — TestFlight** |
| **226** | **🚀 ALPHA 2 — Mark Watched, Lifecycle** |
| **290** | **🚀 BETA 1 — Gestures, Animations, Onboarding** |
| **342** | **🚀 BETA 2 — Notifications, Settings** |
| **410** | **🚀 RC — Monetization, Final Polish** |
| **420** | **🎉 LAUNCH** |

---

## TestFlight Checkpoints

| Build | Target | Step | What's Working |
|-------|--------|------|----------------|
| **Alpha 1** | End of Week 1 | 172 | Add shows, Timeline, Binge Ready, Show Detail (basic UI) |
| **Alpha 2** | End of Week 2 | 226 | Mark watched, episode checklist, lifecycle complete |
| **Beta 1** | End of Week 3 | 290 | Polished gestures, animations, onboarding |
| **Beta 2** | End of Week 4 | 342 | Notifications, settings complete |
| **RC** | Week 5-6 | 410 | Monetization, final polish |
| **Launch** | Week 6 | 420 | App Store release |

---

## Project Configuration

**Bundle ID:** `io.designtoswiftui.countdown2binge`
**Developer:** Cocoa Academy
**TMDB API Key:** `66be443bd46dc8f896607504aa2d72c6`

---

## Week 1: Core + Basic UI → Alpha 1

---

## Phase 1: Project Setup

### 1.1 — Create Xcode Project
- [ ] 1. Create new Xcode project: "Countdown2Binge"
- [ ] 2. Set iOS deployment target to 17.0
- [ ] 3. Select SwiftUI for interface
- [ ] 4. Select SwiftData for storage
- [ ] 5. Enable "Include Tests" checkbox
- [ ] 6. Set device orientation to Portrait only
- [ ] 7. Set appearance to Dark only

### 1.2 — Configure Project Structure
- [ ] 8. Create folder: `Models/`
- [ ] 9. Create folder: `Services/`
- [ ] 10. Create folder: `Services/TMDB/`
- [ ] 11. Create folder: `Services/StateManagement/`
- [ ] 12. Create folder: `Services/Repository/`
- [ ] 13. Create folder: `UseCases/`
- [ ] 14. Create folder: `ViewModels/`
- [ ] 15. Create folder: `Views/`
- [ ] 16. Create folder: `Views/Timeline/`
- [ ] 17. Create folder: `Views/BingeReady/`
- [ ] 18. Create folder: `Views/Search/`
- [ ] 19. Create folder: `Views/ShowDetail/`
- [ ] 20. Create folder: `Views/Components/`
- [ ] 21. Create folder: `Utilities/`

### 1.3 — Configure Test Structure
- [ ] 22. Create folder: `Countdown2BingeTests/Unit/`
- [ ] 23. Create folder: `Countdown2BingeTests/Fixtures/`
- [ ] 24. Create folder: `Countdown2BingeTests/Helpers/`

### 1.4 — Create Configuration Files
- [ ] 25. Create `.gitignore`
- [ ] 26. Create `README.md`
- [ ] 27. Create `CLAUDE.md`
- [ ] 28. Create `Secrets.swift` (gitignored) with TMDB API key
- [ ] 29. Add `Secrets.swift` to `.gitignore`

---

## Phase 2: Data Models

### 2.1 — Create Enums
- [ ] 30. Create `Models/SeasonState.swift`
  - Cases: `anticipated`, `premiering`, `airing`, `bingeReady`, `watched`

- [ ] 31. Create `Models/ShowStatus.swift`
  - Cases: `returning`, `ended`, `canceled`, `inProduction`, `planned`, `unknown`
  - Include `init(fromTMDB:)` initializer

- [ ] 32. Create `Models/ReleasePattern.swift`
  - Cases: `unknown`, `weekly`, `allAtOnce`, `splitSeason`

### 2.2 — Create Core Models
- [ ] 33. Create `Models/Episode.swift`
  - `@Model` class with: id, tmdbId, episodeNumber, name, airDate, runtime, overview, isWatched

- [ ] 34. Create `Models/Season.swift`
  - `@Model` class with: id, tmdbId, seasonNumber, premiereDate, finaleDate, isFinaleEstimated, episodeCount, airedEpisodeCount, releasePattern, state, watchedDate, posterPath
  - Relationship: episodes, show

- [ ] 35. Create `Models/Show.swift`
  - `@Model` class with: id, tmdbId, title, overview, posterPath, backdropPath, status, addedDate
  - Relationship: seasons (cascade delete)

### 2.3 — Configure SwiftData
- [ ] 36. Update `Countdown2BingeApp.swift` with ModelContainer
- [ ] 37. Add Show, Season, Episode to Schema

---

## Phase 3: State Machine

### 3.1 — Create SeasonStateManager
- [ ] 38. Create `Services/StateManagement/SeasonStateManager.swift`
- [ ] 39. Implement `determineState(for:asOf:) -> SeasonState`
- [ ] 40. Implement `isBingeReady(season:asOf:) -> Bool`
- [ ] 41. Implement `daysUntilPremiere(for:asOf:) -> Int?`
- [ ] 42. Implement `daysUntilFinale(for:asOf:) -> Int?`
- [ ] 43. Implement `episodesRemaining(for:) -> Int?`

### 3.2 — Create SeasonDateResolver
- [ ] 44. Create `Services/StateManagement/SeasonDateResolver.swift`
- [ ] 45. Implement `resolve(seasonAirDate:episodeCount:episodes:) -> SeasonDateInfo`
- [ ] 46. Implement `resolvePremiereDate(...)` 
- [ ] 47. Implement `resolveFinaleDate(...)` with estimation
- [ ] 48. Implement `detectReleasePattern(episodes:)`
- [ ] 49. Implement `countAiredEpisodes(episodes:asOf:)`

### 3.3 — Write Core Tests
- [ ] 50. Create `Countdown2BingeTests/Helpers/DateHelpers.swift`
- [ ] 51. Create `Countdown2BingeTests/Unit/SeasonStateManagerTests.swift`
- [ ] 52. Test: No premiere → anticipated
- [ ] 53. Test: Future premiere → premiering
- [ ] 54. Test: Mid-season → airing
- [ ] 55. Test: Finale passed → bingeReady
- [ ] 56. Test: Watched date set → watched
- [ ] 57. Test: Netflix drop → bingeReady on premiere
- [ ] 58. Run tests — all must pass

**✅ MILESTONE: State Machine Tests Pass (Step 58)**

---

## Phase 4: TMDB Service

### 4.1 — Create TMDB Models
- [ ] 59. Create `Services/TMDB/TMDBModels.swift`
- [ ] 60. Implement TMDBSearchResponse, TMDBSearchResult
- [ ] 61. Implement TMDBShowDetails, TMDBSeasonSummary
- [ ] 62. Implement TMDBSeasonDetails, TMDBEpisode

### 4.2 — Create TMDB Service
- [ ] 63. Create `Services/TMDB/TMDBService.swift`
- [ ] 64. Create `TMDBServiceProtocol`
- [ ] 65. Implement `search(query:) async throws -> [TMDBSearchResult]`
- [ ] 66. Implement `getShowDetails(id:) async throws -> TMDBShowDetails`
- [ ] 67. Implement `getSeasonDetails(showId:seasonNumber:) async throws -> TMDBSeasonDetails`
- [ ] 68. Implement `getTrending() async throws -> [TMDBSearchResult]`
- [ ] 69. Create `TMDBError` enum
- [ ] 70. Configure JSONDecoder for TMDB date format

### 4.3 — Create Data Aggregator
- [ ] 71. Create `Services/TMDB/ShowDataAggregator.swift`
- [ ] 72. Implement `fetchFullShowData(showId:) async throws -> FullShowData`
  - Fetch show details
  - Skip season 0
  - Fetch latest season details

### 4.4 — Create Show Processor
- [ ] 73. Create `Services/TMDB/ShowProcessor.swift`
- [ ] 74. Implement `process(fullData:asOf:) -> Show`
  - Create Show from TMDB data
  - Use DateResolver for dates
  - Use StateManager for initial state

**✅ MILESTONE: TMDB Fetches Data (Step 74)**

---

## Phase 5: Repository

### 5.1 — Create Show Repository
- [ ] 75. Create `Services/Repository/ShowRepository.swift`
- [ ] 76. Implement `save(_ show:) async throws`
- [ ] 77. Implement `fetchAllShows() -> [Show]`
- [ ] 78. Implement `fetchShow(byTmdbId:) -> Show?`
- [ ] 79. Implement `fetchTimelineShows() -> [Show]` (returning/inProduction only)
- [ ] 80. Implement `fetchBingeReadySeasons() -> [Season]`
- [ ] 81. Implement `delete(_ show:) async throws`
- [ ] 82. Implement `isShowFollowed(tmdbId:) -> Bool`

**✅ MILESTONE: Repository Works (Step 82)**

---

## Phase 6: Add Show Use Case

- [ ] 83. Create `UseCases/AddShowUseCase.swift`
- [ ] 84. Implement `execute(tmdbId:) async throws -> Show`
  - Check if already followed
  - Fetch full show data
  - Process into local model
  - Save to repository
  - Return saved show

**✅ MILESTONE: Add Show Flow Complete (Step 84)**

---

## Phase 7: Basic UI Components

### 7.1 — Create Shared Components
- [ ] 85. Create `Views/Components/ShowCard.swift`
  - AsyncImage for backdrop
  - Title overlay
  - Basic styling (rounded corners, shadow)

- [ ] 86. Create `Views/Components/StateBadge.swift`
  - Colored badge showing state (Airing, Premiering, etc.)
  - Different colors per state

- [ ] 87. Create `Views/Components/CountdownText.swift`
  - Shows "X DAYS" or "X EPISODES"
  - Simple Text view

- [ ] 88. Create `Views/Components/AddButton.swift`
  - "+ Add" / "Added ✓" states
  - Tappable

---

## Phase 8: Basic Search UI

### 8.1 — Create Search ViewModel
- [ ] 89. Create `ViewModels/SearchViewModel.swift`
- [ ] 90. Properties: `searchQuery`, `searchResults`, `isSearching`, `error`
- [ ] 91. Method: `search() async`
- [ ] 92. Method: `addShow(tmdbId:) async -> Bool`
- [ ] 93. Method: `isFollowed(tmdbId:) -> Bool`

### 8.2 — Create Search Screen
- [ ] 94. Create `Views/Search/SearchView.swift`
- [ ] 95. TextField for search query
- [ ] 96. List of search results
- [ ] 97. Each result: poster, title, year, add button
- [ ] 98. Loading indicator while searching
- [ ] 99. "No results" empty state
- [ ] 100. Toast/alert on add success

---

## Phase 9: Basic Timeline UI

### 9.1 — Create Timeline ViewModel
- [ ] 101. Create `ViewModels/TimelineViewModel.swift`
- [ ] 102. Properties: `airingShows`, `premieringShows`, `anticipatedShows`
- [ ] 103. Property: `isLoading`
- [ ] 104. Method: `loadShows()`
- [ ] 105. Computed: Sort airing by days until finale
- [ ] 106. Computed: Sort premiering by days until premiere

### 9.2 — Create Basic Timeline Screen
- [ ] 107. Create `Views/Timeline/TimelineView.swift`
- [ ] 108. Header: "TIMELINE" title
- [ ] 109. Section: "AIRING NOW" with list of shows
  - Each row: ShowCard + countdown + state badge
- [ ] 110. Section: "PREMIERING SOON" with list of shows
- [ ] 111. Section: "ANTICIPATED" with list of shows
- [ ] 112. Empty state when no shows
- [ ] 113. Tap show → navigate to detail (placeholder for now)

---

## Phase 10: Basic Show Detail UI

### 10.1 — Create Show Detail ViewModel
- [ ] 114. Create `ViewModels/ShowDetailViewModel.swift`
- [ ] 115. Properties: `show`, `selectedSeasonNumber`, `isFollowed`
- [ ] 116. Method: `removeShow() async`
- [ ] 117. Method: `selectSeason(_ number:)`

### 10.2 — Create Show Detail Screen
- [ ] 118. Create `Views/ShowDetail/ShowDetailView.swift`
- [ ] 119. Backdrop image header
- [ ] 120. Title and status
- [ ] 121. Current season info
- [ ] 122. Countdown to premiere/finale
- [ ] 123. Basic season picker (if multiple)
- [ ] 124. Remove show button (if followed)

---

## Phase 11: Basic Binge Ready UI

### 11.1 — Create Binge Ready ViewModel
- [ ] 125. Create `ViewModels/BingeReadyViewModel.swift`
- [ ] 126. Properties: `bingeReadySeasons`
- [ ] 127. Method: `loadSeasons()`

### 11.2 — Create Basic Binge Ready Screen
- [ ] 128. Create `Views/BingeReady/BingeReadyView.swift`
- [ ] 129. Header: "BINGE READY" title
- [ ] 130. List of seasons ready to binge
- [ ] 131. Each row: Show poster, season info, episode count
- [ ] 132. Empty state

---

## Phase 12: Navigation Setup

### 12.1 — Create Tab Navigation
- [ ] 133. Update `ContentView.swift` with TabView
- [ ] 134. Tab 1: Timeline
- [ ] 135. Tab 2: Binge Ready
- [ ] 136. Tab 3: Search
- [ ] 137. Style tab bar (dark theme)

### 12.2 — Wire Up Navigation
- [ ] 138. Timeline → Show Detail navigation
- [ ] 139. Binge Ready → Show Detail navigation
- [ ] 140. Search → Show Detail navigation
- [ ] 141. Pass show data correctly

---

## Phase 13: State Refresh

### 13.1 — Create State Refresh Service
- [ ] 142. Create `Services/StateManagement/StateRefreshService.swift`
- [ ] 143. Implement `refreshAllShows() async`
- [ ] 144. Update states based on current date
- [ ] 145. Save updated states

### 13.2 — Integrate Refresh
- [ ] 146. Refresh on app launch
- [ ] 147. Refresh on app foreground
- [ ] 148. Manual pull-to-refresh on Timeline

**✅ MILESTONE: Basic UI Displays (Step 148)**

---

## Phase 14: Device Testing

### 14.1 — Build on Device
- [ ] 149. Configure signing with your developer account
- [ ] 150. Select your iPhone as target
- [ ] 151. Build and run on device
- [ ] 152. Test search works
- [ ] 153. Test add show works
- [ ] 154. Test Timeline displays shows
- [ ] 155. Test Binge Ready displays shows
- [ ] 156. Test Show Detail loads
- [ ] 157. Test state updates correctly
- [ ] 158. Fix any device-specific issues

**✅ MILESTONE: Runs on Device (Step 158)**

---

## Phase 15: TestFlight Alpha 1 Prep

### 15.1 — App Store Connect Setup
- [ ] 159. Log in to App Store Connect
- [ ] 160. Create app record
- [ ] 161. Set bundle ID: `io.designtoswiftui.countdown2binge`
- [ ] 162. Set version 0.9.0 (1)

### 15.2 — Build Configuration
- [ ] 163. Add app icon (your C2B retro TV icon)
- [ ] 164. Set Display Name: "Countdown2Binge"
- [ ] 165. Configure build number
- [ ] 166. Archive build

### 15.3 — Upload & Submit
- [ ] 167. Upload to App Store Connect
- [ ] 168. Add export compliance info
- [ ] 169. Submit for TestFlight review
- [ ] 170. Wait for approval (usually ~24h)
- [ ] 171. Enable internal testing
- [ ] 172. Install via TestFlight

**✅ 🚀 ALPHA 1 — TestFlight (Step 172)**

---

## Week 2: Complete Lifecycle → Alpha 2

---

## Phase 16: Mark Watched Flow

### 16.1 — Create Mark Watched Use Case
- [ ] 173. Create `UseCases/MarkWatchedUseCase.swift`
- [ ] 174. Implement `execute(season:) async throws -> MarkWatchedResult`
- [ ] 175. Mark season as watched
- [ ] 176. Check show status (Ended vs Returning)
- [ ] 177. If returning → add next season to Anticipated
- [ ] 178. If ended → no action (stays in Binge Ready)

### 16.2 — Mark Watched Result Types
- [ ] 179. Create `MarkWatchedResult` enum
- [ ] 180. Case: `showComplete` (series ended)
- [ ] 181. Case: `nextSeasonAdded` (more coming)
- [ ] 182. Case: `nextSeasonPlaceholder` (no TMDB data yet)

### 16.3 — UI Integration
- [ ] 183. Add "Mark Watched" button to Binge Ready row
- [ ] 184. Add "Mark Watched" button to Show Detail
- [ ] 185. Swipe action on Binge Ready row
- [ ] 186. Confirmation alert
- [ ] 187. Success feedback

---

## Phase 17: Episode Checklist

### 17.1 — Episode List UI
- [ ] 188. Create `Views/ShowDetail/EpisodeListView.swift`
- [ ] 189. Show all episodes for selected season
- [ ] 190. Episode row: number, title, air date
- [ ] 191. Checkbox for watched status
- [ ] 192. Dimmed style for unwatched
- [ ] 193. Checkmark style for watched

### 17.2 — Episode Toggle Logic
- [ ] 194. Create `MarkEpisodeWatchedUseCase.swift`
- [ ] 195. Toggle individual episode watched
- [ ] 196. Update aired episode count
- [ ] 197. If all watched → auto-mark season complete?

### 17.3 — Integrate into Show Detail
- [ ] 198. Show episode list below season picker
- [ ] 199. Collapsible section
- [ ] 200. Episode count summary

---

## Phase 18: Season Progression

### 18.1 — Season Cards (Stacked)
- [ ] 201. Create `Views/ShowDetail/SeasonCardStack.swift`
- [ ] 202. Stack seasons as cards
- [ ] 203. Current season on top
- [ ] 204. Swipe right → complete season
- [ ] 205. Swipe left → previous season
- [ ] 206. Swipe down → complete all

### 18.2 — Season Detail View
- [ ] 207. Create `Views/ShowDetail/SeasonDetailView.swift`
- [ ] 208. Season poster
- [ ] 209. Premiere/finale dates
- [ ] 210. Episode count
- [ ] 211. State badge
- [ ] 212. Countdown display

---

## Phase 19: Lifecycle Tests

### 19.1 — Integration Tests
- [ ] 213. Create `Countdown2BingeTests/Unit/MarkWatchedTests.swift`
- [ ] 214. Test: Mark watched → adds next season
- [ ] 215. Test: Ended show → no next season
- [ ] 216. Test: Full cycle simulation

### 19.2 — The Golden Test
- [ ] 217. Create `Countdown2BingeTests/Unit/GoldenCycleTests.swift`
- [ ] 218. Add show → Anticipated
- [ ] 219. Simulate premiere → Premiering
- [ ] 220. Simulate airing → Airing
- [ ] 221. Simulate finale → Binge Ready
- [ ] 222. Mark watched → Next Season in Anticipated
- [ ] 223. Verify full cycle works

---

## Phase 20: TestFlight Alpha 2 Prep

### 20.1 — Prepare Build
- [ ] 224. Increment version to 0.9.2 (2)
- [ ] 225. Archive and upload
- [ ] 226. Submit for TestFlight review

**✅ 🚀 ALPHA 2 — Mark Watched, Lifecycle Complete (Step 226)**

---

## Week 3: Polish + Onboarding → Beta 1

---

## Phase 21: Timeline Polish

### 21.1 — Currently Airing Cards
- [ ] 227. Create `Views/Timeline/AiringCardView.swift`
- [ ] 228. Large backdrop image
- [ ] 229. Big countdown number
- [ ] 230. Season/show info overlay
- [ ] 231. Horizontal scrolling for multiple

### 21.2 — Slot Machine Countdown
- [ ] 232. Create `Views/Components/SlotMachineCountdown.swift`
- [ ] 233. Fixed "TODAY" marker in center
- [ ] 234. Scrolling days display
- [ ] 235. Finale date on right
- [ ] 236. Animate on card change

### 21.3 — Timeline Sections
- [ ] 237. Premiering Soon list refinement
- [ ] 238. Anticipated list refinement
- [ ] 239. Visual hierarchy (solid → dashed → faded)
- [ ] 240. "+X more" badges

---

## Phase 22: Binge Ready Polish

### 22.1 — Enhanced Binge Ready Cards
- [ ] 241. Create `Views/BingeReady/BingeReadyCardView.swift`
- [ ] 242. Show backdrop
- [ ] 243. Season info
- [ ] 244. Episode count
- [ ] 245. Swipe to mark watched

### 22.2 — Grouping Options
- [ ] 246. Group by show
- [ ] 247. Sort by date added
- [ ] 248. Sort by episode count

---

## Phase 23: Gestures & Animations

### 23.1 — Card Gestures
- [ ] 249. Swipe right → complete
- [ ] 250. Swipe left → previous
- [ ] 251. Swipe down → complete series
- [ ] 252. Haptic feedback

### 23.2 — Transitions
- [ ] 253. Card removal animation
- [ ] 254. State change animation
- [ ] 255. Add show animation
- [ ] 256. Loading shimmer

---

## Phase 24: Empty States

- [ ] 257. Create `Views/Components/EmptyStateView.swift`
- [ ] 258. Timeline empty state
- [ ] 259. Binge Ready empty state
- [ ] 260. Search empty state
- [ ] 261. No results empty state

---

## Phase 25: Onboarding

### 25.1 — Create Onboarding Flow
- [ ] 262. Create `Views/Onboarding/OnboardingView.swift`
- [ ] 263. Page 1: "Track Your Shows" (concept)
- [ ] 264. Page 2: "Know When to Binge" (timeline)
- [ ] 265. Page 3: "Never Miss a Finale" (notifications teaser)
- [ ] 266. Page indicators
- [ ] 267. Skip button
- [ ] 268. "Get Started" button

### 25.2 — First Launch Flow
- [ ] 269. Check if first launch (UserDefaults)
- [ ] 270. Show onboarding on first launch
- [ ] 271. After onboarding → Search screen
- [ ] 272. Add first show prompt

---

## Phase 26: Settings (Basic)

### 26.1 — Create Settings Screen
- [ ] 273. Create `Views/Settings/SettingsView.swift`
- [ ] 274. Add Settings tab (gear icon)
- [ ] 275. App version display
- [ ] 276. "About" section
- [ ] 277. TMDB attribution
- [ ] 278. Reset onboarding (for testing)

### 26.2 — Refresh Settings
- [ ] 279. Manual refresh all shows button
- [ ] 280. Last refreshed timestamp

---

## Phase 27: TestFlight Beta 1 Prep

### 27.1 — Prepare Build
- [ ] 281. Increment version to 0.9.4 (3)
- [ ] 282. QA all features
- [ ] 283. Fix any bugs
- [ ] 284. Archive and upload

### 27.2 — Beta Testing
- [ ] 285. Submit for TestFlight review
- [ ] 286. Enable external testing
- [ ] 287. Invite beta testers (5-10)
- [ ] 288. Create feedback form
- [ ] 289. Monitor crash reports
- [ ] 290. Collect feedback

**✅ 🚀 BETA 1 — Gestures, Animations, Onboarding (Step 290)**

---

## Week 4: Notifications + Settings → Beta 2

---

## Phase 28: Notification Service

### 28.1 — Create Notification Service
- [ ] 291. Create `Services/NotificationService.swift`
- [ ] 292. Method: `requestPermission() async -> Bool`
- [ ] 293. Method: `scheduleBingeReady(for season:)`
- [ ] 294. Method: `schedulePremiereReminder(for season:, timing:)`
- [ ] 295. Method: `scheduleFinaleReminder(for season:, timing:)`
- [ ] 296. Method: `cancelAll(for show:)`
- [ ] 297. Create ReminderTiming enum

### 28.2 — Create Permission Request
- [ ] 298. Create `Views/Components/NotificationPermissionView.swift`
- [ ] 299. Explain benefit
- [ ] 300. Enable button → system prompt
- [ ] 301. Skip option

### 28.3 — Integrate Notifications
- [ ] 302. Request permission after first show added
- [ ] 303. Schedule notifications when show added
- [ ] 304. Cancel notifications when show removed
- [ ] 305. Respect user preferences

---

## Phase 29: Enhanced Search

### 29.1 — Add Trending Section
- [ ] 306. Update SearchViewModel with `trendingShows`
- [ ] 307. Load trending on appear
- [ ] 308. Create `Views/Search/TrendingSectionView.swift`
- [ ] 309. Horizontal scroll of show cards

### 29.2 — Add Category Filters
- [ ] 310. Add category chips (All, Sci-Fi, Drama, Action)
- [ ] 311. Filter search results by category

### 29.3 — Create Search Landing
- [ ] 312. Show landing when query empty
- [ ] 313. Show results when query entered
- [ ] 314. Trending shows section on landing

---

## Phase 30: Enhanced Show Detail

### 30.1 — Add Trailers
- [ ] 315. Fetch videos from TMDB
- [ ] 316. Create `Views/ShowDetail/TrailerRow.swift`
- [ ] 317. Tap → open YouTube or inline player

### 30.2 — Add Cast & Crew
- [ ] 318. Fetch credits from TMDB
- [ ] 319. Create `Views/ShowDetail/CastRow.swift`
- [ ] 320. Horizontal scroll of cast members

### 30.3 — Add Recommendations
- [ ] 321. Fetch recommendations from TMDB
- [ ] 322. Create `Views/ShowDetail/RecommendationsSection.swift`
- [ ] 323. Tap recommendation → new detail view

---

## Phase 31: Settings (Complete)

### 31.1 — Notification Settings
- [ ] 324. Toggle: Binge Ready alerts
- [ ] 325. Toggle: Premiere reminders
- [ ] 326. Toggle: Finale reminders
- [ ] 327. Reminder timing picker (1 day, 3 days, 1 week)

### 31.2 — Data Management
- [ ] 328. Export data option
- [ ] 329. Clear all data option (with confirmation)

### 31.3 — Legal
- [ ] 330. Privacy policy link
- [ ] 331. Terms of service link

---

## Phase 32: TestFlight Beta 2 Prep

### 32.1 — Prepare Build
- [ ] 332. Increment version to 0.9.5 (4)
- [ ] 333. Fix bugs from Beta 1
- [ ] 334. Archive and upload

### 32.2 — Expand Testing
- [ ] 335. Invite more testers (10-20)
- [ ] 336. Test notifications work
- [ ] 337. Collect feedback
- [ ] 338. Create App Store preview screenshots
- [ ] 339. Write release notes
- [ ] 340. Final QA pass
- [ ] 341. Address critical feedback
- [ ] 342. Prepare for RC

**✅ 🚀 BETA 2 — Notifications, Settings Complete (Step 342)**

---

## Week 5-6: Monetization + Final Polish → RC

---

## Phase 33: RevenueCat Integration

### 33.1 — Configure RevenueCat
- [ ] 343. Add RevenueCat SDK via SPM
- [ ] 344. Create RevenueCat account + app
- [ ] 345. Configure entitlement: "premium"
- [ ] 346. Configure offering with subscription
- [ ] 347. Configure 7-day free trial
- [ ] 348. Initialize in app startup

### 33.2 — Create Premium Manager
- [ ] 349. Create `Services/PremiumManager.swift`
- [ ] 350. Property: `isPremium: Bool`
- [ ] 351. Property: `isInTrial: Bool`
- [ ] 352. Method: `checkEntitlements() async`
- [ ] 353. Method: `purchase() async`
- [ ] 354. Method: `restorePurchases() async`

### 33.3 — Create Paywall
- [ ] 355. Create `Views/Settings/PaywallView.swift`
- [ ] 356. Show subscription options
- [ ] 357. Highlight free trial
- [ ] 358. Purchase button
- [ ] 359. Restore purchases button

### 33.4 — Implement Free Tier Limits
- [ ] 360. Free tier: 1 show only
- [ ] 361. Free tier: No notifications
- [ ] 362. Free tier: No countdowns (just status text)
- [ ] 363. Add checks in AddShowUseCase
- [ ] 364. Add upgrade prompts in UI

### 33.5 — Add Subscription Management to Settings
- [ ] 365. Show current subscription status
- [ ] 366. Link to PaywallView
- [ ] 367. Restore purchases option

---

## Phase 34: Ads Integration

### 34.1 — Configure AdMob
- [ ] 368. Add Google AdMob SDK via SPM
- [ ] 369. Configure app ID in Info.plist
- [ ] 370. Create `Services/AdManager.swift`

### 34.2 — Add Banner Ads
- [ ] 371. Create `Views/Components/BannerAdView.swift`
- [ ] 372. Place in non-intrusive location
- [ ] 373. Hide for premium users

### 34.3 — Add Interstitial Ads
- [ ] 374. Load interstitials
- [ ] 375. Show at natural breakpoints
- [ ] 376. Frequency cap
- [ ] 377. Hide for premium users

---

## Phase 35: Crash Reporting & Analytics

### 35.1 — Firebase Setup
- [ ] 378. Add Firebase SDK via SPM
- [ ] 379. Add GoogleService-Info.plist
- [ ] 380. Initialize Firebase
- [ ] 381. Configure Crashlytics

### 35.2 — Add Analytics Events
- [ ] 382. Track: app_open
- [ ] 383. Track: onboarding_complete
- [ ] 384. Track: show_added
- [ ] 385. Track: season_completed
- [ ] 386. Track: subscription_started

---

## Phase 36: Accessibility

- [ ] 387. Add accessibility labels to all interactive elements
- [ ] 388. Add accessibility hints for gestures
- [ ] 389. Test with VoiceOver
- [ ] 390. Test with Dynamic Type (all sizes)
- [ ] 391. Check contrast ratios
- [ ] 392. Add Reduce Motion support

---

## Phase 37: Final Polish

### 37.1 — Visual Polish
- [ ] 393. Review all screens match designs
- [ ] 394. Smooth all animations
- [ ] 395. Add loading states everywhere
- [ ] 396. Add error states everywhere

### 37.2 — Bug Fixes
- [ ] 397. Fix all reported bugs
- [ ] 398. Fix any crashes in Crashlytics
- [ ] 399. Edge case testing

### 37.3 — Performance
- [ ] 400. Profile with Instruments
- [ ] 401. Fix any memory leaks
- [ ] 402. Optimize image loading

---

## Phase 38: Release Candidate 🚀

### 38.1 — Prepare RC Build
- [ ] 403. Set version to 1.0.0 (5)
- [ ] 404. Final QA pass
- [ ] 405. Archive and upload
- [ ] 406. Submit for TestFlight review

### 38.2 — Public Beta
- [ ] 407. Enable public TestFlight link
- [ ] 408. Share beta link
- [ ] 409. Monitor Crashlytics
- [ ] 410. Collect final feedback

**✅ 🚀 RC — Monetization, Final Polish (Step 410)**

---

## Phase 39: App Store Submission

### 39.1 — App Store Assets
- [ ] 411. Create screenshots (6.7", 6.5", 5.5")
- [ ] 412. Write app description
- [ ] 413. Write subtitle
- [ ] 414. Add keywords
- [ ] 415. Create privacy policy URL

### 39.2 — Submit
- [ ] 416. Complete App Store Connect listing
- [ ] 417. Configure pricing
- [ ] 418. Submit for App Store review
- [ ] 419. Wait for approval
- [ ] 420. Release!

**✅ 🎉 VERSION 1.0 SHIPPED (Step 420)**

---

## Summary

| Week | Goal | Steps | TestFlight |
|------|------|-------|------------|
| 1 | Core + Basic UI | 1-172 | Alpha 1 |
| 2 | Complete Lifecycle | 173-226 | Alpha 2 |
| 3 | Polish Gestures + Onboarding | 227-290 | Beta 1 |
| 4 | Settings + Notifications | 291-342 | Beta 2 |
| 5-6 | Monetization + Final | 343-420 | RC → Launch |

**Total: 420 steps**

---

## Design Dependencies

You need these designs before the corresponding phase:

| Design Needed | Blocks Phase | Latest Need By |
|---------------|--------------|----------------|
| Timeline variations | Phase 21 | End of Week 2 |
| Show Detail (Followed) with seasons | Phase 18 | End of Week 2 |
| Binge Ready (done ✅) | Phase 22 | — |
| Settings | Phase 26/31 | End of Week 3 |
| Full Timeline | Phase 21 | End of Week 3 |
| Empty states | Phase 24 | End of Week 3 |
| Paywall | Phase 33 | End of Week 4 |
| Notification permission | Phase 28 | End of Week 4 |
