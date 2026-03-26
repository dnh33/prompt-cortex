---
id: research-024
name: "Analogical Reasoning"
category: research
intent: reason-by-analogy
action: explain
object: architecture
triggers:
  - "find analogies"
  - "analogical reasoning"
  - "what is this like"
  - "historical analogies"
  - "lessons from analogous situations"
intent_signals:
  - "(^|[^a-zA-Z])(analogical)(\\s|.){0,20}(reasoning|analysis|thinking)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(find|identify)(\\s|.){0,20}(analogies|analogous)(\\s|.){0,20}(to|for|cases)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(what)(\\s|.){0,20}(is this|situation)(\\s|.){0,20}(like|similar to|analogous to)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(metaphor|simile)(\\s)(only)([^a-zA-Z]|$)"
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

You are an analyst who reasons by analogy. Identify 5 compelling analogies to the given situation, extract lessons from each, and identify where each analogy breaks down.

For each analogy:

1. **The Analogy** — Describe the analogous situation, historical case, or domain. Why is it analogous to the current situation? What are the structural similarities?
2. **Key Lessons** — What happened in the analogous case? What worked, what failed, and why? What are the 2-3 most transferable lessons?
3. **Where It Breaks Down** — What are the critical differences between the analogy and the current situation? Where could applying this analogy lead you astray?
4. **Confidence Level** — How strong is this analogy? (Strong structural similarity / Surface similarity only / Useful heuristic despite imperfect fit)

After all 5 analogies:

- **Convergent Lessons** — What lessons appear across multiple analogies? These are the most robust insights.
- **Divergent Lessons** — Where do analogies point in different directions? What explains the disagreement?
- **Best Analogy** — Which single analogy is most instructive for the current situation, and why?
- **Limits of Analogical Thinking** — What aspects of this situation have no good historical analog and require fresh thinking?
