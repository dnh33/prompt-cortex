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

## v1.2 — Context Awareness (SHIPPED)

All v1.2 features implemented on 2026-03-27. Full spec: `docs/superpowers/specs/2026-03-26-v1.2-context-awareness-design.md`

### 14 Features, 4 Pillars

**Pillar 1 — Smarter Matching:**
- [x] F1: Phase 3 context filter — language/framework/affinity filtering in match.jq
- [x] F2: Template schema upgrade — `requires`, `project_affinity`, `min_complexity` on all 350 templates
- [x] F3: Enhanced tech detection — monorepo, testing frameworks, linters, package managers, git branch type
- [x] F9: Complexity scoring — classify prompt complexity (trivial→expert), suppress mismatched templates
- [x] F10: Domain synonyms — intents.json v2 with context-sensitive synonyms and domain mapping

**Pillar 2 — Context Intelligence:**
- [x] F6: `/cortex:suggest` — LLM scans CLAUDE.md, proposes boost/suppress rules, user reviews, results cached
- [x] F12.5: CLAUDE.md staleness detection — hash comparison at SessionStart
- [x] F13: CwdChanged hook — reactive context detection with fallback

**Pillar 3 — Extensibility:**
- [x] F4: `.cortex/project.json` — manual per-project config (tech_stack, boost, suppress, disabled, preset)
- [x] F5: Presets system — greenfield, maintenance, strict, learning (activate via `/cortex:preset`)
- [x] F11: Template packs — domain-specific bundles with auto-detection
- [x] F12: Team-shared templates — `.cortex/custom/` in repo, auto-indexed

**Pillar 4 — Commands & Polish:**
- [x] F7: `/cortex:preset` — activate/list/create presets
- [x] F8: `/cortex:context` — show current project intelligence
- [x] F14: Enhanced `/cortex:stats` — context filter effectiveness, preset impact

**Final test count:** 116 tests, 0 failures.

## v1.3 — Refinement & Feedback Loop

- [ ] **Adaptive confidence**: Track which templates produce good feedback, adjust confidence scores over time
- [ ] **Multi-template composition**: Compose 2-3 templates for complex prompts that span multiple intents
- [ ] **Preset auto-detection**: Infer preset from project signals (e.g., fresh repo = greenfield, many open issues = maintenance)
- [ ] **Template pack marketplace**: Community-contributed packs with install/update via `/cortex:pack install <name>`
- [ ] **Prompt history analysis**: `/cortex:history` — show recent prompt→template matches with confidence scores
- [ ] **Negative feedback learning**: Templates with repeated bad feedback get confidence penalty within session

## v2.0 — The Brain (Layer 2)

### `/cortex:optimize` — Deep prompt optimization
On-demand agent that composes multi-template prompts, applies Anthropic's 6 techniques, handles complex requests that Layer 1 can't match with single templates.

### `/cortex:chain` — Prompt decomposition
Decomposes complex requests into prompt chains. The "wow feature" from the original spec.

### Automatic CLAUDE.md parsing
SessionStart hook extracts conventions from CLAUDE.md and writes boost/suppress rules automatically. Requires LLM classification.

### Adaptive Prompt Memory
Cross-session learning: track which templates produce good results (via user feedback signals) and adjust confidence scores over time.
