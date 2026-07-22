# Countdown2Binge Localization Guide

## Overview

Countdown2Binge supports **15 languages** with full localization of UI text, accessibility labels, notifications, and user-facing content. This guide documents the complete localization system.

---

## Supported Languages

| Code | Language | Direction | Notes |
|------|----------|-----------|-------|
| `en` | English | LTR | Base language |
| `es` | Spanish | LTR | |
| `fr` | French | LTR | |
| `de` | German | LTR | |
| `pt-BR` | Portuguese (Brazil) | LTR | |
| `it` | Italian | LTR | |
| `ja` | Japanese | LTR | |
| `ko` | Korean | LTR | |
| `zh-Hans` | Chinese (Simplified) | LTR | |
| `ar` | Arabic | **RTL** | Right-to-left |
| `ru` | Russian | LTR | |
| `tr` | Turkish | LTR | |
| `pl` | Polish | LTR | |
| `nl` | Dutch | LTR | |
| `th` | Thai | LTR | |

---

## File Structure

```
Countdown2Binge/
└── Resources/
    ├── en.lproj/
    │   └── Localizable.strings    ← Base (English)
    ├── es.lproj/
    │   └── Localizable.strings    ← Spanish
    ├── fr.lproj/
    │   └── Localizable.strings    ← French
    ├── de.lproj/
    │   └── Localizable.strings    ← German
    ├── pt-BR.lproj/
    │   └── Localizable.strings    ← Portuguese (Brazil)
    ├── it.lproj/
    │   └── Localizable.strings    ← Italian
    ├── ja.lproj/
    │   └── Localizable.strings    ← Japanese
    ├── ko.lproj/
    │   └── Localizable.strings    ← Korean
    ├── zh-Hans.lproj/
    │   └── Localizable.strings    ← Chinese (Simplified)
    ├── ar.lproj/
    │   └── Localizable.strings    ← Arabic (RTL)
    ├── ru.lproj/
    │   └── Localizable.strings    ← Russian
    ├── tr.lproj/
    │   └── Localizable.strings    ← Turkish
    ├── pl.lproj/
    │   └── Localizable.strings    ← Polish
    ├── nl.lproj/
    │   └── Localizable.strings    ← Dutch
    └── th.lproj/
        └── Localizable.strings    ← Thai
```

### Info.plist Configuration

Languages are registered in `Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>es</string>
    <string>fr</string>
    <string>de</string>
    <string>pt-BR</string>
    <string>it</string>
    <string>ja</string>
    <string>ko</string>
    <string>zh-Hans</string>
    <string>ar</string>
    <string>ru</string>
    <string>tr</string>
    <string>pl</string>
    <string>nl</string>
    <string>th</string>
</array>
```

---

## Key Naming Conventions

### Format

Keys use **snake_case** with category prefixes:

```
{category}_{description}
```

### Category Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `tab_` | Tab bar labels | `tab_timeline`, `tab_search` |
| `button_` | Button text | `button_follow`, `button_cancel` |
| `search_` | Search screen | `search_placeholder`, `search_no_results` |
| `timeline_` | Timeline screen | `timeline_heading`, `timeline_nothing` |
| `binge_ready_` | Binge Ready screen | `binge_ready_heading` |
| `badge_` | Status badges | `badge_airing`, `badge_watched` |
| `status_` | Show status text | `status_watched`, `status_ended` |
| `date_` | Date labels | `date_premiere`, `date_finale` |
| `time_` | Time units | `time_days`, `time_hours` |
| `season_` | Season labels | `season_label`, `season_watched` |
| `notification_` | Notification text | `notification_new_episodes` |
| `settings_` | Settings screen | `settings_heading`, `settings_sound` |
| `premium_` | Premium/paywall | `premium_unlock`, `premium_lifetime` |
| `empty_` | Empty states | `empty_nothing_to_binge` |
| `alert_` | Alert dialogs | `alert_remove_show` |
| `onboarding_` | Onboarding flow | `onboarding_welcome` |
| `show_detail_` | Show detail screen | `show_detail_overview` |
| `a11y_` | Accessibility labels | `a11y_show_poster` |
| `category_` | Genre categories | `category_drama`, `category_comedy` |
| `account_` | Account/auth | `account_sign_out` |
| `sync_` | Cloud sync | `sync_title_welcome_back` |
| `downgrade_` | Downgrade flow | `downgrade_title` |
| `label_` | Generic labels | `label_episodes`, `label_premiere` |
| `countdown_` | Countdown display | `countdown_days`, `countdown_hrs` |
| `paywall_` | Paywall text | `paywall_free_limit` |
| `confirm_` | Confirmation dialogs | `confirm_remove_show` |
| `signin_` | Sign in flow | `signin_sync_your_shows` |
| `debug_` | Debug/dev only | `debug_send_test_notification` |

