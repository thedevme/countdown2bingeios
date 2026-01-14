# Phase Commit

Commit and push the current phase's work.

## Instructions

1. Read the build plan at `/docs/build-plan.md`
2. Ask me which phase number was just completed
3. Find that phase's title in the build plan
4. Run:
```bash
git add -A && git commit -m "Phase {PHASE_NUMBER}: {PHASE_TITLE}" && git push
```