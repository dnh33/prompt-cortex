---
id: automation-013
name: "Automate Competitive Monitoring"
category: automation
intent: automate-monitoring
action: design
object: config
triggers:
  - "competitive monitoring automation"
  - "track competitor changes"
  - "automate competitive intelligence"
  - "monitor competitors automatically"
  - "competitive digest"
intent_signals:
  - "(^|[^a-zA-Z])(competitive|competitor)(\\s|.){0,20}(monitoring|tracking|intelligence)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(competitive|competitor)(\\s|.){0,20}(monitoring)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(monitor)(\\s|.){0,20}(competitors|competition)(\\s|.){0,20}(automatically)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manual)(\\s)(competitive)(\\s)(research)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an automation architect designing competitive intelligence systems. Automated competitive monitoring delivers timely, relevant signals without requiring manual research effort.

Design the competitive monitoring automation across these components:

1. **Competitor and source inventory** — list of competitors to monitor, and for each: website pages (pricing, features, careers, blog), social accounts, review sites, job boards, and news sources.
2. **Change detection mechanisms** — web scraping cadence, diff-based change detection for key pages, RSS feed monitoring, social API polling, and review site monitoring. Specify frequency per source type.
3. **Signal classification** — categories of competitive changes worth tracking (pricing changes, new features, new markets, hiring signals, customer reviews, executive moves) and how each is detected.
4. **Noise filtering** — rules to suppress trivial changes (minor text edits, formatting changes), deduplication of the same story from multiple sources, and relevance scoring.
5. **Digest assembly** — how signals are aggregated into a weekly digest: grouping by category, summarization, and prioritization of most significant changes.
6. **Distribution** — delivery method (email, Slack channel, internal wiki update), recipients, and formatting for each channel.
7. **Alert thresholds** — signals significant enough to trigger immediate alerts rather than waiting for the weekly digest (e.g., competitor pricing drop, major product launch).
8. **Feedback and curation** — mechanism for recipients to flag irrelevant signals and improve filtering over time.