---

## String Categories

### 1. Tab Bar (5 keys)
```
tab_timeline = "Timeline"
tab_planner = "Planner"
tab_search = "Search"
tab_binge_ready = "Binge Ready"
tab_settings = "Settings"
```

### 2. Buttons & Actions (~50 keys)
```
button_follow = "FOLLOW"
button_following = "FOLLOWING"
button_save_notifications = "SAVE NOTIFICATIONS"
button_not_now = "NOT NOW"
button_restore_purchases = "Restore Purchases"
button_start_trial = "START 7-DAY FREE TRIAL"
button_purchase_lifetime = "PURCHASE LIFETIME"
button_upgrade = "UPGRADE"
button_mark_season_watched = "Mark Season Watched"
button_yes = "Yes"
button_no = "No"
button_cancel = "Cancel"
button_remove = "Remove"
button_close = "Close"
button_done = "Done"
button_skip = "Skip"
button_continue = "Continue"
button_get_started = "Get Started"
button_share = "Share"
button_sign_in_with_apple = "Sign in with Apple"
// ... and more
```

### 3. Search Screen (~10 keys)
```
search_placeholder = "Search shows to binge"
search_heading = "Search"
search_browse_by_category = "Browse by Category"
search_trending_shows = "Trending Shows"
search_ending_soon = "Ending Soon"
search_see_all = "SEE ALL"
search_no_results = "No Results"
search_no_shows_found = "No shows found"
search_try_different_category = "Try a different category"
```

### 4. Timeline Screen (~15 keys)
```
timeline_heading = "Currently Airing"
timeline_ending_soon = "Ending Soon"
timeline_premiering_soon = "Premiering Soon"
timeline_anticipated = "Anticipated"
timeline_shows_cycle_back = "SHOWS CYCLE BACK"
timeline_when_seasons_end = "WHEN SEASONS END"
timeline_view_full = "VIEW FULL TIMELINE"
timeline_nothing = "Nothing on the Timeline"
timeline_shows_not_airing = "Your followed shows aren't currently\nairing or premiering soon"
timeline_last_updated = "Last updated:"
```

### 5. Binge Ready Screen (~10 keys)
```
binge_ready_heading = "Binge Ready"
binge_ready_nothing_yet = "Nothing to Binge Yet"
binge_ready_when_seasons_finish = "When seasons finish airing, they'll\nappear here ready to watch"
binge_ready_loading = "Loading..."
binge_ready_include_airing = "Show airing seasons in Binge Ready"
binge_ready_include_airing_subtitle = "Include the current season even if it's still airing"
```

### 6. Badges & Status (~20 keys)
```
badge_airing = "AIRING"
badge_premiering = "PREMIERING"
badge_binge_ready = "BINGE READY"
badge_anticipated = "ANTICIPATED"
badge_cancelled = "CANCELLED"
badge_watched = "WATCHED"
badge_up_next = "UP NEXT"
status_watched = "Watched"
status_in_progress = "In Progress"
status_upcoming = "Upcoming"
status_complete = "Complete"
status_ended = "Ended"
```

### 7. Date & Time Units (~20 keys)
```
date_premiere = "PREMIERE"
date_finale = "FINALE"
date_tbd = "TBD"
time_days = "DAYS"
time_day = "DAY"
time_hours = "HRS"
time_hour = "HR"
time_minutes = "MIN"
time_seconds = "SEC"
time_episodes = "EPISODES"
time_episode = "EPISODE"
time_days_left = "DAYS LEFT"
```

### 8. Season & Episodes (~10 keys)
```
season_label = "SEASON"
season_episodes_count = "EPISODES"
season_aired = "Aired"
season_watched = "Watched"
season_episodes_label = "Episodes"
season_avg_runtime = "Avg Runtime"
season_runtime_minutes = "%d min"
```

