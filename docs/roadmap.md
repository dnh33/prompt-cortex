# prompt-cortex Roadmap

Future features and improvements. Items marked with priority.

## v1.1 — Control & Transparency (SHIPPED)

All v1.1 features implemented on 2026-03-26.

- [x] **Tier filtering** — `/cortex:tier gold|silver|all`, persists in `.cortex/config.json`, filters in match.jq
- [x] **`/cortex:show`** — Display the actual injected template body
- [x] **`/cortex:transparent`** — Toggle mode showing `[cortex: applied X @ Y]` after each injection
- [x] **Intent signal fix** — Removed double-escaping of backslashes in build-index.sh YAML parser
- [x] **Reject-signal boosting** — 2+ `--raw` in recent prompts boosts leave-alone score (max +0.25)
- [x] **Token budget enforcement** — 300 token ceiling, truncate at sentence boundary
- [x] **Synonym expansion** — action/object synonyms from intents.json boost matching
- [x] **`/cortex:feedback good|bad`** — Explicit quality signal logged to usage.jsonl
- [x] **`/cortex:stats`** — Usage analytics from local telemetry
- [x] **`/cortex:add`** — Create template from natural language, save to category dir, rebuild index

**Deferred to v1.2:** `/cortex:suggest` (CLAUDE.md integration) — requires LLM calls, violates "no LLM in Layer 1" constraint.

## v1.2 — Context Awareness

### `/cortex:suggest` — CLAUDE.md integration
Scan CLAUDE.md using LLM call, propose boost/suppress rules for templates based on project conventions. User reviews and accepts. (Deferred from v1.1 — requires LLM calls.)

### Project context filtering (Phase 3 in match.jq)
Use detected language/framework from SessionStart to filter templates. TypeScript projects boost TS-relevant templates, Python projects suppress JS-specific ones.

### `.cortex/project.json` configuration
Manual config for tech stack, boost/suppress rules, quality tier minimum.

## v2.0 — The Brain (Layer 2)

### `/cortex:optimize` — Deep prompt optimization
On-demand agent that composes multi-template prompts, applies Anthropic's 6 techniques, handles complex requests that Layer 1 can't match with single templates.

### `/cortex:chain` — Prompt decomposition
Decomposes complex requests into prompt chains. The "wow feature" from the original spec.

### Automatic CLAUDE.md parsing
SessionStart hook extracts conventions from CLAUDE.md and writes boost/suppress rules automatically. Requires LLM classification.

### Adaptive Prompt Memory
Cross-session learning: track which templates produce good results (via user feedback signals) and adjust confidence scores over time.
