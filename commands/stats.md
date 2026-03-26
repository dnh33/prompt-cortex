---
name: "cortex:stats"
description: "Display prompt-cortex usage analytics — most-used templates, confidence trends, rejection rate, and project-specific template affinity from local telemetry"
---

Display usage analytics from prompt-cortex telemetry data.

Read `.cortex/usage.jsonl` from the current working directory. Parse each line as JSON.

Display the following sections:

### 1. Overview
- Total prompts processed
- Injections (count and %)
- Deferrals (count and %)
- Suppressions (count and %)
- Escapes/rejections (count and %)
- Below threshold (count and %)

### 2. Most-Used Templates (top 10)
- Template ID, name, injection count, average confidence

### 3. Feedback Summary (if any /cortex:feedback entries exist)
- Good ratings: count
- Bad ratings: count
- Templates with most good/bad ratings

### 4. Session Summary
- Date range (first to last entry)
- Average injections per session (rough — group by date)

Example output:
```
## prompt-cortex Stats

### Overview (last 30 days)
| Metric | Count | % |
|--------|-------|---|
| Total prompts | 142 | 100% |
| Injected | 67 | 47% |
| Deferred | 23 | 16% |
| Suppressed | 31 | 22% |
| Escaped | 5 | 4% |
| Below threshold | 16 | 11% |

### Most-Used Templates
| # | Template | Injections | Avg Confidence |
|---|----------|-----------|----------------|
| 1 | coding-001 (Code Review) | 23 | 0.89 |
| 2 | coding-002 (Debug Error) | 15 | 0.82 |
| 3 | coding-003 (Write Tests) | 12 | 0.78 |

### Feedback
- Good: 8 ratings
- Bad: 2 ratings
- Best rated: coding-001 (5 good)

### Activity
- Since: 2026-03-25
- Days active: 3
- Avg injections/day: 22
```

If no `usage.jsonl` exists, tell the user that no telemetry data exists yet.

Implementation: Use `jq` to parse the JSONL file. Read the file line by line or use `jq -s` on the whole file. Group and aggregate as needed. All analysis is local — no data leaves the machine.
