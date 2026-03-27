---
name: "cortex:suggest"
description: "Analyze CLAUDE.md to generate project-specific template configuration"
allowed_tools: ["Read", "Write", "Glob"]
---

# /cortex:suggest — CLAUDE.md Analysis

Analyze the project's CLAUDE.md file(s) to generate intelligent template boost/suppress rules.

## What to do

1. **Find CLAUDE.md files:**
   - Look for `CLAUDE.md` in the project root
   - Also check for subdirectory CLAUDE.md files (e.g., `src/CLAUDE.md`)
   - Read each file completely

2. **Analyze for these signals:**
   - **Tech stack**: Languages, frameworks, runtimes mentioned
   - **Testing philosophy**: TDD requirements, test frameworks, coverage expectations
   - **Code style**: Functional vs OOP, naming conventions, formatting tools
   - **Quality standards**: Error handling, security, performance requirements
   - **Platform constraints**: No default exports, specific import patterns, etc.

3. **Generate rules:**
   Based on your analysis, generate boost/suppress/disabled rules:
   - `boost`: Categories or actions that align with CLAUDE.md priorities
   - `suppress`: Categories or actions that conflict with project constraints
   - `disabled`: Specific template IDs that would be actively harmful
   - Include reasoning for each rule

4. **Present for review:**
   Show the proposed configuration with reasoning. Ask the user to confirm.

5. **On confirmation, save to `.cortex/project-context.json`:**

```json
{
  "generated_at": "<ISO timestamp>",
  "claude_md_hash": "<first 8 chars of CLAUDE.md cksum>",
  "analysis": {
    "tech_stack": { "language": "", "framework": "", "runtime": "" },
    "conventions": {
      "testing": "",
      "style": "",
      "quality": "",
      "constraints": []
    }
  },
  "rules": {
    "boost": [],
    "suppress": [],
    "disabled": []
  },
  "reasoning": {}
}
```

## Flags

- `/cortex:suggest` — Analyze and propose (default)
- `/cortex:suggest --refresh` — Re-analyze (use when CLAUDE.md has changed)
- `/cortex:suggest --dry-run` — Show analysis without saving

## Important

- The LLM call happens HERE (in Claude's process via this command). The hook (Layer 1) never calls an LLM.
- Always present rules for user review before saving. Never auto-save.
- The `claude_md_hash` field enables staleness detection at SessionStart.
- Valid boost/suppress values: actions (create, review, debug, refactor, explain, test, document, optimize, design, fix) and categories (coding, ai-workflows, research, automation, content, productivity).
