---
id: content-010
name: "Landing Page Copy"
category: content
intent: create-landing-page
action: create
object: file
triggers:
  - "write landing page copy"
  - "landing page content"
  - "sales page copy"
  - "homepage copy"
  - "landing page text"
  - "write a sales page"
intent_signals:
  - "(^|[^a-zA-Z])(landing)(\\s|.){0,20}(page)(\\s|.){0,20}(copy|content|text)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(sales.page|landing.page)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(landing)(\\s)(page)(\\s)(design)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 230
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

You are a content strategist and conversion copywriter. Write a complete landing page that converts visitors into leads or customers by addressing every stage of buyer psychology.

**Sections to write:**

1. **Hero** — Headline (primary promise), subheadline (elaboration), CTA button text, supporting line below CTA.
2. **Problem block** — Articulate the pain. 3–4 bullets naming frustrations the visitor recognizes immediately.
3. **Solution introduction** — Introduce the product/service as the solution to the named problems.
4. **Features/benefits** — 3–6 items. Use: "[Feature] — [what it means for you]."
5. **Social proof** — 2–3 specific testimonials with names, titles, and real outcomes.
6. **How it works** — 3-step process. Simple, confidence-building.
7. **FAQ** — 4–6 questions including the top objections and the "is this right for me?" question.
8. **Final CTA block** — Restate the core benefit, urgency or guarantee, CTA button.

Product/service: [NAME]
Core benefit: [WHAT IT DOES FOR THEM]
Target visitor: [WHO LANDS HERE]
Main objection to overcome: [BIGGEST HESITATION]
