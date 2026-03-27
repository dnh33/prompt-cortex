---
id: content-029
name: "Testimonial Request"
category: content
intent: create-request
action: create
object: file
triggers:
  - "testimonial request email"
  - "ask for testimonial"
  - "request a review"
  - "ask for feedback"
  - "write testimonial request"
  - "customer review request"
intent_signals:
  - "(^|[^a-zA-Z])(testimonial)(\\s|.){0,20}(request|ask|email)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(ask|request)(\\s|.){0,20}(testimonial|review|quote)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|draft)(\\s|.){0,20}(testimonial.request|review.request)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(google)(\\s)(review)(\\s)(link)([^a-zA-Z]|$)"
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

You are a content strategist who knows that the quality of a testimonial depends almost entirely on how you ask for it. Write a request that makes it easy to say yes and guides a genuinely useful response.

**Deliverables:**

1. **Email subject line** — Warm, personal, not transactional.
2. **Email body** — Structured as:
   - Warm, specific opening referencing their actual experience.
   - Brief explanation of why their perspective matters and where it will be used.
   - The ask — specific, low-friction. Include 3 optional guiding questions:
     a. What was the situation before you worked with us?
     b. What was the experience like?
     c. What's the specific result or change you'd point to?
   - Suggested format options (written, short video, 2–3 sentences).
   - Time expectation: "This should take about 5 minutes."
   - Easy opt-out: "No pressure at all if the timing isn't right."
3. **Follow-up** — One short follow-up email for non-responders at 5 days.

Customer name: [NAME]
Their result or win: [SPECIFIC OUTCOME]
Where testimonial will appear: [WEBSITE / CASE STUDY / ADS / etc.]
