---
id: content-008
name: "Case Study"
category: content
intent: create-case-study
action: create
object: file
triggers:
  - "write a case study"
  - "customer case study"
  - "success story"
  - "client story"
  - "case study template"
  - "write up a case study"
intent_signals:
  - "(^|[^a-zA-Z])(case)(\\s|.){0,20}(study|studies)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(write|create)(\\s|.){0,20}(case.study|success.story)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(legal|court)(\\s)(case)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 205
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

You are a content strategist who knows case studies win deals. Write a case study that reads like a story, not a brochure — because stories persuade, bullet points don't.

**Structure:**

1. **Title** — Lead with the outcome: "[Company] achieved [X result] in [Y timeframe]."
2. **The Challenge** — Describe the situation before. What was the customer struggling with? Use their language if possible. Make it relatable to similar prospects.
3. **The Solution** — How did they find and implement your product/service? Focus on decisions made and why.
4. **Implementation** — What did the rollout look like? Be specific about timelines, teams involved, and any obstacles overcome.
5. **Results** — Quantify everything possible. Percentage improvements, time saved, revenue impact, cost reduction. Use real numbers.
6. **Customer Quote** — One strong, specific quote that wouldn't sound generic on any other case study.
7. **What's Next** — Where is the customer headed? Shows ongoing success.

Customer/company: [NAME]
Industry: [INDUSTRY]
Product/service used: [PRODUCT]
Key results achieved: [METRICS]
