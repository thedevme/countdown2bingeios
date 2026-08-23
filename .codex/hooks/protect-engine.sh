#!/bin/bash
#
# protect-engine.sh — PreToolUse hook enforcing Countdown2Binge engine rules.
#
# Registered in .claude/settings.json against Edit|Write|MultiEdit. It inspects
# the TEXT ABOUT TO BE WRITTEN and blocks (exit 2) edits that violate the
# mechanically-checkable engine rules, feeding the reason back to Claude so it
# self-corrects. Fuzzy rules (R4–R8) stay in CLAUDE.md; this hook enforces the
# four that keep drifting back: R1, R2, R3, R9.
#
# Exit 0 = allow. Exit 2 = block (message on stderr goes back to Claude).
#
# To temporarily disable (rare, intentional): comment out the hook entry in
# .claude/settings.json. The hook itself has no bypass — that's the point.
#

INPUT=$(cat)

# Need jq. If missing, fail OPEN (don't block work) but warn.
if ! command -v jq >/dev/null 2>&1; then
  echo "protect-engine: jq not found; engine rules NOT enforced this call." >&2
  exit 0
fi

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only Swift files matter.
case "$FILE_PATH" in
  *.swift) ;;
  *) exit 0 ;;
esac

BASENAME=$(basename "$FILE_PATH")

# Text being written: Edit → new_string, Write → content, MultiEdit → all edits.
NEW=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.new_string
  // .tool_input.content
  // ([.tool_input.edits[]?.new_string] | join("\n"))
  // empty
')

# Nothing to inspect.
[ -z "$NEW" ] && exit 0

block() {
  echo "🚫 ENGINE RULE VIOLATION — $1" >&2
  echo "$2" >&2
  echo "Fix the caller to obey the rule (read Series directly, or route the write through SeriesManager). See CLAUDE.md. If this rule truly must change, STOP and ask the human." >&2
  exit 2
}

# ── R1 — no INDEPENDENT lifecycle state defined on a DTO ────────────────────
# BLOCK the old independent-state names. Sanctioned pure-delegation properties
# (showState / isBingeReadyByDate / isBingeReady) are ALLOWED on DTOs because
# they are one-line pass-throughs to BingeEngine — verified, not independent
# math. The forbidden names below are the ones that historically carried their
# own date/finale logic and caused drift.
case "$BASENAME" in
  ShowData.swift|SeasonData.swift|EpisodeData.swift)
    if printf '%s' "$NEW" | grep -Eq 'var[[:space:]]+(lifecycleState|timelineCategory|anticipatedSeason)[[:space:]:]'; then
      block "R1 (independent state on a DTO)" \
        "Do not define lifecycleState / timelineCategory / anticipatedSeason on a DTO — these carried independent state and caused drift. DTOs may expose showState / isBingeReadyByDate / isBingeReady ONLY as pure one-line delegations to BingeEngine."
    fi
    ;;
esac

# ── R2 — no state-carrying model→DTO converters ─────────────────────────────
if printf '%s' "$NEW" | grep -Eq 'func[[:space:]]+(toShowData|toSeasonData|toEpisodeData)[[:space:]]*\('; then
  block "R2 (DTO converter)" \
    "toShowData()/toSeasonData()/toEpisodeData() are forbidden — they reintroduce state drift. Rewire the view to read Series directly."
fi

# ── R9 — CloudKit must stay .none (premium-gated manual sync) ────────────────
if printf '%s' "$NEW" | grep -Eq 'cloudKitDatabase:[[:space:]]*\.automatic'; then
  block "R9 (native CloudKit)" \
    "cloudKitDatabase must stay .none. Sync is premium-gated via manual CloudKit; native sync would sync free users too."
fi

# ── R3 — no direct hasWatched writes outside SeriesManager ──────────────────
# Model files DECLARE 'var hasWatched: Bool = false' (no leading dot) — allowed.
# We only block instance assignments '.hasWatched = x' (not '==') outside the funnel.
case "$BASENAME" in
  SeriesManager.swift) ;;  # the write funnel — allowed
  *)
    if printf '%s' "$NEW" | grep -Eq '\.hasWatched[[:space:]]*=[[:space:]]*[^=]'; then
      block "R3 (watch write outside funnel)" \
        "Writing .hasWatched outside SeriesManager is forbidden. Route watch mutations through SeriesManager (markSeasonWatched / toggleEpisodeWatched / markAiredEpisodesWatched)."
    fi
    ;;
esac

exit 0
