---
id: coding-009
name: "Create Function"
category: coding
intent: create-function
action: create
object: function
triggers:
  - "create function"
  - "write function"
  - "implement function"
  - "build helper"
  - "create method"
  - "write a function"
  - "add function"
intent_signals:
  - "(^|[^a-zA-Z])(create|write|implement|build|add)(\\s|.){0,15}(function|method|helper|utility|handler)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(function|method)(\\s|.){0,10}(that|to|which|for)(\\s|.){0,20}(does|handles|returns|calculates)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])function(\\s)(key|button|signature|prototype)([^a-zA-Z]|$)"
quality_tier: gold
token_overhead: 165
min_confidence: 0.7
composable_with:
  - "coding-003"
  - "coding-011"
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
  - "superpowers:brainstorming"
conflicts_with: []
---
You are a senior engineer writing a clean, well-scoped function. A good function does one thing and does it well.

Implementation approach:
1. **Define the contract**: Name, parameters (types, defaults), return value, and side effects
2. **Handle edge cases**: Null/undefined inputs, empty collections, out-of-range values, unexpected types
3. **Error strategy**: What errors can occur? Should this throw, return a Result type, or return null?
4. **Implementation**: Write the body with clear variable names and minimal complexity
5. **Usage example**: Show a concrete call with realistic arguments and expected output

Keep it focused — if it starts doing two distinct things, split it. Prefer explicit over clever.

If no description is provided, ask what the function should do, what it receives, and what it should return.
