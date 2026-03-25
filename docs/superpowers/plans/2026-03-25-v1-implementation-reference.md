I cannot write to the plan file since this is a READ-ONLY task. I'll deliver the complete plan inline.

---

# prompt-cortex v1.0 Plan A: Core Engine Implementation Plan

## Overview

This plan covers 12 tasks that build the core engine infrastructure. Each task is self-contained and executable by a subagent with zero prior context. Tasks are ordered by dependency: earlier tasks create files that later tasks depend on.

## Architecture Summary

The system works as follows:
1. **SessionStart hook** fires when Claude Code starts. It validates the template index, detects project context, cleans stale state, and injects a one-time onboarding message.
2. **UserPromptSubmit hook** fires on every prompt. It reads stdin JSON, runs the leave-it-alone detector, performs 3-phase matching via jq, and either injects the best template as `additionalContext` or stays silent.
3. **Index builder** pre-compiles `index.json` from template `.md` files, extracting YAML frontmatter and building an inverted keyword index.
4. **Shared state** in `.cortex/state-{session_id}.json` bridges hook runs and tracks recent injections.
5. **Telemetry** appends to `.cortex/usage.jsonl` (local only, no prompt content).

## Key Technical Decisions

1. **jq regex**: `\b` word boundaries do NOT work in jq's regex engine. All regex patterns must use `(^|[^a-zA-Z])word([^a-zA-Z]|$)` instead. The `intent_signals` field in templates must use this format, NOT `\b`.

2. **State file fallback**: `jq --slurpfile` crashes when the file doesn't exist. The hook must create a default state file if missing, or pass state as `--argjson`.

3. **YAML parsing in bash**: No `yq` available. A constrained YAML parser in pure bash handles the flat frontmatter schema (scalar values + simple arrays).

4. **printf over heredoc**: Bash 5.3+ has a heredoc variable expansion bug with large content (superpowers hit this). Use `printf` for JSON output.

5. **Extensionless hook scripts**: Following superpowers' pattern. Scripts named `cortex-match` and `cortex-session-init` (no `.sh` extension) to prevent Windows auto-detection interference.

---

## File Creation Order

```
Phase 1: Scaffold
  T01: .claude-plugin/plugin.json
  T02: hooks/hooks.json
  T03: hooks/run-hook.cmd

Phase 2: Data Layer
  T04: data/intents.json
  T05: data/prompts/coding/coding-001.md
       data/prompts/coding/coding-002.md
       data/prompts/coding/coding-003.md
  T06: scripts/validate-template.sh
  T07: scripts/build-index.sh → produces data/index.json

Phase 3: Core Engine
  T08: scripts/match.jq
  T09: hooks/cortex-match (UserPromptSubmit hook)
  T10: hooks/cortex-session-init (SessionStart hook)

Phase 4: Testing
  T11: tests/run-tests.sh (integration test suite)

Phase 5: Finalization
  T12: .gitignore, LICENSE
```

---

## Task 01: Plugin Manifest

**Creates**: `.claude-plugin/plugin.json`
**Depends on**: Nothing
**Time**: 2 min

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\.claude-plugin\plugin.json`**
```json
{
  "name": "prompt-cortex",
  "version": "1.0.0",
  "description": "Invisible prompt intelligence layer for Claude Code. Matches user input against proven prompt patterns and silently injects optimal framing as context.",
  "author": {
    "name": "Daniel Hjermitslev",
    "url": "https://github.com/dnh33"
  },
  "repository": "https://github.com/dnh33/prompt-cortex",
  "homepage": "https://github.com/dnh33/prompt-cortex",
  "license": "MIT",
  "keywords": ["prompts", "optimization", "prompt-engineering", "templates", "context-injection"]
}
```

**Verification**: `jq . .claude-plugin/plugin.json` should parse without error.

**Commit point**: "scaffold: add plugin manifest"

---

## Task 02: Hook Registration

**Creates**: `hooks/hooks.json`
**Depends on**: Nothing
**Time**: 2 min

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\hooks.json`**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" cortex-session-init",
            "timeout": 15
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" cortex-match",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Key details:
- Path is quoted for Windows spaces in `${CLAUDE_PLUGIN_ROOT}`
- `run-hook.cmd` takes extensionless script name as argument (matching superpowers pattern)
- `UserPromptSubmit` has NO `matcher` field -- it catches all prompts (our own matching engine handles filtering)
- `SessionStart` uses `"startup|clear|compact"` to re-initialize on session restarts
- `timeout: 5` for UserPromptSubmit (our target is <2s, 5s gives margin)
- `timeout: 15` for SessionStart (index validation + state cleanup)

**Verification**: `jq . hooks/hooks.json` should parse without error.

---

## Task 03: Cross-Platform Polyglot Wrapper

**Creates**: `hooks/run-hook.cmd`
**Depends on**: Nothing
**Time**: 3 min

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\run-hook.cmd`**
```cmd
: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for prompt-cortex hook scripts.
REM On Windows: cmd.exe runs the batch portion, finds bash, delegates.
REM On Unix: the shell interprets this as a script (: is a no-op in bash).
REM
REM Usage: run-hook.cmd <script-name> [args...]

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

REM Try Git for Windows bash in standard locations
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM Try bash on PATH (MSYS2, Cygwin, WSL)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM No bash found - exit silently (plugin degrades gracefully)
exit /b 0
CMDBLOCK

# Unix: run the named script directly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

This is identical to superpowers' `run-hook.cmd` -- proven to work on Windows, macOS, and Linux.

**Verification**: On Unix: `bash hooks/run-hook.cmd echo "hello"` should not error. On Windows: `cmd /c hooks\run-hook.cmd echo "hello"` should not error.

**Post-creation**: `chmod +x hooks/run-hook.cmd` (needed for Unix).

**Commit point**: "scaffold: add hooks.json and cross-platform wrapper"

---

## Task 04: Intent Taxonomy

**Creates**: `data/intents.json`
**Depends on**: Nothing
**Time**: 3 min

