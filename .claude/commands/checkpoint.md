---
description: Phase checkpoint — commit and push current work
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(git push:*)
  - Bash(git branch:*)
  - Bash(git remote:*)
argument-hint: [phase note]
model: haiku
---

# /checkpoint — Phase Boundary

You are performing a **hard phase checkpoint**.

Do not start the next phase.

---

## Step 1 — Inspect repo state

!`git status -sb`
!`git diff --stat`

---

## Step 2 — Stage changes

!`git add -A`
!`git status -sb`

---

## Step 3 — Commit

If the user provided a phase note, use it.
Otherwise use "checkpoint".

!`git commit -m "Phase: $ARGUMENTS"`

If this fails due to no changes:
- Say **"No changes to commit. Checkpoint skipped."**
- Stop immediately.

---

## Step 4 — Push

!`git branch --show-current`
!`git remote -v`
!`git push -u origin HEAD`

---

## Step 5 — Confirm

Reply with:
- Branch name
- Commit hash
- Commit message
- One-paragraph summary of changes

Do NOT begin the next phase.
