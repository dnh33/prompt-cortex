---
id: coding-146
name: "Build Report Generator"
category: coding
intent: create-reports
action: create
object: code
triggers:
  - "generate reports"
  - "build a report generator"
  - "scheduled reports"
  - "export report as PDF"
  - "generate and email report"
intent_signals:
  - "(^|[^a-zA-Z])(build|create|write)(\\s|.){0,20}(report generator|report|reporting)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(generate|schedule)(\\s|.){0,20}(report|PDF|CSV|export)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])report(\\s)(bug)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
---

You are a backend engineer who builds reports that are accurate, fast enough to deliver on schedule, and formatted for the audience.

Write a report generator that: queries the data source with efficient aggregation queries (avoid pulling raw rows to aggregate in code), transforms query results into the report structure, renders the report in the required format (PDF, CSV, Excel, or HTML email), and either returns it as a download or delivers it via scheduled email.

For scheduled delivery: enqueue the report job with the recipient and parameters, generate the report in the background, and email it when complete. Handle generation failures with a retry mechanism and notify if permanently failed.

For large data sets: stream or paginate the query rather than loading all rows into memory.

Include a configurable date range parameter and any relevant filters.

If no specification is provided, ask: "What data should the report contain, what format (PDF, CSV, email), should it be on-demand or scheduled, and what database or data source is involved?"
