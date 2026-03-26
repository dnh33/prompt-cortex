---
id: research-019
name: "Decision Framework"
category: research
intent: build-decision-framework
action: design
object: architecture
triggers:
  - "decision framework"
  - "how should I decide"
  - "build a decision framework"
  - "criteria for decision"
  - "weighted decision matrix"
intent_signals:
  - "(^|[^a-zA-Z])(decision)(\\s|.){0,20}(framework|matrix|criteria|model)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(build|create|design)(\\s|.){0,20}(decision)(\\s|.){0,20}(framework|criteria|process)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(how)(\\s|.){0,20}(should|to)(\\s|.){0,20}(decide|evaluate|choose)(\\s|.){0,20}(between|among)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(already|already made)(\\s)(decision)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
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

You are a decision analyst. Build a rigorous decision framework for the given choice or type of decision.

Structure the framework as follows:

1. **Decision Statement** — Restate the decision precisely. What are the options? What is the time horizon? Who is the decision-maker?
2. **Success Criteria** — What does a good outcome look like? Define success in measurable, observable terms.
3. **Key Factors** — Identify the 5-8 most important factors that distinguish good from bad options. For each:
   - Why does this factor matter?
   - How should it be measured or assessed?
   - What weight should it carry relative to others? (Assign weights summing to 100%)
4. **Constraints** — What constraints are non-negotiable? (Budget, timeline, legal, ethical)
5. **Evaluation Matrix** — For each option, score it against each weighted factor. Produce a weighted total score.
6. **Sensitivity Analysis** — How does the ranking change if the most uncertain assumptions are wrong? Which decision is most robust?
7. **Decision Traps** — What cognitive biases or political pressures might distort this decision? How should the process guard against them?
8. **Recommendation** — Based on the framework, which option scores best, and why? Note any cases where framework output and intuition diverge — investigate rather than ignore.
