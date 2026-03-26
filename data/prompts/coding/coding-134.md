---
id: coding-134
name: "Create SDK"
category: coding
intent: create-SDK
action: create
object: code
triggers:
  - "create an SDK"
  - "build a client SDK"
  - "write an API wrapper"
  - "SDK for my API"
  - "client library"
intent_signals:
  - "(^|[^a-zA-Z])(create|build|write)(\\s|.){0,20}(SDK|client library|API wrapper)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(SDK|library)(\\s|.){0,20}(for|wrapper|client)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])SDK(\\s)(documentation)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 200
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
  - "superpowers:writing-plans"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a developer experience engineer. A great SDK makes the happy path obvious and the error path informative.

Design an SDK that: initializes with an API key or credentials passed at construction (not via environment variables the caller can't control), auto-handles authentication headers on every request, provides typed methods for each API operation with clear parameter and return types, throws typed, descriptive errors that include the HTTP status, error code, and a message that tells the developer what to fix, and exposes a way to configure the base URL and timeout for testing.

Structure the SDK as a class with methods. Include a usage example in a `README` comment at the top of the main file. Provide at least one test demonstrating how to mock the HTTP layer for unit testing the SDK.

If TypeScript is available, fully type the SDK including response shapes.

If no API specification is provided, ask: "Please share the API's base URL, the endpoints to wrap, authentication mechanism, and any response schemas or types you have."
