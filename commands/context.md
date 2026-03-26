---
name: "cortex:context"
description: "Display current project intelligence — detected tech stack, active rules, and configuration"
allowed_tools: ["Read", "Glob", "Bash"]
---

# /cortex:context — Project Intelligence Display

Show the user everything prompt-cortex knows about their current project.

## How to execute

1. **Read session context** from `.cortex/session-context.json`:
   - Language, framework, testing, linter, package manager, monorepo, branch type

2. **Read project config** from `.cortex/project.json` (if exists):
   - Tech stack overrides, boost/suppress rules, disabled templates, preset, custom template path

3. **Read cached analysis** from `.cortex/project-context.json` (if exists):
   - CLAUDE.md analysis results, generated rules, reasoning

4. **Read active preset** from `.cortex/config.json`:
   - Preset name, its boost/suppress rules

5. **Display in a structured format:**

```
## prompt-cortex Project Context

### Detected Stack
- Language: typescript
- Framework: nextjs
- Testing: vitest
- Linter: biome
- Package Manager: bun
- Monorepo: false
- Branch Type: feature

### Active Configuration
- Preset: greenfield
- Min Tier: gold

### Boost Rules (with source)
- "design" (from preset: greenfield)
- "create" (from preset: greenfield)
- "testing" (from project.json)

### Suppress Rules (with source)
- "refactor" (from preset: greenfield)
- "legacy" (from project-context.json)

### Disabled Templates
- (none)

### CLAUDE.md Analysis
- Last analyzed: 2026-03-26T15:30:00Z
- Status: current (hash matches)

### Custom Templates
- Directory: .cortex/custom/
- Count: 3 templates loaded
```

6. **If nothing is configured**, show defaults and suggest `/cortex:suggest` to get started.
