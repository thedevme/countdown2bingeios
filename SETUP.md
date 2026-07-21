# Countdown2Binge - Xcode Setup Guide

This guide will help you get the SwiftUI designs running in your Xcode project.

## ⚠️ Current Issues to Fix

The design files are in your project but need to be properly added to Xcode. Here's what you need to do:

### 1. Add Files to Xcode Project

Open the project in Xcode and add the design files if they're not already showing:

```bash
# Open the project
cd /Users/craigclayton/apps/appstore/C2B/app/Countdown2Binge
open Countdown2Binge.xcodeproj
```

**In Xcode:**
1. Right-click on the `Countdown2Binge` folder (blue icon) in the Project Navigator
2. Select "Add Files to Countdown2Binge..."
3. Navigate to `Countdown2Binge/Screens/` folder
4. Select all `.swift` files
5. Make sure "Copy items if needed" is **unchecked** (files are already in place)
6. Make sure "Countdown2Binge" target is **checked**
7. Click "Add"

### 2. Organize File Structure (Optional but Recommended)

Create groups in Xcode for better organization:

1. **Create "Components" group:**
   - Right-click `Countdown2Binge` folder → New Group → Name it "Components"
   - Drag `CoreComponents.swift` and `TabBarView.swift` into it

2. **Keep "Screens" group:**
   - Keep `TimelineScreen.swift`, `BingeReadyScreen.swift`, `DiscoverSearchScreen.swift`, `OnboardingFlow.swift` in the Screens group

3. **Move to root:**
   - Drag `DesignSystem.swift` to the root `Countdown2Binge` folder level

### 3. Add Custom Fonts (Required)

The designs use custom fonts that need to be added:

**Download fonts:**
- [Oswald](https://fonts.google.com/specimen/Oswald) - Download "Bold" weight
- [Anton](https://fonts.google.com/specimen/Anton) (optional alternative)
- [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono) (for monospace)

**Add to project:**
1. Drag font files (`.ttf` or `.otf`) into Xcode project
2. Check "Copy items if needed" and "Countdown2Binge" target
3. Open `Info.plist` (or Info tab in project settings)
4. Add "Fonts provided by application" key
5. Add font filenames:
   - `Oswald-Bold.ttf`
   - `JetBrainsMono-Regular.ttf`
   - `JetBrainsMono-Bold.ttf`

**Update DesignSystem.swift:**

Replace the display font function to use the actual font name:
```swift
static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    return .custom("Oswald-Bold", size: size)
}
```

### 4. Build and Run

Press `Cmd + R` or click the Run button.

The app should launch and show the **Timeline Screen** by default.

## 🎯 What You Should See

When you run the app, you'll see:

1. **Timeline Screen** with:
   - Header with profile avatar
   - Stats bar (Tracked: 12, Upcoming: 8)
   - Hero card stack (3 fanned posters)
   - Day ticker
   - Giant rotated numbers for shows
   - Collapsible sections

2. **Bottom Tab Bar** with:
   - Timeline
   - Discover
   - Binge Ready
   - Settings
   - Floating Search button

## 🔄 Switch Between Screens

Tap the tab bar buttons to navigate:
- **Timeline**: Main home screen with giant numbers
- **Discover**: Browse by network
- **Binge Ready**: Episode tracking interface
- **Search**: Search with segmented tabs

## 📱 Testing Different Layouts

To test different layout variations, modify `ContentView.swift`:

```swift
// Timeline with different number styles:
TimelineScreen(layout: "expanded", numberStyle: "rotated")   // Default
TimelineScreen(layout: "compact", numberStyle: "stacked")    // Vertical numbers
TimelineScreen(layout: "expanded", numberStyle: "chip")      // Bordered chips
```

## 🎨 Xcode Previews

The design files include multiple preview configurations. To see them:

1. Open any screen file (e.g., `TimelineScreen.swift`)
2. Press `Opt + Cmd + Enter` to show preview canvas
3. Use the preview selector to see different variations

Available previews:
- Timeline (expanded/compact)
- Binge Ready
- Search
- Discover
- Onboarding Flow
- Tab Bar

## ⚠️ Known Issues

### Compilation Errors

If you see errors about missing types:

1. **Color extensions**: Make sure `DesignSystem.swift` is in the project
2. **Components**: Make sure all files are added to the target
3. **Font issues**: Update font names in `DesignSystem.swift` to match your installed fonts

### Common Fixes

**Error: "Cannot find 'C2BLayout' in scope"**
- Make sure `DesignSystem.swift` is added to the Xcode project

**Error: "Type 'Color' has no member 'c2bTeal'"**
- Make sure `DesignSystem.swift` is compiled before other files
- Clean build folder: `Cmd + Shift + K`

**Error: "Cannot find 'PosterView' in scope"**
- Make sure `CoreComponents.swift` is added to the project

**Fonts not displaying correctly:**
- Make sure custom fonts are added to Info.plist
- Update font names in `DesignSystem.swift` to match actual font family names

## 🚀 Next Steps

Once the designs are running:

1. **Add Real Data**: Replace placeholder data with actual show information
2. **Add Navigation**: Implement detail screens for individual shows
3. **Add Interactivity**: Make buttons functional
4. **Add State Management**: Use `@StateObject` or `@EnvironmentObject`
5. **Connect to API**: Integrate with TMDB or similar API
6. **Add Images**: Replace poster placeholders with real artwork

## 📚 Documentation

For detailed component documentation, see:
- `/Users/craigclayton/apps/appstore/C2B/Countdown2Binge/README.md`

## 🐛 Troubleshooting

If the app doesn't compile:

1. Clean Build Folder: `Cmd + Shift + K`
2. Delete Derived Data: `Cmd + Shift + K` then close Xcode
3. Open Xcode again and rebuild

If you see a blank screen:
1. Make sure `ContentView.swift` was properly updated
2. Check that all design files are added to the target
3. Check console for error messages

## 💡 Tips

- Use Xcode previews for rapid iteration
- Test on different device sizes using the simulator
- Use Xcode's View Hierarchy debugger to inspect layouts
- Enable "Debug View Hierarchy" to see the component structure

---

**Need Help?** Check the main README.md for component documentation and usage examples.
