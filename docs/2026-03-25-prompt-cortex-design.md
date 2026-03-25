# prompt-cortex: Design Specification

> **Status**: Approved design, pending implementation plan
> **Date**: 2026-03-25
> **Author**: Daniel Hjermitslev + Rune (Claude Opus 4.6)
> **Repo**: dnh33/prompt-cortex

---

## Executive Summary

prompt-cortex is an invisible prompt intelligence layer for Claude Code. It sits beneath every skill, every agent, every workflow — silently making the instructions Claude receives better. It is what CLAUDE.md would be if it were alive.

The plugin has two layers:
- **Layer 1 (The Whisper)**: A `UserPromptSubmit` hook that fires on every prompt, matches against a 300-prompt library in <2 seconds using keyword/regex matching (no LLM), and injects the best template as `additionalContext`. Claude sees both the raw input AND expert guidance. The user sees nothing.
- **Layer 2 (The Brain)**: An on-demand agent/skill for deep optimization. Composes multi-template prompts, applies Anthropic's 6 techniques, decomposes complex requests into prompt chains. Explicit invocation via `/cortex:optimize` or `/cortex:chain`.

prompt-cortex is not a prompt library. It is a **prompt compiler** — a system that observes what the user is trying to do, matches against proven patterns, and injects the optimal framing as invisible context.

---

## Design Council

This design was synthesized from 4 independent expert agents thinking in parallel:

| Agent | Role | Key Contribution |
|---|---|---|
| Agent Builder | Plugin Architect | "Prompt compiler" framing, rich YAML schema, composition model, Adaptive Prompt Memory |
| Researcher | Market Intel | Competitive landscape, gap validation (38.7K stars on awesome-cursorrules), positioning |
| Prompt Engineer | Intelligence Designer | Meta-prompt system, 7-stage pipeline, leave-it-alone detector, quality feedback loop |
| Software Architect | Platform Strategist | `/cortex:chain` wow feature, template packs, anti-Clippy rules, growth roadmap |

---

## Market Context

The market has two occupied poles and an empty center:

```
[Production API tools]         [Empty Center]         [One-off hook scripts]
Langfuse, PromptLayer    <--  prompt-cortex  -->    prompt-improver, MDC rules
Server-side, no IDE           IDE-native,             Reactive enrichment,
No feedback loop,             stateful library,       no memory, no learning,
no developer UX               auto-optimizing         no cross-session state
```

### Competitive Validation

- **awesome-cursorrules**: ~37,000+ GitHub stars — proves massive demand for prompt libraries. This is a cross-tool signal (Cursor-specific), but the appetite for organized prompt libraries transcends any single IDE.
- **severity1/claude-code-prompt-improver**: 1,300 stars — closest competitor. Uses UserPromptSubmit hook for enrichment, achieves 31% token reduction. But no memory, no learning, no library, no composition.
- **GaZmagik/claude-prompt-improver**: Claude Code plugin, auto-enhances prompts using LLM. Adds 30-50s latency (LLM-based matching). Demonstrates demand but proves keyword matching is the right Layer 1 approach.
- **johnpsasser/claude-code-prompt-optimizer**: Tag-triggered (`<optimize>`) prompt expansion. Requires manual opt-in per prompt — fragile UX.
- **FishHawk/claude-prompt-enhancer**: Deprecated slash-command prompt expansion. Confirms the template library approach has been tried.
- **Comfy-Org/comfy-claude-prompt-library**: Organization-level command templates. Shows team-sharing use case is emerging organically.
- **awesome-claude-code**: Has no prompt template library category — the gap is unoccupied.
- **Nobody** has built an IDE-native, stateful, learning prompt intelligence layer that combines keyword matching + template library + composition + memory.

### Known Platform Risk

**Claude Code Issue #10225**: A documented (currently unresolved) bug where plugin `hooks.json` hooks register correctly but their commands never execute. The same config works when placed in `~/.claude/settings.json`. This is a potential GO/NO-GO blocker for v1.0.

**Mitigations:**
1. Verify bug status against current Claude Code version before shipping
2. SessionStart health-check hook that confirms UserPromptSubmit is firing
3. README troubleshooting section with fallback `~/.claude/settings.json` copy-paste instructions
4. Consider shipping v0.1 as a settings-file install, migrating to plugin format once the bug is confirmed fixed

### Developer Pain Points (ranked)

1. **Context rot / drift** — rules forgotten mid-session (universal, daily)
2. **Rules silently ignored** — no feedback on whether CLAUDE.md is being applied
3. **No session persistence** — starting new chat loses all context
4. **Junior/senior prompt gap** — seniors use XML tags, roles, examples; juniors write "fix the bug"
5. **No feedback loop** — bad prompts produce bad results, but no mechanism to improve

### Positioning

> prompt-cortex is what CLAUDE.md would be if it were alive. It's not a static rules file — it's a versioned, learning, optimizable prompt library that knows what worked, adapts to your codebase, and gets smarter across sessions.

---

## Architecture

### Two-Layer Design

```
User types prompt
       |
       v
[Layer 1: The Whisper]     <-- UserPromptSubmit hook, <2s, deterministic
  |                  |
  | HIGH confidence  | LOW confidence / complex / multi-pattern
  | single match     |
  v                  v
additionalContext    Writes candidates to shared state,
injected silently   injects hint for Layer 2
       |                  |
       v                  v
Claude processes     Claude sees hint about deeper
with enhanced        optimization available via
context              /cortex:optimize or /cortex:chain
```

### Boundary with Superpowers

| Layer | Role |
|---|---|
| **Superpowers** | Visible methodology — workflows, TDD, brainstorming, code review |
| **prompt-cortex** | Invisible optimization — prompt quality beneath every interaction |

They complement: cortex makes the prompts that trigger superpowers skills better. Cortex fires on `UserPromptSubmit` (before response). Superpowers fires on `SessionStart` and via skill auto-detection (during response). Different lifecycle points, natural synergy.

### Shared State

