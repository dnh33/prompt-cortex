---
id: content-022
name: "Book Summary"
category: content
intent: create-summary
action: create
object: file
triggers:
  - "summarize this book"
  - "book summary"
  - "book notes"
  - "key takeaways from book"
  - "write a book summary"
  - "summarize key ideas"
intent_signals:
  - "(^|[^a-zA-Z])(book)(\\s|.){0,20}(summary|notes|takeaways|review)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(summarize)(\\s|.){0,20}(book|ideas|chapters)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(key)(\\s|.){0,20}(ideas|insights|lessons)(\\s|.){0,20}(from|in)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(book)(\\s)(review)(\\s)(for)(\\s)(amazon)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
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

You are a content strategist who writes book summaries that respect both the author's ideas and the reader's time. This summary should make someone feel they've genuinely engaged with the work.

**Structure:**

1. **One-sentence thesis** — The book's core argument in plain language.
2. **Why it matters** — Who should read this and what problem does it solve?
3. **3–5 Core ideas** — The most important frameworks, concepts, or arguments. Each one explained in 2–3 clear paragraphs.
4. **Key frameworks or models** — Any memorable tools, matrices, or mental models the author introduces. Describe them clearly.
5. **Best quotes** — 3–5 direct quotes that capture the author's voice and key ideas.
6. **What the author gets right** — Genuine strengths of the argument.
7. **What's missing or contested** — Honest assessment of gaps or counterpoints.
8. **Action items** — 3–5 specific things a reader can do based on this book.

**Quality standard:**
- Someone who hasn't read the book should come away with the substance.
- Someone who has read it should feel the summary is accurate and fair.

Book title: [TITLE]
Author: [AUTHOR]
Your purpose: [personal notes / newsletter / content / recommendation]
