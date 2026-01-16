---

## Slot Machine Countdown Component

**CRITICAL DIRECTION RULE**: The numbers always go from LEFT to RIGHT, lowest to highest.
- Lowest numbers on the LEFT (0, 1, 2...)
- Highest numbers on the RIGHT (...98, 99, TBD)
- TBD is at position 100 (far RIGHT, highest position)
- When countdown decreases, numbers scroll LEFT (revealing lower numbers)
- When value is nil or invalid, animate to TBD (scroll RIGHT to position 100)

---

## Bug Fixing Workflow

**For small bugs** (typos, simple logic errors, obvious fixes): Just fix them.

**For big issues** (architectural changes, changes that affect multiple components, non-obvious fixes):
1. **Explain what's wrong** - describe the issue clearly so the user understands it
2. **Propose a fix** - explain what you're planning to do and why
3. **Wait for approval** - do NOT touch any code until the user approves the approach

If unsure whether something is a small bug or big issue, ask first.

---

## Countdown2Binge Project Rules

- The product specification in `/docs` is the source of truth for all product behavior.
- Do not invent features or flows not described in the spec.
- iOS 17+ only.
- SwiftUI + SwiftData only.
- Core logic and tests must exist before UI work begins.

---

When making code changes, ALWAYS run build_run_sim using xcodebuildmcp unless explicitly instructed to skip testing. This applies when implementing a feature or fix, modifying Services, Models, shared logic, or making multi-view updates, or when the user says things like “test this” or “let’s see if it works.” Do NOT run build_run_sim for single-file UI tweaks (use SwiftUI Previews instead), when actively iterating on the same file, or when changes are limited to comments, formatting, or naming. Do not screenshot, tap through, or visually interact with the simulator to verify behavior unless explicitly requested. Rely on compiler output and test results only. Do not modify signing, provisioning, credentials, or upload builds; this tool is execution-only and should surface errors clearly and immediately.

When a phase completes successfully:
- Print the line exactly: PHASE COMPLETE — READY FOR REVIEW
- Run: `afplay /System/Library/Sounds/Glass.aiff && osascript -e 'display notification "Ready for review" with title "Phase Complete"'`
- Do not begin the next phase automatically

Always use the design skill when changing the UI

After completing a task that involves tool use, provide a quick summary of the work you've done

<execution_mode>
When a product specification or build plan exists, treat it as explicit authorization to implement tasks described within it.

Do not ask for confirmation for individual files or steps that are clearly defined by:
- The product specification
- The approved build plan
- The current active phase

Pause and ask for clarification only when:
- The specification is ambiguous or contradictory
- A decision would alter architecture or product behavior
- A phase boundary has been reached

Proceed autonomously within a phase. Stop only at phase completion or when blocked.
</execution_mode>