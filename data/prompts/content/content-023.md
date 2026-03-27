---
id: content-023
name: "Opinion Piece"
category: content
intent: create-opinion
action: create
object: file
triggers:
  - "write an opinion piece"
  - "op-ed"
  - "opinion article"
  - "write my take on"
  - "editorial piece"
  - "write a perspective on"
intent_signals:
  - "(^|[^a-zA-Z])(opinion)(\\s|.){0,20}(piece|article|post|essay)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(op.ed|editorial)(\\s|.){0,20}(about|on|regarding)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|draft)(\\s|.){0,20}(take|perspective|view)(\\s|.){0,20}(on)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(opinion)(\\s)(survey|poll)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 190
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

You are a content strategist and essayist. Write an opinion piece that makes a bold, well-reasoned argument that challenges the reader to rethink something they take for granted.

**Structure:**

1. **Opening** — A concrete scene, anecdote, or observation that draws the reader in and hints at the argument. Not "In today's world..."
2. **The claim** — State your argument clearly and boldly. Don't bury it. Be specific about what you believe and what you're arguing against.
3. **The evidence** — Support your argument with 3–4 concrete pieces of evidence: research, examples, historical analogies, or data. Not opinion stacked on opinion.
4. **Steelmanning the opposition** — Take the strongest counterargument seriously. Show you understand why smart people disagree with you.
5. **The rebuttal** — Why your view still holds, or where you concede ground and sharpen your argument.
6. **The call to rethink** — What should the reader now question, believe, or do differently? End with something memorable.

**Tone:** Confident but not arrogant. Specific not vague. Provocative not inflammatory.

Your position: [THE ARGUMENT YOU WANT TO MAKE]
Topic area: [FIELD OR SUBJECT]
Target publication or audience: [WHERE / WHO]
