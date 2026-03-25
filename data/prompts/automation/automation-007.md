---
id: automation-007
name: "Automate Social Media Posting"
category: automation
intent: automate-posting
action: design
object: config
triggers:
  - "automate social media posting"
  - "schedule social posts"
  - "social media automation"
  - "cross-post content"
  - "social publishing workflow"
intent_signals:
  - "(^|[^a-zA-Z])(automate|schedule)(\\s|.){0,20}(social|posting|posts)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(social media)(\\s|.){0,20}(automation|workflow|pipeline)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(cross-post|crosspost)(\\s|.){0,20}(content|articles)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(manually)(\\s)(post)(\\s)(each)([^a-zA-Z]|$)"
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

You are an automation architect designing social media publishing systems. Automated posting must preserve brand voice, respect platform constraints, and track performance without manual intervention.

Design the social media automation system across these components:

1. **Content intake** — how content enters the pipeline (content calendar, RSS feed, CMS webhook, manual queue), and what metadata accompanies each piece.
2. **Platform adaptation** — transformation rules for each target platform: character limits, hashtag strategy, image sizing, link handling, and tone adjustments per platform.
3. **Scheduling logic** — optimal posting times per platform and audience, spacing rules to avoid over-posting, blackout periods (crisis mode, off-hours), and calendar conflict resolution.
4. **Approval gates** — which content types require human review before publishing, and what the approval workflow looks like.
5. **Asset management** — image and video handling, automatic resizing, alt-text generation, and storage/CDN integration.
6. **Publishing execution** — API integrations per platform, retry logic on failure, and confirmation logging.
7. **Performance tracking** — metrics pulled post-publication (engagement, reach, clicks), aggregation schedule, and where data is stored.
8. **Failure and crisis handling** — what happens when a post fails to publish, and how to pause all scheduled posts quickly in a crisis.
