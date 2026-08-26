#!/bin/bash
#
#  premium-gate-audit.sh
#  Countdown2Binge
#
#  Fails the build if a premium gate disappears.
#
#  Every entry is a feature that must be premium-only. Each is a grep for the
#  guard that enforces it. If someone refactors a view and drops the check, or
#  a debug override that force-enables premium comes back, the build stops here
#  rather than shipping a free tier that hands out paid features.
#
#  This is static analysis, not a runtime test: it proves the guard is present
#  in the source, not that the UI behaves. Treat a pass as "nothing was
#  deleted", not "verified working".
#

set -uo pipefail
cd "${SRCROOT:-$(dirname "$0")/..}" || exit 1

ROOT="Countdown2Binge"
fail=0
pass=0

# name | file | pattern that must exist
check() {
  local name="$1" file="$2" pattern="$3"
  if [[ ! -f "$ROOT/$file" ]]; then
    echo "$ROOT/$file:1: error: [premium-gate] file missing — '$name' cannot be verified"
    fail=$((fail + 1)); return
  fi
  local line
  line=$(grep -n -- "$pattern" "$ROOT/$file" | head -1 | cut -d: -f1)
  if [[ -n "$line" ]]; then
    pass=$((pass + 1))
    echo "  [GATED]   $name  ($file:$line)"
  else
    fail=$((fail + 1))
    echo "$ROOT/$file:1: error: [premium-gate] '$name' lost its premium guard (expected: $pattern)"
  fi
}

echo "── premium gate audit ─────────────────────────────────"

check "Show limit (3)"             "Views/Discover/DiscoverViewModel.swift"                  "canAddShow(currentCount"
check "Over-limit modal on launch" "ContentView.swift"                                       "showDowngradeModal = seriesManager"
check "Notification scheduling"    "Services/Core Engine/SeriesManager.swift"                "guard PremiumManager.shared.isPremium"
check "Follow digest"              "Services/Notifications/FollowDigest.swift"               "guard PremiumManager.shared.isPremium"
check "Notif onboarding (discover)" "Views/Discover/DiscoverScreen.swift"                    "canUseNotifications"
check "Notif onboarding (search)"  "Views/DiscoverSearchScreen.swift"                        "canUseNotifications"
check "Alerts bell (show detail)"  "Views/Timeline/FollowedShowDetail.swift"                 "if PremiumManager.shared.isPremium"
check "Alerts bell (timeline)"     "Views/TimelineScreen.swift"                              "if PremiumManager.shared.isPremium"
check "Alerts bell (my list)"      "Views/MyList/Landscape/MyListLandscapeCard.swift"        "if PremiumManager.shared.isPremium"
check "iCloud sync/restore/merge"  "Services/Core Engine/SeriesManager.swift"                "guard PremiumManager.shared.canUseCloudSync"
check "Spin-offs (followed)"       "Views/Timeline/FollowedShowDetail.swift"                 "canViewSpinoffs"
check "Settings rows hidden"       "Views/Settings/SettingsScreen.swift"                     "if isPremium {"
check "Profile screen"             "Views/Settings/SettingsScreen.swift"                      "ProfileScreen(isPremium:"
check "Cloud Sync screen"          "Views/Settings/CloudSyncView/CloudSyncView.swift"        "premiumManager.isPremium"
check "Edit profile photo"         "Views/Profile/EditProfileScreen.swift"                   "disabled(!isPremium)"
check "Share lineup (profile)"     "Views/Profile/ProfileScreen.swift"                       "if showShareSheet, isPremium"

# ── iCloud must be gated in all three entry points, not just one ──
cloud_guards=$(grep -c "guard PremiumManager.shared.canUseCloudSync" "$ROOT/Services/Core Engine/SeriesManager.swift")
if [[ "$cloud_guards" -lt 3 ]]; then
  fail=$((fail + 1))
  echo "$ROOT/Services/Core Engine/SeriesManager.swift:1: error: [premium-gate] expected 3 canUseCloudSync guards (restore/merge/sync), found $cloud_guards"
else
  pass=$((pass + 1))
  echo "  [GATED]   iCloud: all 3 entry points guarded"
fi

# ── nothing may grant premium except RevenueCat ──
assigns=$(grep -c "isPremium = " "$ROOT/Services/PremiumManager.swift")
if [[ "$assigns" -ne 1 ]]; then
  fail=$((fail + 1))
  echo "$ROOT/Services/PremiumManager.swift:1: error: [premium-gate] isPremium is assigned $assigns times; it must be assigned exactly once, from the RevenueCat entitlement"
else
  pass=$((pass + 1))
  echo "  [GATED]   isPremium assigned once, from RevenueCat only"
fi

# ── a debug override must never come back ──
if grep -rqn "debugPremiumOverride\|isTestFlight" "$ROOT" --include="*.swift"; then
  fail=$((fail + 1))
  echo "$ROOT/Services/PremiumManager.swift:1: error: [premium-gate] a debug/TestFlight premium override was reintroduced"
else
  pass=$((pass + 1))
  echo "  [GATED]   no debug/TestFlight premium override"
fi

echo "───────────────────────────────────────────────────────"
echo "  passed: $pass   failed: $fail"
echo "───────────────────────────────────────────────────────"

[[ "$fail" -eq 0 ]] || exit 1