This file defines the closed taxonomy of actions and objects used for matching. It serves as reference for template authors and is loaded by `match.jq` for validation.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\data\intents.json`**
```json
{
  "version": 1,
  "actions": [
    "create",
    "review",
    "debug",
    "refactor",
    "explain",
    "test",
    "document",
    "optimize",
    "design",
    "fix"
  ],
  "objects": [
    "code",
    "function",
    "file",
    "component",
    "test",
    "PR",
    "commit",
    "API",
    "schema",
    "prompt",
    "config",
    "error",
    "architecture",
    "database"
  ],
  "categories": [
    "coding",
    "ai-workflows",
    "research",
    "automation",
    "content",
    "productivity"
  ],
  "action_synonyms": {
    "create": ["build", "make", "generate", "write", "implement", "add", "scaffold"],
    "review": ["check", "audit", "look at", "examine", "inspect", "evaluate"],
    "debug": ["fix", "troubleshoot", "investigate", "diagnose", "trace", "find bug"],
    "refactor": ["clean up", "restructure", "reorganize", "improve", "simplify"],
    "explain": ["what is", "how does", "why", "describe", "tell me about", "walk through"],
    "test": ["write tests", "add tests", "test coverage", "unit test", "integration test"],
    "document": ["add docs", "document", "write docs", "JSDoc", "README"],
    "optimize": ["speed up", "improve performance", "make faster", "reduce", "profile"],
    "design": ["architect", "plan", "structure", "model", "blueprint"],
    "fix": ["resolve", "repair", "patch", "correct", "handle"]
  },
  "object_synonyms": {
    "code": ["codebase", "source", "implementation", "logic"],
    "function": ["method", "handler", "callback", "routine", "procedure"],
    "file": ["module", "script", "source file"],
    "component": ["widget", "element", "view", "page", "screen"],
    "test": ["spec", "test suite", "test case", "unit test"],
    "API": ["endpoint", "route", "REST", "GraphQL", "service"],
    "error": ["bug", "issue", "exception", "crash", "failure"],
    "config": ["configuration", "settings", "env", "environment"]
  }
}
```

**Verification**: `jq '.actions | length' data/intents.json` should output `10`.

**Commit point**: "data: add intent taxonomy"

---

## Task 05: Three Sample Templates

**Creates**:
- `data/prompts/coding/coding-001.md` (Code Review)
- `data/prompts/coding/coding-002.md` (Debug Error)
- `data/prompts/coding/coding-003.md` (Write Tests)

**Depends on**: Nothing
**Time**: 5 min

These are gold-tier templates with full frontmatter. They are the minimum viable set for testing the engine.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\data\prompts\coding\coding-001.md`**
```markdown
---
id: coding-001
name: "Code Review"
category: coding
intent: review-code
action: review
object: code
triggers:
  - "code review"
  - "review this"
  - "review my code"
  - "review the code"
  - "look at this code"
  - "check this code"
  - "audit this"
intent_signals:
  - "(^|[^a-zA-Z])(review|audit|check|examine|inspect)(\\s|.){0,20}(code|PR|pull request|function|class|module)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])review(\\s)(meeting|notes|book|document)([^a-zA-Z]|$)"
quality_tier: gold
token_overhead: 180
min_confidence: 0.7
composable_with:
  - "coding-003"
composition_role: primary
conflicts_with: []
---
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

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\data\prompts\coding\coding-002.md`**
```markdown
---
id: coding-002
name: "Debug Error"
category: coding
intent: debug-error
action: debug
object: error
triggers:
  - "debug"
  - "not working"
  - "find the bug"
  - "fix this error"
  - "why is this failing"
  - "troubleshoot"
  - "investigate"
intent_signals:
  - "(^|[^a-zA-Z])(debug|troubleshoot|investigate|diagnose)(\\s|.){0,20}(error|bug|issue|failure|crash|problem)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(not|isn.t|doesn.t|won.t|can.t)(\\s)(work|load|compile|run|start|connect|render)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])debug(\\s)(mode|flag|log|level|output)([^a-zA-Z]|$)"
quality_tier: gold
token_overhead: 170
min_confidence: 0.7
composable_with:
  - "coding-003"
composition_role: primary
conflicts_with:
  - "coding-001"
---
You are a senior engineer systematically debugging a problem. Do not guess -- trace the issue methodically.

Investigation approach:
1. **Reproduce**: Identify the exact steps and conditions that trigger the failure
2. **Isolate**: Narrow down to the specific module, function, or line causing the issue
3. **Trace**: Follow the execution path from entry point through the failure
4. **Root cause**: State the precise root cause before proposing any fix
5. **Fix**: Propose a minimal, targeted fix that addresses the root cause

Think through each step before concluding. Show your reasoning at each stage.

If no error or code is provided, ask what the expected vs actual behavior is.
```

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\data\prompts\coding\coding-003.md`**
```markdown
---
id: coding-003
name: "Write Tests"
category: coding
intent: write-tests
action: test
object: code
triggers:
  - "write tests"
  - "add tests"
  - "test this"
  - "unit test"
  - "test coverage"
  - "write unit tests"
  - "add test cases"
intent_signals:
  - "(^|[^a-zA-Z])(write|add|create|generate)(\\s|.){0,15}(tests?|specs?|test cases?)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(unit|integration|e2e|end.to.end)(\\s)(tests?|specs?)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])(test)(\\s)(environment|server|database|deploy)([^a-zA-Z]|$)"
quality_tier: gold
token_overhead: 190
min_confidence: 0.7
composable_with:
  - "coding-001"
  - "coding-002"
composition_role: primary
conflicts_with: []
---
You are a senior QA engineer writing comprehensive tests. Tests are documentation -- they describe what the code SHOULD do.

Testing strategy:
1. **Happy path**: The primary use case works correctly with valid inputs
2. **Edge cases**: Boundary values, empty inputs, max-length inputs, unicode
3. **Error cases**: Invalid inputs, missing required fields, network failures, timeouts
4. **State transitions**: Before/after side effects, concurrent access, cleanup

Naming convention: test names describe behavior, not implementation.
Example: `test_returns_empty_list_when_no_items_match_filter` not `test_filter_function`

If no code is provided, ask the user to share the code they want tests for.
```

**Verification**: Each file should have valid YAML between `---` markers. Verify with: `head -20 data/prompts/coding/coding-001.md`

**Commit point**: "data: add 3 sample gold-tier templates"

---

## Task 06: Template Validator

**Creates**: `scripts/validate-template.sh`
**Depends on**: T05 (templates to validate)
**Time**: 5 min

This script validates that a template `.md` file has all required frontmatter fields.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\scripts\validate-template.sh`**
```bash
#!/usr/bin/env bash
# validate-template.sh — Validates template .md files have required frontmatter
# Usage: validate-template.sh <file.md> [file2.md ...]
# Exit 0: all valid. Exit 1: validation errors found.

set -euo pipefail

REQUIRED_FIELDS=("id" "name" "category" "intent" "action" "object" "triggers")
VALID_CATEGORIES=("coding" "ai-workflows" "research" "automation" "content" "productivity")
VALID_ACTIONS=("create" "review" "debug" "refactor" "explain" "test" "document" "optimize" "design" "fix")

errors=0

validate_file() {
  local file="$1"
  local file_errors=0

  # Check file exists
  if [[ ! -f "$file" ]]; then
    echo "ERROR: File not found: $file"
    return 1
  fi

  # Extract YAML frontmatter (between first two --- lines)
  local in_frontmatter=false
  local frontmatter=""
  local line_num=0
  local found_start=false
  local found_end=false

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" == "---" ]]; then
      if ! $found_start; then
        found_start=true
        continue
      else
        found_end=true
        break
      fi
    fi
    if $found_start && ! $found_end; then
      frontmatter+="$line"$'\n'
    fi
  done < "$file"

  if ! $found_start || ! $found_end; then
    echo "ERROR [$file]: Missing YAML frontmatter delimiters (---)"
    return 1
  fi

  # Check body exists (content after second ---)
  local body_lines
  body_lines=$(tail -n +"$((line_num + 1))" "$file" | grep -c '[^ ]' 2>/dev/null || echo "0")
  if [[ "$body_lines" -eq 0 ]]; then
    echo "ERROR [$file]: Empty template body (no content after frontmatter)"
    file_errors=$((file_errors + 1))
  fi

  # Parse scalar fields from frontmatter
  local -A fields
  local current_key=""
  local in_array=false
  local array_count=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # Array item
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      if $in_array; then
        array_count=$((array_count + 1))
      fi
      continue
    fi

    # Flush array
    if $in_array; then
      fields["$current_key"]="ARRAY:$array_count"
      in_array=false
      array_count=0
    fi

    # Key: value
    if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*):(.*)$ ]]; then
      current_key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      val="${val#"${val%%[![:space:]]*}"}"  # trim leading whitespace
      val="${val#\"}"  # strip quotes
      val="${val%\"}"

      if [[ -z "$val" ]]; then
        in_array=true
        array_count=0
      else
        fields["$current_key"]="$val"
      fi
    fi
  done <<< "$frontmatter"

  # Flush final array
  if $in_array; then
    fields["$current_key"]="ARRAY:$array_count"
  fi

  # Check required fields
  for field in "${REQUIRED_FIELDS[@]}"; do
    if [[ -z "${fields[$field]+x}" ]]; then
      echo "ERROR [$file]: Missing required field: $field"
      file_errors=$((file_errors + 1))
    fi
  done

  # Validate category
  if [[ -n "${fields[category]+x}" ]]; then
    local valid=false
    for cat in "${VALID_CATEGORIES[@]}"; do
      if [[ "${fields[category]}" == "$cat" ]]; then
        valid=true
        break
      fi
    done
    if ! $valid; then
      echo "ERROR [$file]: Invalid category '${fields[category]}'. Must be one of: ${VALID_CATEGORIES[*]}"
      file_errors=$((file_errors + 1))
    fi
  fi

  # Validate action
  if [[ -n "${fields[action]+x}" ]]; then
    local valid=false
    for act in "${VALID_ACTIONS[@]}"; do
      if [[ "${fields[action]}" == "$act" ]]; then
        valid=true
        break
      fi
    done
    if ! $valid; then
      echo "ERROR [$file]: Invalid action '${fields[action]}'. Must be one of: ${VALID_ACTIONS[*]}"
      file_errors=$((file_errors + 1))
    fi
  fi

  # Validate triggers has at least 3 entries
  if [[ -n "${fields[triggers]+x}" ]]; then
    local trigger_count="${fields[triggers]#ARRAY:}"
    if [[ "$trigger_count" =~ ^[0-9]+$ ]] && [[ "$trigger_count" -lt 3 ]]; then
      echo "ERROR [$file]: triggers must have at least 3 entries (found $trigger_count)"
      file_errors=$((file_errors + 1))
    fi
  fi

  # Validate id matches filename
  if [[ -n "${fields[id]+x}" ]]; then
    local basename
    basename=$(basename "$file" .md)
    if [[ "${fields[id]}" != "$basename" ]]; then
      echo "WARN  [$file]: id '${fields[id]}' does not match filename '$basename'"
    fi
  fi

  if [[ "$file_errors" -eq 0 ]]; then
    echo "OK    [$file]"
  fi

  return "$file_errors"
}

# Main
if [[ $# -eq 0 ]]; then
  echo "Usage: validate-template.sh <file.md> [file2.md ...]"
  echo "       validate-template.sh data/prompts/**/*.md"
  exit 1
fi

for file in "$@"; do
  validate_file "$file" || errors=$((errors + 1))
done

if [[ "$errors" -gt 0 ]]; then
  echo ""
  echo "FAILED: $errors file(s) with errors"
  exit 1
else
  echo ""
  echo "PASSED: All files valid"
  exit 0
fi
```

