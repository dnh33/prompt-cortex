# prompt-cortex v1.0 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete v1.0 "The Library That Injects Itself" — plugin scaffold, matching engine, hooks, 50 gold templates, 3 commands, escape mechanisms, and onboarding.

**Architecture:** Two-layer system. Layer 1 (UserPromptSubmit hook) fires on every prompt, matches against template library via pure bash+jq in <2s, injects best match as additionalContext. SessionStart hook initializes index, detects project context, cleans stale state.

**Tech Stack:** Pure bash + jq (no Python/Node). Cross-platform via .cmd polyglot wrapper.

**Spec:** `docs/2026-03-25-prompt-cortex-design.md`

---

## Scope: Full v1.0

1. Plugin scaffold (plugin.json, hooks.json, run-hook.cmd)
2. Intent taxonomy (data/intents.json)
3. 50 gold-tier templates with YAML frontmatter (coding + debugging + AI workflows)
4. Template validator (scripts/validate-template.sh)
5. Index builder (scripts/build-index.sh -> data/index.json)
6. Matching engine (scripts/match.jq — leave-it-alone + 3-phase scoring)
7. UserPromptSubmit hook (hooks/cortex-match)
8. SessionStart hook (hooks/cortex-session-init)
9. 3 commands: /cortex:debug, /cortex:list, /cortex:sync
10. Escape mechanisms (--raw, /cx off)
11. First-session onboarding disclosure
12. Local telemetry (.cortex/usage.jsonl)
13. .gitignore, LICENSE (MIT), README.md, CONTRIBUTING.md
14. Integration test suite

## Split into Two Plan Documents

This is a large v1.0. Split execution into:

**Plan A (this file):** Core engine — Tasks 1-12 below. Creates the scaffold, hooks, matching engine, index builder, validator, 3 sample templates, tests, and supporting files. ~12 tasks, executable by subagents.

**Plan B (separate file, after Plan A):** Content — 50 gold templates, 3 commands (/cortex:debug, /cortex:list, /cortex:sync), README.md, CONTRIBUTING.md. Depends on Plan A being complete.

---

## Key Technical Decisions

1. **jq regex**: `\b` word boundaries do NOT work in jq's ONIG regex. Use `(^|[^a-zA-Z])word([^a-zA-Z]|$)` instead.
2. **State file fallback**: `jq --slurpfile` crashes on missing files. Pass state as `--arg` string, parse inside jq.
3. **YAML parsing**: Pure bash parser for flat frontmatter (no yq dependency).
4. **printf over heredoc**: Avoid bash 5.3+ heredoc variable expansion bug. Use `printf` for JSON output.
5. **Extensionless hook scripts**: Named `cortex-match` not `cortex-match.sh` (Windows auto-detection interference).
6. **Cross-platform**: `.cmd` polyglot wrapper (bash + batch in one file), proven pattern from superpowers plugin.

## Hook API Contract (verified)

**UserPromptSubmit stdin:**
```json
{"session_id":"abc","user_prompt":"text","cwd":"/path","hook_event_name":"UserPromptSubmit"}
```

**Output for injection:**
```json
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<prompt-cortex>...</prompt-cortex>"}}
```

**Output for silence:** `{}`

---

## File Structure

```
prompt-cortex/
  .claude-plugin/
    plugin.json                    # Plugin manifest
  hooks/
    hooks.json                     # Hook registrations
    run-hook.cmd                   # Cross-platform polyglot wrapper
    cortex-match                   # UserPromptSubmit hook (extensionless)
    cortex-session-init            # SessionStart hook (extensionless)
  data/
    intents.json                   # Action/object taxonomy + synonyms
    index.json                     # Pre-built inverted index (generated)
    prompts/
      coding/
        coding-001.md              # Code Review (sample)
        coding-002.md              # Debug Error (sample)
        coding-003.md              # Write Tests (sample)
  scripts/
    match.jq                       # Core matching engine (pure jq)
    build-index.sh                 # Index compiler
    validate-template.sh           # Template schema validator
  tests/
    run-tests.sh                   # Integration test suite
  .gitignore
  LICENSE
  docs/
    2026-03-25-prompt-cortex-design.md  # (exists)
```

---

## Task 1: Plugin Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `hooks/hooks.json`
- Create: `hooks/run-hook.cmd`

