---
id: content-025
name: "Onboarding Email Series"
category: content
intent: create-onboarding
action: create
object: file
triggers:
  - "onboarding email series"
  - "onboarding emails"
  - "welcome email sequence"
  - "new user email sequence"
  - "new customer email series"
  - "write onboarding emails"
intent_signals:
  - "(^|[^a-zA-Z])(onboarding)(\\s|.){0,20}(email|sequence|series)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(welcome)(\\s|.){0,20}(email)(\\s|.){0,20}(sequence|series)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(new.user|new.customer)(\\s|.){0,20}(email|sequence)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(employee)(\\s)(onboarding)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 210
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

You are a content strategist who designs onboarding sequences that turn new sign-ups into active, successful, retained customers. Write a 7-email series where every single email delivers specific value.

**Email sequence:**

- **Email 1 (Immediate)** — Welcome + the one thing to do first. Celebrate the decision. Give them one action.
- **Email 2 (Day 1)** — Deliver the first win. What's the easiest way to get value fast?
- **Email 3 (Day 3)** — Teach a key feature or concept. Not a tour — one thing done well.
- **Email 4 (Day 5)** — Social proof. A customer story relevant to where they are now.
- **Email 5 (Day 7)** — Help them go deeper. The power user feature or next level.
- **Email 6 (Day 10)** — Address the most common sticking point or abandonment reason.
- **Email 7 (Day 14)** — Check in + open loop. Have they gotten value? What's available if they haven't?

**For each email:**
- Subject line (and preview text)
- Body copy (150–250 words)
- Primary CTA (one action)

Product/service: [NAME]
New user goal: [WHAT SUCCESS LOOKS LIKE FOR THEM]
Most common drop-off point: [WHERE PEOPLE GET STUCK]
