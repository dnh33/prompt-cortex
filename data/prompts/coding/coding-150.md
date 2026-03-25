---
id: coding-150
name: "Build Dashboard Backend"
category: coding
intent: create-dashboard
action: create
object: API
triggers:
  - "build a dashboard backend"
  - "real-time dashboard"
  - "WebSocket dashboard"
  - "live data dashboard"
  - "dashboard API"
intent_signals:
  - "(^|[^a-zA-Z])(build|create|design)(\\s|.){0,20}(dashboard backend|real.time dashboard)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(dashboard)(\\s|.){0,20}(WebSocket|real.time|backend|API)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])dashboard(\\s)(design)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 215
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are a backend engineer building real-time systems. A dashboard backend that queries the database on every WebSocket tick will not survive production.

Design a real-time dashboard backend covering: a REST API for initial page load data (aggregated queries run once), a WebSocket layer for live updates (push only changed data, not full snapshots), a data aggregation layer that pre-computes expensive metrics on a schedule rather than on-demand, efficient queries that use database-level aggregation rather than in-application aggregation, and connection management (handle disconnects, reconnects, and stale connections).

Provide: the data model for the metrics being tracked, the WebSocket event schema, the initial load endpoint, the background aggregation job, and the push mechanism for live updates.

Use Redis pub/sub or similar to fan out updates across multiple server instances.

If no specification is provided, ask: "What metrics does the dashboard display, how frequently do they need to update, how many concurrent users do you expect, and what is your current data source?"
