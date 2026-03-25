# Contributing to prompt-cortex

Templates are the core value of prompt-cortex. Adding high-quality templates is the most impactful contribution you can make.

## Template schema

Every template is a markdown file with YAML frontmatter. Here's the required schema:

### Required fields

```yaml
---
id: category-NNN            # Must match filename (e.g., coding-001.md → id: coding-001)
name: "Human-Readable Name"
category: coding             # One of: coding, ai-workflows, research, automation, content, productivity
intent: verb-noun            # e.g., review-code, debug-error, create-function
action: review               # One of: create, review, debug, refactor, explain, test, document, optimize, design, fix
object: code                 # One of: code, function, file, component, test, PR, commit, API, schema, prompt, config, error, architecture, database
triggers:                    # At least 3 trigger phrases (7+ recommended)
  - "code review"
  - "review this"
  - "review my code"
---
```

### Recommended fields

```yaml
intent_signals:              # Regex patterns that boost confidence (jq-compatible, NO \b)
  - "(^|[^a-zA-Z])(review|audit)(\\s|.){0,20}(code|PR)([^a-zA-Z]|$)"
negative_signals:            # Regex patterns that reduce confidence
  - "(^|[^a-zA-Z])review(\\s)(meeting|notes)([^a-zA-Z]|$)"
quality_tier: gold           # gold (best), silver, bronze
token_overhead: 180          # Estimated tokens the template body adds
min_confidence: 0.7          # Minimum confidence to inject (0.0-1.0)
composable_with:             # Template IDs this composes well with
  - "coding-003"
composition_role: primary    # primary or supporting
conflicts_with: []           # Template IDs that conflict
```

### Template body

The body (after the second `---`) is the actual prompt template injected into context. Guidelines:

- **Role framing**: Start with a senior expert persona ("You are a senior engineer...")
- **Systematic approach**: Use numbered steps
- **Conditional**: Include "If no X provided, ask the user..."
- **Target length**: 150-200 words (tokens ≈ words × 1.3)
- **No fluff**: Every sentence should add value

## Regex patterns

**CRITICAL**: jq's ONIG regex engine does NOT support `\b` word boundaries. Use this pattern instead:

```
(^|[^a-zA-Z])word([^a-zA-Z]|$)
```

Example — matching "review" followed by "code" within 20 chars:
```
(^|[^a-zA-Z])(review|audit)(\\s|.){0,20}(code|PR)([^a-zA-Z]|$)
```

## Adding a template

1. **Choose a category**: `data/prompts/coding/` or `data/prompts/ai-workflows/`
2. **Pick the next ID**: Look at existing files and increment
3. **Create the file**: `data/prompts/<category>/<id>.md`
4. **Write frontmatter**: Include all required fields
5. **Write the body**: Follow the guidelines above
6. **Validate**:
   ```bash
   bash scripts/validate-template.sh data/prompts/your-category/your-template.md
   ```
7. **Rebuild index**:
   ```bash
   bash scripts/build-index.sh
   ```
8. **Test matching**:
   ```bash
   jq -f scripts/match.jq \
     --arg prompt "your trigger phrase" \
     --arg state "null" \
     --arg cwd "" \
     data/index.json
   ```

## Quality tiers

- **Gold**: Full frontmatter, intent_signals, negative_signals, tested triggers, expert-level body. This is the bar for inclusion in the core library.
- **Silver**: Full frontmatter, good body, but may lack intent_signals or have fewer triggers.
- **Bronze**: Minimum frontmatter (7 required fields), basic body.

## Pull request guidelines

1. One PR per template (or per logical group of related templates)
2. Include the validation output in your PR description
3. Include at least one match test showing your template triggers correctly
4. Ensure no existing tests break: `bash tests/run-tests.sh`

## Development

```bash
# Run tests
bash tests/run-tests.sh

# Validate all templates
bash scripts/validate-template.sh data/prompts/**/*.md

# Rebuild index
bash scripts/build-index.sh

# Test matching
echo '{"session_id":"test","prompt":"your prompt","cwd":"."}' | \
  CLAUDE_PLUGIN_ROOT=. bash hooks/cortex-match
```

## Code of conduct

Be helpful, be kind, write good templates.