**Post-creation**: `chmod +x scripts/validate-template.sh`

**Verification**:
```bash
bash scripts/validate-template.sh data/prompts/coding/coding-001.md
# Expected: OK    [data/prompts/coding/coding-001.md]
```

**Commit point**: "scripts: add template validator"

---

## Task 07: Index Builder

**Creates**: `scripts/build-index.sh`, produces `data/index.json`
**Depends on**: T05 (templates), T04 (intents.json)
**Time**: 8 min

This is the most complex bash script. It reads all template `.md` files, extracts YAML frontmatter using pure bash, converts to JSON, builds the inverted keyword index, and writes `data/index.json`.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\scripts\build-index.sh`**
```bash
#!/usr/bin/env bash
# build-index.sh — Compiles index.json from template .md files
# Usage: build-index.sh [prompts_dir] [output_file]
# Defaults: prompts_dir=data/prompts, output_file=data/index.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROMPTS_DIR="${1:-${PLUGIN_ROOT}/data/prompts}"
OUTPUT_FILE="${2:-${PLUGIN_ROOT}/data/index.json}"

# --- Pure-bash YAML frontmatter parser ---
# Handles: scalar values, simple arrays (- "item"), quoted and unquoted values
# Does NOT handle: nested objects, multi-line values, YAML anchors
parse_yaml_frontmatter() {
  local file="$1"
  local in_frontmatter=false
  local found_start=false
  local found_end=false
  local json="{"
  local first=true
  local in_array=false
  local array_key=""
  local array_vals=""
  local line_num=0

  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" == "---" ]]; then
      if ! $found_start; then
        found_start=true
        continue
      else
        found_end=true
        break
      fi
    fi
    if ! $found_start; then continue; fi

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Array item (starts with whitespace + "- ")
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      local val="${BASH_REMATCH[1]}"
      # Strip surrounding quotes
      val="${val#\"}"
      val="${val%\"}"
      val="${val#\'}"
      val="${val%\'}"
      # Escape backslashes and quotes for JSON
      val="${val//\\/\\\\}"
      val="${val//\"/\\\"}"
      if [[ -n "$array_vals" ]]; then
        array_vals="${array_vals},\"${val}\""
      else
        array_vals="\"${val}\""
      fi
      continue
    fi

    # Flush previous array if we hit a non-array line
    if $in_array; then
      if ! $first; then json+=","; fi
      first=false
      json+="\"${array_key}\":[${array_vals}]"
      in_array=false
      array_vals=""
    fi

    # Key: value pair
    if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*):(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      # Trim leading whitespace
      val="${val#"${val%%[![:space:]]*}"}"

      if [[ -z "$val" ]]; then
        # Array declaration (values on subsequent lines)
        in_array=true
        array_key="$key"
        array_vals=""
        continue
      fi

      # Strip surrounding quotes
      val="${val#\"}"
      val="${val%\"}"
      val="${val#\'}"
      val="${val%\'}"
      # Escape for JSON
      val="${val//\\/\\\\}"
      val="${val//\"/\\\"}"

      if ! $first; then json+=","; fi
      first=false
      json+="\"${key}\":\"${val}\""
    fi
  done < "$file"

  # Flush final array
  if $in_array; then
    if ! $first; then json+=","; fi
    json+="\"${array_key}\":[${array_vals}]"
  fi

  json+="}"
  printf '%s' "$json"
}

# --- Extract template body (everything after second ---) ---
get_body_token_estimate() {
  local file="$1"
  local in_body=false
  local dash_count=0
  local word_count=0

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      dash_count=$((dash_count + 1))
      if [[ "$dash_count" -ge 2 ]]; then
        in_body=true
        continue
      fi
    fi
    if $in_body; then
      # Rough token estimate: word count * 1.3
      local words
      words=$(echo "$line" | wc -w)
      word_count=$((word_count + words))
    fi
  done < "$file"

  # Rough token estimate
  echo $(( (word_count * 13 + 9) / 10 ))
}

# --- Get relative path from prompts dir ---
get_relative_path() {
  local file="$1"
  local base="$2"
  # Remove base prefix
  echo "${file#"$base"/}"
}

# --- Main ---
echo "Building index from: $PROMPTS_DIR"

# Find all template .md files
template_files=()
while IFS= read -r -d '' file; do
  template_files+=("$file")
done < <(find "$PROMPTS_DIR" -name "*.md" -type f -print0 | sort -z)

