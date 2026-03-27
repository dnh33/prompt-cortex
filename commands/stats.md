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

## Additional v1.2 Analytics

### Context Intelligence
When displaying stats, also show:

1. **Context Coverage**: What percentage of prompts had project context available (entries with a non-empty `context` or `project` field in the telemetry)
2. **Filter Effectiveness**: How many candidate templates were filtered by Phase 3 context matching (requires language/framework mismatch). Look for entries where `filtered_count` > 0 or where the disposition indicates context filtering removed candidates.
3. **Affinity Impact**: Average confidence boost from `project_affinity` matches. If telemetry entries include an `affinity_boost` field, compute the mean across all injected prompts.
4. **Preset Active**: Whether a preset is currently active (check `.cortex/config.json` for `preset` field) and its impact on injection rates — compare injection % for entries with vs without a preset.
5. **Top Filtered**: Templates most frequently removed by context filter (may indicate schema misalignment). List up to 5 templates that appear in `filtered_templates` arrays.

### Cross-Project View
If `.cortex/usage.jsonl` contains entries from multiple projects (via the `project` field), offer a per-project breakdown showing:
- Project name/path
- Injection count and rate per project
- Most-used template per project
- Which projects benefit most from context awareness (highest affinity boost averages)

Example additional output:
```
### Context Intelligence
| Metric | Value |
|--------|-------|
| Context coverage | 78% (111/142 prompts) |
| Templates filtered by context | 34 removals across 111 prompts |
| Avg affinity boost | +0.12 confidence |
| Active preset | backend-api |

### Top Filtered Templates
| Template | Times Filtered | Likely Reason |
|----------|---------------|---------------|
| content-012 | 18 | language mismatch |
| productivity-003 | 9 | framework mismatch |

### Per-Project Breakdown
| Project | Prompts | Injections | Rate | Top Template |
|---------|---------|------------|------|--------------|
| /home/user/api | 89 | 52 | 58% | coding-001 |
| /home/user/docs | 53 | 15 | 28% | content-005 |
```

If no `usage.jsonl` exists, tell the user that no telemetry data exists yet.

Implementation: Use `jq` to parse the JSONL file. Read the file line by line or use `jq -s` on the whole file. Group and aggregate as needed. All analysis is local — no data leaves the machine.
