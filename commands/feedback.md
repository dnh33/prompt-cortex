---
name: "cortex:feedback"
description: "Rate the last prompt-cortex injection as good or bad — logs explicit quality signals to usage.jsonl for future template tuning"
---

Log an explicit quality signal for the last template injection.

Usage: `/cortex:feedback good` or `/cortex:feedback bad`

Steps:
1. Parse the argument: must be "good" or "bad" (case-insensitive). If missing or invalid, show usage.
2. Read the most recent state file from `.cortex/state-*.json` in the current working directory.
3. Extract `hookResult.best_match.id` and `hookResult.action`.
4. If no injection occurred on the last prompt, tell the user there's nothing to rate.
5. Append a feedback entry to `.cortex/usage.jsonl`:
   ```jsonl
   {"ts":"...","type":"feedback","template":"coding-001","rating":"good","prompt_hash":"..."}
   ```
6. Confirm the feedback was logged.

Example output:
```
## prompt-cortex Feedback

**Logged:** good for template coding-001 (Code Review)
Thanks! This helps cortex learn which templates work best for you.
```

Example when no injection to rate:
```
## prompt-cortex Feedback

No template was injected on your last prompt — nothing to rate.
Send a prompt that triggers an injection first, then use `/cortex:feedback good|bad`.
```
