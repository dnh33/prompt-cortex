---
id: content-041
name: "Workshop Curriculum"
category: content
intent: create-curriculum
action: create
object: file
triggers:
  - "workshop curriculum"
  - "half day workshop"
  - "workshop outline"
  - "training workshop plan"
  - "workshop session plan"
  - "design a workshop"
intent_signals:
  - "(^|[^a-zA-Z])(workshop)(\\s|.){0,20}(curriculum|outline|plan|design|session)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(design|create|write)(\\s|.){0,20}(workshop|training)(\\s|.){0,20}(curriculum|outline|plan)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(half.day|full.day)(\\s|.){0,20}(workshop|training)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(woodworking)(\\s)(workshop)([^a-zA-Z]|$)"
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

You are a content strategist and instructional designer. Create a half-day workshop curriculum (3.5–4 hours) that produces real behavior change, not just awareness.

**Curriculum structure:**

1. **Learning objectives** — 3–5 specific, measurable outcomes. What will participants be able to DO differently afterward?
2. **Pre-work (optional)** — What should participants read, reflect on, or prepare before arrival?
3. **Session 1 (60 min): Foundation** — Context, mindset, shared language. Include opening activity.
4. **Break (10 min)**
5. **Session 2 (60 min): Core skills** — The main teaching. Interactive, not lecture-only.
6. **Lunch / Break (30 min)**
7. **Session 3 (60 min): Application** — Participants apply the learning to their real situation.
8. **Session 4 (30 min): Practice and feedback** — Small group work, coaching, iteration.
9. **Closing (20 min)** — Commitments, measurement, next steps.

**For each session:**
- Learning objective
- Content overview
- Activity or exercise
- Materials needed
- Facilitation notes

Workshop topic: [TOPIC]
Participants: [ROLE / BACKGROUND]
Desired behavior change: [WHAT SHOULD BE DIFFERENT AFTER]
Facilitator experience level: [NOVICE / INTERMEDIATE / EXPERT]
