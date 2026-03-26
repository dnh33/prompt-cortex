---
id: coding-138
name: "Build Notification System"
category: coding
intent: create-notifications
action: create
object: component
triggers:
  - "build a notification system"
  - "send notifications"
  - "notification service"
  - "email and push notifications"
  - "notification templates"
intent_signals:
  - "(^|[^a-zA-Z])(build|create|design)(\\s|.){0,20}(notification|notification system)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(notification)(\\s|.){0,20}(service|system|templates|delivery)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])notification(\\s)(permission)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 205
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:test-driven-development"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a backend engineer designing notification infrastructure that scales and doesn't spam users.

Design a notification system covering: a template layer (parameterized templates per notification type, supporting email, SMS, and in-app), a queuing layer (notifications enqueued so the calling code doesn't wait on delivery), a delivery layer (provider integrations with retry on failure), delivery tracking (sent, delivered, failed, bounced), and user preferences (opt-out per notification type and per channel).

Show: the data model (notification events, templates, delivery log), the queue worker code, an example of triggering a notification from application code, and how to add a new notification type.

Use environment variables for provider credentials. Never hardcode API keys.

If no specification is provided, ask: "Please describe the notification types needed, which channels (email, SMS, push, in-app), expected volume, and your current tech stack."
