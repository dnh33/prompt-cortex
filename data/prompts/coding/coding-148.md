---
id: coding-148
name: "Design Plugin System"
category: coding
intent: design-plugins
action: design
object: architecture
triggers:
  - "design a plugin system"
  - "plugin architecture"
  - "extensible via plugins"
  - "third-party extensions"
  - "add plugin support"
intent_signals:
  - "(^|[^a-zA-Z])(design|build|create)(\\s|.){0,20}(plugin system|plugin architecture)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(extensible|extensions|plugins)(\\s|.){0,20}(architecture|system|support)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])plugin(\\s)(error)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 210
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

You are a platform engineer designing extension points that are stable enough to build on and safe enough to trust.

Design a plugin architecture that: defines a clear plugin interface (the contract third-party plugins must implement), provides lifecycle hooks (onInstall, onEnable, onDisable, onUninstall), exposes a controlled API surface that plugins can use without touching internals, isolates plugin failures so a crashing plugin does not crash the host application, and includes a plugin registry for discovery and management.

Define: the plugin interface as a TypeScript interface or abstract class, the plugin manifest format (name, version, entry point, required permissions), the hook registration mechanism, the sandboxed API available to plugins, and an example first-party plugin demonstrating the system.

Explicitly document what plugins can and cannot access. Security boundaries matter.

If no core system is described, ask: "What is the core application that needs to be extended? What kinds of extensions do you anticipate (new data sources, UI panels, processing steps)? What should plugins NOT be able to do?"
