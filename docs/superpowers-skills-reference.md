# Superpowers Skills Reference

Reference for mapping prompt-cortex templates to superpowers skills. Use this when adding new templates — check which skills your template naturally complements and add them to the `compatible_with` field.

## Skill Inventory

11 of 14 superpowers skills are template-complementary. 3 are meta/orchestration (not mapped to individual templates).

### Template-Complementary Skills

| Skill | When it fires | What it does | Best paired with templates that... |
|-------|---------------|--------------|-------------------------------------|
| `brainstorming` | Before creative work | Explores intent, requirements, design before implementation | ...involve design, architecture, or creating something new |
| `test-driven-development` | Before implementing features/bugfixes | Write test first, then implementation | ...create code, fix bugs, or need verification |
| `systematic-debugging` | When encountering bugs/failures | Methodical debugging before proposing fixes | ...debug errors, fix bugs, trace issues |
| `verification-before-completion` | Before claiming work is done | Run verification commands, confirm output before success claims | ...audit, optimize, validate, or verify results |
| `requesting-code-review` | After completing tasks | Review implementation against plan and standards | ...review code, PRs, security, architecture |
| `receiving-code-review` | When getting review feedback | Technical rigor when implementing suggestions | ...refactor or fix issues from feedback |
| `writing-plans` | Before multi-step tasks | Design implementation plan before touching code | ...require architecture, pipeline design, or planning |
| `writing-skills` | When creating/editing skills | Skill structure, system prompts, progressive disclosure | ...craft prompts, system instructions, or reasoning patterns |
| `dispatching-parallel-agents` | When facing 2+ independent tasks | Parallel execution without shared state | ...involve batch processing or multi-agent orchestration |
| `finishing-a-development-branch` | When implementation is complete | Merge, PR, or cleanup options | ...complete PRs or git workflows |
| `using-git-worktrees` | Before feature work | Isolated git worktrees for safe development | ...involve deployment, branching, or release |

### Meta/Orchestration Skills (NOT mapped to templates)

| Skill | Why not mapped |
|-------|----------------|
| `executing-plans` | Orchestrates plan execution — operates above the template level |
| `subagent-driven-development` | Dispatches subagents for plan tasks — orchestration, not content |
| `using-superpowers` | Meta-skill that establishes how to find/use other skills |

## Mapping Guidelines

When adding a new template, ask:

1. **What does the user do AFTER getting this template's guidance?**
   - If they'll write code → `test-driven-development`
   - If they'll review code → `requesting-code-review`
   - If they'll verify results → `verification-before-completion`

2. **What should the user do BEFORE this template fires?**
   - If design is needed → `brainstorming`
   - If a plan is needed → `writing-plans`
   - If debugging context → `systematic-debugging`

3. **What lifecycle moment does this template serve?**
   - Creating → `brainstorming`, `writing-plans`, `test-driven-development`
   - Reviewing → `requesting-code-review`, `receiving-code-review`
   - Fixing → `systematic-debugging`, `test-driven-development`
   - Shipping → `verification-before-completion`, `finishing-a-development-branch`

### Rules

- Every template should map to **1-3 skills** (not more — be selective)
- Choose skills that represent the **natural next step** in the workflow
- Don't map to meta/orchestration skills
- When in doubt, `verification-before-completion` is the most universal complement

## Current Coverage Matrix

### By superpowers skill (how many templates reference it)

| Skill | Coding | AI Workflows | Total |
|-------|--------|-------------|-------|
| `brainstorming` | 6 | 8 | 14 |
| `test-driven-development` | 8 | 6 | 14 |
| `verification-before-completion` | 7 | 8 | 15 |
| `systematic-debugging` | 4 | 0 | 4 |
| `writing-plans` | 5 | 7 | 12 |
| `requesting-code-review` | 5 | 0 | 5 |
| `writing-skills` | 0 | 5 | 5 |
| `dispatching-parallel-agents` | 0 | 2 | 2 |
| `finishing-a-development-branch` | 1 | 0 | 1 |
| `using-git-worktrees` | 2 | 0 | 2 |
| `receiving-code-review` | 2 | 0 | 2 |
