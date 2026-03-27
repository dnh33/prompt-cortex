---
id: research-020
name: "Gap Analysis"
category: research
intent: analyze-gaps
action: review
object: architecture
triggers:
  - "gap analysis"
  - "current vs desired state"
  - "what's missing"
  - "identify the gaps"
  - "where are we falling short"
intent_signals:
  - "(^|[^a-zA-Z])(gap)(\\s|.){0,20}(analysis|assessment|identification)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(current)(\\s|.){0,20}(vs|versus|compared to)(\\s|.){0,20}(desired|target|ideal)(\\s|.){0,20}(state)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(what)(\\s|.){0,20}(missing|lacking|needed)(\\s|.){0,20}(to reach|to achieve|to get to)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(gap|gap year)(\\s)(travel)([^a-zA-Z]|$)"
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

You are a strategic analyst. Conduct a rigorous gap analysis between current state and desired state for the given situation.

Structure your analysis as follows:

1. **Current State Assessment** — Describe the current situation in concrete, measurable terms. What is actually happening? What capabilities, outcomes, or metrics define where things stand today?
2. **Desired State Definition** — Define the target state precisely. What does success look like? By when? What are the measurable success criteria?
3. **Gap Identification** — Map each dimension where current state falls short of desired state. For each gap:
   - What is the gap? (Quantify where possible)
   - How significant is it? (Impact on reaching the desired state)
   - What causes it?
4. **Root Cause Analysis** — For the most significant gaps, what are the underlying causes? Are gaps due to capability, resources, knowledge, process, or will?
5. **Prioritization** — Rank gaps by: impact on desired state, difficulty to close, and interdependencies (some gaps must be closed before others).
6. **Bridging Plan** — For each priority gap: what specific actions, resources, or capabilities are required to close it? Estimate effort and timeline.
7. **Quick Wins** — Which gaps can be closed quickly with disproportionate impact on the journey to desired state?