Lightweight JSON at `.cortex/state-{session_id}.json` bridges hook-to-agent communication. Session-scoped to prevent concurrent session conflicts. The `session_id` is provided by the hook environment. Stale state files (>24hr) are cleaned up by the SessionStart hook.

```json
{
  "lastHookRun": "2026-03-25T15:30:00Z",
  "lastPromptHash": "a7f3b2c1",
  "hookResult": {
    "matchedTemplates": ["coding-001", "coding-004"],
    "confidence": 0.72,
    "injectedTemplate": "coding-001",
    "deferredTemplates": ["coding-004"],
    "userIntent": "review-code"
  },
  "recentInjections": [
    {"template": "coding-001", "ts": "2026-03-25T15:28:00Z"},
    {"template": "coding-004", "ts": "2026-03-25T15:25:00Z"}
  ],
  "sessionOptimizations": 3,
  "adaptations": {
    "project_language": "typescript",
    "framework": "nextjs",
    "user_style": "concise"
  }
}
```

---

## YAML Frontmatter Schema

Each of the 300 prompts is a `.md` file with rich YAML frontmatter. The schema enables fast matching (Layer 1), intelligent composition (Layer 2), and anti-Clippy safeguards.

```yaml
---
# === Identity ===
id: coding-001                    # Unique, stable, never changes
name: "Code Review"
version: 2                        # Bump on material template changes
category: coding                  # coding | ai-workflows | research | automation | content | productivity
subcategory: review               # Free-form within category

# === Matching (Layer 1) ===
intent: review-code               # Canonical intent label (closed taxonomy)
action: review                    # From action space: create, review, debug, refactor, explain, test, document, optimize, design, fix
object: code                      # From object space: code, function, file, component, test, PR, commit, API, schema, prompt, config
triggers:                         # Keyword/phrase triggers, ordered by specificity
  - "code review"
  - "review this"
  - "review my code"
  - "review the PR"
  - "look at this code"
intent_signals:                   # Regex patterns that boost match confidence
  - "\\b(review|audit|check)\\b.*\\b(code|PR|pull request|function|class)\\b"
negative_signals:                 # Patterns that should NOT match this template
  - "\\breview (meeting|notes|book)\\b"

# === Context Requirements ===
requires:
  has_codebase: true              # Does this need an actual project?
  language: []                    # Empty = any language
  framework: []                   # Empty = any framework
  min_complexity: medium          # trivial | low | medium | high | expert
project_affinity:                 # Project types where this template shines
  - "web"
  - "api"
  - "library"

# === Composition (Layer 2) ===
composable_with:                  # IDs this combines well with
  - "coding-004"                  # Write Unit Tests
  - "coding-011"                  # Security Audit
composition_role: primary         # primary | modifier | wrapper
  # primary: stands alone, provides core framing
  # modifier: adds a technique/constraint to a primary
  # wrapper: wraps any other template with a meta-technique
conflicts_with:                   # IDs that should NEVER be combined
  - "coding-007"                  # "Explain This Code" — different intent

# === Ecosystem Integration ===
compatible_with:                  # Superpowers skills this template complements
  - "superpowers:requesting-code-review"
  - "superpowers:verification-before-completion"

# === Quality & Budget ===
quality_tier: gold                # gold | silver | bronze
token_overhead: 180               # Approximate tokens this template adds (target 150-200)
effectiveness_score: 0.89         # From evals, updatable via feedback loop
techniques_used:                  # Which of the 6 techniques this applies
  - structural_rewriting
  - chain_of_thought

# === Anti-Clippy ===
min_confidence: 0.7               # Don't inject below this threshold
anti_patterns:                    # When NOT to use this template
  - "User already provided detailed review criteria"
  - "User is asking about a concept, not reviewing real code"

# === Attribution ===
source: "cyrilXBT/300-prompts"
created: 2026-03-25
---
```

### Schema Rationale

- **`triggers` + `intent_signals` + `negative_signals`**: Three-tier matching. Triggers = fast keyword lookup (O(1) inverted index). Signals = regex boosters for fuzzy matching. Negatives = false positive killers.
- **`action` + `object`**: From the Prompt Engineer's intent extraction model. Enables cross-template matching on dimensions.
- **`composable_with` + `composition_role` + `conflicts_with`**: The key to Layer 2. Not every template can combine with every other. The role taxonomy dictates composition order. `conflicts_with` is enforced at runtime in the match engine — if two conflicting templates both score above threshold, the lower-confidence one is dropped silently.
- **`quality_tier` + `effectiveness_score`**: DSPy-inspired. Templates compete; winners get promoted in ranking.
- **`token_overhead`**: Budget control. Hard cap: 300 tokens for a single template, 400 for composed multi-template. Templates should target 150-200 tokens. When a composition exceeds budget, drop the lowest-confidence template. If session context exceeds 50K tokens, raise the injection threshold by +0.10 to reduce noise in long conversations.
- **`compatible_with`**: Declares which superpowers skills this template complements. Prevents conflicts — if superpowers:systematic-debugging is about to inject debugging guidance, cortex's debugging template adds complementary context, not competing context.
- **`anti_patterns` + `min_confidence`**: Prevents Clippy behavior. Silence when uncertain.

---

## Layer 1: The Whisper — Detailed Design

### Pipeline

