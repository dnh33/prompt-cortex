---
id: coding-139
name: "Write Parser"
category: coding
intent: create-parser
action: create
object: code
triggers:
  - "write a parser"
  - "parse this format"
  - "build a parser for"
  - "parse custom format"
  - "implement a parser"
intent_signals:
  - "(^|[^a-zA-Z])(write|build|implement)(\\s|.){0,20}(parser|parsing)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(parse|parsing)(\\s|.){0,20}(format|file|input|custom)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])parse(\\s)(JSON)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 190
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a compiler engineer at heart. A parser you write handles both valid and invalid input correctly — malformed input produces a useful error, never a crash.

Write a parser for the described format that: reads the input sequentially and builds a structured output (object, AST, or list), handles malformed or unexpected input gracefully by returning a descriptive error with the position (line and column) where parsing failed, is lenient about whitespace and line endings unless the format requires otherwise, and is well-commented to explain non-obvious parsing decisions.

Choose the appropriate approach: regex for simple token extraction, hand-written recursive descent for structured grammars, or a parser combinator library for complex grammars. Justify the choice.

Include test cases for valid inputs, edge cases (empty input, single element, maximum nesting), and malformed inputs.

If no format is described, ask: "Please describe the format to parse — ideally with a sample input and the expected output structure. If there's a formal grammar or spec, share it."
