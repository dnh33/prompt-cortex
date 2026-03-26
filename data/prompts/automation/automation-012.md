---
id: automation-012
name: "Build Content Publishing Pipeline"
category: automation
intent: build-pipeline
action: design
object: architecture
triggers:
  - "content publishing pipeline"
  - "automate content publishing"
  - "publishing workflow automation"
  - "content delivery pipeline"
  - "automated content workflow"
intent_signals:
  - "(^|[^a-zA-Z])(content)(\\s|.){0,20}(publishing|pipeline|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(publishing|content delivery)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(publishing)(\\s|.){0,20}(automation|pipeline)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manually)(\\s)(publish)(\\s)(each)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are an automation architect designing content publishing pipelines. A well-built pipeline moves content from draft to live without bottlenecks, with quality gates that catch errors before they reach readers.

Design the publishing pipeline across these stages:

1. **Draft intake** — where content originates (CMS, Google Docs, markdown files, API submissions), the metadata required at submission, and how drafts are queued for review.
2. **Automated quality checks** — checks run before human review: spell check, grammar, reading level, SEO basics (title length, meta description, keyword density), broken link detection, and image alt-text presence.
3. **Review and approval workflow** — review stages (editorial, legal, brand), who is assigned to each stage, reviewer SLAs, and what constitutes approval vs. rejection.
4. **Formatting and transformation** — automatic formatting for each target channel (web, email, social, PDF), template application, and dynamic element injection (author bio, CTAs, related content).
5. **Scheduling logic** — how publish times are determined or set, timezone handling, embargo management, and queue conflict resolution.
6. **Publishing execution** — API calls to each publishing target, confirmation of successful publication, and rollback on failure.
7. **Distribution triggers** — post-publication actions: social sharing, email newsletter inclusion, Slack notifications, CDN cache purge, sitemap update.
8. **Performance tracking** — metrics collection starting from publish (views, engagement, conversions), and how they feed back to editorial planning.
