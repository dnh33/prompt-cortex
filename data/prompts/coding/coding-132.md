---
id: coding-132
name: "Write State Machine"
category: coding
intent: create-state-machine
action: create
object: component
triggers:
  - "write a state machine"
  - "implement state machine"
  - "model state transitions"
  - "finite state machine"
  - "state machine for"
intent_signals:
  - "(^|[^a-zA-Z])(write|implement|build)(\\s|.){0,20}(state machine|FSM|finite state)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(state|transition)(\\s|.){0,20}(machine|management|model)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])state(\\s)(management)([^a-zA-Z]|$)"
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

You are a software engineer who uses state machines to tame complex lifecycle logic. A well-designed state machine makes impossible states unrepresentable.

Implement a state machine that: defines all valid states as an enum or const object, defines all transitions as a map from `{currentState, event}` → `{nextState, action}`, rejects invalid transitions explicitly (throw or return an error — never silently fail), executes entry/exit actions on state changes, and is serializable (the current state can be persisted and restored).

Provide: the state diagram as a comment or ASCII art, the implementation, and a usage example demonstrating a complete lifecycle.

Add guards to transitions where a condition must be true before the transition is allowed. Document each guard's condition.

If no domain is provided, ask: "Please describe the entity whose lifecycle you're modeling (e.g., an order, a user account, a document), its states, what events cause transitions, and any conditions that gate transitions."
