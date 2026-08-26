#!/bin/bash
#
#  run-tests.sh
#  Countdown2Binge
#
#  Runs the unit tests as a build phase, so a failing test fails the build.
#
#  Why a build phase and not a scheme pre-action: Xcode does not propagate a
#  pre-action's exit code. A failing pre-action still reports BUILD SUCCEEDED,
#  and reports it silently. A Run Script build phase does fail the build.
#
#  Release only. The suite takes minutes and boots simulator clones; running it
#  on every Cmd+R would make the app impossible to iterate on. Release is what
#  an Archive builds, so this is the gate in front of App Store Connect.
#
#  Three things this has to avoid:
#    1. Recursion — `xcodebuild test` builds the project, which would run this
#       phase again. The env guard below breaks that.
#    2. DerivedData — the nested build gets its own directory so it never
#       fights Xcode for a lock. It must also be a SHORT path: nesting it under
#       $TARGET_TEMP_DIR made paths long enough that SPM failed to write its
#       bundles ("file name ... is invalid"), which looked like a test failure
#       and would have blocked every archive.
#    3. The UI target — it boots the app and adds minutes. Unit tests only.
#

set -uo pipefail

# ── 1. Recursion guard ──
if [[ -n "${C2B_RUNNING_TESTS:-}" ]]; then
  echo "note: nested build — skipping test phase"
  exit 0
fi

# ── 2. Release only ──
if [[ "${CONFIGURATION:-}" != "Release" ]]; then
  echo "note: skipping tests (CONFIGURATION=${CONFIGURATION:-unset}, tests run on Release/Archive)"
  exit 0
fi

cd "${SRCROOT}" || exit 1

# Any booted simulator, else a named fallback. Archives build for a generic
# device, so a destination has to be supplied explicitly.
UDID=$(xcrun simctl list devices booted -j 2>/dev/null \
  | /usr/bin/python3 -c 'import json,sys
d=json.load(sys.stdin)["devices"]
print(next((x["udid"] for v in d.values() for x in v if x.get("state")=="Booted"), ""))' 2>/dev/null)

if [[ -n "$UDID" ]]; then
  DEST="platform=iOS Simulator,id=$UDID"
else
  DEST="platform=iOS Simulator,name=iPhone 17 Pro"
fi

echo "── running unit tests before archive ──"

LOG="/tmp/c2b-tests.log"
# A CLEAN environment. Inheriting Xcode's build variables makes SPM fail to
# write its resource bundles ("file name ... is invalid") — which surfaces as a
# build error and would block every archive for a reason unrelated to tests.
env -i \
  HOME="$HOME" \
  PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" \
  USER="${USER:-}" \
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  C2B_RUNNING_TESTS=1 \
  xcodebuild test \
  -project "${SRCROOT}/Countdown2Binge.xcodeproj" \
  -scheme Countdown2Binge \
  -destination "$DEST" \
  -derivedDataPath "/tmp/c2b-test-dd" \
  -only-testing:Countdown2BingeTests \
  > "$LOG" 2>&1
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
  echo "error: unit tests failed — archive blocked. Full log: $LOG"
  # Surface the individual failures as build errors so they are clickable.
  grep -E "Expectation failed|XCTAssert.* failed|error:" "$LOG" | head -20 | while read -r line; do
    echo "error: $line"
  done
  grep -A20 "Failing tests:" "$LOG" | head -20
  exit 1
fi

echo "── unit tests passed ──"
grep -cE "' passed on " "$LOG" | xargs -I{} echo "note: {} tests passed"
exit 0