### 9. Notifications (~40 keys)
```
notification_you_are_following = "YOU ARE NOW FOLLOWING:"
notification_season_premiere = "SEASON PREMIERE"
notification_new_episodes = "NEW EPISODES"
notification_finale_reminder = "FINALE REMINDER"
notification_season_binge_ready = "SEASON BINGE-READY"
notification_quiet_hours = "QUIET HOURS"
notification_default = "DEFAULT NOTIFICATIONS"
notification_applied_to_all = "Applied to all new shows"
// ... and more
```

### 10. Settings (~25 keys)
```
settings_heading = "Settings"
settings_sound = "Sound"
settings_haptics = "Haptics"
settings_countdown_mode = "Countdown"
settings_reminders = "Reminders"
settings_get_in_touch = "Get in touch"
settings_privacy_policy = "Privacy policy"
settings_terms_of_use = "Terms of use"
settings_api_provided_by = "API provided by themoviedb.org"
settings_cloud_sync = "Cloud Sync"
settings_account = "Account"
// ... and more
```

### 11. Premium & Paywall (~40 keys)
```
premium_unlock = "UNLOCK"
premium_countdown2binge = "COUNTDOWN2BINGE"
premium_heading = "Premium"
premium_unlimited_shows = "Unlimited Shows"
premium_track_all_shows = "Track all your favorite series"
premium_spinoff_shows = "Spinoff Collections"
premium_discover_related = "Discover related series & universes"
premium_smart_notifications = "Smart Notifications"
premium_cloud_sync = "Cloud Sync"
premium_yearly = "YEARLY"
premium_monthly = "MONTHLY"
premium_lifetime = "LIFETIME"
premium_most_popular = "MOST POPULAR"
premium_best_value = "BEST VALUE"
// ... and more
```

### 12. Empty States (~10 keys)
```
empty_nothing_to_binge = "Nothing to Binge Yet"
empty_coming_soon = "Coming Soon"
empty_plan_binge_sessions = "Plan your binge sessions"
empty_no_shows_followed = "No shows followed yet"
empty_search_to_add = "Search to add your favorite shows"
```

### 13. Alerts & Dialogs (~10 keys)
```
alert_remove_show = "Remove %@?"
alert_remove_show_message = "This will remove the show from your followed list."
alert_mark_watched = "Mark as Watched?"
alert_mark_watched_message = "This will mark all episodes as watched."
alert_error = "Error"
alert_purchase_error = "Purchase Error"
```

### 14. Onboarding (~25 keys)
```
onboarding_step_of = "STEP %d OF %d"
onboarding_welcome = "Welcome to"
onboarding_app_name = "Countdown2Binge"
onboarding_tagline = "Know when it's binge-ready."
onboarding_add_shows = "Add Your Shows"
onboarding_add_shows_desc = "Search and follow your favorite TV shows"
onboarding_notifications = "Stay Updated"
onboarding_notifications_desc = "Get notified when seasons are ready to binge"
onboarding_complete = "You're All Set!"
// ... and more
```

### 15. Show Details (~15 keys)
```
show_detail_overview = "Overview"
show_detail_cast = "Cast"
show_detail_seasons = "Seasons"
show_detail_spinoffs = "Spin-offs"
show_detail_watch_order = "Watch Order"
show_detail_release_order = "Release Order"
show_detail_chronological = "Chronological"
show_detail_recommendations = "Recommendations"
show_detail_where_to_watch = "Where to Watch"
show_detail_no_overview = "No overview available."
```

### 16. Categories/Genres (~10 keys)
```
category_drama = "Drama"
category_comedy = "Comedy"
category_action = "Action & Adventure"
category_scifi = "Sci-Fi & Fantasy"
category_crime = "Crime"
category_mystery = "Mystery"
category_animation = "Animation"
category_documentary = "Documentary"
category_reality = "Reality"
category_family = "Family"
```

### 17. Account & Cloud Sync (~30 keys)
```
account_title = "Account"
account_info = "Account Info"
account_signed_in_with_apple = "Signed in with Apple"
account_sync_status = "Sync Status"
account_sync_now = "Sync Now"
account_sign_out = "Sign Out"
account_delete = "Delete Account"
sync_title_welcome_back = "Welcome Back!"
sync_title_backed_up = "Backup Complete"
sync_result_restored_one = "We restored 1 show from your cloud backup."
// ... and more
```

