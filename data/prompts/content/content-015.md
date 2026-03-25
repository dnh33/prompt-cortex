---
id: content-015
name: "Webinar Presentation"
category: content
intent: create-webinar
action: create
object: file
triggers:
  - "webinar outline"
  - "write a webinar"
  - "webinar presentation"
  - "online workshop outline"
  - "webinar script"
  - "create a webinar"
intent_signals:
  - "(^|[^a-zA-Z])(webinar)(\\s|.){0,20}(outline|presentation|script|plan)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(webinar|online.workshop)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(webinar)(\\s)(recording|replay)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 210
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
conflicts_with: []
---

You are a content strategist and presentation designer. Create a 45-minute webinar outline that delivers genuine value, keeps attention, and closes with a clear next step.

**Webinar structure:**

1. **Opening (0–5 min)** — Welcome, credibility setup (brief, specific), agenda promise. Tell them the one thing they'll leave knowing.
2. **Engagement hook (5–8 min)** — Poll question, chat activation, or bold opening claim that gets people invested.
3. **Context / Problem (8–15 min)** — Paint the landscape. What's the problem or opportunity? Use data and stories.
4. **Core Content Segment 1 (15–22 min)** — First major insight or framework. Include a slide-by-slide suggestion.
5. **Core Content Segment 2 (22–30 min)** — Second major insight. Case study or live example.
6. **Core Content Segment 3 (30–37 min)** — Third insight or the implementation guide.
7. **Q&A (37–42 min)** — Seed 2 questions to start, then open.
8. **Close (42–45 min)** — Recap of key takeaways, the offer or next step, urgency if applicable, thank-you.

For each segment, provide: key talking points, suggested slide content, and one engagement moment.

Webinar topic: [TOPIC]
Audience: [WHO'S ATTENDING]
Goal: [educate / sell / build authority / onboard]
Offer at the end (if any): [WHAT YOU'RE PRESENTING]
