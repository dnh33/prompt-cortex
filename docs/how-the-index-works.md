# How the Index Works

prompt-cortex matches user prompts to templates in under 2 seconds using a pre-compiled inverted index — the same data structure that powers search engines. No LLM calls, no network requests. Pure `bash` + `jq`.

## The Pipeline

```
Template .md files
       │
       ▼
┌─────────────────┐
│  build-index.sh │  Pure-bash YAML parser extracts frontmatter
│                 │  from every template, converts to JSON,
│                 │  builds inverted keyword index
└────────┬────────┘
         │
         ▼
    index.json          Pre-compiled, ready for instant lookup
         │
         ▼
┌─────────────────┐
│    match.jq     │  User prompt comes in → keyword extraction →
│                 │  inverted index lookup → candidate scoring →
│                 │  confidence gating → inject or stay silent
└─────────────────┘
```

## Step 1: Build Time — The Inverted Index

When `build-index.sh` runs, it processes every template `.md` file:

### 1a. Parse YAML frontmatter (pure bash, no yq)

Each template has YAML frontmatter between `---` markers. The builder parses this character-by-character in bash — handling scalars, quoted strings, and simple arrays — and emits raw JSON. No external YAML parser needed.

```
data/prompts/coding/coding-001.md
    ↓ parse_yaml_frontmatter()
{"id":"coding-001","name":"Code Review","action":"review","object":"code",
 "triggers":["code review","review this","review my code",...], ...}
```

### 1b. Build the inverted index

For each template, every **trigger phrase** is decomposed into the index:

```
Template: coding-001 (Code Review)
Triggers: ["code review", "review this", "review my code", ...]

Index entries created:
  "code review"  → ["coding-001"]         (full phrase)
  "code"         → ["coding-001"]         (individual word, >2 chars)
  "review"       → ["coding-001"]         (individual word)
  "review this"  → ["coding-001"]         (full phrase)
  "review"       → ["coding-001"]         (already exists, deduped)
  ...

Also indexed:
  "review"       → ["coding-001"]         (from action field)
  "code"         → ["coding-001"]         (from object field)
```

The same word from different templates accumulates into arrays:

```
"review"  → ["coding-001", "coding-012", "coding-014", "coding-017", "coding-028"]
"debug"   → ["coding-002", "coding-007"]
"design"  → ["ai-051", "ai-056", "ai-058", "coding-006", "coding-013", ...]
```

With 50 templates, this produces **622 index keys** — a dense map from every meaningful word and phrase to the templates it could match.

### 1c. The output: index.json

```json
{
  "version": "f4fb19d7...",        // Hash of all template modification times
  "built": "2026-03-25T21:00:00Z",
  "template_count": 50,
  "templates": [ ... ],            // Full metadata for all 50 templates
  "inverted_index": {              // 622 keyword → template ID mappings
    "review": ["coding-001", "coding-012", "coding-014", "coding-017", "coding-028"],
    "code review": ["coding-001"],
    "debug": ["coding-002", "coding-007"],
    "design agent": ["ai-051"],
    ...
  }
}
```

## Step 2: Match Time — The 4-Phase Engine

When a user types a prompt, `match.jq` runs the full pipeline in a single `jq` invocation:

### Phase 0: Leave-It-Alone Detector

Before any matching, 12 signals check if the prompt should be left alone:

| Signal | Score | Example |
|--------|-------|---------|
| Slash command | 1.0 | `/commit`, `/help` |
| `--raw` flag | 1.0 | `--raw fix this` |
| `/cx off` state | 1.0 | Cortex disabled |
| Shell command | 0.60 | `git status`, `npm install` |
| XML tags present | 0.50 | `<context>...</context>` |
| Long + structured | 0.45 | 80+ words with headers/lists |
| Continuation | 0.45 | `ok`, `yes`, `looks good`, `ship it` |
| Role assignment | 0.40 | `you are a...`, `act as a...` |
| Conceptual question | 0.30 | `what is React?` |
| Numbered list | 0.15 | `1. Do this 2. Then that` |
| Output format | 0.10 | `respond in JSON` |

Scores combine via **max-of-top-2**: `min(1.0, top_score + second_score × 0.3)`. If the combined score ≥ 0.60, the prompt is left alone — no matching attempted.

