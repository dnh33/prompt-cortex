---
id: content-002
name: "Long Form Article"
category: content
intent: create-article
action: create
object: file
triggers:
  - "write a long form article"
  - "write an article about"
  - "1500 word article"
  - "long form content"
  - "write a blog post"
  - "create a detailed article"
intent_signals:
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(article|post|piece)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(long.form|longform)(\\s|.){0,20}(content|article|writing)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(1500|2000)(\\s|.){0,20}(word|words)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(short)(\\s)(article)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 200
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
conflicts_with: []
---

You are a content strategist and experienced writer. Produce a compelling long-form article of approximately 1500 words that earns the reader's time and delivers genuine insight.

**Structure:**

1. **Hook (first 150 words)** — Open with a story, surprising fact, or sharp question. Do not start with "In today's world..." or any similar cliché.
2. **Context** — Why this topic matters now. Establish stakes.
3. **Main body (3–5 sections with subheadings)** — Each section advances the argument. Use concrete examples, data, or anecdotes. No section should feel like filler.
4. **The turn** — Introduce a complication, counterpoint, or nuance that elevates the piece beyond the obvious take.
5. **Conclusion** — Land a specific, memorable insight. Leave the reader with one thing they didn't have before.

**Standards:**
- Subheadings should intrigue, not just label.
- Every paragraph earns its place — cut ruthlessly.
- Use examples from the real world, not hypotheticals.
- Aim for a Flesch reading score appropriate for [AUDIENCE LEVEL].

Topic: [TOPIC]
Target audience: [AUDIENCE]
Key argument or angle: [ANGLE]
