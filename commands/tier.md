---
name: "cortex:tier"
description: "Set the minimum quality tier for prompt-cortex template matching — gold (curated only), silver (default, full library), or all (including bronze)"
---

Set the minimum quality tier for prompt-cortex template matching.

Read the argument: the user will type `/cortex:tier gold`, `/cortex:tier silver`, or `/cortex:tier all`.

Valid values:
- **gold** — Only the 50 purpose-built gold templates (highest precision, fewer matches)
- **silver** — Gold + silver templates (default — full 350-template library)
- **all** — Everything including bronze/community templates

Steps:
1. Parse the tier argument (case-insensitive). If no argument or invalid value, show current setting and usage.
2. Read `.cortex/config.json` from the current working directory (create if doesn't exist).
3. Update the `min_tier` field.
4. Write back to `.cortex/config.json`.
5. Confirm the change.

Example output when setting a tier:
```
## prompt-cortex Tier

**Tier set to:** gold
- Only gold-tier templates will be matched (50 templates)
- Use `/cortex:tier silver` to restore full library (350 templates)
```

Example output when no argument provided:
```
## prompt-cortex Tier

**Current tier:** silver (default)
- Matching against 350 templates (50 gold + 300 silver)

Usage: `/cortex:tier gold|silver|all`
```

Config file format (`.cortex/config.json`):
```json
{
  "min_tier": "silver",
  "transparent": false
}
```