if [[ ${#template_files[@]} -eq 0 ]]; then
  echo "ERROR: No template files found in $PROMPTS_DIR"
  exit 1
fi

echo "Found ${#template_files[@]} template(s)"

# Build version hash from all template modification times
version_input=""
for file in "${template_files[@]}"; do
  mtime=$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file" 2>/dev/null)
  version_input+="${file}:${mtime};"
done
# Use simple hash (sha256 if available, md5 as fallback, or cksum)
if command -v sha256sum &>/dev/null; then
  version_hash=$(printf '%s' "$version_input" | sha256sum | cut -d' ' -f1)
elif command -v shasum &>/dev/null; then
  version_hash=$(printf '%s' "$version_input" | shasum -a 256 | cut -d' ' -f1)
else
  version_hash=$(printf '%s' "$version_input" | cksum | cut -d' ' -f1)
fi

# Parse each template and collect as JSON array
templates_json="[]"
inverted_index_input=""

for file in "${template_files[@]}"; do
  echo "  Processing: $(basename "$file")"

  # Parse frontmatter
  frontmatter_json=$(parse_yaml_frontmatter "$file")

  # Validate required fields exist
  local_id=$(printf '%s' "$frontmatter_json" | jq -r '.id // empty')
  if [[ -z "$local_id" ]]; then
    echo "  WARN: Skipping $file — no 'id' in frontmatter"
    continue
  fi

  # Get relative file path
  rel_path=$(get_relative_path "$file" "$PROMPTS_DIR")

  # Compute defaults for optional fields
  templates_json=$(printf '%s' "$templates_json" | jq \
    --argjson tmpl "$frontmatter_json" \
    --arg file_path "$rel_path" \
    '. + [$tmpl + {
      file: $file_path,
      quality_tier: ($tmpl.quality_tier // "bronze"),
      min_confidence: (($tmpl.min_confidence // "0.7") | tonumber),
      token_overhead: (($tmpl.token_overhead // "200") | tonumber),
      composable_with: ($tmpl.composable_with // []),
      composition_role: ($tmpl.composition_role // "primary"),
      conflicts_with: ($tmpl.conflicts_with // []),
      intent_signals: ($tmpl.intent_signals // []),
      negative_signals: ($tmpl.negative_signals // [])
    }]')
done

# Build inverted index from triggers
# Map each trigger keyword/phrase to template IDs
inverted_index=$(printf '%s' "$templates_json" | jq '
  reduce .[] as $tmpl ({};
    . as $idx |
    ($tmpl.triggers // []) as $triggers |
    reduce $triggers[] as $trigger ($idx;
      # Add the full trigger phrase
      .[$trigger] = ((.[$trigger] // []) + [$tmpl.id]) |
      # Also add individual words from multi-word triggers
      reduce ($trigger | split(" ")[]) as $word (.;
        if ($word | length) > 2 then
          .[$word] = ((.[$word] // []) + [$tmpl.id])
        else . end
      )
    ) |
    # Also index by action and object
    .[$tmpl.action] = ((.[$tmpl.action] // []) + [$tmpl.id]) |
    .[$tmpl.object] = ((.[$tmpl.object] // []) + [$tmpl.id])
  ) |
  # Deduplicate arrays
  with_entries(.value |= unique)
')

# Compose final index
built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

final_index=$(jq -n \
  --arg version "$version_hash" \
  --arg built "$built_at" \
  --argjson templates "$templates_json" \
  --argjson inverted "$inverted_index" \
  '{
    version: $version,
    built: $built,
    template_count: ($templates | length),
    templates: $templates,
    inverted_index: $inverted
  }')

# Write output
printf '%s\n' "$final_index" > "$OUTPUT_FILE"

echo "Index built: $OUTPUT_FILE"
echo "  Templates: $(printf '%s' "$final_index" | jq '.template_count')"
echo "  Index keys: $(printf '%s' "$final_index" | jq '.inverted_index | keys | length')"
echo "  Version: ${version_hash:0:16}..."
```

**Post-creation**: `chmod +x scripts/build-index.sh`

**Verification**:
```bash
bash scripts/build-index.sh
# Expected output:
# Building index from: .../data/prompts
# Found 3 template(s)
#   Processing: coding-001.md
#   Processing: coding-002.md
#   Processing: coding-003.md
# Index built: .../data/index.json
#   Templates: 3
#   Index keys: <some number>
#   Version: <hash>...

# Verify index structure:
jq '.templates[0].id' data/index.json
# Expected: "coding-001"

jq '.inverted_index["review"]' data/index.json
# Expected: ["coding-001"]

jq '.inverted_index["debug"]' data/index.json
# Expected: ["coding-002"]
```

**Commit point**: "scripts: add index builder"

---

## Task 08: Matching Engine (match.jq)

**Creates**: `scripts/match.jq`
**Depends on**: T07 (index.json must exist for testing)
**Time**: 10 min

This is the core intelligence of prompt-cortex. A pure jq program that implements:
1. Leave-it-alone detector
2. 3-phase matching algorithm
3. Scoring with weighted signals
4. Confidence threshold gating

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\scripts\match.jq`**
```jq
# match.jq — Core matching engine for prompt-cortex
# Input: index.json (via file)
# Arguments:
#   $prompt  — the user's raw prompt text
#   $state   — JSON string of current session state (or "null")
#   $cwd     — current working directory (or "")
#
# Output: JSON with matching result
#   { "action": "inject"|"defer"|"suppress"|"skip"|"escape",
#     "confidence": <float>,
#     "best_match": { template object } | null,
#     "candidates": [ { id, confidence } ],
#     "leave_alone_score": <float>,
#     "leave_alone_reason": "<reason>" }

# ===== Helper functions =====

def prompt_lower: $prompt | ascii_downcase;

def prompt_words: prompt_lower | split(" ") | map(select(length > 0));

def prompt_word_count: prompt_words | length;

def prompt_bigrams:
  prompt_words as $w |
  [range($w | length - 1) as $i | "\($w[$i]) \($w[$i+1])"];

# Check if state has recent injections of a template
def recently_injected($tmpl_id):
  if $state == null or $state == "null" then false
  elif ($state | type) != "object" then false
  else
    ($state.recentInjections // []) |
    map(select(.template == $tmpl_id)) |
    length >= 3
  end;

# Check if cortex is disabled via /cx off
def cortex_disabled:
  if $state == null or $state == "null" then false
  elif ($state | type) != "object" then false
  else ($state.cortex_disabled // false)
  end;

# ===== Phase 0: Leave-it-alone detector =====
# Returns { score: float, reason: string }

def leave_it_alone:
  prompt_lower as $p |
  prompt_word_count as $wc |

  # Collect all detector scores
  [
    # Slash command prefix
    (if ($p | test("^/[a-z]")) then { score: 1.0, reason: "slash_command" } else null end),

    # --raw flag
    (if ($p | test("^--raw(\\s|$)")) then { score: 1.0, reason: "raw_flag" } else null end),

    # /cx off state (checked via state)
    (if cortex_disabled then { score: 1.0, reason: "cx_off" } else null end),

    # Already has XML tags
    (if ($p | test("<[a-z][a-z0-9_-]*[^>]*>")) then { score: 0.50, reason: "has_xml_tags" } else null end),

    # Looks like a shell command
    (if ($p | test("^(git|npm|yarn|pnpm|pip|cargo|make|docker|kubectl|cd|ls|cat|mkdir|mv|cp|rm|chmod|curl|wget|ssh|scp)\\s")) then { score: 0.60, reason: "shell_command" } else null end),

    # Continuation prompt
    (if ($p | test("^(ok|okay|yes|yep|yeah|sure|go ahead|do it|looks good|that works|next|also|and also|continue|proceed|perfect|great|thanks|thank you|lgtm|ship it|merge it)$")) then { score: 0.45, reason: "continuation" } else null end),

    # Already has role assignment
    (if ($p | test("(^|[^a-zA-Z])(you are|act as|pretend to be|as a|role:)")) then { score: 0.40, reason: "has_role" } else null end),

    # Conceptual question
    (if ($p | test("^(what is|what are|how does|how do|why does|why do|explain|tell me about|describe|define)\\s")) then { score: 0.30, reason: "conceptual_question" } else null end),

    # Already has numbered list
    (if ($p | test("(^|\\n)[0-9]+\\.\\s")) then { score: 0.15, reason: "has_numbered_list" } else null end),

    # Already specifies output format
    (if ($p | test("(format|output|respond|reply|answer)(\\s+)(as|in|with|using)(\\s+)(json|yaml|markdown|csv|table|list|bullet)")) then { score: 0.10, reason: "specifies_format" } else null end),

    # Long + structured (>80 words AND >=2 structural markers)
    (if ($wc > 80) and (
        [ ($p | test("(^|\\n)[0-9]+\\.")),
          ($p | test("<[a-z]")),
          ($p | test("(^|\\n)-\\s")),
          ($p | test("(^|\\n)##")),
          ($p | test("```"))
        ] | map(select(.)) | length >= 2
      ) then { score: 0.45, reason: "long_structured" }
      else null end)
  ] |

  # Remove nulls and compute max-of-top-2
  map(select(. != null)) |
  sort_by(-.score) |
  if length == 0 then { score: 0, reason: "none" }
  elif length == 1 then .[0]
  else
    # max-of-top-2: max(top_1, top_2 * 0.5) -- but since top_1 >= top_2,
    # the result is always top_1 unless top_2 * 0.5 > top_1 (impossible).
    # Actually the formula is: max(top_1, top_2 * 0.5) which is always top_1.
    # The real intent is: score = top_1 + (top_2 * 0.5) clamped to 1.0
    # Let's use: score = min(1.0, .[0].score + .[1].score * 0.3)
    { score: ([1.0, (.[0].score + .[1].score * 0.3)] | min),
      reason: .[0].reason }
  end;

# ===== Phase 1: Keyword extraction + inverted index lookup =====

def keyword_candidates:
  prompt_words as $words |
  prompt_bigrams as $bigrams |
  .inverted_index as $idx |

  # Look up each word and bigram in the inverted index
  ([$words[] | . as $w | $idx[$w] // [] | .[]] +
   [$bigrams[] | . as $b | $idx[$b] // [] | .[]]) |

  # Count occurrences per template ID (more hits = more relevant)
  group_by(.) |
  map({ id: .[0], hits: length }) |
  sort_by(-.hits);

# ===== Phase 2: Score candidates against prompt =====

def score_candidate($tmpl):
  prompt_lower as $p |
  prompt_words as $words |
  prompt_bigrams as $bigrams |

  # --- Action matching ---
  # Check if template action appears in prompt (via synonym expansion)
  (if ($words | index($tmpl.action)) != null then 0.45
   elif ($bigrams | map(select(test("(^|\\s)" + $tmpl.action + "(\\s|$)"))) | length > 0) then 0.20
   else 0 end) as $action_score |

  # --- Object matching ---
  (if ($words | index($tmpl.object)) != null then 0.35
   elif ($bigrams | map(select(test("(^|\\s)" + $tmpl.object + "(\\s|$)"))) | length > 0) then 0.15
   else 0 end) as $object_score |

  # --- Keyword overlap with triggers ---
  (($tmpl.triggers // []) |
   map(ascii_downcase) |
   map(. as $trigger |
     if ($p | test($trigger)) then 0.02 else 0 end
   ) | add // 0 |
   if . > 0.08 then 0.08 else . end) as $keyword_score |

  # --- Intent signal boost ---
  (($tmpl.intent_signals // []) |
   map(. as $sig |
     if ($p | test($sig; "i")) then 0.10 else 0 end
   ) | add // 0 |
   if . > 0.10 then 0.10 else . end) as $signal_boost |

  # --- Negative signal penalty ---
  (($tmpl.negative_signals // []) |
   map(. as $sig |
     if ($p | test($sig; "i")) then -0.30 else 0 end
   ) | add // 0) as $negative_penalty |

  # --- Complexity mismatch penalty ---
  (if (prompt_word_count < 6) and ($tmpl.min_confidence > 0.7) then -0.15
   else 0 end) as $complexity_penalty |

  # --- Multi-turn suppression ---
  (if recently_injected($tmpl.id) then -0.40
   else 0 end) as $suppression_penalty |

  # --- Total ---
  {
    id: $tmpl.id,
    name: $tmpl.name,
    confidence: ([$action_score + $object_score + $keyword_score + $signal_boost + $negative_penalty + $complexity_penalty + $suppression_penalty, 0] | max),
    breakdown: {
      action: $action_score,
      object: $object_score,
      keyword: $keyword_score,
      signal_boost: $signal_boost,
      negative: $negative_penalty,
      complexity: $complexity_penalty,
      suppression: $suppression_penalty
    }
  };

# ===== Phase 3: Context filter (stub for v1.0) =====
# In v1.0, no project context filtering. This is where language/framework
# checks would go in v1.1+.

def context_filter($scored):
  $scored;

# ===== Main pipeline =====

# 0. Check escape mechanisms first
if ($prompt | ascii_downcase | test("^--raw(\\s|$)")) then
  { action: "escape", confidence: 0, best_match: null, candidates: [],
    leave_alone_score: 1.0, leave_alone_reason: "raw_flag" }
elif cortex_disabled then
  { action: "escape", confidence: 0, best_match: null, candidates: [],
    leave_alone_score: 1.0, leave_alone_reason: "cx_off" }
else

  # 1. Leave-it-alone detector
  leave_it_alone as $lia |

  if $lia.score >= 0.60 then
    { action: "suppress", confidence: 0, best_match: null, candidates: [],
      leave_alone_score: $lia.score, leave_alone_reason: $lia.reason }
  else

    # 2. Get candidate templates from inverted index
    keyword_candidates as $candidates |

    if ($candidates | length) == 0 then
      { action: "skip", confidence: 0, best_match: null, candidates: [],
        leave_alone_score: $lia.score, leave_alone_reason: $lia.reason }
    else

      # 3. Score top candidates (limit to top 10 by hit count for performance)
      .templates as $all_templates |
      ($candidates | .[0:10] | map(.id)) as $candidate_ids |

      ($all_templates | map(select(.id as $tid | $candidate_ids | index($tid) != null))) as $candidate_templates |

      [($candidate_templates[] | score_candidate(.))] |
      sort_by(-.confidence) as $scored |

      # Apply context filter
      context_filter($scored) as $filtered |

      # 4. Determine action based on confidence
      if ($filtered | length) == 0 then
        { action: "skip", confidence: 0, best_match: null, candidates: [],
          leave_alone_score: $lia.score, leave_alone_reason: $lia.reason }
      else
        $filtered[0] as $best |

        # Check per-template min_confidence
        ($all_templates | map(select(.id == $best.id)) | .[0].min_confidence // 0.7) as $min_conf |

        if $best.confidence >= ([0.70, $min_conf] | max) then
          { action: "inject",
            confidence: $best.confidence,
            best_match: $best,
            candidates: ($filtered | .[0:3] | map({id: .id, confidence: .confidence})),
            leave_alone_score: $lia.score,
            leave_alone_reason: $lia.reason }
        elif $best.confidence >= 0.40 then
          { action: "defer",
            confidence: $best.confidence,
            best_match: $best,
            candidates: ($filtered | .[0:3] | map({id: .id, confidence: .confidence})),
            leave_alone_score: $lia.score,
            leave_alone_reason: $lia.reason }
        else
          { action: "skip",
            confidence: $best.confidence,
            best_match: null,
            candidates: ($filtered | .[0:3] | map({id: .id, confidence: .confidence})),
            leave_alone_score: $lia.score,
            leave_alone_reason: $lia.reason }
        end
      end

    end
  end
end
```

**Verification**:
```bash
# Test 1: "review my code" should match coding-001 with high confidence
jq -f scripts/match.jq \
  --arg prompt "review my code" \
  --arg state "null" \
  --arg cwd "" \
  data/index.json
# Expected: action="inject", best_match.id="coding-001", confidence >= 0.70

# Test 2: "git status" should be left alone
jq -f scripts/match.jq \
  --arg prompt "git status" \
  --arg state "null" \
  --arg cwd "" \
  data/index.json
# Expected: action="suppress", leave_alone_reason="shell_command"

# Test 3: "--raw fix the bug" should escape
jq -f scripts/match.jq \
  --arg prompt "--raw fix the bug" \
  --arg state "null" \
  --arg cwd "" \
  data/index.json
# Expected: action="escape"

# Test 4: "ok" should be left alone (continuation)
jq -f scripts/match.jq \
  --arg prompt "ok" \
  --arg state "null" \
  --arg cwd "" \
  data/index.json
# Expected: action="suppress", leave_alone_reason="continuation"

# Test 5: "help me debug why auth isn't working" should match coding-002
jq -f scripts/match.jq \
  --arg prompt "help me debug why auth isn't working" \
  --arg state "null" \
  --arg cwd "" \
  data/index.json
# Expected: action="inject" or "defer", best_match.id="coding-002"
```

**Commit point**: "core: add jq matching engine"

---

## Task 09: UserPromptSubmit Hook

**Creates**: `hooks/cortex-match`
**Depends on**: T03 (run-hook.cmd), T07 (index.json), T08 (match.jq)
**Time**: 8 min

This is the main hook that fires on every user prompt. It reads stdin, runs the matching engine, reads the template body, and outputs the hook response JSON.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\cortex-match`**
```bash
#!/usr/bin/env bash
# cortex-match — UserPromptSubmit hook for prompt-cortex
# Reads user prompt from stdin, matches against template library,
# injects best template as additionalContext when confident.
#
# Stdin: { session_id, user_prompt, cwd, ... }
# Stdout: { hookSpecificOutput: { hookEventName, additionalContext } } or {}

set -euo pipefail

# --- Determine paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
INDEX="${PLUGIN_ROOT}/data/index.json"
MATCH_JQ="${PLUGIN_ROOT}/scripts/match.jq"

# --- Read stdin ---
input=$(cat)
user_prompt=$(printf '%s' "$input" | jq -r '.user_prompt // ""')
session_id=$(printf '%s' "$input" | jq -r '.session_id // "default"')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

# --- Early exit: empty prompt ---
if [[ -z "$user_prompt" ]]; then
  echo '{}'
  exit 0
fi

# --- Early exit: no index ---
if [[ ! -f "$INDEX" ]]; then
  echo '{}'
  exit 0
fi

# --- State file ---
# Use cwd for .cortex directory (project-local state)
CORTEX_DIR="${cwd:-.}/.cortex"
STATE_FILE="${CORTEX_DIR}/state-${session_id}.json"

# Load state or use null
state_json="null"
if [[ -f "$STATE_FILE" ]]; then
  state_json=$(cat "$STATE_FILE" 2>/dev/null || echo "null")
fi

# --- Run matching engine ---
match_result=$(jq -f "$MATCH_JQ" \
  --arg prompt "$user_prompt" \
  --arg state "$state_json" \
  --arg cwd "$cwd" \
  "$INDEX" 2>/dev/null) || {
  # jq failed — silent degradation
  echo '{}'
  exit 0
}

action=$(printf '%s' "$match_result" | jq -r '.action // "skip"')
confidence=$(printf '%s' "$match_result" | jq -r '.confidence // 0')
template_id=$(printf '%s' "$match_result" | jq -r '.best_match.id // ""')
leave_alone_reason=$(printf '%s' "$match_result" | jq -r '.leave_alone_reason // ""')

# --- Determine disposition for telemetry ---
disposition="$action"
case "$action" in
  inject)  disposition="injected" ;;
  defer)   disposition="deferred" ;;
  suppress) disposition="suppressed" ;;
  escape)  disposition="user_escaped" ;;
  skip)    disposition="below_threshold" ;;
esac

# --- Log telemetry ---
log_telemetry() {
  # Ensure .cortex directory exists
  mkdir -p "$CORTEX_DIR" 2>/dev/null || true

  local prompt_hash
  prompt_hash=$(printf '%s' "$user_prompt" | cksum | cut -d' ' -f1)
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local project_name
  project_name=$(basename "${cwd:-.}")
  local matched_ids
  matched_ids=$(printf '%s' "$match_result" | jq -c '[.candidates[]?.id // empty]' 2>/dev/null || echo '[]')

  local log_entry
  log_entry=$(jq -n -c \
    --arg ts "$ts" \
    --arg prompt_hash "$prompt_hash" \
    --argjson matched "$matched_ids" \
    --arg confidence "$confidence" \
    --arg injected "$template_id" \
    --arg disposition "$disposition" \
    --arg project "$project_name" \
    '{
      ts: $ts,
      prompt_hash: $prompt_hash,
      matched: $matched,
      confidence: ($confidence | tonumber),
      injected: (if $injected == "" then null else $injected end),
      disposition: $disposition,
      project: $project
    }')

  printf '%s\n' "$log_entry" >> "${CORTEX_DIR}/usage.jsonl" 2>/dev/null || true
}

# --- Update session state ---
update_state() {
  mkdir -p "$CORTEX_DIR" 2>/dev/null || true

  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local prompt_hash
  prompt_hash=$(printf '%s' "$user_prompt" | cksum | cut -d' ' -f1)

  # Build new state preserving recent injections
  local recent_injections
  if [[ -f "$STATE_FILE" ]]; then
    recent_injections=$(jq -c '.recentInjections // []' "$STATE_FILE" 2>/dev/null || echo '[]')
  else
    recent_injections='[]'
  fi

  # Add current injection and keep last 10
  if [[ -n "$template_id" ]]; then
    recent_injections=$(printf '%s' "$recent_injections" | jq -c \
      --arg tmpl "$template_id" \
      --arg ts "$ts" \
      '[{template: $tmpl, ts: $ts}] + . | .[0:10]')
  fi

  local new_state
  new_state=$(jq -n \
    --arg ts "$ts" \
    --arg hash "$prompt_hash" \
    --argjson hook_result "$match_result" \
    --argjson recent "$recent_injections" \
    '{
      lastHookRun: $ts,
      lastPromptHash: $hash,
      hookResult: $hook_result,
      recentInjections: $recent,
      cortex_disabled: false
    }')

  printf '%s\n' "$new_state" > "$STATE_FILE" 2>/dev/null || true
}

# --- Escape for JSON embedding ---
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# --- Read template body (everything after second ---) ---
read_template_body() {
  local file="$1"
  local in_body=false
  local dash_count=0
  local body=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      dash_count=$((dash_count + 1))
      if [[ "$dash_count" -ge 2 ]]; then
        in_body=true
        continue
      fi
    fi
    if $in_body; then
      if [[ -n "$body" ]]; then
        body+=$'\n'"$line"
      else
        body="$line"
      fi
    fi
  done < "$file"

  printf '%s' "$body"
}

# --- Check first-session onboarding ---
check_first_injection() {
  local marker="${CORTEX_DIR}/.onboarded"
  if [[ ! -f "$marker" ]]; then
    return 0  # Not yet onboarded
  fi
  return 1  # Already onboarded
}

mark_onboarded() {
  mkdir -p "$CORTEX_DIR" 2>/dev/null || true
  printf '%s' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${CORTEX_DIR}/.onboarded" 2>/dev/null || true
}

# --- Main output logic ---

# Always log telemetry
log_telemetry

case "$action" in
  inject)
    # Find template file
    template_file=$(printf '%s' "$match_result" | jq -r '.best_match.id // ""')
    # Look up file path from index
    template_path=$(jq -r --arg id "$template_id" \
      '.templates[] | select(.id == $id) | .file // ""' \
      "$INDEX" 2>/dev/null)

    if [[ -z "$template_path" ]]; then
      echo '{}'
      exit 0
    fi

    full_path="${PLUGIN_ROOT}/data/prompts/${template_path}"
    if [[ ! -f "$full_path" ]]; then
      echo '{}'
      exit 0
    fi

    # Read template body
    template_body=$(read_template_body "$full_path")
    if [[ -z "$template_body" ]]; then
      echo '{}'
      exit 0
    fi

    # Update state
    update_state

    # Build context string
    template_body_escaped=$(escape_for_json "$template_body")

    # Check first-session onboarding
    onboarding_note=""
    if check_first_injection; then
      onboarding_note="\\n\\n[prompt-cortex] Applied template ${template_id} (${confidence} confidence). Use --raw prefix to skip enhancement for any prompt."
      mark_onboarded
    fi

    # Output hook response using printf (not heredoc — bash 5.3+ bug)
    printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<prompt-cortex match=\\"%s\\" confidence=\\"%s\\">\\n%s\\n</prompt-cortex>%s"}}\n' \
      "$template_id" "$confidence" "$template_body_escaped" "$onboarding_note"
    ;;

  defer)
    # Medium confidence: write state, inject Layer 2 hint
    update_state

    printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<prompt-cortex-hint>prompt-cortex detected patterns relevant to this request but confidence was below threshold (%s). Candidates: %s</prompt-cortex-hint>"}}\n' \
      "$confidence" \
      "$(printf '%s' "$match_result" | jq -r '[.candidates[]?.id] | join(", ")' 2>/dev/null || echo "none")"
    ;;

  suppress|escape|skip|*)
    # No injection
    echo '{}'
    ;;
esac

exit 0
```

**Post-creation**: `chmod +x hooks/cortex-match`

**Verification**:
```bash
# Test by piping mock stdin
echo '{"session_id":"test123","user_prompt":"review my code","cwd":"/tmp/test-project"}' | \
  CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-match
# Expected: JSON with hookSpecificOutput containing template body

echo '{"session_id":"test123","user_prompt":"git status","cwd":"/tmp/test-project"}' | \
  CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-match
# Expected: {}

echo '{"session_id":"test123","user_prompt":"--raw fix the bug","cwd":"/tmp/test-project"}' | \
  CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-match
# Expected: {}
```

**Commit point**: "core: add UserPromptSubmit hook"

---

## Task 10: SessionStart Hook

**Creates**: `hooks/cortex-session-init`
**Depends on**: T03 (run-hook.cmd), T07 (index.json)
**Time**: 5 min

The SessionStart hook runs once when Claude Code starts. It:
1. Validates that `index.json` exists (rebuilds if missing/stale)
2. Detects project context (language, framework)
3. Cleans up stale state files (>24hr old)
4. Injects a brief system message confirming cortex is active

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\cortex-session-init`**
```bash
#!/usr/bin/env bash
# cortex-session-init — SessionStart hook for prompt-cortex
# Validates index, detects project context, cleans stale state.
#
# Environment: CLAUDE_PLUGIN_ROOT, CLAUDE_ENV_FILE (optional)
# Stdout: { hookSpecificOutput: { hookEventName, additionalContext } }

set -euo pipefail

# --- Determine paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
INDEX="${PLUGIN_ROOT}/data/index.json"
BUILD_SCRIPT="${PLUGIN_ROOT}/scripts/build-index.sh"

# --- Validate index exists ---
if [[ ! -f "$INDEX" ]]; then
  if [[ -f "$BUILD_SCRIPT" ]]; then
    bash "$BUILD_SCRIPT" >/dev/null 2>&1 || true
  fi
fi

# Verify index is valid JSON
if [[ -f "$INDEX" ]]; then
  template_count=$(jq -r '.template_count // 0' "$INDEX" 2>/dev/null || echo "0")
else
  template_count=0
fi

# --- Detect project context ---
# Try to determine language and framework from common files
# This writes to CLAUDE_ENV_FILE if available
detect_project() {
  local project_dir="${CLAUDE_PROJECT_DIR:-.}"
  local language="unknown"
  local framework="unknown"

  # Language detection
  if [[ -f "${project_dir}/package.json" ]]; then
    language="javascript"
    # Check for TypeScript
    if [[ -f "${project_dir}/tsconfig.json" ]]; then
      language="typescript"
    fi
    # Framework detection
    if grep -q '"react"' "${project_dir}/package.json" 2>/dev/null; then
      framework="react"
    elif grep -q '"next"' "${project_dir}/package.json" 2>/dev/null; then
      framework="nextjs"
    elif grep -q '"vue"' "${project_dir}/package.json" 2>/dev/null; then
      framework="vue"
    elif grep -q '"svelte"' "${project_dir}/package.json" 2>/dev/null; then
      framework="svelte"
    elif grep -q '"express"' "${project_dir}/package.json" 2>/dev/null; then
      framework="express"
    fi
  elif [[ -f "${project_dir}/requirements.txt" ]] || [[ -f "${project_dir}/pyproject.toml" ]]; then
    language="python"
    if grep -q 'django' "${project_dir}/requirements.txt" 2>/dev/null; then
      framework="django"
    elif grep -q 'fastapi' "${project_dir}/requirements.txt" 2>/dev/null; then
      framework="fastapi"
    elif grep -q 'flask' "${project_dir}/requirements.txt" 2>/dev/null; then
      framework="flask"
    fi
  elif [[ -f "${project_dir}/Cargo.toml" ]]; then
    language="rust"
  elif [[ -f "${project_dir}/go.mod" ]]; then
    language="go"
  elif [[ -f "${project_dir}/build.gradle" ]] || [[ -f "${project_dir}/pom.xml" ]]; then
    language="java"
  fi

  printf '%s %s' "$language" "$framework"
}

project_context=$(detect_project 2>/dev/null || echo "unknown unknown")
project_lang=$(echo "$project_context" | cut -d' ' -f1)
project_framework=$(echo "$project_context" | cut -d' ' -f2)

# --- Clean stale state files (>24 hours old) ---
cleanup_stale_state() {
  local cortex_dir="${CLAUDE_PROJECT_DIR:-.}/.cortex"
  if [[ -d "$cortex_dir" ]]; then
    # Find state files older than 24 hours
    find "$cortex_dir" -name "state-*.json" -mmin +1440 -delete 2>/dev/null || true
  fi
}
cleanup_stale_state

# --- Escape for JSON ---
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# --- Build session context message ---
context_msg="<prompt-cortex-init>\\nprompt-cortex v1.0 active. ${template_count} templates loaded.\\nProject: ${project_lang}/${project_framework}\\nEscape: prefix any prompt with --raw to skip enhancement.\\n</prompt-cortex-init>"

# --- Output ---
if [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  printf '{"additional_context":"%s"}\n' "$context_msg"
elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$context_msg"
else
  printf '{"additional_context":"%s"}\n' "$context_msg"
fi

exit 0
```

**Post-creation**: `chmod +x hooks/cortex-session-init`

**Verification**:
```bash
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/cortex-session-init
# Expected: JSON with hookSpecificOutput containing init message
```

**Commit point**: "core: add SessionStart hook"

---

## Task 11: Integration Test Suite

**Creates**: `tests/run-tests.sh`
**Depends on**: T05-T10 (all previous tasks)
**Time**: 10 min

This is a comprehensive test script that validates every component.

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\tests\run-tests.sh`**
```bash
#!/usr/bin/env bash
# run-tests.sh — Integration test suite for prompt-cortex
# Usage: bash tests/run-tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  NC=''
fi

pass() {
  PASS=$((PASS + 1))
  printf "${GREEN}PASS${NC} %s\n" "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  ERRORS+="  FAIL: $1 — $2\n"
  printf "${RED}FAIL${NC} %s — %s\n" "$1" "$2"
}

assert_eq() {
  local test_name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "expected '$expected', got '$actual'"
  fi
}

assert_contains() {
  local test_name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$test_name"
  else
    fail "$test_name" "expected to contain '$needle'"
  fi
}

assert_not_empty() {
  local test_name="$1" value="$2"
  if [[ -n "$value" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "expected non-empty value"
  fi
}

# ===== Test Group: Plugin Scaffold =====
echo ""
echo "=== Plugin Scaffold ==="

# T1: plugin.json exists and is valid
if jq . "${PLUGIN_ROOT}/.claude-plugin/plugin.json" >/dev/null 2>&1; then
  pass "plugin.json is valid JSON"
else
  fail "plugin.json is valid JSON" "parse error"
fi

plugin_name=$(jq -r '.name' "${PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null || echo "")
assert_eq "plugin.json name" "prompt-cortex" "$plugin_name"

# T2: hooks.json exists and is valid
if jq . "${PLUGIN_ROOT}/hooks/hooks.json" >/dev/null 2>&1; then
  pass "hooks.json is valid JSON"
else
  fail "hooks.json is valid JSON" "parse error"
fi

has_session=$(jq 'has("hooks") and (.hooks | has("SessionStart"))' "${PLUGIN_ROOT}/hooks/hooks.json" 2>/dev/null || echo "false")
assert_eq "hooks.json has SessionStart" "true" "$has_session"

has_prompt=$(jq 'has("hooks") and (.hooks | has("UserPromptSubmit"))' "${PLUGIN_ROOT}/hooks/hooks.json" 2>/dev/null || echo "false")
assert_eq "hooks.json has UserPromptSubmit" "true" "$has_prompt"

# T3: run-hook.cmd exists
if [[ -f "${PLUGIN_ROOT}/hooks/run-hook.cmd" ]]; then
  pass "run-hook.cmd exists"
else
  fail "run-hook.cmd exists" "file not found"
fi

# ===== Test Group: Templates =====
echo ""
echo "=== Templates ==="

for tmpl in coding-001 coding-002 coding-003; do
  if [[ -f "${PLUGIN_ROOT}/data/prompts/coding/${tmpl}.md" ]]; then
    pass "template ${tmpl}.md exists"
  else
    fail "template ${tmpl}.md exists" "file not found"
  fi
done

# T6: Template validator
echo ""
echo "=== Template Validator ==="

if bash "${PLUGIN_ROOT}/scripts/validate-template.sh" "${PLUGIN_ROOT}/data/prompts/coding/coding-001.md" 2>&1 | grep -q "OK"; then
  pass "validate-template: coding-001 passes"
else
  fail "validate-template: coding-001 passes" "validation failed"
fi

# ===== Test Group: Index Builder =====
echo ""
echo "=== Index Builder ==="

# Build index
bash "${PLUGIN_ROOT}/scripts/build-index.sh" >/dev/null 2>&1
if [[ -f "${PLUGIN_ROOT}/data/index.json" ]]; then
  pass "build-index creates index.json"
else
  fail "build-index creates index.json" "file not created"
fi

tmpl_count=$(jq '.template_count' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null || echo "0")
assert_eq "index has 3 templates" "3" "$tmpl_count"

# Check inverted index has expected keys
has_review=$(jq '.inverted_index | has("review")' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null || echo "false")
assert_eq "inverted index has 'review'" "true" "$has_review"

has_debug=$(jq '.inverted_index | has("debug")' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null || echo "false")
assert_eq "inverted index has 'debug'" "true" "$has_debug"

# ===== Test Group: Matching Engine =====
echo ""
echo "=== Matching Engine (match.jq) ==="

# Test: "review my code" → inject coding-001
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "review my code" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')
assert_eq "match 'review my code' action" "inject" "$action"
assert_eq "match 'review my code' template" "coding-001" "$match_id"

# Test: "help me debug why auth isn't working" → match coding-002
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "help me debug why auth isn't working" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')
assert_eq "match 'debug auth' template" "coding-002" "$match_id"

# Test: "write unit tests for the auth module" → match coding-003
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "write unit tests for the auth module" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')
assert_eq "match 'write tests' template" "coding-003" "$match_id"

# Test: "git status" → suppress (shell command)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "git status" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
reason=$(printf '%s' "$result" | jq -r '.leave_alone_reason')
assert_eq "leave-alone 'git status' action" "suppress" "$action"
assert_eq "leave-alone 'git status' reason" "shell_command" "$reason"

# Test: "ok" → suppress (continuation)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "ok" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "leave-alone 'ok' action" "suppress" "$action"

# Test: "--raw fix the bug" → escape
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "--raw fix the bug" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "escape '--raw' action" "escape" "$action"

# Test: /cx off state → escape
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "review my code" \
  --arg state '{"cortex_disabled":true}' \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "escape '/cx off' state" "escape" "$action"

# Test: "/cortex:debug" → suppress (slash command)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "/cortex:debug" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "leave-alone '/cortex:debug'" "suppress" "$action"

# Test: random unrelated prompt → skip
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what is the weather today in Copenhagen" \
  --arg state "null" \
  --arg cwd "" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
# Should be skip or suppress (conceptual question)
if [[ "$action" == "skip" ]] || [[ "$action" == "suppress" ]]; then
  pass "no match for unrelated prompt"
else
  fail "no match for unrelated prompt" "got action=$action"
fi

# ===== Test Group: UserPromptSubmit Hook =====
echo ""
echo "=== UserPromptSubmit Hook (cortex-match) ==="

# Create temp dir for state
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test: inject template
output=$(echo '{"session_id":"test-001","user_prompt":"review my code","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
if printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "cortex-match injects on 'review my code'"
else
  fail "cortex-match injects on 'review my code'" "no additionalContext in output"
fi

# Test: skip on shell command
output=$(echo '{"session_id":"test-002","user_prompt":"git status","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
assert_eq "cortex-match skips 'git status'" "{}" "$output"

# Test: escape on --raw
output=$(echo '{"session_id":"test-003","user_prompt":"--raw fix the bug","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
assert_eq "cortex-match escapes '--raw'" "{}" "$output"

# Test: telemetry file created
if [[ -f "${TEST_DIR}/.cortex/usage.jsonl" ]]; then
  pass "telemetry file created"
  telem_lines=$(wc -l < "${TEST_DIR}/.cortex/usage.jsonl")
  if [[ "$telem_lines" -ge 1 ]]; then
    pass "telemetry has entries"
  else
    fail "telemetry has entries" "file is empty"
  fi
else
  fail "telemetry file created" "usage.jsonl not found"
fi

# Test: state file created
if ls "${TEST_DIR}/.cortex/state-"*.json >/dev/null 2>&1; then
  pass "state file created"
else
  fail "state file created" "no state-*.json found"
fi

# ===== Test Group: SessionStart Hook =====
echo ""
echo "=== SessionStart Hook ==="

output=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-session-init" 2>/dev/null)
if printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "session-init outputs valid hook JSON"
else
  fail "session-init outputs valid hook JSON" "invalid output: $output"
fi

assert_contains "session-init mentions template count" "templates loaded" "$output"

# ===== Results =====
echo ""
echo "================================"
printf "Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}\n" "$PASS" "$FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Failures:"
  printf "$ERRORS"
  exit 1
fi

exit 0
```

**Post-creation**: `chmod +x tests/run-tests.sh`

**Verification**: `bash tests/run-tests.sh` should show all tests passing.

**Commit point**: "tests: add integration test suite"

---

## Task 12: Project Housekeeping

**Creates**: `.gitignore`, `LICENSE`
**Depends on**: Nothing
**Time**: 2 min

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\.gitignore`**
```
# State files (session-specific, never commit)
.cortex/

# OS files
.DS_Store
Thumbs.db
desktop.ini

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# Temp
*.tmp
*.bak
```

**File: `C:\Users\Danie\Documents\GitHub\prompt-cortex\LICENSE`**
Standard MIT license with "Daniel Hjermitslev" as copyright holder, year 2026.

**Commit point**: "chore: add .gitignore and LICENSE"

---

## Dependency Graph

```
T01 (plugin.json)          ─┐
T02 (hooks.json)            │
T03 (run-hook.cmd)          ├── Phase 1: Scaffold (parallel, no deps)
T04 (intents.json)          │
T12 (.gitignore, LICENSE)  ─┘

T05 (3 templates)          ─── Phase 2a: Data (no deps)

T06 (validate-template.sh) ─── Phase 2b: Validator (depends on T05 for testing)

T07 (build-index.sh)       ─── Phase 2c: Index builder (depends on T05 for input)
                                 produces: data/index.json

T08 (match.jq)             ─── Phase 3a: Core engine (depends on T07 for testing)

T09 (cortex-match)         ─── Phase 3b: Hook wrapper (depends on T03, T07, T08)

T10 (cortex-session-init)  ─── Phase 3c: Session hook (depends on T03, T07)

T11 (run-tests.sh)         ─── Phase 4: Tests (depends on ALL above)
```

## Execution Order

**Batch 1** (parallel, no dependencies):
- T01, T02, T03, T04, T12

**Batch 2** (after Batch 1):
- T05 (templates need directory created in T01's commit)

**Batch 3** (after T05):
- T06, T07 (can run parallel; T07 needs T05 templates)

**Batch 4** (after T07):
- T08 (needs index.json for testing)

**Batch 5** (after T08):
- T09, T10 (can run parallel; both need T03, T07, T08)

**Batch 6** (after all):
- T11 (integration tests)

## Critical Risks and Mitigations

1. **jq `\b` word boundary**: Confirmed NOT working. All regex patterns use `(^|[^a-zA-Z])` instead. The 3 sample templates already use this format.

2. **`--slurpfile` with missing state**: jq crashes. Solution: pass state as `--arg state "$state_json"` (string), parse in jq using `$state | fromjson` if needed, or use the simpler approach of passing the state content as `--arg state` and checking for `"null"` string.

3. **bash 5.3+ heredoc bug**: Superpowers hit this. Solution: use `printf` for all JSON output, never heredoc with variable expansion.

4. **Windows path spaces**: `${CLAUDE_PLUGIN_ROOT}` must be quoted in hooks.json command. The `run-hook.cmd` polyglot wrapper handles bash discovery.

5. **`stat` portability**: Linux uses `stat -c '%Y'`, macOS uses `stat -f '%m'`. The build-index.sh tries both.

6. **YAML parsing limitations**: The pure-bash parser handles only flat key-value pairs and simple arrays. Nested objects, multi-line values, and YAML anchors are not supported. This is sufficient for the v1.0 frontmatter schema.

7. **Claude Code Issue #10225**: Plugin hooks.json hooks may not execute. Mitigation: SessionStart hook confirms cortex is active. README (Plan B) will include `~/.claude/settings.json` fallback instructions.

---

### Critical Files for Implementation

- `C:\Users\Danie\Documents\GitHub\prompt-cortex\scripts\match.jq` - Core matching intelligence: leave-it-alone detector, 3-phase scoring algorithm, confidence thresholds. The brain of the entire plugin.
- `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\cortex-match` - UserPromptSubmit hook orchestrator: reads stdin, calls match.jq, reads template body, outputs hook JSON, manages state and telemetry.
- `C:\Users\Danie\Documents\GitHub\prompt-cortex\scripts\build-index.sh` - Index compiler: pure-bash YAML parser, inverted index builder, version hashing. Must run before any matching can work.
- `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\run-hook.cmd` - Cross-platform polyglot wrapper: enables bash scripts to run on Windows via Git Bash discovery. Critical for Windows compatibility.
- `C:\Users\Danie\Documents\GitHub\prompt-cortex\hooks\hooks.json` - Hook registration: defines when SessionStart and UserPromptSubmit fire, timeout values, and command paths with proper quoting.
