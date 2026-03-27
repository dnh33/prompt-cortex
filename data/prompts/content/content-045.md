---
id: content-045
name: "Community Guidelines"
category: content
intent: create-guidelines
action: create
object: file
triggers:
  - "community guidelines"
  - "write community rules"
  - "forum guidelines"
  - "community standards"
  - "community code of conduct"
  - "write community policies"
intent_signals:
  - "(^|[^a-zA-Z])(community)(\\s|.){0,20}(guidelines|rules|standards|policy)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create|draft)(\\s|.){0,20}(community.guidelines|code.of.conduct)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(forum|group)(\\s|.){0,20}(guidelines|rules|standards)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(government)(\\s)(guidelines)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
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

You are a content strategist who understands that great community guidelines protect what the community is for — not just what it's against. Write guidelines that feel like an invitation, not a legal document.

**Structure:**

1. **Opening: What this community is for** — Describe the shared purpose and the kind of experience you're creating together. Make members feel proud to be here.
2. **The values we live by** — 3–5 positive principles that define the community culture. Written as aspirations, not prohibitions.
3. **What we expect from members** — Specific, constructive behaviors. "We do X" not "don't do Y" where possible.
4. **What's not okay** — Clear, specific violations. Direct language without being punitive. Include examples.
5. **Consequences** — What happens when guidelines are violated. Be clear and consistent.
6. **How to get help** — Who to contact, how to report, what happens when you do.
7. **A human closing** — These guidelines were written by people who care about this space. End with that.

**Tone:**
- Human, not legal.
- Specific, not vague ("be respectful" means nothing without examples).
- The most important guidelines get the most space.

Community name: [NAME]
Community purpose: [WHAT IT'S FOR]
Platform: [WHERE IT LIVES]
Top concerns to address: [BEHAVIORS YOU'VE SEEN OR ANTICIPATE]
