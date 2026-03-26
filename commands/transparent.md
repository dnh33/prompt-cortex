---
name: "cortex:transparent"
description: "Toggle transparent mode — when enabled, prompt-cortex appends a brief note after each injection showing which template was applied and at what confidence"
---

Toggle prompt-cortex transparent mode on or off.

Steps:
1. Read `.cortex/config.json` from the current working directory (create if doesn't exist).
2. Toggle the `transparent` boolean field (flip current value).
3. Write back to `.cortex/config.json`.
4. Confirm the new state.

If an explicit argument is provided (`/cortex:transparent on` or `/cortex:transparent off`), use that instead of toggling.

Example output:
```
## prompt-cortex Transparent Mode

**Status:** ON

When a template is injected, you'll see a note like:
> [cortex: applied coding-001 "Code Review" @ 0.92]

Use `/cortex:transparent` again to turn off, or `/cortex:transparent off`.
```

Config file format (`.cortex/config.json`):
```json
{
  "min_tier": "silver",
  "transparent": true
}
```

When transparent mode is active, the cortex-match hook appends this to the additionalContext:
`\n[cortex: applied {template_id} "{template_name}" @ {confidence}]`

This note is injected as part of additionalContext, visible in Claude's context. When Claude sees it, Claude should mention which template was applied (e.g., "I'm using the Code Review template for this."). This gives users visibility into what cortex is doing — the whole point of transparent mode.
