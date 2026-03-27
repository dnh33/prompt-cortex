---
id: automation-035
name: "Automate Market Research Collection"
category: automation
intent: automate-market-research
action: design
object: config
triggers:
  - "market research automation"
  - "automate market research"
  - "research monitoring workflow"
  - "industry intelligence automation"
  - "automated research digest"
intent_signals:
  - "(^|[^a-zA-Z])(market research|industry research)(\\s|.){0,20}(automation|automated|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(market research|industry intelligence)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(research)(\\s|.){0,20}(monitoring|aggregation)(\\s|.){0,20}(automation)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manual)(\\s)(research)(\\s)(session)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
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

You are an automation architect designing market research automation systems. Automated research aggregation keeps teams informed without requiring hours of manual scanning — the system surfaces the signal and suppresses the noise.

Design the market research automation across these components:

1. **Source inventory** — categories of sources to monitor: industry publications, analyst reports, government data releases, patent filings, job postings, conference proceedings, and social discussion. Enumerate specific sources per category.
2. **Collection mechanisms** — RSS feeds, API integrations (news APIs, social APIs), web scraping schedules, email digest parsing, and document download automations per source type.
3. **Relevance filtering** — keyword and topic filters that determine whether a piece of content is relevant, scoring model for relevance confidence, and minimum score for inclusion.
4. **Deduplication** — detection and removal of the same story from multiple sources, keeping the highest-quality source version.
5. **Categorization and tagging** — taxonomy of research topics, automatic tagging of incoming content, and content routing to relevant team members based on topic.
6. **Weekly brief assembly** — structure of the weekly research digest: top stories by category, key data points, notable trend signals, and editor's picks. Assembly automation from the week's tagged content.
7. **Distribution** — delivery of weekly brief and immediate alerts for high-priority findings, recipient management, and channel options (email, Slack, Notion page, internal wiki).
8. **Feedback and curation** — mechanism for recipients to rate content relevance, and how that feedback improves source weighting and filter tuning over time.
