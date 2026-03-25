---
id: automation-047
name: "Automate Social Listening"
category: automation
intent: automate-social-listening
action: design
object: config
triggers:
  - "social listening automation"
  - "automate social monitoring"
  - "brand mention monitoring"
  - "social media monitoring workflow"
  - "automate mention tracking"
intent_signals:
  - "(^|[^a-zA-Z])(social listening|social monitoring)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(automate)(\\s|.){0,20}(social listening|mention monitoring|brand monitoring)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(brand mention|mention tracking)(\\s|.){0,20}(automation|workflow)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manually)(\\s)(check)(\\s)(mentions)([^a-zA-Z]|$)"
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

You are an automation architect designing social listening automation. Automated social listening captures every relevant brand mention across platforms and routes responses before opportunities and crises pass.

Design the social listening automation across these components:

1. **Keyword and topic inventory** — brand name variations, product names, executive names, competitor names, industry keywords, and campaign hashtags. Include common misspellings and abbreviations.
2. **Platform coverage** — platforms to monitor (Twitter/X, LinkedIn, Reddit, Facebook, Instagram, TikTok, review sites, forums, news), API or tool integration per platform, and coverage gaps for platforms without API access.
3. **Mention ingestion** — polling frequency per platform, mention deduplication across platforms, and normalization into a unified mention record with author, platform, content, reach estimate, and sentiment.
4. **Classification and routing** — sentiment classification (positive, neutral, negative), category classification (support issue, feature request, praise, crisis signal, sales opportunity, press), and routing rules per category.
5. **Priority scoring** — urgency scoring based on: account reach, sentiment severity, category, and volume spike detection. High-priority mentions alert immediately; others queue for daily review.
6. **Response workflow** — for mentions requiring response: assignment to appropriate team member (support, PR, sales, marketing), response templates per category, SLA by priority, and response logging.
7. **Crisis detection** — volume spike detection for negative mentions, keyword patterns that signal potential crisis (safety, legal, executive mention), and crisis team alert workflow.
8. **Reporting** — daily mention digest, weekly sentiment trend report, share of voice tracking, and campaign performance monitoring.
