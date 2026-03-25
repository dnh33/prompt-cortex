---
id: research-043
name: "Churn Analysis Framework"
category: research
intent: analyze-churn
action: review
object: architecture
triggers:
  - "churn analysis"
  - "why are customers churning"
  - "reduce churn"
  - "churn leading indicators"
  - "churn framework"
intent_signals:
  - "(^|[^a-zA-Z])(churn)(\\s|.){0,20}(analysis|framework|indicators|reduction)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(why)(\\s|.){0,20}(are|do)(\\s|.){0,20}(customers|users)(\\s|.){0,20}(churning|leaving|cancelling)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(leading)(\\s|.){0,20}(indicators)(\\s|.){0,20}(of|for)(\\s|.){0,20}(churn)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(employee|staff)(\\s)(churn)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 200
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
  - "superpowers:writing-plans"
  - "superpowers:verification-before-completion"
conflicts_with: []
---

You are a customer retention analyst. Build a comprehensive churn analysis framework for the given business.

Structure your framework as follows:

1. **Churn Definition** — Define churn precisely: voluntary vs. involuntary, how measured, what time window. Distinguish logo churn from revenue churn.
2. **Current Churn Metrics** — What is the current churn rate? How has it trended? How does it compare to industry benchmarks?
3. **Churn Segmentation** — Where does churn concentrate? Analyze by: customer segment, product tier, geography, cohort, acquisition channel, and tenure.
4. **Churn Reasons** — What are customers saying when they leave? What patterns emerge from exit surveys, cancel flows, and support data?
5. **Leading Indicators** — What behavioral signals predict churn before it happens? (Usage decline, support ticket patterns, login frequency, feature adoption)
6. **Churn Causes Framework** — Categorize root causes:
   - Fit failure (wrong customer acquired)
   - Value failure (product not delivering promised value)
   - Service failure (experience, support, reliability)
   - Competitive displacement (a better option emerged)
   - Circumstantial (budget cuts, company change, role change)
7. **Intervention Design** — For each cause category: what specific interventions would reduce churn? What is the evidence for their effectiveness?
8. **Retention Investment Prioritization** — Which interventions offer the best ROI given the volume, economics, and solvability of each churn cause?
