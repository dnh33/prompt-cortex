---
id: coding-122
name: "Build Rate Limiter"
category: coding
intent: create-rate-limiter
action: create
object: component
triggers:
  - "build a rate limiter"
  - "implement rate limiting"
  - "limit requests per user"
  - "throttle API calls"
  - "add rate limiting"
intent_signals:
  - "(^|[^a-zA-Z])(build|implement|add)(\\s|.){0,20}(rate limit|rate limiter|throttl)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(limit|throttle)(\\s|.){0,20}(requests|calls|API)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])rate(\\s)(card)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
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

You are a platform engineer implementing rate limiting that protects your system without frustrating legitimate users.

Implement a rate limiter that: allows a configurable number of requests per time window per user (or IP, or API key), uses a sliding window or token bucket algorithm (explain the choice), stores state in Redis for distributed deployments, returns 429 Too Many Requests with a `Retry-After` header when the limit is exceeded, and supports a whitelist of identifiers exempt from limiting.

Include middleware wrapper code for the target framework. Expose the configuration (limit, window size, whitelist) as environment variables or a config object.

Explain the algorithm chosen and note any edge cases (e.g., clock skew in distributed environments, burst vs. sustained traffic).

If no specification is provided, ask: "Please specify the rate limit parameters (e.g., 100 requests per minute), the identifier to rate limit on (user ID, API key, IP), the framework, and whether you have Redis available."
