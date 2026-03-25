---
name: "cortex:sync"
description: "Rebuild the prompt-cortex template index — validates all templates, rebuilds index.json, and reports stats"
---

Rebuild the prompt-cortex template index from source templates.

Execute the following steps in order:

1. **Validate all templates**: Run the template validator on all template files:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-template.sh ${CLAUDE_PLUGIN_ROOT}/data/prompts/**/*.md
   ```
   Report any validation errors. If errors are found, list them but continue with the rebuild.

2. **Rebuild index**: Run the index builder:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/build-index.sh
   ```

3. **Report results**:
   ```
   ## prompt-cortex Sync Complete

   - Templates validated: N
   - Validation errors: N (list if any)
   - Index rebuilt: data/index.json
   - Template count: N
   - Index keys: N
   - Version hash: <hash>
   ```

If `${CLAUDE_PLUGIN_ROOT}` is not set, try to find the plugin root by looking for `.claude-plugin/plugin.json` in parent directories.

This command is useful after:
- Adding new templates
- Editing existing templates
- Pulling updates from the repository
