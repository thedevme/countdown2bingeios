#!/bin/bash

# Countdown2Binge Setup Verification Script

echo "🔍 Verifying Countdown2Binge Setup..."
echo ""

PROJECT_DIR="/Users/craigclayton/apps/appstore/C2B/app/Countdown2Binge"
cd "$PROJECT_DIR"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check counters
MISSING=0
FOUND=0

# Required files
DESIGN_FILES=(
    "Countdown2Binge/Screens/DesignSystem.swift"
    "Countdown2Binge/Screens/CoreComponents.swift"
    "Countdown2Binge/Screens/TabBarView.swift"
    "Countdown2Binge/Screens/TimelineScreen.swift"
    "Countdown2Binge/Screens/BingeReadyScreen.swift"
    "Countdown2Binge/Screens/DiscoverSearchScreen.swift"
    "Countdown2Binge/Screens/OnboardingFlow.swift"
    "Countdown2Binge/ContentView.swift"
)

echo "📁 Checking Design Files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for file in "${DESIGN_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
        ((FOUND++))
    else
        echo -e "${RED}✗${NC} $file (MISSING)"
        ((MISSING++))
    fi
done

echo ""
echo "📊 File Check Summary:"
echo "   Found: $FOUND files"
echo "   Missing: $MISSING files"
echo ""

# Check if Xcode project exists
if [ -f "Countdown2Binge.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✓${NC} Xcode project found"
else
    echo -e "${RED}✗${NC} Xcode project not found"
fi

echo ""
echo "⚠️  Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Xcode project:"
echo "   open Countdown2Binge.xcodeproj"
echo ""
echo "2. Add files to Xcode:"
echo "   - Right-click 'Countdown2Binge' folder"
echo "   - Select 'Add Files to Countdown2Binge...'"
echo "   - Select all files in Screens/ folder"
echo "   - Ensure target is checked"
echo ""
echo "3. Add custom fonts:"
echo "   - Download Oswald Bold from Google Fonts"
echo "   - Add to project and Info.plist"
echo ""
echo "4. Build and run:"
echo "   - Press Cmd+R or click Run button"
echo ""

# Check for font files
echo "🔤 Checking for Font Files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FONT_DIR="Countdown2Binge/Fonts"
if [ -d "$FONT_DIR" ]; then
    FONT_COUNT=$(find "$FONT_DIR" -name "*.ttf" -o -name "*.otf" | wc -l)
    if [ $FONT_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Found $FONT_COUNT font file(s)"
        find "$FONT_DIR" -name "*.ttf" -o -name "*.otf" | while read font; do
            echo "   - $(basename "$font")"
        done
    else
        echo -e "${YELLOW}⚠${NC}  Fonts folder exists but no fonts found"
        echo "   Download fonts from: https://fonts.google.com"
    fi
else
    echo -e "${YELLOW}⚠${NC}  No Fonts folder found"
    echo "   Create: mkdir -p Countdown2Binge/Fonts"
    echo "   Download Oswald, Anton, JetBrains Mono from Google Fonts"
fi

echo ""
echo "📖 Documentation:"
echo "   - Setup Guide: SETUP.md"
echo "   - Component Docs: ../../Countdown2Binge/README.md"
echo ""
echo "✅ Verification Complete!"
