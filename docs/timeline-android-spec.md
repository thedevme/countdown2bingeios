# Timeline Screen — Android Implementation Spec

This document captures the iOS Timeline implementation for reference when building the Android version.

---

## Overview

The Timeline screen is the main home screen showing:
1. Header with greeting, avatar, and actions
2. Hero card stack (swipeable airing shows)
3. Slot machine countdown (syncs with hero)
4. Three collapsible sections: Ending Soon, Premiering Soon, Anticipated
5. Footer with "View Full Timeline" button

---

## Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#000000` | Screen background |
| Card Background | `#0D0D0D` | Button backgrounds |
| Border | `#252525` | Card borders |
| Teal Accent | `rgb(0.45, 0.90, 0.70)` / `#73E6B3` | Ending Soon, Premiering Soon accents |
| Gray Accent | `rgb(0.4, 0.4, 0.4)` / `#666666` | Anticipated section accent |
| Text Primary | `#FFFFFF` | Main text |
| Text Secondary | `#666666` | Subtitle text |
| Text Muted | `#555555` | Timestamps |

---

## 1. TimelineHeaderView

### Layout
```
┌─────────────────────────────────────────────────┐
│ [Avatar]  GOOD EVENING        [Refresh Button]  │
│           Alex                                  │
│                                                 │
│           Last updated: 2:15 pm                 │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │     VIEW ENTIRE TIMELINE  →             │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Properties
- **Greeting**: Dynamic based on time of day
  - 5:00-11:59 → "GOOD MORNING"
  - 12:00-16:59 → "GOOD AFTERNOON"
  - 17:00-20:59 → "GOOD EVENING"
  - 21:00-4:59 → "GOOD NIGHT"

### Styling
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Greeting | 10sp | Medium | #666666 |
| Name | 18sp | Semibold | #FFFFFF |
| Last updated | 11sp | Regular | #555555 |
| Button text | 12sp | Semibold | #FFFFFF (0.9 alpha) |

### Avatar
- Size: 44x44dp
- Background: #2A2A2A
- Icon: person.fill, 18sp, #4A4A4A

### Refresh Button
- Size: 44x44dp circle
- Background: #1A1A1A
- Icon: arrow.clockwise, 16sp semibold, white 0.8 alpha
- Animation: Rotates 360° continuously while refreshing (1 second duration, linear)
- Disabled while refreshing

### "View Entire Timeline" Button
- Height: 70dp
- Corner radius: 16dp
- Background: #0D0D0D
- Border: 1px #252525
- Text tracking/letter-spacing: 1.5

### Padding
- Horizontal: 24dp
- Top: 16dp
- Button horizontal inset: -4dp (extends slightly beyond padding)

---

## 2. HeroCardStack

Swipeable stack of currently airing shows sorted by days until finale.

### Card Dimensions
- Width: 280dp
- Height: 365dp
- Corner radius: 32dp

### Stack Behavior
- Cards stack with z-index (front card on top)
- Maximum visible cards: all airing shows
- Scale reduction per position: 0.1 (card 2 = 0.9, card 3 = 0.8, etc.)
- Horizontal offset per position: 35dp
- 3D rotation per position: 2 degrees

### Gesture Handling
- **Swipe left**: Go to next card (cycles to first at end)
- **Swipe right**: Go to previous card (cycles to last at beginning)
- **Swipe threshold**: 50dp
- **Only front card moves** during drag
- **Disabled** when only 1 card

### Animation
- Spring animation on snap back
- Duration: ~0.3s
- Response: 0.5, damping: 0.8

### Sound & Haptics
- Play card swipe sound on card change
- Light haptic feedback on card change
- Sound volume: 0.3
- Sound file: cardswipe.wav
- **Important**: Preload sound on view appear to avoid first-play delay

### Card Content
- AsyncImage for show poster
- Fill mode, clipped to rounded rect
- Shadow: black 0.3 alpha, radius 20, y-offset 10

### Empty State
- Shows placeholder with "No Shows Airing" text
- TV icon, 48sp, gray

---

## 3. SlotMachineCountdown

Horizontal scrolling number display that syncs with hero card.

### Layout
```
┌─────────────────────────────────────────────────┐
│           TODAY • JAN 9                         │
│                                                 │
│     19   18   [17]   16   15                   │
│                DAYS                             │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Cell width: 70dp
- Cell height: 70dp
- Visible cells: 5

