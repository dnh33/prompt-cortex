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

# Write templates to temp file (avoids "Argument list too long" for large template sets)
TMPDIR_BUILD=$(mktemp -d)
trap "rm -rf $TMPDIR_BUILD" EXIT

TEMPLATES_FILE="${TMPDIR_BUILD}/templates.json"
printf '%s\n' "$templates_json" > "$TEMPLATES_FILE"

# Build inverted index from triggers
# Map each trigger keyword/phrase to template IDs
INVERTED_FILE="${TMPDIR_BUILD}/inverted.json"
jq '
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
' "$TEMPLATES_FILE" > "$INVERTED_FILE"

# Compose final index using temp files (avoids arg length limits)
built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg version "$version_hash" \
  --arg built "$built_at" \
  --slurpfile templates "$TEMPLATES_FILE" \
  --slurpfile inverted "$INVERTED_FILE" \
  '{
    version: $version,
    built: $built,
    template_count: ($templates[0] | length),
    templates: $templates[0],
    inverted_index: $inverted[0]
  }' > "$OUTPUT_FILE"

echo "Index built: $OUTPUT_FILE"
echo "  Templates: $(jq '.template_count' "$OUTPUT_FILE")"
echo "  Index keys: $(jq '.inverted_index | keys | length' "$OUTPUT_FILE")"
echo "  Version: ${version_hash:0:16}..."
