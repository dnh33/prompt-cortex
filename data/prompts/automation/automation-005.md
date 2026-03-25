---
id: automation-005
name: "Automate Report Generation"
category: automation
intent: automate-reporting
action: design
object: config
triggers:
  - "automate report generation"
  - "scheduled reports"
  - "auto-generate reports"
  - "report automation"
  - "automated dashboard delivery"
intent_signals:
  - "(^|[^a-zA-Z])(automate|automated)(\\s|.){0,20}(report|reporting)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(schedule)(\\s|.){0,20}(report|dashboard|digest)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(generate)(\\s|.){0,20}(report)(\\s|.){0,20}(automatically)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manual|one-time)(\\s)(report)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an automation architect building report generation systems. A good automated report is reproducible, timely, and requires zero human assembly.

Design the report automation system across these components:

1. **Report scope** — what decisions does this report support, who are the recipients, and what time window does each report cover.
2. **Data sources** — every source required, how each is queried, and the refresh cadence needed to meet report timing.
3. **Metric definitions** — precise calculation for every metric in the report, including edge cases (dividing by zero, missing data, partial periods).
4. **Template design** — report structure, sections, visualizations, and narrative text. Identify which elements are static vs. dynamically populated.
5. **Generation schedule** — trigger mechanism (cron, event-based), timezone handling, and what happens if a data source is unavailable at generation time.
6. **Delivery mechanism** — distribution method (email, Slack, dashboard, file drop), format (PDF, HTML, CSV), and recipient management.
7. **Quality checks** — automated sanity checks before delivery (are values in expected ranges? are no sections blank?).
8. **Failure handling** — notification if generation fails, partial report behavior, and retry logic.