### 18. Downgrade Flow (~10 keys)
```
downgrade_title = "Manage Shows"
downgrade_subscription_ended = "SUBSCRIPTION ENDED"
downgrade_choose_shows = "Choose Shows to Keep"
downgrade_free_tier_limit = "The free tier supports up to 3 shows. Select shows below to remove."
downgrade_remove_shows = "Remove Selected Shows"
```

---

## Parameterized Strings

### Format Specifiers

| Specifier | Type | Example |
|-----------|------|---------|
| `%@` | String | `"Remove %@?"` → "Remove Breaking Bad?" |
| `%d` | Integer (32-bit) | `"Season %d"` → "Season 3" |
| `%lld` | Integer (64-bit) | `"%lld shows"` → "5 shows" |
| `%.1f` | Float (1 decimal) | `"%.1f stars"` → "8.5 stars" |

### Parameterized Key Naming

For parameterized strings, include format specifiers in the key name:

```
// Single parameter
"alert_remove_show" = "Remove %@?"
"season_runtime_minutes" = "%d min"

// Multiple parameters (use positional specifiers for reordering)
"sync_result_merged %lld %lld" = "We restored %lld shows and backed up %lld shows."
"a11y_episode_progress_partial %lld %lld" = "%lld of %lld episodes watched"
```

### Common Parameterized Strings

```swift
// Show names
"alert_remove_show" = "Remove %@?"
"a11y_show_poster" = "%@ poster"
"a11y_follow_button" = "Follow %@"

// Counts
"label_episodes_count %lld" = "%lld Episodes"
"label_seasons_count %lld" = "%lld Seasons"
"a11y_shows_count %lld" = "%lld shows"
"premium_days_remaining %lld" = "%lld days remaining"

// Multiple parameters
"onboarding_step_of" = "STEP %d OF %d"
"downgrade_remove_count %lld %lld" = "%lld of %lld to remove"
"a11y_episode_progress_partial %lld %lld" = "%lld of %lld episodes watched"
```

---

## Accessibility Labels (a11y_)

Accessibility labels are prefixed with `a11y_` and provide VoiceOver descriptions.

### Categories

#### Show Descriptions
```
a11y_show_poster = "%@ poster"
a11y_show_card = "%@, %@"
a11y_binge_ready = "Binge ready"
a11y_currently_airing = "Currently airing"
```

#### Actions
```
a11y_follow_button = "Follow %@"
a11y_unfollow_button = "Unfollow %@"
a11y_close_button = "Close"
a11y_settings_button = "Settings"
a11y_search_button = "Search"
```

#### Gestures & Hints
```
a11y_swipe_seasons = "Swipe left or right to change seasons"
a11y_swipe_mark_watched = "Swipe down to mark watched"
a11y_swipe_remove = "Swipe up to remove show"
a11y_double_tap_view = "Double tap to view details"
a11y_double_tap_follow = "Double tap to follow"
a11y_hint_tap_details = "Tap for details"
a11y_hint_swipe_remove = "Swipe to remove"
```

#### VoiceOver Custom Actions
```
a11y_action_next_season = "Next season"
a11y_action_previous_season = "Previous season"
a11y_action_mark_watched = "Mark as watched"
a11y_action_remove_show = "Remove show"
```

#### Countdown Announcements
```
a11y_countdown_days = "%d days"
a11y_countdown_hours = "%d hours"
a11y_countdown_minutes = "%d minutes"
a11y_countdown_seconds = "%d seconds"
a11y_countdown_remaining = "%@ remaining until %@"
```

---

## RTL Support (Arabic)

Arabic is the only RTL language. SwiftUI handles most RTL layout automatically, but be aware of:

### Considerations

1. **Text alignment**: SwiftUI automatically flips `.leading` and `.trailing`
2. **Icons with direction**: Use `Image(systemName:).flipsForRightToLeftLayoutDirection()` for directional icons
3. **Numeric formatting**: Numbers remain LTR even in RTL context
4. **String concatenation**: Use `String(localized:)` instead of manual concatenation

### Arabic-Specific Translations

Arabic translations maintain meaning while respecting RTL context:

```
// English
"timeline_heading" = "Currently Airing"

// Arabic
"timeline_heading" = "يُعرض حالياً"
```

---

## Using Localized Strings in Code

### SwiftUI Text Views

```swift
// Direct usage (auto-localized)
Text("button_follow")

// Explicit localization
Text(String(localized: "button_follow"))

// With parameters
Text(String(localized: "alert_remove_show \(showName)"))

// LocalizedStringKey
Text(LocalizedStringKey("button_follow"))
```