### Phase 1: Keyword Extraction + Index Lookup

The prompt is lowercased, split into words and bigrams, then each is looked up in the inverted index:

```
User types: "review my code"

Words:   ["review", "my", "code"]
Bigrams: ["review my", "my code"]

Index lookups:
  "review"    → ["coding-001", "coding-012", "coding-014", "coding-017", "coding-028"]
  "my"        → (not in index, skipped)
  "code"      → ["coding-001", "coding-002", "coding-003", "coding-005", ...]
  "review my" → (not in index)
  "my code"   → (not in index)

Hit counting:
  coding-001: 2 hits (from "review" + "code")    ← top candidate
  coding-012: 1 hit  (from "review")
  coding-014: 1 hit  (from "review")
  coding-005: 1 hit  (from "code")
  ...
```

The top 10 candidates by hit count advance to scoring.

### Phase 2: Weighted Scoring

Each candidate template is scored against the prompt with weighted signals:

| Signal | Weight | What it checks |
|--------|--------|----------------|
| Action exact match | +0.45 | Prompt contains template's action word ("review") |
| Action via bigram | +0.20 | Action appears in a bigram |
| Action plural/suffix | +0.45/0.40 | "reviews", "reviewing" matches "review" |
| Object exact match | +0.35 | Prompt contains template's object word ("code") |
| Object via bigram | +0.15 | Object appears in a bigram |
| Keyword overlap | +0.02 each (max 0.08) | Trigger phrases found as substrings |
| Intent signal boost | +0.10 | Regex pattern matches (e.g., "review.*code") |
| Negative signal | -0.30 | Anti-pattern matches (e.g., "review meeting") |
| Complexity mismatch | -0.15 | Short prompt + high min_confidence |
| Multi-turn suppression | -0.40 | Same template injected 3+ times recently |

**Example scoring for "review my code" → coding-001:**
```
Action "review" in words:     +0.45
Object "code" in words:       +0.35
Trigger "review my code":     +0.02
Trigger "review this":        +0.00 (not in prompt)
Trigger "code review":        +0.02
Intent signal match:          +0.10
─────────────────────────────────────
Total:                         0.94  (capped contributions)
```

### Phase 3: Context Filter (v1.0 stub)

Reserved for v1.1+ — will filter by detected language/framework. Currently passes through.

### Confidence Gating

The final score determines the action:

| Confidence | Action | What happens |
|------------|--------|--------------|
| ≥ 0.70 | **inject** | Template body injected as `additionalContext` |
| 0.40 – 0.69 | **defer** | Hint injected ("patterns detected, below threshold") |
| < 0.40 | **skip** | Nothing happens |

Per-template `min_confidence` can only raise the inject threshold, never lower it.

## Why This Design

### Why an inverted index?

Iterating over 50 templates and checking every trigger against every prompt would be O(templates × triggers). The inverted index flips this: look up words → get candidates instantly. O(prompt_words × 1 lookup each). With 622 index keys, any word either hits or misses in constant time.

### Why pure bash + jq?

- **Zero dependencies.** No Python, Node, or package manager needed. Works everywhere bash and jq exist.
- **Fast.** The entire match pipeline runs in <2 seconds — well within Claude Code's 5-second hook timeout.
- **Portable.** Runs on macOS, Linux, and Windows (via Git Bash) without modification.

### Why YAML frontmatter in markdown?

- Templates are **human-readable** and **human-editable** — just markdown files.
- The YAML frontmatter is **machine-parseable** — structured metadata without a separate config file.
- Adding a template is as simple as creating a `.md` file. No database, no API, no registration.

### Why not just regex matching?

Regex alone can't score confidence. The inverted index + weighted scoring gives a nuanced signal: "review my code" scores 0.92 for coding-001 (code review) but only 0.12 for coding-012 (PR review). Simple regex would match both equally.

## The Numbers

- **50 templates** produce **622 index keys**
- Average template has **7 triggers**, each decomposed into ~4 index entries
- A typical prompt with 5 words generates ~9 lookups (5 words + 4 bigrams)
- The entire match pipeline: ~50-100ms in jq
- End-to-end hook execution: <2 seconds including bash startup and I/O
