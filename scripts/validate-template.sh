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
