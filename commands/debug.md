---
name: "cortex:debug"
description: "Show what prompt-cortex would inject for the last prompt — displays matched templates, confidence scores, leave-alone score, and disposition"
---

Show the user what prompt-cortex matched on their last prompt.

Read the most recent state file from `.cortex/state-*.json` in the current working directory. If multiple state files exist, use the one with the most recent `lastHookRun` timestamp.

Display the following information in a clear table format:

1. **Last Prompt Hash**: from `lastPromptHash`
2. **Hook Result**:
   - Action/disposition (injected, deferred, suppressed, escaped, below_threshold)
   - Leave-alone score and reason
   - Best match template ID and confidence
   - Top 3 candidates with confidence scores
   - Score breakdown (action, object, keyword, signal_boost, negative, complexity, suppression)
3. **Recent Injections**: last 5 from `recentInjections` array
4. **Cortex Status**: enabled or disabled (`cortex_disabled` flag)

If no state file is found, tell the user that no prompt-cortex state exists yet — they need to send at least one prompt first.

Example output format:
```
## prompt-cortex Debug

**Status**: Active (enabled)
**Last run**: 2026-03-25T20:29:45Z

### Match Result
| Field | Value |
|-------|-------|
| Disposition | injected |
| Template | coding-001 (Code Review) |
| Confidence | 0.92 |
| Leave-alone | 0.00 (none) |

### Score Breakdown
| Signal | Score |
|--------|-------|
| Action match | +0.45 |
| Object match | +0.35 |
| Keyword overlap | +0.02 |
| Intent signal | +0.10 |

### Recent Injections (last 5)
1. coding-001 @ 2026-03-25T20:29:45Z
```
