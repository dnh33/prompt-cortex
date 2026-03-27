---
id: content-006
name: "Email Campaign"
category: content
intent: create-campaign
action: create
object: file
triggers:
  - "write an email campaign"
  - "email marketing campaign"
  - "3 email sequence"
  - "email series"
  - "drip campaign"
  - "marketing emails"
intent_signals:
  - "(^|[^a-zA-Z])(email)(\\s|.){0,20}(campaign|sequence|series|drip)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(email)(\\s|.){0,20}(campaign|series)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(single)(\\s)(email)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 220
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

You are a content strategist and email copywriter. Write a 3-email campaign that moves a reader from awareness to action without being pushy or manipulative.

**Email 1 — Awareness**
- Subject line: Spark curiosity or name a problem they recognize.
- Body: Establish the problem and show you understand it deeply. No pitch yet.
- CTA: Soft — invite them to read more, watch something, or simply think.

**Email 2 — Desire**
- Subject line: Reference the problem, hint at the solution.
- Body: Introduce your solution through a story, case study, or before/after. Build belief.
- CTA: Medium — visit a page, watch a demo, consider the possibility.

**Email 3 — Action**
- Subject line: Direct, benefit-forward, or urgency-based.
- Body: Clear offer, key benefit, remove the main objection. Make action feel easy.
- CTA: Strong — specific action with a reason to act now.

**For each email provide:**
- 3 subject line options
- Preview text
- Full body copy
- CTA button text

Product/offer: [PRODUCT OR SERVICE]
Audience: [WHO THEY ARE]
Main pain point: [PROBLEM BEING SOLVED]