```
User types prompt
       |
       v
[Gate Check: Leave-It-Alone Detector]
  |  Scoring: max-of-top-2 → max(top_1, top_2 * 0.5)
  |
  |  Slash command prefix (/cmd)?            → score = 1.0 (override)
  |  --raw flag or /cx off?                  → score = 1.0 (override)
  |  Already has XML tags?                   → 0.50
  |  Looks like a command (git, npm, etc)?   → 0.60
  |  Continuation prompt (ok, also, wait,    → 0.45
  |    yes, sure, go ahead, do it, looks
  |    good, that works, next)?
  |  Already has role assignment?             → 0.40
  |  Same template injected in last 3 turns? → 0.40 (multi-turn suppression)
  |  Conceptual question (what is, how does,  → 0.30
  |    explain, why)?
  |  Already has numbered list?              → 0.15
  |  Already specifies output format?        → 0.10
  |  >80 words AND >=2 structural markers?   → 0.45 (composite signal)
  |
  |  Score >= 0.60 → LEAVE ALONE, exit
  |  Score clamped to [0.0, 1.0]
  |
       v
[Fast Match: 3-Phase Algorithm]
  |  Phase 1: Keyword extraction + inverted index lookup (<5ms)
  |           Extract words + bigrams, look up in pre-built index
  |  Phase 2: Regex signal boost/penalty on candidates (<20ms)
  |           Run intent_signals for boost, negative_signals for kill
  |  Phase 3: Context filter (<5ms)
  |           Check requires.language, requires.framework against project
  |
       v
[Inject or Defer]
  |  confidence >= 0.70 → Inject best template as additionalContext (max 300 tokens)
  |  confidence 0.40-0.69 → Write candidates to state, inject Layer 2 hint
  |  confidence < 0.40  → Do nothing. Silence is a feature.
```

### Template Scoring Weights

When multiple templates are candidates, scoring determines the best match:

| Signal | Weight | Notes |
|---|---|---|
| Primary action match (exact) | +0.45 | User's first detected action matches template's `action` |
| Primary action match (secondary) | +0.20 | Template's action appears in user's action list but not first |
| Primary object match (exact) | +0.35 | User's first detected object matches template's `object` |
| Primary object match (secondary) | +0.15 | Template's object appears but not as primary |
| Secondary action overlap | +0.05 each (max 0.10) | Cross-match against template's secondary actions |
| Secondary object overlap | +0.05 each (max 0.10) | Cross-match against template's secondary objects |
| Keyword overlap | +0.02 each (max 0.08) | Raw word overlap between input and template's `triggers` |
| Project context affinity | +0.05 | Project type matches template's `project_affinity` |
| Complexity mismatch penalty | -0.15 | Short input (<6 words) vs high `min_complexity` template |

**Thresholds**: A clean action + object match scores 0.80 (0.45 + 0.35). Per-template `min_confidence` can override the global threshold upward only. Max 3 matches returned. Redundant matches (same action + object) are deduplicated.

### Implementation: Bash + jq (No Python/Node startup cost)

```bash
#!/bin/bash
# hooks/scripts/cortex-match.sh
set -euo pipefail

input=$(cat)
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

if [ -z "$user_prompt" ]; then
  echo '{}'
  exit 0
fi

INDEX="${CLAUDE_PLUGIN_ROOT}/data/index.json"
SESSION_ID=$(echo "$input" | jq -r '.session_id // "default"')
STATE="${CLAUDE_PROJECT_DIR:-.}/.cortex/state-${SESSION_ID}.json"

# Fast match via jq (pure bash+jq, no external runtime)
result=$(jq -f "${CLAUDE_PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "$user_prompt" \
  --slurpfile state "$STATE" \
  "$INDEX")

confidence=$(echo "$result" | jq -r '.confidence // 0')
template_id=$(echo "$result" | jq -r '.best_match.id // ""')

if [ -z "$template_id" ]; then
  echo '{}'
  exit 0
fi

if [ "$(echo "$confidence" | jq '. >= 0.70')" = "true" ]; then
  # High confidence: inject template
  template_content=$(sed -n '/^---$/,/^---$/!p' \
    "${CLAUDE_PLUGIN_ROOT}/data/prompts/${template_id}.md" | tail -n +1)

  # Update shared state
  echo "$result" > "$STATE"

  # Inject as additionalContext (wrapped in tags for debug mode)
  jq -n --arg ctx "<prompt-cortex match=\"${template_id}\" confidence=\"${confidence}\">
${template_content}
</prompt-cortex>" '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $ctx
    }
  }'
else
  # Low confidence: defer to Layer 2
  echo "$result" > "$STATE"

  jq -n '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "prompt-cortex detected patterns relevant to this request but needs deeper analysis. Use /cortex:optimize for full prompt engineering."
    }
  }'
fi
```

### Why Not LLM Classification in Layer 1?

- Hook fires on **every single prompt**. 50 prompts/session = 50 LLM calls just for matching.
- Keyword + regex matching completes in <100ms, costs zero tokens, works offline.
- Deterministic and debuggable — same input always produces same output.
- The agent (Layer 2) handles the nuanced 10% that keywords miss.
- v1.0 is pure bash+jq with no external runtime dependencies. If profiling shows jq is a bottleneck in v1.1+, an optional compiled accelerator can be introduced.

---

## Layer 2: The Brain — Detailed Design

### Meta-Prompt System

The Layer 2 agent receives a structured payload and applies optimization. Core system instruction:

```
You are the prompt optimization core for prompt-cortex. Your job is to take a raw
user input and transform it into a prompt that elicits better work from Claude.

## Your Input Payload

- RAW_INPUT: The user's original text
- MATCHED_TEMPLATES: 0-3 template objects from the library
- CONTEXT_SIGNALS: Project type, recent files, CLAUDE.md summary, git branch
- ENHANCEMENT_BUDGET: "minimal" | "standard" | "full"
- LEAVE_ALONE_SCORE: Float 0.0-1.0 (if >= 0.60, return original unchanged)

## The Six Techniques (apply minimum needed, rarely >2 user-facing, up to 3 chain steps)

1. Chain-of-Thought: Add when task requires analysis, comparison, or multi-step reasoning.
   Before: "Is this function safe?"
   After: "Analyze this function's safety. Think through: input validation, error paths, resource leaks, concurrency issues. State your conclusion after reasoning through each."

2. XML Structuring: Add when prompt has multiple distinct inputs or output sections.
   Before: "Review my code and check for security issues and also suggest tests"
   After: "<task>Review code</task><focus>security</focus><also>suggest unit tests</also>"

3. Example Enrichment: Add when user's prompt is ambiguous about format or depth.
   Before: "Write a commit message"
   After: "Write a commit message. Example: 'fix(auth): resolve token refresh race condition in concurrent sessions'"

4. Structural Rewriting: Add when raw input is a run-on sentence mixing multiple requests.
   Before: "fix the bug and then add tests and also update the docs and deploy"
   After: "1. Fix the bug (identify root cause first) 2. Add tests covering the fix 3. Update relevant docs 4. Prepare for deployment"

5. Prefill Addition (Layer 2 only): Add when output format is predictable (JSON, markdown, code blocks). Not available in Layer 1 (hooks cannot prefill responses).
   Before: "Generate a JSON config"
   After: [prefill: "```json\n{"] — forces structured output from first token

6. Length Anchoring: Add when response length expectations are implicit but important.
   Before: "Explain React hooks"
   After: "Explain React hooks in 2-3 paragraphs, focusing on useState and useEffect with one example each."

## Composition Rule (when multiple templates match)

1. Take highest-confidence template as base (must be composition_role: primary)
2. If two primaries match, demote the lower-confidence one to modifier role
3. Lead with persona/role framing from the primary template
4. Extract unique role/persona elements from modifiers — merge, never stack competing personas. If personas conflict, the primary's persona wins.
5. Extract unique output requirements from modifiers, append as constraints
6. If a wrapper template is present, wrap the composed result
7. Remove contradictions (defer to primary template on conflicts)
8. Result must read as one coherent prompt, not a concatenation

## What You Must Never Do

- Do not change the user's intent. Enhance clarity, not direction.
- Do not add requirements the user did not imply.
- Do not make the prompt longer than necessary. Every word earns its place.
- Do not apply a technique just because you can. Apply because the prompt needs it.
```

### 7-Stage Enhancement Pipeline

```
Raw Input
    |
    v
[Stage 1: Gate Check]
    |  Compute LEAVE_ALONE_SCORE (max-of-top-2 scoring)
    |  If >= 0.60 → emit raw input unchanged, exit
    |
    v
[Stage 2: Intent Extraction]
    |  Extract action[], object[], modifiers[]
    |  Compute word_count, question_type
    |
    v
[Stage 3: Context Loading]
    |  Read CLAUDE.md → extract quality_standards, project_type
    |  Check recent files → infer language, framework
    |  Check git branch → infer task type (feature/bugfix/hotfix)
    |
    v
[Stage 4: Template Matching]
    |  Score all templates against intent + context
    |  Resolve: single match / multi-match / no match
    |  Read shared state (skip if Layer 1 already matched)
    |  Note: Layer 1 performs its own fast matching. If Layer 1 already
    |  injected a template, Stage 4 reads state and skips re-matching.
    |
    v
[Stage 5: Composition + Context Weaving]
    |  No match → generic enhancement (techniques only)
    |  Single match → slot-fill template with context
    |  Multi-match → composition engine (primary + modifiers + wrapper)
    |  Weave in project language, standards, specific file references
    |
    v
[Stage 6: Technique Application]
    |  Missing CoT? → add if analytical task
    |  Flat structure? → structural rewrite if 3+ requirements
    |  Ambiguous format? → add prefill (Layer 2 only)
    |  Missing examples? → add if non-obvious format
    |  Mixed data/instructions? → XML wrap
    |  Implicit length? → add length anchor
    |  Apply minimum needed, rarely >2 user-facing
    |
    v
[Stage 7: Quality Check]
    |  Length: enhanced < 2.5x original word count?
    |  Intent: preserved? (keyword overlap check)
    |  No hallucinated requirements?
    |  Coherence: composed output reads as one voice, no contradictions?
    |  If any fail → trim or revert to Stage 5 output
    |
    v
Enhanced Output
```

### Concrete Example

**Input**: "help me debug why the auth isn't working"

**Stage 1**: Leave-alone score = 0.22 (vague, short, no structure). Proceed.

**Stage 2**: actions=["debug"], objects=["auth"], word_count=9

**Stage 3**: TypeScript project, recent files: `auth.middleware.ts`, `jwt.service.ts`. CLAUDE.md: "production-grade error handling"

**Stage 4**: Top match: Debug Error template (#2, confidence 0.71)

**Stage 6**: Apply CoT (debugging is analytical) + XML structuring (separate files from task)

**Output**:
```xml
<task>
Debug why authentication is failing in this TypeScript project.
Work through the problem systematically.

Investigation steps:
1. Trace the request path from entry point through auth middleware to JWT verification
2. Identify where the failure occurs: missing token, invalid signature, expired token,
   wrong secret, or middleware logic error
3. Check for environment-specific issues (env vars, config loading order)
4. State the root cause precisely before suggesting a fix
</task>

<files-to-examine>
- auth.middleware.ts
- jwt.service.ts
</files-to-examine>

Think through each step before concluding. Show your reasoning at each stage.
```

### Multi-Template Composition Example

**Input**: "review my code and write tests"

**Matched templates**:
1. Code Review (#1, confidence 0.78) — primary
2. Write Unit Tests (#4, confidence 0.61) — modifier, declared composable_with #1

**Composed output**:
```
Review the provided code with the eye of a senior engineer preparing it for production.

Evaluate:
1. Logic correctness and edge cases
2. Error handling completeness
3. Naming clarity and code organization
4. Performance considerations
5. Security implications

For each issue found, specify: location, severity (critical/major/minor), and concrete fix.

Additionally:
- After the review, write comprehensive unit tests for the reviewed code
- Cover happy path, edge cases, null inputs, and error conditions
- Name tests as documentation (describe what, not how)
```

---

## Wow Feature #1: `/cortex:chain` — Prompt Decomposition

When a user types something complex, cortex decomposes it into a multi-step prompt sequence where each step gets the optimal template applied.

User types: "Build a real-time notification system with WebSocket fallback to SSE, persistent storage, read receipts, and delivery guarantees"

Cortex decomposes:

```
Analyzing your request... Detected 6 sub-problems.

Step 1: Architecture Decision (template: architecture-decision)
  → "Design the high-level architecture for a notification system.
     Consider: WebSocket vs SSE vs hybrid, message broker selection,
     storage strategy. Present 2-3 options with trade-offs."

Step 2: Data Model (template: data-modeling)
  → "Design the data model for notifications with: read receipts,
     delivery status tracking, user preferences. Show schema and
     key queries."

Step 3: WebSocket Layer (template: implementation-focused)
  → "Implement the WebSocket connection manager with: reconnection
     logic, heartbeat, graceful fallback to SSE."

Step 4: Delivery Guarantees (template: distributed-systems)
  → "Implement at-least-once delivery with: outbox pattern,
     idempotency keys, retry with exponential backoff."

Step 5: Read Receipts (template: implementation-focused)
  → "Add read receipt tracking: batch updates, optimistic UI,
     conflict resolution for multi-device."

Step 6: Integration Tests (template: integration-testing)
  → "Wire all components together. Write integration tests for:
     connection lifecycle, message delivery, fallback scenarios,
     read receipt sync."

Run this chain? [Y/n] Or edit any step.
```

Each step gets the optimal template applied. Output of step N feeds step N+1. This turns a single vague prompt into a structured implementation plan where each step is optimally prompted.

**Why this is tweet-worthy**: The user sees their fuzzy idea decomposed into a crisp execution plan. The gap between what they typed and what they needed becomes visible. That gap is the value proposition in a screenshot.

---

## Wow Feature #2: Adaptive Prompt Memory

Over time, cortex tracks what works for each user through implicit behavioral signals:

### Quality Signals — Feasibility Assessment

| Signal | Meaning | v1.0 Feasible? | Notes |
|---|---|---|---|
| `/cortex:feedback good/bad` | Explicit user signal | Yes | Only reliable signal in v1.0 |
| Correction language in next prompt ("no", "wrong", "actually") | Negative — template missed | v1.2+ | Requires prompt content analysis |
| Timestamp delta (prompt → next prompt < 30s) | Confusion signal | v1.2+ | Requires timestamp tracking in hooks |
| Same template rejected 2+ times in session | Strong negative | v1.2+ | Requires rejection tracking across prompts |
| User accepted output, no follow-up corrections | Positive — template worked | Not feasible | Hooks cannot observe Claude's response or user's next action |
| User cleared prompt and retyped | Strong negative | Not feasible | Hooks cannot detect prompt clearing |
| Task completed without clarification | Strong positive | Not feasible | No completion detection in hook model |

### Personal Mutations

Feedback accumulates into thin override layers on base templates:

```yaml
# Auto-generated: coding-001-personal.md
---
parent: coding-001
mutation_type: constraint_addition
---
<personal_constraints>
- Always check for proper TypeScript strict null handling
- Prefer functional patterns over class-based when suggesting fixes
- When reviewing Go code, prefer mutex over channels unless data flow is naturally stream-shaped
</personal_constraints>
```

These personal mutations layer on top of base templates. Upstream improvements to the base template still apply — the mutation only overrides specific constraints.

### The Flywheel (Aspirational — v1.2+)

```
User types naturally
  → Hook injects template
    → Claude responds better
      → User provides explicit feedback (/cortex:feedback) or implicit signals
        → Feedback updates template scores
          → Personal mutations accumulate
            → Next injection is even better
              → User types naturally (with higher baseline quality)
```

This is the DSPy philosophy as a north star. v1.0 relies on explicit `/cortex:feedback good/bad` signals. Implicit behavioral signals require hook capabilities not available until v1.2+. The full flywheel is aspirational — it becomes real when the signal pipeline matures.

**Mutation commitment threshold**: A personal mutation is only persisted after 3+ negative signals in 10 uses of a template (constraint addition) or 10+ positive signals (technique promotion). This prevents noisy single-session feedback from corrupting base templates.

### Usage Telemetry (Local Only)

Every injection is logged to `.cortex/usage.jsonl`. No prompt content is stored — only hashes, template IDs, confidence scores, and timestamps. Fully local, no network transmission.

```jsonl
{"ts":"2026-03-25T14:22:01Z","prompt_hash":"a1b2c3","matched":["coding-001"],"confidence":0.87,"injected":"coding-001","disposition":"injected","project":"easygreen-transport-pwa"}
{"ts":"2026-03-25T14:25:33Z","prompt_hash":"d4e5f6","matched":[],"confidence":0,"injected":null,"disposition":"below_threshold","project":"easygreen-transport-pwa"}
{"ts":"2026-03-25T14:30:12Z","prompt_hash":"g7h8i9","matched":["coding-012"],"confidence":0.65,"injected":null,"disposition":"deferred","project":"easygreen-transport-pwa"}
{"ts":"2026-03-25T14:31:05Z","prompt_hash":"j0k1l2","matched":[],"confidence":0,"injected":null,"disposition":"suppressed","project":"easygreen-transport-pwa"}
{"ts":"2026-03-25T14:32:00Z","prompt_hash":"m3n4o5","matched":[],"confidence":0,"injected":null,"disposition":"user_escaped","project":"easygreen-transport-pwa"}
```

**Disposition values**: `injected` (template added as additionalContext), `deferred` (candidates written to state, Layer 2 hint injected), `suppressed` (leave-alone detector fired), `user_escaped` (`--raw` or `/cx off`), `below_threshold` (no match above 0.40).

**What the telemetry enables:**

| Analysis | Signal |
|---|---|
| Dead template detection | Templates that never match → refine triggers or remove |
| Signal tuning | "error" matches debugging but "issue" doesn't → expand triggers |
| Project profiling | Project triggers architecture 80% of the time → pre-boost category |
| Confidence calibration | Template matches at 0.6, user immediately rephrases → decay weight |
| Template ranking | Aggregate `effectiveness_score` updates from quality signals |

The `/cortex:stats` command surfaces this data:
- Most-used templates (top 10)
- Average confidence per category
- Enhancement rejection rate
- Project-specific template affinity

---

## Extension Model

### User-Authored Templates

```bash
/cortex:add "When I ask to optimize database queries, first EXPLAIN the query plan,
then suggest index changes, then rewrite the query"
```

The agent converts natural language into a proper `.md` template with full frontmatter, saves to `~/.cortex/custom/`, and rebuilds the index. Zero manual YAML editing.

### Template Packs

Domain-specific packs that auto-detect project type:

```json
// packs/react/pack.json
{
  "name": "react",
  "description": "Prompt templates for React development",
  "version": "1.0.0",
  "signals_boost": ["react", "component", "hook", "useState", "jsx", "tsx"],
  "auto_detect": ["package.json contains 'react'"],
  "auto_enable": true
}
```

A React project automatically gets React prompt templates boosted. Installed packs:
- `react/` — component design, state management, performance
- `devops/` — CI/CD, infrastructure, incident response
- `python/` — data science, Django, FastAPI patterns

### Team-Shared Templates

Teams create `.cortex/` in their repo:

```
project-root/
  .cortex/
    project.json         # Project config, preset selection
    custom/
      our-api-style.md   # Team's API design template
      our-testing.md     # Team's testing philosophy
```

### Presets

Named configurations for different work modes:

```json
{
  "presets": {
    "greenfield": {
      "boost": ["architecture", "data-modeling", "api-design"],
      "suppress": ["legacy", "migration"]
    },
    "maintenance": {
      "boost": ["debugging", "refactoring", "performance"],
      "suppress": ["architecture"]
    },
    "strict": {
      "boost": ["security", "testing", "error-handling"],
      "inject_always": ["security-checklist"]
    }
  }
}
```

Activate via `/cortex:preset maintenance` or auto-detect from git history.

### Project-Level Overrides

`.cortex/project.json` in any project can:
- Disable specific templates
- Set default techniques
- Override context requirements
- Pin template versions
- Read CLAUDE.md conventions to auto-configure

```json
{
  "disabled": ["coding-015"],
  "defaults": {
    "techniques": ["xml_structuring", "chain_of_thought"],
    "quality_tier_minimum": "silver"
  },
  "overrides": {
    "coding-012": {
      "requires": { "language": ["typescript"] }
    }
  }
}
```

### CLAUDE.md Integration

**v1.0**: Manual configuration via `.cortex/project.json`. Users declare their tech stack, testing philosophy, and quality standards directly. This is the reliable path — no parsing ambiguity.

**v1.1**: `/cortex:suggest` scans CLAUDE.md using an LLM call (Layer 2 agent) and proposes boost/suppress rules. User reviews and accepts. Semi-automatic.

**v2.0**: Automatic CLAUDE.md parsing. SessionStart hook extracts conventions and writes boost/suppress rules to state automatically. Deferred because reliable bash-based parsing of free-form CLAUDE.md is infeasible — LLM classification is needed but too expensive for SessionStart.

| Extracted Signal | How It's Used | Available |
|---|---|---|
| Tech stack (language, framework) | Filter templates by `requires.language` / `requires.framework` | v1.0 (manual) |
| Testing philosophy ("we use TDD") | Boost testing templates, suppress quick-fix templates | v1.1 (`/cortex:suggest`) |
| Code style ("functional over class-based") | Feed into personal mutations as project-level constraints | v1.1 |
| Quality standards ("production-grade") | Boost security, error-handling, testing templates | v1.1 |
| Platform constraints ("jQuery 1.11, no Promises") | Activate legacy-JS templates, suppress modern-JS | v1.1 |

```json
// .cortex/project.json — v1.0 manual configuration
{
  "tech_stack": { "language": "typescript", "framework": "nextjs" },
  "boost": ["coding", "testing"],
  "suppress": ["legacy"]
}
```

---

## Anti-Clippy Guarantees

All 4 design council agents independently flagged this risk. The safeguards:

| Rule | Implementation |
|---|---|
| Silence is default | confidence < 0.40 = inject nothing |
| Token budget | Max 300 tokens per injection, 400 for multi-template |
| Speed guarantee | < 2 second latency, no LLM calls in Layer 1 |
| Leave-it-alone | Recognizes well-structured prompts, commands, continuations |
| Escape hatch | `--raw` prefix or `/cx off` for explicit opt-out |
| Invisible Layer 1 | No "I enhanced your prompt!" messages. `/cortex:debug` for transparency |
| Never rewrites | Layer 1 only injects alongside, never replaces. Rewriting = Layer 2, explicit only |

### Escape Mechanisms

Users can opt out of enhancement at multiple levels:

| Mechanism | Scope | Behavior |
|---|---|---|
| `/cx off` | Remainder of session | **Primary escape.** Sets `cortex_disabled: true` in state. Hook checks state and skips all matching until session ends or `/cx on`. Clean, session-level. |
| `--raw` prefix | Single prompt | Hook detects prefix, returns empty `{}` (no injection). Prefix passes through to Claude harmlessly (cannot be stripped by hooks). Logged with disposition `user_escaped`. |
| `/cortex:preset off` | Project-level | Disables all injection for this project via `.cortex/project.json`. |
| `"disabled": ["*"]` | Project config | Wildcards disable all templates in project config. |

When `--raw` is used, the hook:
1. Detects the prefix via regex `^--raw\s+`
2. Returns empty `{}` (no additionalContext injection). The prefix cannot be stripped — hooks have no prompt mutation capability (see ADR-002). The `--raw` text passes through to Claude harmlessly.
3. Logs the rejection signal (disposition: `user_escaped`) to `.cortex/usage.jsonl`
4. If 2+ rejections in last 10 prompts, the leave-alone detector increases its base score by 0.10 per rejection (max +0.25)

**Recommended escape**: Use `/cx off` for clean session-level suppression. `--raw` is a per-prompt fallback when you want a single prompt unenhanced.

### First-Session Onboarding

Invisible tools that never show value get uninstalled. To avoid this:

- **First injection**: On the very first successful template injection in a session, surface a one-time systemMessage: `[cortex] Applied template coding-001 (0.87 confidence). Use /cortex:debug to see details.`
- **After first injection**: Stay fully invisible. The user now knows cortex is working.
- **Post-session**: If 3+ injections occurred, log to terminal at session end: `[cortex] Enhanced 3 prompts this session. Run /cortex:stats for details.`
- **Never repeat**: The first-injection disclosure fires once per install, not once per session.

### What Would Make Users Uninstall

1. Noticeable latency on every prompt (even 500ms feels wrong)
2. Irrelevant injections that confuse the model
3. Conflicting with superpowers or other installed plugins
4. Over-injection that eats context window on long conversations
5. Breaking simple prompts ("list files in src/" should NOT get architectural guidance)
6. Never noticing the tool is there (invisible value = zero retention)

---

## Plugin Directory Structure

```
prompt-cortex/
  .claude-plugin/
    plugin.json                    # Plugin manifest
  hooks/
    hooks.json                     # Hook registrations
    scripts/
      cortex-match.sh              # Layer 1: UserPromptSubmit fast matcher
      cortex-session-init.sh       # SessionStart: project detection + index build
  commands/
    optimize.md                    # /cortex:optimize — deep prompt optimization
    chain.md                       # /cortex:chain — prompt decomposition
    debug.md                       # /cortex:debug — show what Layer 1 would inject
    list.md                        # /cortex:list — browse available templates
    add.md                         # /cortex:add — create template from natural language
    eval.md                        # /cortex:eval — evaluate template effectiveness
    stats.md                       # /cortex:stats — usage analytics
    preset.md                      # /cortex:preset — switch work mode
    suggest.md                     # /cortex:suggest — suggest templates based on project context
    feedback.md                    # /cortex:feedback good/bad — explicit quality signal
    tune.md                        # /cortex:tune — interactive calibration per project
    sync.md                        # /cortex:sync — rebuild index after adding templates
  agents/
    prompt-composer.md             # Layer 2: deep optimization agent
    chain-decomposer.md           # Chain decomposition agent
  skills/
    compose/
      SKILL.md                     # Skill(prompt-cortex:compose) — deep composition
      references/
        optimization-techniques.md # The 6 techniques + DSPy philosophy
        composition-patterns.md    # How templates combine
    library/
      SKILL.md                     # Skill(prompt-cortex:library) — browse/search
      references/
        category-guide.md          # Guide to all 6 categories
  data/
    index.json                     # Pre-computed inverted index (versioned via SHA-256 of template mtimes)
    intents.json                   # Intent taxonomy (closed set)
    prompts/                       # The 300 template files (named {id}.md)
      coding/
        coding-001.md
        coding-002.md
        coding-003.md
        ...                        # 50 files
      ai-workflows/
        ai-051.md
        ...                        # 50 files
      research/
        research-101.md
        ...                        # 50 files
      automation/
        auto-151.md
        ...                        # 50 files
      content/
        content-201.md
        ...                        # 50 files
      productivity/
        prod-251.md
        ...                        # 50 files
  packs/                           # Domain template packs (v1.1+)
    react/
      pack.json
    devops/
      pack.json
  scripts/
    match.jq                       # Core matching logic (pure jq, no external runtime)
    build-index.sh                 # Recompiles index.json from all templates
    validate-template.sh           # Validates template frontmatter schema
    eval-runner.sh                 # Runs evals against templates
  README.md
```

### hooks.json

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/cortex-session-init.sh",
            "timeout": 15
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/cortex-match.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### plugin.json

```json
{
  "name": "prompt-cortex",
  "version": "1.0.0",
  "description": "Invisible prompt intelligence layer for Claude Code. Matches user input against 300 proven prompt patterns and silently injects optimal framing.",
  "author": {
    "name": "Daniel Hjermitslev",
    "url": "https://github.com/dnh33"
  },
  "repository": "https://github.com/dnh33/prompt-cortex",
  "license": "MIT",
  "keywords": ["prompts", "optimization", "prompt-engineering", "intelligence", "library"]
}
```

---

## The 300-Prompt Library

### Source

All 300 prompts sourced from @cyrilXBT's comprehensive prompt collection (https://x.com/cyrilXBT/status/2036280031782060364), adapted with rich YAML frontmatter, optimized template bodies, and composition metadata for the prompt-cortex intelligence layer.

### Categories

| Category | Range | Count | Description |
|---|---|---|---|
| Coding & Debugging | 1-50 | 50 | Code review, debugging, testing, refactoring, architecture |
| AI Workflows | 51-100 | 50 | Agent design, RAG, classification, prompt chains, evaluation |
| Research & Analysis | 101-150 | 50 | Market analysis, competitive intel, frameworks, decision-making |
| Automation | 151-200 | 50 | Process automation, pipelines, monitoring, integrations |
| Content Creation | 201-250 | 50 | Writing, social media, marketing, documentation |
| Productivity Systems | 251-300 | 50 | Planning, goal-setting, team systems, knowledge management |

### Quality Tiers

- **Gold** (top ~50): Highest effectiveness scores, most broadly applicable, ship in v1.0. Gold templates must: lead with persona/role framing, include a conditional for missing input (e.g., "If no code is provided, ask for it"), provide 1-2 few-shot examples in the template body, and target 150-200 tokens.
- **Silver** (~100): Strong templates, ship in v1.1
- **Bronze** (~150): Specialized/niche, ship in v1.1

### Minimum Viable Template (for contributors)

Community contributors only need 8 required fields. Everything else gets defaults or is computed at index-build time:

```yaml
---
id: coding-050                    # Required: unique ID
name: "Load Testing Script"       # Required: human-readable name
category: coding                  # Required: one of the 6 categories
intent: create-load-test          # Required: canonical intent
action: create                    # Required: from action space
object: test                      # Required: from object space
triggers:                         # Required: at least 3 keywords/phrases
  - "load test"
  - "stress test"
  - "performance test"
---

Template body here...
```

All other fields (`intent_signals`, `negative_signals`, `composable_with`, `composition_role`, `quality_tier`, `token_overhead`, `effectiveness_score`, `techniques_used`, `min_confidence`, `anti_patterns`, etc.) default to sensible values or are computed by `scripts/build-index.sh`. The `scripts/validate-template.sh` script shows exactly which required fields are missing with human-readable errors.

A `CONTRIBUTING.md` ships with the repo containing this template stub and contribution guidelines.

---

## Phased Roadmap

### v1.0 — "The Library That Injects Itself" (Ship Fast)

- 50 gold-tier templates (highest-impact: coding + debugging + AI workflows)
- Layer 1 hook with keyword matching + leave-it-alone detector
- Pre-computed index at SessionStart
- **3 commands only**: `/cortex:debug`, `/cortex:list`, `/cortex:sync`
- Project context detection (language, framework)
- `--raw` and `/cx off` escape mechanisms (context window protection from day one)
- First-session onboarding disclosure (one-time)
- SessionStart health-check for platform bug #10225
- Zero configuration required — works out of the box

**Success metric**: Users notice better first-pass responses AND know cortex is responsible (via first-session disclosure).

### v1.1 — "Full Library + Composition"

- All 300 templates with regex signal matching
- Layer 2 agent — `Skill(prompt-cortex:compose)` and `/cortex:optimize`
- Multi-template composition (primary + modifiers + wrapper)
- `/cortex:add` — create templates from natural language
- `/cortex:suggest` — recommend templates based on project context (merges into `/cortex:list --for-project`)
- Template packs with auto-detection (React, DevOps, Python)
- Custom templates in `.cortex/custom/`
- CLAUDE.md integration via `/cortex:suggest` (LLM-powered, not bash)

**Success metric**: Users actively configure and create custom templates.

### v1.2 — "Intelligence"

- `/cortex:chain` — prompt decomposition into multi-step sequences (with low-confidence fallback: "this may not need a chain")
- `/cortex:eval` — evaluate template effectiveness + interactive tuning (merges tune functionality)
- `/cortex:stats` — usage analytics with `.cortex/usage.jsonl`
- `/cortex:feedback good/bad` — explicit quality signal
- Feedback loop — feasible implicit signals (correction language, timestamp delta)
- Personal mutations — auto-generated preference overrides (with privacy disclosure)
- Presets (greenfield, maintenance, strict)

**Note**: Do not market `/cortex:chain` as the launch feature. Market v1.0 on the library and invisible enhancement. Market v1.2 on chain when it has been tested on messy real-world inputs.

**Success metric**: The tweet happens. Users share their chain decompositions.

### v2.0 — "Platform"

- Community template marketplace — publish and install packs
- Team sharing — export/import prompt libraries
- Prompt API — other plugins call cortex for domain-specific templates
- Semantic matching — embedding-based similarity (local model, no cloud)
- Conversation awareness — boost templates based on multi-turn context
- `/cortex:learn` — watches successful conversations, extracts patterns as templates
- Template A/B testing — inject variant A or B, track which performs better

**Success metric**: Other plugin authors integrate with cortex. It becomes assumed infrastructure.

---

## Architectural Decision Records

### ADR-001: Keyword Matching Over LLM Classification in Layer 1

**Decision**: Use weighted keyword + regex matching. No LLM calls in Layer 1.

**Rationale**: Hook fires on every prompt. 50 prompts/session = 50 LLM calls just for matching. Keyword + regex completes in <100ms, costs zero tokens, works offline, is deterministic and debuggable. The agent handles the 10% that keywords miss.

### ADR-002: Injection Over Rewriting

**Decision**: Layer 1 always injects context alongside the user's prompt. Original prompt is never modified. Hooks cannot mutate prompt text — they can only add `additionalContext`.

**Rationale**: No risk of destroying user intent. Transparent — model sees both. Users trust it because their words are preserved. Rewriting only in Layer 2 with explicit consent. This also means escape mechanisms (e.g., `--raw`) cannot strip prefixes — they return empty `{}` and the prefix passes through harmlessly.

### ADR-003: Local-Only Telemetry

**Decision**: All telemetry stays local in `.cortex/usage.jsonl`. No prompt content stored — only hashes, template IDs, confidence scores.

**Rationale**: Zero privacy concerns. No infrastructure. No GDPR. Users can inspect/modify/delete anytime. Community signal comes from GitHub stars/PRs instead of aggregate telemetry.

### ADR-004: Confidence Threshold at 0.70

**Decision**: Only inject when confidence >= 0.70 for single template match. Recalibrated weights (action=0.45, object=0.35) mean a clean action+object match scores 0.80, comfortably above threshold.

**Rationale**: False positives are worse than false negatives. Injecting the wrong template makes Claude worse, not better. The 0.70 threshold balances precision (0.80 was too conservative — useful matches at 0.72 were silently dropped) with safety (0.60 would inject on partial matches). Per-template `min_confidence` can override this upward only.

### ADR-005: Max Composition Budget

**Decision**: Max 1 primary + 2 modifiers + 1 wrapper per composition.

**Rationale**: More than 4 composed templates creates bloated, contradictory instructions. The wrapper limit (1) prevents nesting nightmares. Keep compositions tight and coherent.

**Enforcement**: The match engine enforces this ceiling at runtime — if more than 4 templates match, excess modifiers are dropped by lowest confidence. The meta-prompt's composition rule also enforces this: "If more than 2 modifiers match, keep only the 2 with highest confidence."

---

## Growth Strategy

### Distribution Hook

The 300-prompt library itself is the distribution mechanism. awesome-cursorrules proved that a well-organized prompt library gets 38.7K stars. prompt-cortex ships with that AND makes it intelligent.

### Content Strategy

Every feature is a content moment:
- Launch: "300 expert prompts that inject themselves into your Claude Code workflow"
- `/cortex:chain`: "Watch prompt-cortex decompose a single sentence into 6 perfectly-prompted steps"
- Personal mutations: "Your AI coding assistant just learned how YOU prefer code reviews"

### Community Flywheel

1. Users install for the library (passive value)
2. Power users create custom templates via `/cortex:add`
3. Best custom templates get shared as PRs
4. Library grows → more users install → more contributions

### Early Marketplace Placement

Get listed on Claude Code's official plugin marketplace early. Curation is by install count, stars, and community votes. Being first in the "prompt optimization" category = structural advantage.