### Programmatic Access

```swift
// Basic
let text = String(localized: "button_follow")

// With comment for translators
let text = String(localized: "button_follow", comment: "Follow button label")

// With default value
let text = String(localized: "button_follow", defaultValue: "FOLLOW")
```

### Best Practices

1. **Never hardcode user-facing strings**
   ```swift
   // Bad
   Text("Follow")

   // Good
   Text("button_follow")
   ```

2. **Use parameterized strings for dynamic content**
   ```swift
   // Bad
   Text("Remove " + showName + "?")

   // Good
   Text(String(localized: "alert_remove_show \(showName)"))
   ```

3. **Add accessibility labels**
   ```swift
   Button(action: follow) {
       Text("button_follow")
   }
   .accessibilityLabel(String(localized: "a11y_follow_show \(showName)"))
   ```

---

## Adding New Strings

### Step 1: Add to English Base

Add the new key to `en.lproj/Localizable.strings`:

```
// MARK: - New Feature
"new_feature_title" = "My New Feature";
"new_feature_description" = "This is a description with %@ parameter.";
```

### Step 2: Add to All Language Files

Add translations to all 15 language files:

- `es.lproj/Localizable.strings`
- `fr.lproj/Localizable.strings`
- `de.lproj/Localizable.strings`
- `pt-BR.lproj/Localizable.strings`
- `it.lproj/Localizable.strings`
- `ja.lproj/Localizable.strings`
- `ko.lproj/Localizable.strings`
- `zh-Hans.lproj/Localizable.strings`
- `ar.lproj/Localizable.strings`
- `ru.lproj/Localizable.strings`
- `tr.lproj/Localizable.strings`
- `pl.lproj/Localizable.strings`
- `nl.lproj/Localizable.strings`
- `th.lproj/Localizable.strings`

### Step 3: Use in Code

```swift
Text("new_feature_title")
Text(String(localized: "new_feature_description \(parameter)"))
```

---

## Adding a New Language

### Step 1: Create Language Folder

```bash
mkdir Countdown2Binge/Resources/vi.lproj  # Vietnamese example
```

### Step 2: Copy Base Strings

```bash
cp Countdown2Binge/Resources/en.lproj/Localizable.strings \
   Countdown2Binge/Resources/vi.lproj/Localizable.strings
```

### Step 3: Update Info.plist

Add the language code to `CFBundleLocalizations`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <!-- existing languages -->
    <string>vi</string>  <!-- Add new language -->
