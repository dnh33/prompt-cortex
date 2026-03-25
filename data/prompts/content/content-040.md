---
id: content-040
name: "Re-Engagement Campaign"
category: content
intent: create-reengagement
action: create
object: file
triggers:
  - "re-engagement campaign"
  - "win back email"
  - "reactivation campaign"
  - "lapsed customer email"
  - "win back inactive users"
  - "re-engagement email series"
intent_signals:
  - "(^|[^a-zA-Z])(re.engagement|reengagement)(\\s|.){0,20}(campaign|email|series)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(win.back|winback)(\\s|.){0,20}(email|campaign|customers)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(inactive|lapsed)(\\s|.){0,20}(customer|user|subscriber)(\\s|.){0,20}(email|campaign)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(customer)(\\s)(feedback)(\\s)(email)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
conflicts_with: []
---

You are a content strategist who knows re-engagement campaigns fail when they're either desperate or generic. Write a 3-email sequence that acknowledges the gap honestly and earns a reason to return.

**Email 1 — Acknowledge the gap**
- Subject: Reference the absence without shame.
- Body: Acknowledge you haven't been in touch. No excuses — just honesty. Remind them of what they valued before. Ask: "Still relevant?"
- CTA: Low-friction. Not a purchase — a click, a read, an update.

**Email 2 — Deliver value, no strings**
- Subject: Benefit-forward, relevant to their past behavior.
- Body: Give something genuinely useful. A guide, insight, or resource. Show what's new or improved since they left.
- CTA: Still soft — curiosity-driven.

**Email 3 — The offer and honest close**
- Subject: Direct. Either an offer or an honest goodbye.
- Body: Make a concrete reason to come back (incentive, new capability, or changed circumstance). Then offer an honest exit: "If this isn't for you anymore, I understand."
- CTA: Clear action OR easy unsubscribe. Respect their decision.

Brand: [NAME]
Why they went inactive: [HYPOTHESIS]
What's changed since they left: [NEW VALUE / IMPROVEMENT]
Incentive available: [OPTIONAL: DISCOUNT / BONUS]
