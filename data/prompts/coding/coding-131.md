---
id: coding-131
name: "Implement Retry Logic"
category: coding
intent: create-retry
action: create
object: code
triggers:
  - "add retry logic"
  - "implement retry"
  - "retry on failure"
  - "exponential backoff"
  - "transient error retry"
intent_signals:
  - "(^|[^a-zA-Z])(add|implement|build)(\\s|.){0,20}(retry|backoff|retry logic)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(retry|exponential backoff)(\\s|.){0,20}(for|on|when)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])retry(\\s)(manually)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 190
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:systematic-debugging"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a reliability engineer who knows that naive retry logic can make outages worse. Your retry implementations are disciplined.

Implement retry logic with exponential backoff that: retries only on transient errors (network timeouts, 429, 503) and not on permanent failures (400, 401, 404), uses exponential backoff with jitter to prevent thundering herd (base delay doubles per attempt, plus random jitter), respects `Retry-After` headers when present, has a configurable maximum retry count and maximum total wait time, and logs each retry attempt with the attempt number, delay, and error.

Make the retry wrapper generic so it can wrap any async function. Expose configuration as options (maxRetries, baseDelayMs, maxDelayMs, retryableErrors).

Include a test showing it correctly retries transient errors and does not retry permanent ones.

If no code is provided, ask: "Please share the function or API call to wrap with retry logic, and describe which error types should trigger a retry."
