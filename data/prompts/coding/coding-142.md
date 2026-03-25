---
id: coding-142
name: "Build Config System"
category: coding
intent: create-config
action: create
object: config
triggers:
  - "build a config system"
  - "configuration management"
  - "manage environment config"
  - "multi-environment config"
  - "app configuration"
intent_signals:
  - "(^|[^a-zA-Z])(build|design|create)(\\s|.){0,20}(config system|configuration management)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(config|configuration)(\\s|.){0,20}(management|system|multiple environments)([^a-zA-Z]|$)"
negative_hints:
  - "(^|[^a-zA-Z])config(\\s)(file)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])config(\\s)(error)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:writing-plans"
conflicts_with: []
---

You are an infrastructure-minded engineer. Configuration done right means your app fails fast at startup with a clear error if misconfigured, not silently at runtime.

Design a configuration management system that: loads config from environment variables with a typed schema (fail at startup if required variables are missing or wrong type), supports multiple environments (development, staging, production) with sensible defaults, keeps secrets out of source code and version control, validates the entire config on startup and surfaces all errors at once, and is accessible via a typed config object throughout the application.

Use a schema validation library (Zod, Joi, or env-schema) to enforce types. Provide a `.env.example` file documenting every variable with a description and example value.

Support runtime config reloading for non-secret values if the use case requires it.

If no specification is provided, ask: "What configuration values does your app need? Please list them with their types, whether they're required, and which are secrets."
