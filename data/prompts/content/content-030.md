---
id: content-030
name: "Product Launch Email"
category: content
intent: create-launch-email
action: create
object: file
triggers:
  - "product launch email"
  - "launch announcement email"
  - "new product email"
  - "write a launch email"
  - "product release email"
  - "launch day email"
intent_signals:
  - "(^|[^a-zA-Z])(product|launch)(\\s|.){0,20}(launch|announcement)(\\s|.){0,20}(email)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|draft|create)(\\s|.){0,20}(launch.email|product.email)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(new.product|new.feature)(\\s|.){0,20}(email|announcement)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(rocket)(\\s)(launch)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 180
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
---

You are a content strategist and launch copywriter. Write a product launch email that converts warm subscribers into buyers by making them feel like the timing is perfect and the decision is easy.

**Structure:**

1. **Subject line** — 3 options: one that creates anticipation, one direct/benefit-first, one curiosity-based.
2. **Preview text** — Complements the subject line. 40–60 characters.
3. **Opening** — Build anticipation from what came before (if a pre-launch sequence exists) or establish the moment. Why today, why now.
4. **The announcement** — Clear, simple. What is it, what does it do, who is it for.
5. **The key benefit** — One headline benefit. Not a feature list — the thing that changes everything for the right person.
6. **Urgency** — Real, not manufactured. Launch pricing, limited availability, bonus for early buyers.
7. **Objection handling** — The most common "but what about..." answered in 1–2 sentences.
8. **CTA** — One button. Clear action. Reiterate the key benefit.
9. **P.S.** — Restate the urgency or add a secondary benefit. P.S. lines get read.

Product name: [NAME]
Core benefit: [WHAT IT DOES FOR THEM]
Launch offer or urgency: [DISCOUNT / BONUS / DEADLINE]
List context: [WHO'S RECEIVING THIS]