- [ ] Create `.claude-plugin/plugin.json` with name, version 1.0.0, MIT license, dnh33 author
- [ ] Create `hooks/hooks.json` with SessionStart (matcher: "*", timeout: 15) and UserPromptSubmit (matcher: "*", timeout: 5) both calling run-hook.cmd via polyglot wrapper
- [ ] Create `hooks/run-hook.cmd` polyglot wrapper (batch finds Git Bash on Windows, Unix runs directly)
- [ ] chmod +x hooks/run-hook.cmd
- [ ] Verify: `jq . .claude-plugin/plugin.json && jq . hooks/hooks.json`
- [ ] Commit: "scaffold: plugin manifest, hooks registration, cross-platform wrapper"

---

## Task 2: Intent Taxonomy

**Files:**
- Create: `data/intents.json`

- [ ] Create `data/intents.json` with 10 actions (create/review/debug/refactor/explain/test/document/optimize/design/fix), 14 objects, 6 categories, action_synonyms map, object_synonyms map
- [ ] Verify: `jq '.actions | length' data/intents.json` outputs 10
- [ ] Commit: "data: add intent taxonomy with synonym maps"

---

## Task 3: Three Sample Templates

**Files:**
- Create: `data/prompts/coding/coding-001.md` (Code Review, gold)
- Create: `data/prompts/coding/coding-002.md` (Debug Error, gold)
- Create: `data/prompts/coding/coding-003.md` (Write Tests, gold)

- [ ] Create coding-001.md with full YAML frontmatter (id, name, category, intent, action, object, triggers x7, intent_signals, negative_signals, quality_tier: gold, token_overhead, min_confidence, composable_with, composition_role: primary) + template body (senior engineer code review, 5-point checklist)
- [ ] Create coding-002.md (debug template, 5-step investigation approach, composable with coding-003)
- [ ] Create coding-003.md (test writing template, 4-category testing strategy)
- [ ] All intent_signals use jq-compatible regex (no \b — use `(^|[^a-zA-Z])word([^a-zA-Z]|$)`)
- [ ] Commit: "data: add 3 gold-tier sample templates"

---

## Task 4: Template Validator

**Files:**
- Create: `scripts/validate-template.sh`

- [ ] Write validator that checks: frontmatter delimiters exist, 7 required fields present (id/name/category/intent/action/object/triggers), category in valid set, action in valid set, triggers >= 3 entries, id matches filename, body not empty
- [ ] chmod +x scripts/validate-template.sh
- [ ] Test: `bash scripts/validate-template.sh data/prompts/coding/coding-001.md` → OK
- [ ] Commit: "scripts: add template frontmatter validator"

---

## Task 5: Index Builder

**Files:**
- Create: `scripts/build-index.sh`
- Generates: `data/index.json`

- [ ] Write pure-bash YAML frontmatter parser (handles scalars + simple arrays, no yq)
- [ ] Parse all .md files in data/prompts/, extract frontmatter as JSON via jq
- [ ] Build inverted_index: map triggers (full phrases + individual words >2 chars) + action + object → template IDs
- [ ] Compute version hash from template modification times
- [ ] Output index.json with: version, built timestamp, template_count, templates array, inverted_index
- [ ] chmod +x scripts/build-index.sh
- [ ] Test: `bash scripts/build-index.sh && jq '.template_count' data/index.json` → 3
- [ ] Test: `jq '.inverted_index["review"]' data/index.json` → contains "coding-001"
- [ ] Commit: "scripts: add index builder, generate initial index"

---

## Task 6: Matching Engine (match.jq)

**Files:**
- Create: `scripts/match.jq`

- [ ] Implement leave-it-alone detector with max-of-top-2 scoring: slash commands (1.0), --raw (1.0), /cx off (1.0), XML tags (0.50), shell commands (0.60), continuations (0.45), role assignments (0.40), same template in last 3 turns (0.40), conceptual questions (0.30), numbered lists (0.15), output format (0.10), long+structured (0.45). All 12 signals. Threshold >= 0.60 = leave alone.
- [ ] Implement reject-signal boosting: if 2+ `--raw` rejections in last 10 prompts (from state.recentInjections), boost leave-alone base score by +0.10 per rejection (max +0.25)
- [ ] Implement Phase 1: keyword extraction (lowercase split) + bigrams + inverted index lookup
- [ ] Implement Phase 2: score candidates with weights — action exact (+0.45), action secondary (+0.20), object exact (+0.35), object secondary (+0.15), keyword overlap (+0.02 each, max 0.08), intent signal boost (+0.10), negative signal penalty (-0.30), complexity mismatch (-0.15), multi-turn suppression (-0.40)
- [ ] Phase 3 stub (context filter, pass-through for v1.0)
- [ ] Gating: >= 0.70 inject, 0.40-0.69 defer, < 0.40 skip. Per-template min_confidence can only raise threshold.
- [ ] Output: `{action, confidence, best_match, candidates, leave_alone_score, leave_alone_reason}`
- [ ] Test: `jq -f scripts/match.jq --arg prompt "review my code" --arg state "null" --arg cwd "" data/index.json` → action=inject, coding-001
- [ ] Test: `jq -f scripts/match.jq --arg prompt "git status" --arg state "null" --arg cwd "" data/index.json` → action=suppress
- [ ] Test: `jq -f scripts/match.jq --arg prompt "--raw fix bug" --arg state "null" --arg cwd "" data/index.json` → action=escape
- [ ] Test: `jq -f scripts/match.jq --arg prompt "ok" --arg state "null" --arg cwd "" data/index.json` → action=suppress
- [ ] Commit: "core: add jq matching engine with leave-it-alone detector"

