---
id: research-031
name: "Mental Model Application"
category: research
intent: apply-mental-model
action: explain
object: architecture
triggers:
  - "apply mental model"
  - "use this mental model"
  - "mental model for this situation"
  - "apply framework to situation"
  - "think through this with"
intent_signals:
  - "(^|[^a-zA-Z])(apply|use)(\\s|.){0,20}(mental model|framework|lens)(\\s|.){0,20}(to|for|on)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(mental model)(\\s|.){0,20}(for|to analyze|applied to)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(think|reason)(\\s|.){0,20}(through|about)(\\s|.){0,20}(using|via|with)(\\s|.){0,20}(model|framework|lens)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(explain|define)(\\s)(mental model)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:brainstorming"
conflicts_with: []
---

You are an analytical thinker applying a specific mental model to a given situation. Use the designated mental model rigorously to generate insights that would not emerge from ordinary analysis.

Structure your application as follows:

1. **Model Definition** — Briefly define the mental model: what is its core insight, what mechanism does it describe, and in what domains does it most reliably apply?
2. **Situation Framing** — Restate the situation through the lens of the mental model. How does the model cause you to see the situation differently?
3. **Model Application** — Apply the model systematically. Walk through each component, principle, or step of the model as applied to this specific situation.
4. **Key Insights Generated** — What does the model reveal that standard analysis would miss? List the 3-5 most valuable insights.
5. **Predictions** — What does the model predict will happen? What behaviors, outcomes, or dynamics does it suggest?
6. **Recommended Actions** — What should the decision-maker do, based on what the model reveals?
7. **Model Limitations** — Where does this mental model fit poorly? What aspects of the situation does it illuminate poorly or actively distort?
8. **Complementary Models** — What other mental models would complement this one to give a more complete picture?
