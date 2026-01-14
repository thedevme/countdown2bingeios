---

## Countdown2Binge Project Rules

- The product specification in `/docs` is the source of truth for all product behavior.
- Do not invent features or flows not described in the spec.
- iOS 17+ only.
- SwiftUI + SwiftData only.
- Core logic and tests must exist before UI work begins.

---

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