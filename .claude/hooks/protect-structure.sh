#!/bin/bash
#
# protect-structure.sh — PreToolUse hook (Write matcher): naming & reuse guard.
#
#  1. BLOCK creating a file named *Screen.swift → views are *View.swift.
#  2. WARN (non-blocking) when a NEW component file's name starts with an
#     existing view's prefix (e.g. a view TimelineView.swift exists and you're
#     creating TimelineHeader.swift). This nudges CLI to first look for a
#     reusable component and only prefix if nothing fits. It does NOT block —
#     legit view-specific components are allowed through.
#
# Fires only on Write to a NEW *.swift file (not edits to existing files).
#

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "protect-structure: jq not found; structure guard NOT enforced." >&2
  exit 0
fi

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only care about new Swift files being written.
case "$FILE_PATH" in
  *.swift) ;;
  *) exit 0 ;;
esac
# Only the Write tool creates new files; Edit/MultiEdit modify existing ones.
[ "$TOOL" = "Write" ] || exit 0

BASENAME=$(basename "$FILE_PATH")
NAME="${BASENAME%.swift}"

# ── 1. BLOCK *Screen.swift ──────────────────────────────────────────────────
case "$NAME" in
  *Screen)
    echo "🚫 BLOCKED: '$BASENAME' — views are named *View, never *Screen." >&2
    echo "Rename to ${NAME%Screen}View.swift. The top-level folder is Views/ and every screen file is a *View." >&2
    exit 2
    ;;
esac

# ── 2. WARN on view-name-prefixed component ─────────────────────────────────
# Learn existing view prefixes from Views/ (files ending in View.swift).
# CLAUDE_PROJECT_DIR is set by Claude Code to the project root.
ROOT="${CLAUDE_PROJECT_DIR:-.}"
VIEWS_DIR="$ROOT/Countdown2Binge/Views"
[ -d "$VIEWS_DIR" ] || VIEWS_DIR="$ROOT/Views"

if [ -d "$VIEWS_DIR" ]; then
  # Only warn if the new file is NOT itself a *View (components aren't views).
  case "$NAME" in
    *View) exit 0 ;;  # a view file — not a component, skip
  esac

  # Collect view prefixes: TimelineView.swift → Timeline
  PREFIXES=$(find "$VIEWS_DIR" -name '*View.swift' -type f 2>/dev/null \
    | sed 's|.*/||; s|View\.swift$||' | sort -u)

  for p in $PREFIXES; do
    [ -z "$p" ] && continue
    case "$NAME" in
      "$p"*)
        echo "⚠️  REUSE CHECK: '$BASENAME' starts with the view prefix '$p'." >&2
        echo "Before creating a view-specific component, SEARCH Components/ and the view's Supporting Files/ for an existing one that fits (e.g. a shared PosterTile, SectionHeader). Reuse it if one fits." >&2
        echo "Only create a '$p'-prefixed component if you have confirmed nothing reusable exists — then place it in the view's Supporting Files/. If it could be reused elsewhere, give it a GENERIC name (PosterTile, not ${p}Poster) and put it in Components/." >&2
        echo "(This is a warning, not a block — proceeding.)" >&2
        exit 0
        ;;
    esac
  done
fi

exit 0
