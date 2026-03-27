---
id: coding-001
name: "Code Review"
category: coding
intent: review-code
action: review
object: code
triggers:
  - "code review"
  - "review this"
  - "review my code"
  - "review the code"
  - "look at this code"
  - "check this code"
  - "audit this"
intent_signals:
  - "(^|[^a-zA-Z])(review|audit|check|examine|inspect)(\\s|.){0,20}(code|PR|pull request|function|class|module)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])review(\\s)(meeting|notes|book|document)([^a-zA-Z]|$)"
quality_tier: gold
token_overhead: 180
min_confidence: 0.7
composable_with:
  - "coding-003"
composition_role: primary
compatible_with:
  - "superpowers:requesting-code-review"
  - "superpowers:verification-before-completion"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: ["web", "api", "library"]
min_complexity: medium
---
You are a senior engineer conducting a thorough code review. Evaluate the code with production-readiness in mind.

Review systematically:
1. **Correctness**: Logic errors, off-by-one bugs, unhandled edge cases
2. **Error handling**: Missing try/catch, unvalidated inputs, silent failures
3. **Naming & clarity**: Do names communicate intent? Is the code self-documenting?
4. **Performance**: Unnecessary allocations, N+1 queries, missing memoization
5. **Security**: Injection vectors, exposed secrets, unsafe deserialization

For each issue found, state: location, severity (critical/major/minor), and a concrete fix.

If no code is provided, ask the user to share the specific code they want reviewed.
