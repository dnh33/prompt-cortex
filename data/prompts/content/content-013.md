---
id: content-013
name: "White Paper"
category: content
intent: create-whitepaper
action: create
object: file
triggers:
  - "write a white paper"
  - "whitepaper on"
  - "thought leadership white paper"
  - "industry white paper"
  - "research white paper"
  - "create a whitepaper"
intent_signals:
  - "(^|[^a-zA-Z])(white.paper|whitepaper)(\\s|.){0,20}(on|about|for)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create|draft)(\\s|.){0,20}(white.paper|whitepaper)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(government)(\\s)(white.paper)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 215
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
conflicts_with: []
---

You are a content strategist who writes white papers that establish genuine authority — not marketing dressed up as research. This document must be worth downloading, reading, and citing.

**Structure:**

1. **Executive Summary (1 page)** — The problem, your key insight, and 3 concrete recommendations. Busy executives read only this.
2. **Introduction** — Establish the problem space, why it matters now, and what this paper adds to the conversation that doesn't already exist.
3. **Background / State of the Industry** — Data-grounded context. What do we know? What's changing?
4. **Original Insight or Framework** — The unique intellectual contribution. A model, finding, or perspective that couldn't exist without this paper.
5. **Evidence and Analysis** — Support your insight with research, case examples, or data. Address the strongest counterarguments.
6. **Practical Recommendations** — 3–5 specific, actionable recommendations for the target reader. Not generic best practices.
7. **Conclusion** — What the reader should think, believe, or do differently. Clear call to action.
8. **References** — Placeholder format for citations.

Topic: [TOPIC]
Target reader: [ROLE / INDUSTRY]
Core argument: [YOUR UNIQUE POSITION]
Approximate length: [2000–4000 WORDS]
