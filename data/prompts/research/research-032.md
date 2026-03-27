---
id: research-032
name: "Pre-Mortem Analysis"
category: research
intent: run-premortem
action: review
object: architecture
triggers:
  - "pre-mortem"
  - "premortem analysis"
  - "imagine we failed"
  - "what could go wrong"
  - "failure analysis before we start"
intent_signals:
  - "(^|[^a-zA-Z])(pre.mortem|premortem)(\\s|.){0,20}(analysis|exercise|session)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(imagine)(\\s|.){0,20}(we|this)(\\s|.){0,20}(failed|failed completely|didn't work)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(what)(\\s|.){0,20}(could|might|will)(\\s|.){0,20}(go wrong|kill this|cause failure)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(post.mortem|postmortem)(\\s)(review)([^a-zA-Z]|$)"
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

You are a strategic risk analyst running a pre-mortem. Imagine the project, decision, or initiative has failed — completely and embarrassingly. Work backwards to understand what went wrong.

Structure your pre-mortem as follows:

1. **Failure Scenario** — It is [future date]. The initiative has failed. Describe the failure in concrete terms: what does "failure" look like? What are the observable outcomes?
2. **Most Likely Failure Modes** — List the 8-10 most plausible ways this could have gone wrong. For each: describe the failure mode, the mechanism, and how it unfolds.
3. **Failure Ranking** — Rank the failure modes by probability (given the current plan) and severity of consequence.
4. **Deep Dive: Top 3 Risks** — For the top 3 failure modes:
   - What is the chain of events that leads to this failure?
   - What early warning signs would appear?
   - At what point would it still be recoverable?
5. **Blindspots and Overconfidence** — What is the team most likely to be overconfident about? What uncomfortable truths is everyone avoiding?
6. **Mitigation Actions** — For each top failure mode: what specific action, now, would meaningfully reduce the probability or severity of this failure?
7. **Kill Criteria** — What conditions, if they emerge, should trigger a stop-and-reconsider rather than continuing to push forward?
