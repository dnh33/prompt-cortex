# prompt-cortex

```
                                          ╭─────────────────────────────╮
    ┌──────────────────┐                  │                             │
    │  "review my code" ├────────────────►│   ░░░░░░░░░░░░░░░░░░░░░░   │
    └──────────────────┘                  │   ░  prompt-cortex      ░   │
           what you type                  │   ░  350 templates      ░   │
                                          │   ░  622 index keys     ░   │
    ┌──────────────────┐                  │   ░  <2s matching       ░   │
    │  senior engineer  │                 │   ░░░░░░░░░░░░░░░░░░░░░░   │
    │  code review with │◄────────────────│                             │
    │  5-point checklist│                 ╰─────────────────────────────╯
    └──────────────────┘
           what claude gets                      you see nothing
```

**The invisible layer beneath every prompt.** 350 proven templates. Pure bash + jq. Zero latency. You type naturally — Claude receives expert-level framing.

> *prompt-cortex is what CLAUDE.md would be if it were alive.*

---

## Built for Superpowers

prompt-cortex is the invisible half of the [superpowers](https://github.com/superpowers-marketplace/superpowers) stack. Two plugins, two layers, one pipeline:

```
    "review my code"
           │
     ══════╪══════════════════════════════════════════
     ░░░░░░▼░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     ░  PROMPT-CORTEX              invisible layer   ░
     ░  UserPromptSubmit hook      fires BEFORE      ░
     ░  ─────────────────────────────────────────     ░
     ░  + senior engineer code review template       ░
     ░  + 5-point checklist (correctness, security   ░
     ░    error handling, performance, naming)        ░
     ░  + injected as additionalContext               ░
     ░░░░░░│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     ──────┼──────────────────────────────────────────
     ██████▼██████████████████████████████████████████
     █  SUPERPOWERS                 visible layer    █
     █  Skill auto-detection        fires DURING     █
     █  ─────────────────────────────────────────     █
     █  + requesting-code-review workflow             █
     █  + diff analysis, structured output            █
     █  + verification-before-completion              █
     ██████│██████████████████████████████████████████
     ══════╪══════════════════════════════════════════
           ▼
    Claude responds with expert framing
    AND a structured workflow
```

**They complement, not compete.** Cortex injects the *what to think about*. Superpowers provides the *how to execute*. Different lifecycle points, natural synergy. Every template declares which superpowers skills it pairs with via `compatible_with` — 11 of 14 superpowers skills are mapped.

Install both for the full stack:
```bash
claude plugin add github:dnh33/prompt-cortex
# + superpowers from marketplace
```

## What it does

When you type a prompt, prompt-cortex analyzes it in the background and — if it matches a known pattern — silently injects a proven prompt template as additional context. You don't see it, but Claude does. The result: better responses without changing how you work.

**Example**: You type `review my code`. prompt-cortex detects a code review intent, injects a senior engineer code review template with a 5-point checklist (correctness, error handling, naming, performance, security), and Claude responds with structured, thorough feedback — all without you having to write a detailed prompt.

## How it works

1. **SessionStart hook** fires when Claude Code starts. Validates the template index, detects your project's language/framework, and confirms cortex is active.
2. **UserPromptSubmit hook** fires on every prompt. A pure `jq` matching engine scores your prompt against 50 gold-tier templates in <2 seconds.
3. If confidence is high enough (≥0.70), the best template is injected as `additionalContext` — invisible to you, visible to Claude.
4. If confidence is medium (0.40-0.69), a hint is injected instead.
5. If the prompt looks like it should be left alone (shell commands, continuations, already-structured prompts), cortex stays silent.

### Full pipeline example

Prompt: **"review the changes I made to checkout"**

```
 ┌─────────────────────────────────────────────────────────────────┐
 │ 1. Leave-it-alone detector                                     │
 │    13 signals checked → score 0.0 → passes through             │
 ├─────────────────────────────────────────────────────────────────┤
 │ 2. Preprocessor (v1.3)                                         │
 │    P6 detects "review" as known action, strips filler "I made" │
 │    → inferred_action: "review"                                 │
 │    → cleaned_terms: ["review", "changes", "checkout"]          │
 ├─────────────────────────────────────────────────────────────────┤
 │ 3. Keyword lookup                                              │
 │    "review", "changes", "checkout" hit inverted index           │
 │    → coding-001 "Code Review" is top candidate                 │
 ├─────────────────────────────────────────────────────────────────┤
 │ 4. Scoring                                                     │
 │    action  0.45  (exact match: review)                         │
 │    object  0.35  (match: code)                                 │
 │    signal  0.10  (intent signal hit)                           │
 │    total   0.90  confidence                                    │
 ├─────────────────────────────────────────────────────────────────┤
 │ 5. Context filter                                              │
 │    No language/framework restrictions → passes                 │
 ├─────────────────────────────────────────────────────────────────┤
 │ 6. Result                                                      │
 │    action: "inject" at 0.90                                    │
 │    coding-001 body → additionalContext                         │
 └─────────────────────────────────────────────────────────────────┘
```

### Conversational NLP (v1.3)

Before v1.3, matching relied on exact keyword hits. Natural phrasing — filler words, implicit actions, pronouns — degraded scores or caused misses. The v1.3 preprocessor strips noise and infers intent from conversational patterns before scoring begins.

| Prompt | Before v1.3 | After v1.3 |
|--------|-------------|------------|
| "something is wrong with the API" | skip (no action match) | **defer** — preprocessor infers `debug`, boosts candidates (conf 0.35 skip, but preprocessor extracts intent) |
| "make it faster" | skip ("make" suppressed as shell cmd) | **defer** — preprocessor maps "faster" → `optimize` via adjective_actions (conf 0.35 skip, intent extracted) |
| "how does the auth flow work" | skip (conceptual question suppressed) | **defer** — preprocessor extracts `explain` + subject "auth flow" (conf 0.40) |
| "can you help me debug this" | defer (weak prefix match) | **defer** — "can you help me" stripped, clean `debug` term boosts match (conf 0.47) |

## Install

```bash
# Clone the repo
git clone https://github.com/dnh33/prompt-cortex.git

# Install as Claude Code plugin
claude plugin add /path/to/prompt-cortex
```

Or install directly from GitHub:
```bash
claude plugin add github:dnh33/prompt-cortex
```

## Escape mechanisms

prompt-cortex is designed to stay out of your way. If you ever want to bypass it:

| Method | How | Scope |
|--------|-----|-------|
| `--raw` prefix | Start any prompt with `--raw` | Single prompt |
| `/cx off` | Type `/cx off` as a prompt | Rest of session |
| `/cx on` | Type `/cx on` to re-enable | Rest of session |

The engine also automatically stays silent for:
- Shell commands (`git status`, `npm install`, etc.)
- Slash commands (`/commit`, `/help`, etc.)
- Continuations (`ok`, `yes`, `looks good`, `ship it`)
- Already-structured prompts (XML tags, numbered lists, role assignments)
- Conceptual questions (`what is React?`, `how does X work?`)

## Superpowers skill coverage

Every template maps to 1-3 superpowers skills via the `compatible_with` field. See [docs/superpowers-skills-reference.md](docs/superpowers-skills-reference.md) for the full mapping and guidelines for new templates.

<details>
<summary>Skill coverage matrix</summary>

| Superpowers Skill | Templates that complement it |
|---|---|
| `brainstorming` | API design, architecture, components, agents, RAG, embeddings, tool use, prompts, search, auth |
| `test-driven-development` | Write tests, create functions, fix bugs, error handling, regex, concurrency, evals, guardrails, parsers |
| `verification-before-completion` | Code review, performance, security audit, config, accessibility, deployment, cost optimization |
| `systematic-debugging` | Debug error, fix bug, error handling, concurrency, type safety, logging |
| `writing-plans` | API design, database, architecture, deployment, auth, caching, search, RAG, agents, embeddings |
| `requesting-code-review` | Code review, refactor, PR review, docs, security audit, architecture, accessibility |
| `writing-skills` | Prompt engineering, system prompts, chain-of-thought, few-shot, tool use, conversation design |
| `dispatching-parallel-agents` | Agent design, batch processing |
| `finishing-a-development-branch` | PR review, git workflow |
| `using-git-worktrees` | Git workflow, deployment |
| `receiving-code-review` | Refactor code, type safety |

</details>

## Commands

| Command | Description |
|---------|-------------|
| `/cortex:debug` | Show what cortex matched on your last prompt |
| `/cortex:list` | List all available templates by category |
| `/cortex:sync` | Rebuild the template index after changes |

## Templates

50 gold-tier templates across two categories:

- **coding** (28 templates): Code review, debugging, testing, refactoring, API design, security audit, performance optimization, error handling, and more.
- **ai-workflows** (22 templates): Agent design, RAG pipelines, prompt engineering, evaluation, embeddings, tool use, guardrails, streaming, cost optimization, and more.

Each template includes:
- Senior expert role framing
- Systematic approach (numbered steps)
- Conditional guidance ("If no code provided, ask...")
- Triggers and intent signals for accurate matching
- Negative signals to avoid false positives

## Adding templates

See [CONTRIBUTING.md](CONTRIBUTING.md) for the template schema and guidelines.

Quick start:
1. Create a `.md` file in `data/prompts/<category>/`
2. Add YAML frontmatter with required fields
3. Validate: `bash scripts/validate-template.sh your-template.md`
4. Rebuild index: `/cortex:sync` or `bash scripts/build-index.sh`

## Architecture

```
prompt-cortex/
  .claude-plugin/plugin.json       # Plugin manifest
  hooks/
    hooks.json                     # Hook registrations
    run-hook.cmd                   # Cross-platform wrapper
    cortex-match                   # UserPromptSubmit hook
    cortex-session-init            # SessionStart hook
  data/
    intents.json                   # Action/object taxonomy
    index.json                     # Pre-built inverted index
    prompts/                       # Template library
      coding/*.md
      ai-workflows/*.md
  scripts/
    match.jq                      # Core matching engine
    build-index.sh                 # Index compiler
    validate-template.sh           # Template validator
  tests/
    run-tests.sh                   # Integration tests
  commands/
    debug.md                       # /cortex:debug
    list.md                        # /cortex:list
    sync.md                        # /cortex:sync
```

**Tech stack**: Pure bash + jq. No Python, Node, or other runtime dependencies. Cross-platform via `.cmd` polyglot wrapper (Windows/macOS/Linux).

## Troubleshooting

### Hooks not firing

If prompt-cortex doesn't seem active after installation, the plugin hooks may not be loading (known Claude Code issue #10225). Workaround: copy the hook configuration to your user settings:

```bash
# Copy hooks to user settings
cat prompt-cortex/hooks/hooks.json
# Then add the hooks to ~/.claude/settings.json under the "hooks" key
```

### Verifying it works

1. Run `/cortex:debug` after sending a prompt
2. Check `.cortex/usage.jsonl` in your project directory for telemetry
3. Run the test suite: `bash tests/run-tests.sh`

### Index out of date

If you've added or modified templates, rebuild the index:
```bash
bash scripts/build-index.sh
# or use the command:
/cortex:sync
```

## Local telemetry

prompt-cortex logs match results to `.cortex/usage.jsonl` in your project directory. This is local-only, contains no prompt content (only hashes), and is gitignored. Use it to understand what's being matched and at what confidence.

## License

MIT — Daniel Hjermitslev ([@dnh33](https://github.com/dnh33))