---

## Task 7: UserPromptSubmit Hook

**Files:**
- Create: `hooks/cortex-match`

- [ ] Read stdin JSON, extract user_prompt, session_id, cwd
- [ ] Early exit on empty prompt or missing index
- [ ] Load session state from .cortex/state-{session_id}.json (or null)
- [ ] Run match.jq with prompt, state, cwd arguments
- [ ] If inject: read template body (after second ---), wrap in `<prompt-cortex>` tags, output as additionalContext
- [ ] If defer: inject Layer 2 hint with candidates
- [ ] If suppress/escape/skip: output `{}`
- [ ] Implement `/cx off` escape: if user_prompt matches `^/cx\s+off`, write `cortex_disabled: true` to state file and output `{}`. If user_prompt matches `^/cx\s+on`, write `cortex_disabled: false`. Check `cortex_disabled` in state at start of hook — if true, skip all matching.
- [ ] Log telemetry to .cortex/usage.jsonl with ALL fields: ts (ISO-8601), prompt_hash, matched (array), confidence, injected (id or null), disposition (one of: injected/deferred/suppressed/user_escaped/below_threshold), project (from basename of cwd)
- [ ] Update session state (lastHookRun, lastPromptHash, hookResult, recentInjections with last 10, cortex_disabled flag)
- [ ] Token budget enforcement: after reading template body, estimate token count (words * 1.3). If >300 tokens, truncate at last sentence boundary before 300. Log truncation.
- [ ] First-session onboarding: one-time disclosure on first injection per INSTALL (not per session). Store marker at `.cortex/.onboarded` file. Exact message: `[prompt-cortex] Applied template {id} ({confidence} confidence). Use --raw prefix to skip enhancement for any prompt.`
- [ ] chmod +x hooks/cortex-match
- [ ] Test: `echo '{"session_id":"t1","user_prompt":"review my code","cwd":"/tmp"}' | CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-match` → JSON with additionalContext
- [ ] Test: `echo '{"session_id":"t1","user_prompt":"git status","cwd":"/tmp"}' | CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-match` → `{}`
- [ ] Commit: "core: add UserPromptSubmit hook with telemetry and onboarding"

---

## Task 8: SessionStart Hook

**Files:**
- Create: `hooks/cortex-session-init`

- [ ] Validate index.json exists (rebuild if missing via build-index.sh)
- [ ] Detect project context: language (JS/TS/Python/Rust/Go/Java) and framework (React/Next/Vue/Express/Django/FastAPI/Flask) from package.json/tsconfig.json/requirements.txt/Cargo.toml/go.mod
- [ ] Clean stale .cortex/state-*.json files older than 24 hours
- [ ] Platform bug #10225 health-check: write a `.cortex/.health-check` marker with timestamp. The UserPromptSubmit hook checks for this marker on first run. If marker is stale (>5 min) or missing after SessionStart should have fired, log a warning. This validates the hook pipeline is working.
- [ ] Output additionalContext with init message: template count, detected project, escape instructions
- [ ] Support both Claude Code (hookSpecificOutput) and Cursor (additional_context) output formats
- [ ] chmod +x hooks/cortex-session-init
- [ ] Test: `CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-session-init` → JSON with init message
- [ ] Commit: "core: add SessionStart hook with project detection and health-check"

---

## Task 9: Integration Tests

**Files:**
- Create: `tests/run-tests.sh`

