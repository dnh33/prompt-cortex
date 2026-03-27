#!/usr/bin/env bash
# bulk-schema-upgrade.sh — Adds v1.2 schema fields to all templates
# Usage: bash scripts/bulk-schema-upgrade.sh [--dry-run]
# Adds: requires_language, requires_framework, project_affinity, min_complexity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROMPTS_DIR="${PLUGIN_ROOT}/data/prompts"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "DRY RUN — no files will be modified"
fi

# --- Gold template mapping ---
# Most gold templates are language-agnostic (empty requires)
gold_language_for() {
  local id="$1"
  local category="$2"
  local action="$3"
  local object="$4"

  # Most gold coding templates are language-agnostic
  echo "[]"
}

gold_affinity_for() {
  local id="$1"
  local category="$2"

  case "$category" in
    coding)       echo '["web", "api", "library"]' ;;
    ai-workflows) echo '["ai", "ml"]' ;;
    *)            echo '[]' ;;
  esac
}

gold_complexity_for() {
  local action="$1"
  case "$action" in
    review|refactor|optimize) echo "medium" ;;
    design|document)          echo "low" ;;
    debug|fix)                echo "low" ;;
    create|test)              echo "low" ;;
    explain)                  echo "low" ;;
    *)                        echo "low" ;;
  esac
}

# --- Process each template ---
updated=0
skipped=0

while IFS= read -r -d '' file; do
  filename=$(basename "$file")
  id="${filename%.md}"

  # Check if already has requires_language (idempotent)
  if grep -q "^requires_language:" "$file" 2>/dev/null; then
    skipped=$((skipped + 1))
    continue
  fi

  # Read current fields
  category=$(grep "^category:" "$file" | head -1 | awk -F: '{gsub(/^[[:space:]]+/, "", $2); print $2}')
  action=$(grep "^action:" "$file" | head -1 | awk -F: '{gsub(/^[[:space:]]+/, "", $2); print $2}')
  tier=$(grep "^quality_tier:" "$file" | head -1 | awk -F: '{gsub(/^[[:space:]]+/, "", $2); print $2}')

  # Determine fields based on tier
  if [[ "$tier" == "gold" ]]; then
    lang=$(gold_language_for "$id" "$category" "$action" "")
    affinity=$(gold_affinity_for "$id" "$category")
    complexity=$(gold_complexity_for "$action")
  else
    # Silver/bronze: empty defaults
    lang="[]"
    affinity="[]"
    complexity="low"
  fi

  if $DRY_RUN; then
    echo "  Would update: $file"
    echo "    + requires_language: $lang"
    echo "    + project_affinity: $affinity"
    echo "    + min_complexity: $complexity"
  else
    # Insert before the closing --- using awk (cross-platform, no sed -i issues)
    tmpfile="${file}.tmp"
    awk -v lang="$lang" -v affinity="$affinity" -v complexity="$complexity" '
    BEGIN { dash_count=0 }
    /^---$/ {
      dash_count++
      if (dash_count == 2) {
        print "requires_language: " lang
        print "requires_framework: []"
        print "project_affinity: " affinity
        print "min_complexity: " complexity
      }
    }
    { print }
    ' "$file" > "$tmpfile" && mv "$tmpfile" "$file"
    updated=$((updated + 1))
  fi
done < <(find "$PROMPTS_DIR" -name "*.md" -type f -print0 | sort -z)

echo ""
echo "Updated: $updated files"
echo "Skipped: $skipped files (already have requires_language)"
echo ""
if ! $DRY_RUN; then
  echo "Now rebuild the index: bash scripts/build-index.sh"
fi
