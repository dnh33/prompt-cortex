---
id: content-032
name: "Community Post"
category: content
intent: create-community-post
action: create
object: file
triggers:
  - "community post"
  - "write a forum post"
  - "community discussion post"
  - "write for community"
  - "slack community post"
  - "discord post"
intent_signals:
  - "(^|[^a-zA-Z])(community)(\\s|.){0,20}(post|discussion|message)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(community|forum)(\\s|.){0,20}(post|thread)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(slack|discord|circle|forum)(\\s|.){0,20}(post|message|update)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(community)(\\s)(guidelines)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 165
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a content strategist who understands that community engagement requires genuine contribution, not broadcast marketing. Write a post that starts a real conversation and adds value.

**Structure:**

1. **Hook** — A question, observation, or short story that makes members stop scrolling. First line determines if they read on.
2. **Value delivery** — Share something genuinely useful: an insight, lesson, resource, or perspective. This is the deposit that earns the conversation.
3. **Personal angle** — Why does this matter to you specifically? What's your stake? Authenticity drives engagement in communities.
4. **The question** — End with a specific, easy-to-answer question that invites responses. Not "what do you think?" — something with a clear angle: "Has anyone tried X?" or "What's your go-to approach for Y?"

**Community post principles:**
- Give more than you take. Every post should deliver before it asks.
- Be specific. Generic observations get ignored.
- Write like a member, not a brand.
- Keep it under 300 words unless the content demands more.

Community type: [PROFESSIONAL / INTEREST / CUSTOMER / etc.]
Platform: [SLACK / DISCORD / CIRCLE / FACEBOOK GROUP / etc.]
Topic to share: [INSIGHT OR RESOURCE]
Goal: [start conversation / share resource / get feedback / build relationships]
