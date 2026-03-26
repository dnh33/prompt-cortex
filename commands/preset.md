---
name: "cortex:preset"
description: "Manage prompt-cortex presets — activate, deactivate, list, or create custom presets"
allowed_tools: ["Read", "Write", "Glob", "Bash"]
---

# /cortex:preset — Preset Management

## Usage

- `/cortex:preset <name>` — Activate a preset (greenfield, maintenance, strict, learning)
- `/cortex:preset off` — Return to defaults (remove active preset)
- `/cortex:preset list` — Show all available presets with descriptions
- `/cortex:preset create <name>` — Save current boost/suppress config as custom preset

## How to execute

### `/cortex:preset <name>` or `/cortex:preset off`

1. Read `.cortex/config.json` (create if doesn't exist)
2. Set or remove the `preset` field
3. Write updated config
4. Confirm to user: "Preset `<name>` activated" or "Preset deactivated"

```bash
# Read current config
config=$(cat .cortex/config.json 2>/dev/null || echo '{}')
# Set preset
echo "$config" | jq --arg p "<name>" '.preset = $p' > .cortex/config.json
```

### `/cortex:preset list`

1. List built-in presets from the plugin's `data/presets/` directory
2. List custom presets from `.cortex/presets/` if they exist
3. Show each preset's name, description, boost/suppress rules, and whether active

### `/cortex:preset create <name>`

1. Read current `.cortex/config.json` or `.cortex/project.json`
2. Extract current boost/suppress rules
3. Save as `.cortex/presets/<name>.json`
4. Format: `{"name": "<name>", "description": "", "boost": [...], "suppress": [...], "min_confidence_adjust": 0}`

## Valid preset names (built-in)

- **greenfield**: New project development — boosts design, create, document
- **maintenance**: Bug fixes and quality — boosts debug, fix, refactor, optimize, test
- **strict**: Security-first — boosts review, test, fix; raises confidence threshold
- **learning**: Explanations — boosts explain, document; lowers confidence threshold