- [ ] Test template validator: valid file passes, missing field fails, bad category fails
- [ ] Test index builder: produces valid JSON, correct template count, inverted index has expected keys
- [ ] Test match.jq: "review my code" → coding-001 inject, "debug this" → coding-002, "git status" → suppress, "--raw fix" → escape, "ok" → suppress, "what is React" → suppress (conceptual)
- [ ] Test cortex-match hook: end-to-end with mock stdin, verify JSON output shape, verify telemetry written
- [ ] Test cortex-session-init: verify JSON output, verify stale state cleanup
- [ ] Test escape: /cx off in state → all prompts suppressed
- [ ] chmod +x tests/run-tests.sh
- [ ] Run: `bash tests/run-tests.sh` → all pass
- [ ] Commit: "tests: add integration test suite"

---

## Task 10: Supporting Files

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`

- [ ] .gitignore: `.cortex/` (user state), `*.jsonl` (telemetry), `node_modules/`, `.DS_Store`
- [ ] LICENSE: MIT, Daniel Hjermitslev, 2026
- [ ] Commit: "meta: add .gitignore and MIT license"

---

## Task 11: 50 Gold Templates (25 Coding + 25 AI Workflows)

**Files:**
- Create: `data/prompts/coding/coding-004.md` through `coding-028.md` (25 additional, 28 total with 3 samples)
- Create: `data/prompts/ai-workflows/ai-051.md` through `ai-072.md` (22 templates, total = 50 with coding)

Note: 28 coding (3 sample + 25 new) + 22 AI workflows = 50 gold templates total.

- [ ] Create 25 additional coding templates (004-028): refactoring, architecture review, API design, security audit, performance optimization, error handling, documentation, migration, dependency analysis, code explanation, git workflow, database queries, regex help, config management, logging, authentication, caching, search implementation, data validation, concurrency, deployment, monitoring, type safety, accessibility, CI/CD
- [ ] Create 22 AI workflow templates (051-072): agent design, RAG pipeline, classification, prompt engineering, evaluation, fine-tuning guidance, embedding strategy, context management, tool use, chain-of-thought design, few-shot design, system prompt crafting, guardrails, output parsing, structured extraction, multi-modal, batch processing, streaming, cost optimization, model selection, retrieval tuning, conversation design
- [ ] All gold-tier templates MUST have: persona/role framing in body, conditional for missing input ("If no X provided, ask..."), 1-2 few-shot examples, 150-200 token target body, full YAML frontmatter (all 8 required fields + intent_signals + negative_signals + composable_with + composition_role + quality_tier: gold + token_overhead + min_confidence)
- [ ] All intent_signals use jq-compatible regex (no \b)
- [ ] Validate: `bash scripts/validate-template.sh data/prompts/coding/*.md data/prompts/ai-workflows/*.md`
- [ ] Rebuild index: `bash scripts/build-index.sh`
- [ ] Verify: `jq '.template_count' data/index.json` → 50
- [ ] Commit: "data: add 50 gold-tier templates (coding + AI workflows)"

---

## Task 12: 3 Commands + README + CONTRIBUTING

**Files:**
- Create: `commands/debug.md` (/cortex:debug)
- Create: `commands/list.md` (/cortex:list)
- Create: `commands/sync.md` (/cortex:sync)
- Create: `README.md`
- Create: `CONTRIBUTING.md`

- [ ] /cortex:debug — skill that shows what Layer 1 would inject for the last prompt (reads .cortex/state-*.json, shows matched templates, confidence scores, leave-alone score, disposition)
- [ ] /cortex:list — skill that lists available templates by category with search/filter support
- [ ] /cortex:sync — skill that rebuilds index.json from templates (calls build-index.sh, validates all templates, reports stats)
- [ ] README.md: project description, install instructions, how it works, escape mechanisms, commands, troubleshooting section with platform bug #10225 fallback (copy hooks config to ~/.claude/settings.json), contributing link
- [ ] CONTRIBUTING.md: minimum viable template schema (8 required fields), how to add templates, validation steps, PR guidelines
- [ ] Commit: "docs: add commands, README with troubleshooting, CONTRIBUTING guide"

---

## Verification Plan

After all tasks complete:

1. `bash tests/run-tests.sh` — all pass
2. `bash scripts/validate-template.sh data/prompts/**/*.md` — all valid
3. `bash scripts/build-index.sh` — builds clean
4. Manual test: `echo '{"session_id":"test","user_prompt":"review my code","cwd":"."}' | CLAUDE_PLUGIN_ROOT=. bash hooks/cortex-match` — returns template injection
5. Manual test: `echo '{"session_id":"test","user_prompt":"ok","cwd":"."}' | CLAUDE_PLUGIN_ROOT=. bash hooks/cortex-match` — returns `{}`
6. Manual test: `CLAUDE_PLUGIN_ROOT=. bash hooks/cortex-session-init` — returns init message
7. Install plugin locally and test with real Claude Code session
