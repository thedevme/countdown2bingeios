---
description: Phase checkpoint — verify completion, summarize work, commit, and push
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git remote:*), Bash(git branch:*), Bash(git rev-parse:*)
argument-hint: [phase note]
model: haiku
---

# /checkpoint — Phase Boundary

The `/checkpoint` command represents a **hard boundary between phases**.

When the user runs `/checkpoint`, perform the following steps **in order**.

---

## Step 1 — Phase Verification

- Verify the current phase is complete based on the master plan.
- If phase completion is unclear or incomplete:
  - Say so clearly
  - Ask for confirmation before proceeding
- Do NOT assume the next phase automatically.

---

## Step 2 — Phase Summary

Summarize the work completed in this phase, including:

- Files created, updated, or removed
- Key architectural or logic decisions
- Known limitations, technical debt, or follow-ups

This summary should be concise and factual.

---

## Step 3 — Repository Health Check

Inspect the working tree:

<git_status>
!`git status -sb`
</git_status>

<git_diff>
!`git diff`
</git_diff>

If the working tree is inconsistent or unsafe to commit, stop and explain why.

---

## Step 4 — Stage Changes

Stage all tracked and untracked changes:

!`git add -A`

Re-check status:

<git_status_after_add>
!`git status -sb`
</git_status_after_add>

---

## Step 5 — Commit

Create a commit message in this format:

"Phase X: $ARGUMENTS"

Rules:
- If `$ARGUMENTS` is empty, use: `"checkpoint"`
- Keep it short and phase-scoped
- No emojis

Run:

!`git commit -m "Phase $ARGUMENTS"`

If there is nothing to commit, say so clearly and stop.

---

## Step 6 — Push

Check remotes:

<git_remotes>
!`git remote -v`
</git_remotes>

Push the current branch:
- If upstream exists, push normally
- If not, set upstream automatically

Use:
!`git push`
If needed:
!`git push -u origin HEAD`

---

## Step 7 — Confirmation

Confirm that the checkpoint is complete by reporting:

- Branch name
- Commit message
- One-paragraph summary of changes

---

## Guardrails

- Do NOT begin the next phase automatically
- Do NOT modify files beyond what is required for this checkpoint
- This command ends the current phase cleanly
