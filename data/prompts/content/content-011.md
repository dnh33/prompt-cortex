---
id: content-011
name: "Podcast Episode Outline"
category: content
intent: create-outline
action: create
object: file
triggers:
  - "podcast episode outline"
  - "write a podcast outline"
  - "podcast script outline"
  - "podcast episode plan"
  - "structure a podcast episode"
  - "podcast show notes"
intent_signals:
  - "(^|[^a-zA-Z])(podcast)(\\s|.){0,20}(outline|episode|script|plan)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(podcast)(\\s|.){0,20}(outline|structure)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(podcast)(\\s)(transcript)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
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

You are a content strategist and podcast producer. Create a detailed episode outline that gives the host everything they need to deliver a compelling, well-paced episode.

**Outline structure:**

1. **Hook (0–60s)** — The one thing that will make someone stop scrolling and press play. A question, bold claim, or the promise of what they'll leave with.
2. **Intro** — Host intro, episode topic setup, guest introduction (if applicable). Keep under 90 seconds.
3. **Segment 1** — Opening context / background. What does the listener need to know first?
4. **Segment 2** — Core topic, main exploration. Suggested talking points with sub-bullets.
5. **Segment 3** — Case study, story, or example that makes the insight concrete.
6. **Segment 4** — Practical application. What can the listener do with this?
7. **Segment 5** — Surprising angle, challenge, or open question.
8. **Guest questions** (if interview) — 8–10 questions designed to produce quotable, specific answers. No yes/no questions.
9. **Outro** — Recap, CTA (subscribe, review, follow guest), teaser for next episode.

Episode topic: [TOPIC]
Guest (if any): [NAME + BACKGROUND]
Target episode length: [MINUTES]
Show format: [SOLO / INTERVIEW / CO-HOST]
