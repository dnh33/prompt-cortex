---
name: "cortex:show"
description: "Display the full template body that prompt-cortex injected on your last prompt — shows exactly what Claude received as additional context"
---

Show the user the actual template content that was injected on their last prompt.

Steps:
1. Read the most recent state file from `.cortex/state-*.json` in the current working directory.
2. Extract `hookResult.best_match.id` to find which template was injected.
3. Extract `hookResult.action` — if it wasn't "inject", tell the user no template was injected.
4. Read the template file from `${CLAUDE_PLUGIN_ROOT}/data/prompts/` using the file path from the index.
5. Display the template body (everything after the second `---` in the .md file).
6. Also show the confidence score and template metadata.

Example output when a template was injected:
```
## prompt-cortex — Last Injection

**Template:** coding-001 (Code Review)
**Confidence:** 0.92
**Category:** coding | **Tier:** gold

### Injected Content

You are a senior engineer conducting a thorough code review. Evaluate the code with production-readiness in mind.

Review systematically:
1. **Correctness**: Logic errors, off-by-one bugs, unhandled edge cases
2. **Error handling**: Missing try/catch, unvalidated inputs, silent failures
3. **Naming & clarity**: Do names communicate intent? Is the code self-documenting?
4. **Performance**: Unnecessary allocations, N+1 queries, missing memoization
5. **Security**: Injection vectors, exposed secrets, unsafe deserialization

For each issue found, state: location, severity (critical/major/minor), and a concrete fix.

If no code is provided, ask the user to share the specific code they want reviewed.
```

Example output when nothing was injected:
```
## prompt-cortex — Last Injection

No template was injected on your last prompt.
- **Disposition:** suppressed (shell_command)
- **Leave-alone score:** 0.60

Use `/cortex:debug` for full scoring details.
```

If no state file exists, tell the user to send a prompt first.
