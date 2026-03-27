---
id: content-012
name: "Social Media Calendar"
category: content
intent: create-calendar
action: create
object: file
triggers:
  - "social media calendar"
  - "content calendar"
  - "30 day social plan"
  - "monthly content plan"
  - "social media plan"
  - "content schedule"
intent_signals:
  - "(^|[^a-zA-Z])(social.media|content)(\\s|.){0,20}(calendar|schedule|plan)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(30.day|monthly)(\\s|.){0,20}(content|social|posting)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(google)(\\s)(calendar)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 200
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a content strategist building a 30-day social media calendar. Create a plan that maintains consistent output without sacrificing quality or burning out the creator.

**Deliverable format:**

Produce a 30-day table with these columns:
- Day / Date
- Platform
- Content type (educational / entertaining / promotional / personal / engagement)
- Topic or hook
- Format (post / reel / story / carousel / video)
- Optimal posting time
- Hashtag category (not specific tags — categories like "niche + broad + brand")
- Notes

**Planning principles:**
- Follow the 4:1:1 rule — 4 value posts, 1 promotional, 1 personal for every 6 posts.
- Vary formats to avoid feed fatigue.
- Build content themes across the week (e.g., Monday motivation, Wednesday tips, Friday wins).
- Include 4 "engagement" days focused on responding and community building.
- Flag 2 high-effort "hero content" pieces per month.

Brand/business: [NAME]
Platforms: [INSTAGRAM / LINKEDIN / TWITTER / TIKTOK / etc.]
Audience: [WHO YOU'RE REACHING]
Business goals this month: [GOALS]
Content pillars: [2–4 THEMES YOU ALWAYS COVER]
