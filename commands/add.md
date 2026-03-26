---
name: "cortex:add"
description: "Create a new prompt-cortex template from natural language — generates proper frontmatter, saves to the correct category directory, and rebuilds the index"
---

Create a new prompt template from the user's natural language description.

Usage: `/cortex:add` (then describe what the template should do)

Example: `/cortex:add a template for writing database migration scripts that checks for backwards compatibility`

Steps:

1. **Parse the user's description** to determine:
   - **Name**: Short descriptive name (e.g., "Database Migration")
   - **Category**: Best fit from: coding, ai-workflows, research, automation, content, productivity
   - **Action**: Best fit from: create, review, debug, refactor, explain, test, document, optimize, design, fix
   - **Object**: Best fit from: code, function, file, component, test, PR, commit, API, schema, prompt, config, error, architecture, database
   - **Triggers**: 3-5 keyword phrases that would match this template

2. **Generate the template** with proper frontmatter and a high-quality prompt body.

3. **Determine the ID**: Use pattern `{category}-{next_number}` where next_number is the highest existing ID in that category + 1. Check `data/prompts/{category}/` for existing files.

4. **Save** to `data/prompts/{category}/{id}.md`

5. **Validate** by running: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-template.sh <file>`

6. **Rebuild index**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/build-index.sh`

7. **Confirm** with the template details.

Template format:
```markdown
---
id: {id}
name: "{name}"
category: {category}
intent: {action}-{object}
action: {action}
object: {object}
triggers:
  - "{trigger1}"
  - "{trigger2}"
  - "{trigger3}"
quality_tier: bronze
token_overhead: {estimated}
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with: []
conflicts_with: []
---
{Generated prompt body — clear role, specific instructions, structured output format}
```

Note: User-created templates are always `quality_tier: bronze` by default. They can be promoted to silver/gold by editing the file.

Example output:
```
## prompt-cortex — Template Created

**ID:** coding-151
**Name:** Database Migration
**Category:** coding
**Intent:** create → database
**Triggers:** "database migration", "migration script", "schema migration"
**Tier:** bronze (user-created)

**Body preview:**
> You are a database migration specialist. Write migration scripts that...

Template saved to: `data/prompts/coding/coding-151.md`
Index rebuilt: 351 templates, 3200+ keys
```