</array>
```

### Step 4: Add to Xcode Project

1. Select `Localizable.strings` in Xcode
2. Open File Inspector (right panel)
3. Click "Localize..." if needed
4. Check the new language

### Step 5: Translate

Replace English strings with translations in the new language file.

---

## String Key Index by Screen

### Timeline Screen
- `tab_timeline`
- `timeline_heading`
- `timeline_ending_soon`
- `timeline_premiering_soon`
- `timeline_anticipated`
- `timeline_shows_cycle_back`
- `timeline_when_seasons_end`
- `timeline_view_full`
- `timeline_nothing`
- `timeline_shows_not_airing`
- `timeline_last_updated`
- `badge_airing`
- `badge_premiering`
- `badge_binge_ready`
- `badge_anticipated`
- `time_days`
- `time_hours`
- `date_premiere`
- `date_finale`

### Search Screen
- `tab_search`
- `search_placeholder`
- `search_heading`
- `search_browse_by_category`
- `search_trending_shows`
- `search_ending_soon`
- `search_see_all`
- `search_no_results`
- `search_no_shows_found`
- `button_follow`
- `button_following`
- `status_already_added`
- `category_*` (all genre keys)

### Binge Ready Screen
- `tab_binge_ready`
- `binge_ready_heading`
- `binge_ready_nothing_yet`
- `binge_ready_when_seasons_finish`
- `binge_ready_loading`
- `badge_watched`
- `badge_up_next`
- `label_episodes`
- `label_watched`

### Show Detail Screen
- `show_detail_overview`
- `show_detail_cast`
- `show_detail_seasons`
- `show_detail_spinoffs`
- `show_detail_watch_order`
- `show_detail_recommendations`
- `button_follow`
- `button_following`
- `label_cast_and_crew`
- `label_trailers_and_clips`
- `label_synopsis`
- `season_label`
- `season_episodes_label`

### Settings Screen
- `tab_settings`
- `settings_heading`
- `settings_sound`
- `settings_haptics`
- `settings_countdown_mode`
- `settings_reminders`
- `settings_get_in_touch`
- `settings_privacy_policy`
- `settings_terms_of_use`
- `settings_cloud_sync`
- `settings_account`
- `premium_heading`
- `button_restore_purchases`

### Onboarding Flow
- `onboarding_welcome`
- `onboarding_app_name`
- `onboarding_tagline`
- `onboarding_add_shows`
- `onboarding_add_shows_desc`
- `onboarding_review_shows`
- `onboarding_notifications`
- `onboarding_notifications_desc`
- `onboarding_complete`
- `onboarding_step_of`
- `button_skip`
- `button_continue`
- `button_get_started`

### Premium/Paywall
- `premium_unlock`
- `premium_countdown2binge`
- `premium_unlimited_shows`
- `premium_spinoff_shows`
- `premium_smart_notifications`
- `premium_cloud_sync`
- `premium_yearly`
- `premium_monthly`
- `premium_lifetime`
- `premium_most_popular`
- `premium_best_value`
- `button_start_trial`
- `button_purchase_lifetime`

---

## Testing Localization

### In Simulator

1. **Change language**: Settings → General → Language & Region → iPhone Language
2. **Preview specific language**: Edit Scheme → Run → Options → App Language

### Debug Techniques

```swift
// Force specific locale for testing
UserDefaults.standard.set(["es"], forKey: "AppleLanguages")
```

### Pseudo-Localization

For testing layout with longer strings, use pseudo-localization:
- Double-length strings test UI overflow
- Special characters test encoding
- RTL preview tests layout direction

### Checklist

- [ ] All strings use localization keys (no hardcoded text)
- [ ] Parameterized strings work with all languages
- [ ] RTL layout works correctly (Arabic)
- [ ] Long translations don't break layout
- [ ] Accessibility labels are localized
- [ ] Notifications use localized text
- [ ] Date/time formatting respects locale

---

## Complete String Count by Category

| Category | Count |
|----------|-------|
| Tab Bar | 5 |
| Buttons & Actions | ~50 |
| Search | ~10 |
| Timeline | ~15 |
| Binge Ready | ~10 |
| Badges & Status | ~20 |
| Date & Time | ~20 |
| Season & Episodes | ~10 |
| Notifications | ~40 |
| Settings | ~25 |
| Premium & Paywall | ~40 |
| Empty States | ~10 |
| Alerts & Dialogs | ~10 |
| Onboarding | ~25 |
| Show Details | ~15 |
| Categories | ~10 |
| Account & Sync | ~30 |
| Downgrade | ~10 |
| Labels | ~40 |
| Countdown | ~10 |
| Accessibility | ~80 |
| Confirmations | ~10 |
| Sign In | ~10 |
| Debug | ~10 |
| **Total** | **~600+** |

---

## Franchise/Spinoff Localization

Franchise names are stored in Firebase with multi-language support:

```json
{
  "franchiseName": {
    "en": "Breaking Bad Universe",
    "es": "Universo Breaking Bad",
    "fr": "Univers Breaking Bad",
    "de": "Breaking Bad Universum",
    "ja": "ブレイキング・バッド・ユニバース",
    "ko": "브레이킹 배드 유니버스",
    "zh-Hans": "绝命毒师宇宙",
    "ar": "عالم بريكنج باد",
    "ru": "Вселенная Во все тяжкие",
    "tr": "Breaking Bad Evreni",
    "pl": "Uniwersum Breaking Bad",
    "nl": "Breaking Bad Universum",
    "th": "จักรวาล Breaking Bad",
    "pt-BR": "Universo Breaking Bad",
    "it": "Universo Breaking Bad"
  }
}
```

See `spinoffs-feature.md` for full Firebase spinoff localization structure.

---

## Maintenance

### Regular Tasks

1. **New feature strings**: Add to all 15 language files
2. **Translation updates**: Update when copy changes
3. **Missing key audit**: Verify all keys exist in all files
4. **Unused key cleanup**: Remove deprecated strings

### Translation Workflow

1. Developer adds English strings
2. Export strings for translation
3. Professional translators provide translations
4. Import translations to language files
5. QA tests in each language

---

## Resources

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [String Catalog (Xcode 15+)](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [TMDB API Languages](https://developer.themoviedb.org/docs/languages)
