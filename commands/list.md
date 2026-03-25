---
name: "cortex:list"
description: "List all available prompt-cortex templates by category, with optional search/filter"
---

List all templates available in the prompt-cortex library.

Read `data/index.json` from `${CLAUDE_PLUGIN_ROOT}` (or find it relative to this plugin's installation).

Display templates grouped by category. For each template show:
- **ID** and **Name**
- **Action** → **Object** (e.g., review → code)
- **Quality tier** (gold/silver/bronze)
- **Triggers** (first 3)

If the user provides a search term as an argument (e.g., `/cortex:list debug`), filter templates to only show those whose name, triggers, action, or object match the search term (case-insensitive).

Example output:
```
## prompt-cortex Templates (50 total)

### coding (28 templates)

| ID | Name | Intent | Tier |
|----|------|--------|------|
| coding-001 | Code Review | review → code | gold |
| coding-002 | Debug Error | debug → error | gold |
| coding-003 | Write Tests | test → code | gold |
| ... | ... | ... | ... |

### ai-workflows (22 templates)

| ID | Name | Intent | Tier |
|----|------|--------|------|
| ai-051 | Agent Design | design → architecture | gold |
| ... | ... | ... | ... |
```

If no index.json is found, tell the user to run `/cortex:sync` to build the index.