### Center "Today Box"
- Border: 2px white
- Corner radius: 12dp
- Contains current day count

### Number Styling
| Position | Size | Weight | Alpha |
|----------|------|--------|-------|
| Center | 42sp | Heavy | 1.0 |
| Adjacent | 42sp | Heavy | 0.3 |
| Far | 42sp | Heavy | 0.15 |

### "DAYS" Label
- Size: 10sp
- Weight: Bold
- Letter-spacing: 2
- Color: white 0.6 alpha

### "TODAY" Label
- Format: "TODAY • MMM d" (e.g., "TODAY • JAN 9")
- Size: 11sp
- Weight: Medium
- Letter-spacing: 1.5
- Color: white 0.5 alpha

### Animation
- Horizontal scroll animation when value changes
- **Custom timing curve**: (0.0, 0.0, 0.15, 1.0) - ease out with strong deceleration
- Duration: 0.6s
- Numbers scroll through center position

### Offset Calculation
```
centerIndex = maxNumber / 2.0
xOffset = (centerIndex - currentValue) * cellWidth
```

---

## 4. TimelineSectionHeader

Collapsible section header with title and count.

### Layout
```
┌─────────────────────────────────────────────────┐
│  ●  PREMIERING SOON            3 total    ▼    │
└─────────────────────────────────────────────────┘
```

