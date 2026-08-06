#!/bin/bash
#
# protect-git.sh — PreToolUse hook (Bash matcher): BLOCK-AND-ASK on commit/push.
#
# Every git commit / git push is blocked (exit 2) and CLI is told to STOP and
# ask the human for a FRESH yes in chat before trying again. A prior approval
# NEVER carries forward — each attempt is blocked again until the human has
# explicitly said yes for THIS attempt. The hook runs below the model, so CLI
# cannot decide it already has permission or batch pushes past it.
#
# Read-only git (status/diff/log/add/branch/fetch/pull) is always allowed.
#

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "protect-git: jq not found; git guard NOT enforced this call." >&2
  exit 0
fi

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
NORM=$(printf '%s' "$CMD" | tr '\n' ' ')

ask() {
  echo "🛑 STOP — $1" >&2
  echo "" >&2
  echo "This requires the human's explicit approval RIGHT NOW, for THIS push/commit." >&2
  echo "A previous 'yes' does NOT count — approval never carries over between attempts." >&2
  echo "" >&2
  echo "Do NOT retry, reword, or route around this. Ask the human in chat:" >&2
  echo "  \"Do you want me to run: ${CMD}  ? (yes/no)\"" >&2
  echo "Only after they reply 'yes' in their very next message may you attempt it again — and it will be blocked again, so relay their approval to the human to run manually if needed." >&2
  exit 2
}

# git push
if printf '%s' "$NORM" | grep -Eq '(^|[;&|]|[[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|$)'; then
  ask "git push — pushing to a remote needs fresh human approval."
fi

# git commit
if printf '%s' "$NORM" | grep -Eq '(^|[;&|]|[[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)'; then
  ask "git commit — committing needs fresh human approval."
fi

exit 0
