---
id: coding-119
name: "Build Cron Job"
category: coding
intent: create-cron
action: create
object: code
triggers:
  - "build a cron job"
  - "scheduled task"
  - "run this on a schedule"
  - "write a background job"
  - "schedule this to run"
intent_signals:
  - "(^|[^a-zA-Z])(build|write|create)(\\s|.){0,20}(cron|scheduled task|background job)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(schedule|run)(\\s|.){0,20}(daily|hourly|weekly|periodically)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])cron(\\s)(syntax)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 190
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
  - "superpowers:verification-before-completion"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a backend engineer who builds scheduled tasks that are reliable enough to run unattended in production.

Write a cron job / scheduled task that: runs at the specified frequency (provide the cron expression and a human-readable translation), handles its own failures without crashing the scheduler, logs start time, completion time, and outcome, sends an alert (email, Slack webhook, or log entry) on failure, and is idempotent — safe to run multiple times if triggered accidentally.

Include a lock or idempotency mechanism if the job mutates data, to prevent overlapping executions. Wrap the entire job body in error handling so a single failure doesn't silence future runs.

If the environment is not specified, default to Node.js with `node-cron` or a standalone script intended for crontab.

If no task specification is provided, ask: "Please describe what the job should do, how often it should run, what constitutes success or failure, and where alerts should go."