### Styles
| Style | Dot Color | Text Color |
|-------|-----------|------------|
| endingSoon | Teal | Teal |
| premiering | Teal | Teal |
| anticipated | Gray (#666666) | Gray |

### Dot
- Size: 12x12dp
- Position: x=34dp from left

### Title
- Size: 11sp
- Weight: Heavy
- Letter-spacing: 2

### Count Badge
- Format: "X total"
- Size: 11sp
- Weight: Medium
- Color: white 0.5 alpha

### Disclosure Arrow
- Icon: chevron.down
- Size: 12sp, semibold
- Rotates 180° when collapsed
- Hidden when `showDisclosure = false`

### Behavior
- Entire row tappable to toggle expand/collapse
- Animation: 0.3s ease-in-out
- All sections sync together (one state controls all)

### Padding
- Vertical: 16dp
- Left: 24dp (past the dot)

---

## 5. TimelineShowCard (Expanded View)

Landscape backdrop card with countdown on left.

### Layout
```
┌─────────────────────────────────────────────────┐
│  16    │  ┌─────────────────────────────┐      │
│ DAYS   │  │      [Backdrop Image]       │  S3  │
│        │  └─────────────────────────────┘      │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Total height: 190dp (frame), 175dp (backdrop)
- Backdrop corner radius: 24dp
- Left column width: 80dp

### Countdown Text (Left Side)
| Style | Format | Size |
|-------|--------|------|
| endingSoon/premiering | "XX" (2 digits) | 36sp |
| anticipated with year | "2025" | 36sp |
| anticipated TBD | "TBD" | 24sp |

- Weight: Heavy
- Design: Rounded
- Monospaced digits

### Countdown Label
| Style | Label |
|-------|-------|
| endingSoon/premiering | "DAYS" |
| anticipated with year | "EXP." |
| anticipated TBD | "DATE" |

- Size: 9sp
- Weight: Heavy
- Letter-spacing: 1

### Season Badge
- Position: Bottom-right of backdrop
- Format: "S#" (e.g., "S3")
- Size: 20sp
- Weight: Bold
- Color: White
- Padding: right 12dp, bottom 10dp

### Backdrop
- AsyncImage with fill
- Border: 1px, white 0.4 alpha, 0.5 opacity
- Placeholder: Gradient #262626 to #1A1A1A with first letter

### Padding
- Right: 24dp

---

## 6. CompactPosterRow (Collapsed View)

Portrait poster cards shown when section is collapsed.

### Layout
```
┌─────────────────────────────────────────────────┐
│  16    │                    ┌──────────────┐   │
│ DAYS   │                    │   [Poster]   │   │
│        │                    │              │   │
│        │                    │          S3  │   │
│        │                    └──────────────┘   │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Card height: 320dp
- Poster size: 230x310dp
- Poster corner radius: 15dp
- Left column width: 80dp

### Season Badge (on poster)
- Size: 56sp
- Weight: Heavy
- Color: White
- Position: Bottom-right
- Padding: right 16dp, bottom 12dp

### Countdown (same as TimelineShowCard)
- Left side with same styling

### Spacing
- Vertical spacing between cards: 30dp
- Max cards shown: 3

---

## 7. EmptySlotCard (Expanded Empty State)

Dashed border placeholder for empty sections.

### Layout
```
┌─────────────────────────────────────────────────┐
│  --    │  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐    │
│ DAYS   │  │                               │    │
│        │  │         EMPTY SLOT            │    │
│        │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘    │
└─────────────────────────────────────────────────┘
```

### Dimensions
- Same as TimelineShowCard (190dp height, 175dp inner)
- Corner radius: 24dp

### Placeholder Text
- "--" for endingSoon/premiering
- "TBD" for anticipated
- Label: "DAYS" or "DATE"

### Dashed Border
- Stroke: 1px
- Dash pattern: [6, 4]
- Color: accent color at 0.5 alpha

### "EMPTY SLOT" Text
- Size: 11sp
- Weight: Medium
- Letter-spacing: 1.5
- Color: #595959 (white 0.35)

---

## 8. EmptyPortraitSlots (Collapsed Empty State)

Portrait placeholder for empty collapsed sections.

### Dimensions
- Card height: 320dp
- Poster placeholder: 230x310dp
- Corner radius: 15dp

### Border
- Dashed stroke: [6, 4]
- Color: accent at 0.5 alpha

### "EMPTY" Text
- Size: 11sp
- Weight: Medium
- Letter-spacing: 1.5
- Color: #595959

---

## 9. TimelineFooterView

Bottom footer with full timeline button.

### Layout
```
┌─────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────┐   │
│  │     VIEW FULL TIMELINE  →               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│     ↻  SHOWS CYCLE BACK WHEN SEASONS END       │
└─────────────────────────────────────────────────┘
```

### Button
- Same styling as header button
- Height: 56dp
- Corner radius: 28dp (pill shape)
- Background: #1A1A1A
- Border: 1px #2A2A2A

### Info Text
- Icon: arrow.trianglehead.2.clockwise.rotate.90
- Size: 10sp
- Weight: Medium
- Letter-spacing: 1
- Color: #4A4A4A

### Padding
- Horizontal: 24dp
- Top: 40dp
- Bottom: 60dp

---

## 10. FullTimelineView

Full timeline showing all shows (no 3-show limit).

### Navigation
- Push navigation (not modal)
- Title: "FULL TIMELINE" centered
- Back button (automatic)
- **View toggle button** in trailing position

### View Toggle Button
- Icon (compact): `rectangle.grid.1x2`
- Icon (expanded): `rectangle.ratio.3.to.4`
- Default: Compact view
- Animation: 0.3s ease-in-out

### Sections
Same three sections as main timeline:
1. Ending Soon
2. Premiering Soon
3. Anticipated

### Differences from Main Timeline
- No hero card stack
- No slot machine countdown
- No 3-card limit per section (shows ALL shows)
- Toggle between compact (poster) and expanded (backdrop) views

---

## 11. Vertical Connector Line

Dashed line connecting sections.

### Styling
- Width: 2dp
- Dash pattern: [4, 4]
- Position: x = 40dp from left

### Colors
- Ending Soon/Premiering Soon: Teal at 0.8 alpha
- Anticipated: Gray (0.4) at 0.8 alpha

---

## 12. Data Logic

### Section Categories

**Ending Soon**
- Shows where `lifecycleState == .airing`
- Must have `daysUntilFinale` value
- Sorted by `daysUntilFinale` ascending (soonest first)

**Premiering Soon**
- Shows with upcoming premiere within ~90 days
- Sorted by `daysUntilPremiere` ascending

**Anticipated**
- Shows with future seasons but no confirmed date, or date > 90 days
- Sorted: Shows with dates first (by date), then TBD shows (alphabetically)

### Display Rules
- Main Timeline: Max 3 cards per section
- Full Timeline: All shows
- Count badge shows total count even if only 3 displayed
- Empty sections show 3 placeholder cards

### Hero Card Logic
- Only shows currently airing shows
- Sorted by soonest finale
- If no airing shows, hero section is hidden

---

## 13. State Management

### Expand/Collapse State
- Single boolean controls all sections together
- Default: Expanded on main timeline
- Default: Compact on full timeline
- Persisted per screen (not shared)

### Refresh State
- `isRefreshing: Boolean`
- Triggers rotation animation on refresh button
- Disables refresh button while active

---

## 14. Animations Summary

| Animation | Duration | Curve |
|-----------|----------|-------|
| Section expand/collapse | 0.3s | ease-in-out |
| Card stack snap | ~0.3s | spring (response 0.5, damping 0.8) |
| Slot machine scroll | 0.6s | (0.0, 0.0, 0.15, 1.0) |
| Refresh button rotation | 1.0s | linear, repeating |
| View toggle | 0.3s | ease-in-out |
| Disclosure arrow rotation | 0.2s | ease-in-out |

---

## 15. Sound & Haptics

### Card Swipe Sound
- File: cardswipe.wav
- Volume: 0.3
- Preload on view appear
- Play on card index change

### Haptic Feedback
- Type: Light impact
- Trigger: Card swipe completion
- Prepare generator on init

---

## 16. File Structure

```
Views/
└── Timeline/
    ├── TimelineView.swift          (Main screen)
    ├── TimelineHeaderView.swift    (Header component)
    ├── HeroCardStack.swift         (Swipeable card stack)
    ├── HeroShowCard.swift          (Individual hero card)
    ├── SlotMachineCountdown.swift  (Day counter)
    ├── TimelineSectionHeader.swift (Collapsible header)
    ├── TimelineShowCard.swift      (Expanded show card)
    ├── CompactPosterRow.swift      (Collapsed poster view)
    ├── EmptySlotCard.swift         (Expanded empty state)
    ├── EmptyPortraitSlots.swift    (Collapsed empty state)
    ├── TimelineFooterView.swift    (Footer component)
    └── FullTimelineView.swift      (Full timeline screen)

Utilities/
└── SoundManager.swift              (Audio & haptics)
```

---

## 17. Assets Required

- `cardswipe.wav` - Card swipe sound effect
- SF Symbols (or Material Icons equivalents):
  - `person.fill` - Avatar placeholder
  - `arrow.clockwise` - Refresh
  - `arrow.right` - Button arrows
  - `chevron.down` - Disclosure
  - `rectangle.grid.1x2` - Compact view icon
  - `rectangle.ratio.3.to.4` - Expanded view icon
  - `arrow.trianglehead.2.clockwise.rotate.90` - Cycle info icon
  - `tv` - Empty hero placeholder

---

## Notes for Android Implementation

1. **Jetpack Compose** recommended for declarative UI matching SwiftUI patterns
2. **Material 3** components can be customized to match iOS styling
3. **ExoPlayer** or similar for sound playback
4. **HapticFeedbackType.LightImpact** equivalent in Android
5. **LazyColumn** for scrolling sections
6. **HorizontalPager** or custom gesture handling for card stack
7. **AnimatedVisibility** for expand/collapse animations
8. **rememberInfiniteTransition** for refresh button rotation
