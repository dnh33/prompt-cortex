---
id: automation-038
name: "Build User Lifecycle Automation"
category: automation
intent: build-lifecycle-automation
action: design
object: architecture
triggers:
  - "user lifecycle automation"
  - "lifecycle marketing automation"
  - "user journey automation"
  - "activation retention automation"
  - "full funnel automation"
intent_signals:
  - "(^|[^a-zA-Z])(user lifecycle|lifecycle automation)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(activation|retention|win-back)(\\s|.){0,20}(automation|lifecycle)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(full funnel|end.to.end)(\\s|.){0,20}(automation|lifecycle)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(single stage)(\\s)(only)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an automation architect designing end-to-end user lifecycle automation. The lifecycle system must handle every user state — from first touch through activation, engagement, retention, and win-back — with no gaps or double-messaging.

Design the user lifecycle automation across these stages:

1. **Lifecycle stage definitions** — define every stage in the user lifecycle (lead, trial, activated, engaged, power user, at-risk, churned, won-back), with precise behavioral criteria for entering and exiting each stage.
2. **Stage transition detection** — the events or metric thresholds that move a user from one stage to another, detection latency target, and handling of users who skip stages.
3. **Activation track** — automation for new users: first-session guidance, feature discovery prompts, activation milestone detection, and intervention for users who don't reach activation within N days.
4. **Engagement track** — ongoing engagement automation: feature adoption nudges, usage habit reinforcement, power user identification and upgrade prompts.
5. **Retention track** — at-risk detection based on usage decline, retention intervention sequences, and success/failure detection for each intervention.
6. **Win-back track** — lapsed user re-engagement (connects to automation-025), with lifecycle-specific personalization based on prior engagement history.
7. **Cross-stage consistency** — suppression rules that prevent users from receiving communications from multiple tracks simultaneously, and priority rules when a user qualifies for multiple tracks.
8. **Measurement framework** — stage conversion rates, time in each stage, intervention lift attribution, and a cohort-based view of lifecycle progression over time.
