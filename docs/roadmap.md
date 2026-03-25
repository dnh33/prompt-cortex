# prompt-cortex Roadmap

Future features and improvements. Items marked with priority.

## v1.1 — Control & Transparency

### Tier filtering — Turn quality tiers on/off (HIGH PRIORITY)
Users need control over which templates are active. The three tiers:
- **Gold** (50): Purpose-built, carefully tuned triggers and signals
- **Silver** (300): Adapted from external prompt library, solid but less precise
- **Bronze** (future): Community contributions meeting minimum requirements

**Implementation**: Add tier filtering to match.jq. Before scoring candidates, filter by minimum tier. Tier order: gold > silver > bronze.

**User controls**:
- `/cortex:tier gold` — only gold templates (minimal, highest confidence)
- `/cortex:tier silver` — gold + silver (default — full library)
- `/cortex:tier all` — everything including bronze
- Persist choice in `.cortex/config.json` so it survives sessions

**In match.jq**: Add early filter after `keyword_candidates`:
```
# Filter by minimum tier
($candidates | map(select(
  .quality_tier as $t |
  if $min_tier == "gold" then $t == "gold"
  elif $min_tier == "silver" then ($t == "gold" or $t == "silver")
  else true end
)))
```

**Why this matters**: Some users want the full 350-template coverage. Others want only the curated 50. This is a core control lever, not a nice-to-have.

### `/cortex:show` — See what was injected (HIGH PRIORITY)
Some users will be uncomfortable with invisible injection. They need a way to see exactly what cortex added to their last prompt — not just debug metadata, but the actual template body that was injected.

**Proposal**: `/cortex:show` displays the full injected template from the last prompt in a clear, non-intrusive format. Different from `/cortex:debug` which shows scoring internals — this shows the actual content Claude received.

**Stretch**: `/cortex:transparent` toggle that always shows a brief summary of what was injected after each response. Like a quiet footer: `[cortex: applied coding-001 "Code Review" @ 0.92]`. Users who want full visibility can enable this; everyone else stays invisible.

**Why this matters**: The spec says "invisible" but trust requires an opt-in transparency path. People who can see the magic are more likely to trust and recommend it. The ones who are scared of "hidden prompt injection" need to be able to verify.

### `/cortex:suggest` — CLAUDE.md integration
Scan CLAUDE.md using LLM call, propose boost/suppress rules for templates based on project conventions. User reviews and accepts.

### Intent signal fix
Fix double-escaping of backslashes in build-index.sh YAML parser. Currently `\\s` in template frontmatter becomes `\\\\s` in index.json, breaking regex matching. Matching still works via action/keyword scoring but intent signals are effectively dead.

### Reject-signal boosting
If user sends 2+ `--raw` rejections in last 10 prompts, boost leave-alone base score by +0.10 per rejection (max +0.25). Learns that user doesn't want injection right now.

### Token budget enforcement
After reading template body, estimate token count (words * 1.3). If >300 tokens, truncate at last sentence boundary before 300. Log truncation.

## v1.2 — Context Awareness

### Project context filtering (Phase 3 in match.jq)
Use detected language/framework from SessionStart to filter templates. TypeScript projects boost TS-relevant templates, Python projects suppress JS-specific ones.

### `.cortex/project.json` configuration
Manual config for tech stack, boost/suppress rules, quality tier minimum.

## v2.0 — The Brain (Layer 2)

### `/cortex:optimize` — Deep prompt optimization
On-demand agent that composes multi-template prompts, applies Anthropic's 6 techniques, handles complex requests that Layer 1 can't match with single templates.

### `/cortex:chain` — Prompt decomposition
Decomposes complex requests into prompt chains. The "wow feature" from the original spec.

### Automatic CLAUDE.md parsing
SessionStart hook extracts conventions from CLAUDE.md and writes boost/suppress rules automatically. Requires LLM classification.

### Adaptive Prompt Memory
Cross-session learning: track which templates produce good results (via user feedback signals) and adjust confidence scores over time.
