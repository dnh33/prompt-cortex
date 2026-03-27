#!/usr/bin/env bash
# e2e-user-sim.sh — Real-world user simulation tests for prompt-cortex v1.2
# Tests actual prompts through the full pipeline as a user would experience them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MATCH_JQ="${PLUGIN_ROOT}/scripts/match.jq"
INDEX="${PLUGIN_ROOT}/data/index.json"
INTENTS="${PLUGIN_ROOT}/data/intents.json"
PASS=0
FAIL=0

run_match() {
  local prompt="$1"
  local context="$2"
  local rules="$3"
  local adjust="${4:-0}"
  jq -f "$MATCH_JQ" \
    --arg prompt "$prompt" \
    --arg state "null" \
    --arg cwd "" \
    --arg min_tier "silver" \
    --arg min_confidence_adjust "$adjust" \
    --argjson context "$context" \
    --argjson project_rules "$rules" \
    --slurpfile intents "$INTENTS" \
    "$INDEX" 2>/dev/null
}

check() {
  local desc="$1"
  local expected="$2"
  local result="$3"
  local action=$(printf '%s' "$result" | jq -r '.action')
  local id=$(printf '%s' "$result" | jq -r '.best_match.id // "none"')
  local conf=$(printf '%s' "$result" | jq -r '.confidence // 0')

  if [[ "$expected" == "inject_or_defer" ]]; then
    if [[ "$action" == "inject" ]] || [[ "$action" == "defer" ]]; then
      PASS=$((PASS+1))
      printf "  PASS: %-50s -> %-7s id=%-15s conf=%s\n" "$desc" "$action" "$id" "$conf"
    else
      FAIL=$((FAIL+1))
      printf "  FAIL: %-50s -> expected inject/defer, got %s\n" "$desc" "$action"
    fi
  elif [[ "$action" == "$expected" ]]; then
    PASS=$((PASS+1))
    printf "  PASS: %-50s -> %-7s id=%-15s conf=%s\n" "$desc" "$action" "$id" "$conf"
  else
    FAIL=$((FAIL+1))
    printf "  FAIL: %-50s -> expected %s, got %s (id=%s conf=%s)\n" "$desc" "$expected" "$action" "$id" "$conf"
  fi
}

check_conf() {
  local desc="$1"
  local op="$2"
  local val_a="$3"
  local val_b="$4"
  local result=$(jq -n --arg a "$val_a" --arg b "$val_b" "(\$a|tonumber) $op (\$b|tonumber)")
  if [[ "$result" == "true" ]]; then
    PASS=$((PASS+1))
    printf "  PASS: %-50s (%s %s %s)\n" "$desc" "$val_a" "$op" "$val_b"
  else
    FAIL=$((FAIL+1))
    printf "  FAIL: %-50s (%s %s %s)\n" "$desc" "$val_a" "$op" "$val_b"
  fi
}

# Context presets
NO_CTX='{}'
NO_RULES='{"boost":[],"suppress":[],"disabled":[]}'
TS_NEXT='{"lang":"typescript","framework":"nextjs","testing":"vitest","linter":"biome","pkgmgr":"bun","branch_type":""}'
PY_DJANGO='{"lang":"python","framework":"django","testing":"pytest","linter":"ruff","pkgmgr":"pip","branch_type":""}'
RUST_CTX='{"lang":"rust","framework":"","testing":"","linter":"","pkgmgr":"cargo","branch_type":""}'
GO_CTX='{"lang":"go","framework":"","testing":"","linter":"","pkgmgr":"","branch_type":""}'
FIX_BRANCH='{"lang":"typescript","framework":"nextjs","testing":"","linter":"","pkgmgr":"","branch_type":"fix"}'
FEAT_BRANCH='{"lang":"typescript","framework":"react","testing":"","linter":"","pkgmgr":"","branch_type":"feature"}'
REFACTOR_BRANCH='{"lang":"typescript","framework":"","testing":"","linter":"","pkgmgr":"","branch_type":"refactor"}'

echo "========================================"
echo "prompt-cortex v1.2 — User Simulation"
echo "========================================"

# -----------------------------------------------
echo ""
echo "=== 1. Core Coding Actions (no context) ==="
check "review my code"           "inject" "$(run_match 'review my code' "$NO_CTX" "$NO_RULES")"
check "debug this error"         "inject" "$(run_match 'debug this error' "$NO_CTX" "$NO_RULES")"
check "write tests for auth"     "inject" "$(run_match 'write unit tests for the auth module' "$NO_CTX" "$NO_RULES")"
check "refactor for readability" "inject" "$(run_match 'refactor this function to be more readable' "$NO_CTX" "$NO_RULES")"
check "explain auth flow"        "inject" "$(run_match 'explain how this authentication flow works' "$NO_CTX" "$NO_RULES")"
check "create component"         "inject_or_defer" "$(run_match 'create a new component for the dashboard' "$NO_CTX" "$NO_RULES")"
check "optimize db queries"      "inject_or_defer" "$(run_match 'optimize the database queries in the user service' "$NO_CTX" "$NO_RULES")"
check "fix login bug"            "inject" "$(run_match 'fix the bug in the login page where users get 403' "$NO_CTX" "$NO_RULES")"
check "design API schema"        "inject_or_defer" "$(run_match 'design the API schema for the new payment service' "$NO_CTX" "$NO_RULES")"
check "document the endpoints"   "inject_or_defer" "$(run_match 'document the REST API endpoints' "$NO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 2. Leave-it-alone (must NOT inject) ==="
check "git status"              "skip" "$(run_match 'git status' "$NO_CTX" "$NO_RULES")"
check "git log --oneline"       "skip" "$(run_match 'git log --oneline -10' "$NO_CTX" "$NO_RULES")"
check "ls -la"                  "skip" "$(run_match 'ls -la' "$NO_CTX" "$NO_RULES")"
check "cd src"                  "skip" "$(run_match 'cd src' "$NO_CTX" "$NO_RULES")"
check "ok"                      "skip" "$(run_match 'ok' "$NO_CTX" "$NO_RULES")"
check "yes"                     "skip" "$(run_match 'yes' "$NO_CTX" "$NO_RULES")"
check "no"                      "skip" "$(run_match 'no' "$NO_CTX" "$NO_RULES")"
check "thanks"                  "skip" "$(run_match 'thanks' "$NO_CTX" "$NO_RULES")"
check "npm install express"     "skip" "$(run_match 'npm install express' "$NO_CTX" "$NO_RULES")"
check "mkdir src/components"    "skip" "$(run_match 'mkdir -p src/components' "$NO_CTX" "$NO_RULES")"
check "--raw escape"            "escape" "$(run_match '--raw just do what I say' "$NO_CTX" "$NO_RULES")"
check "single word: help"       "skip" "$(run_match 'help' "$NO_CTX" "$NO_RULES")"
check "single word: what?"      "skip" "$(run_match 'what?' "$NO_CTX" "$NO_RULES")"
check "continuation: sure"      "skip" "$(run_match 'sure' "$NO_CTX" "$NO_RULES")"
check "continuation: go ahead"  "skip" "$(run_match 'go ahead' "$NO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 3. TypeScript/Next.js Context ==="
check "TS: review my code"      "inject" "$(run_match 'review my code' "$TS_NEXT" "$NO_RULES")"
check "TS: debug API route"     "inject" "$(run_match 'debug the API route handler' "$TS_NEXT" "$NO_RULES")"
check "TS: create page"         "inject_or_defer" "$(run_match 'create a new page component' "$TS_NEXT" "$NO_RULES")"
check "TS: fix checkout"        "inject" "$(run_match 'fix the checkout flow error' "$TS_NEXT" "$NO_RULES")"
check "TS: optimize bundle"     "inject_or_defer" "$(run_match 'optimize the bundle size' "$TS_NEXT" "$NO_RULES")"
check "TS: test middleware"     "inject_or_defer" "$(run_match 'write tests for the middleware' "$TS_NEXT" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 4. Python/Django Context ==="
check "PY: review my code"      "inject" "$(run_match 'review my code' "$PY_DJANGO" "$NO_RULES")"
check "PY: debug 500 error"     "inject" "$(run_match 'debug the user view that returns 500' "$PY_DJANGO" "$NO_RULES")"
check "PY: create model"        "inject_or_defer" "$(run_match 'create a new Django model for orders' "$PY_DJANGO" "$NO_RULES")"
check "PY: fix migration"       "inject" "$(run_match 'fix the database migration error' "$PY_DJANGO" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 5. Rust Context ==="
check "Rust: review code"       "inject" "$(run_match 'review my code' "$RUST_CTX" "$NO_RULES")"
check "Rust: fix lifetime"      "inject" "$(run_match 'fix the lifetime error in the parser' "$RUST_CTX" "$NO_RULES")"
check "Rust: optimize perf"     "inject_or_defer" "$(run_match 'optimize the performance of the hash map' "$RUST_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 6. Go Context ==="
check "Go: review code"         "inject" "$(run_match 'review my code' "$GO_CTX" "$NO_RULES")"
check "Go: debug goroutine"     "inject_or_defer" "$(run_match 'debug the goroutine deadlock' "$GO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 7. Git Branch Boosting ==="
# Fix branch should boost debug/fix/test actions
r_no_branch=$(run_match 'debug this error in the auth module' "$TS_NEXT" "$NO_RULES")
r_fix_branch=$(run_match 'debug this error in the auth module' "$FIX_BRANCH" "$NO_RULES")
conf_no=$(printf '%s' "$r_no_branch" | jq -r '.confidence')
conf_fix=$(printf '%s' "$r_fix_branch" | jq -r '.confidence')
check_conf "fix branch boosts debug confidence" ">=" "$conf_fix" "$conf_no"

# Feature branch should boost create/design actions
r_no_branch2=$(run_match 'create a new dashboard component' "$TS_NEXT" "$NO_RULES")
r_feat_branch=$(run_match 'create a new dashboard component' "$FEAT_BRANCH" "$NO_RULES")
conf_no2=$(printf '%s' "$r_no_branch2" | jq -r '.confidence')
conf_feat=$(printf '%s' "$r_feat_branch" | jq -r '.confidence')
check_conf "feature branch boosts create confidence" ">=" "$conf_feat" "$conf_no2"

# Refactor branch
r_refactor=$(run_match 'refactor this module for clarity' "$REFACTOR_BRANCH" "$NO_RULES")
check "refactor branch: refactor prompt" "inject" "$r_refactor"

# -----------------------------------------------
echo ""
echo "=== 8. Boost/Suppress/Disabled Rules ==="
BOOST_REVIEW='{"boost":["review"],"suppress":[],"disabled":[]}'
r_base=$(run_match 'review my code' "$NO_CTX" "$NO_RULES")
r_boosted=$(run_match 'review my code' "$NO_CTX" "$BOOST_REVIEW")
conf_base=$(printf '%s' "$r_base" | jq -r '.confidence')
conf_boosted=$(printf '%s' "$r_boosted" | jq -r '.confidence')
check_conf "boost increases confidence" ">" "$conf_boosted" "$conf_base"

SUPPRESS_REVIEW='{"boost":[],"suppress":["review"],"disabled":[]}'
r_supp=$(run_match 'review my code' "$NO_CTX" "$SUPPRESS_REVIEW")
conf_supp=$(printf '%s' "$r_supp" | jq -r '.confidence')
check_conf "suppress decreases confidence" "<" "$conf_supp" "$conf_base"

DISABLE_001='{"boost":[],"suppress":[],"disabled":["coding-001"]}'
r_dis=$(run_match 'review my code' "$NO_CTX" "$DISABLE_001")
dis_id=$(printf '%s' "$r_dis" | jq -r '.best_match.id // "none"')
if [[ "$dis_id" != "coding-001" ]]; then
  PASS=$((PASS+1))
  printf "  PASS: %-50s (got %s instead)\n" "disabled removes coding-001" "$dis_id"
else
  FAIL=$((FAIL+1))
  printf "  FAIL: %-50s (still got coding-001)\n" "disabled removes coding-001"
fi

# Disable by category
DISABLE_CODING='{"boost":[],"suppress":[],"disabled":["coding"]}'
r_dis_cat=$(run_match 'review my code' "$NO_CTX" "$DISABLE_CODING")
dis_cat_id=$(printf '%s' "$r_dis_cat" | jq -r '.best_match.id // "none"')
dis_cat_cat=$(printf '%s' "$r_dis_cat" | jq -r '.best_match.category // "none"')
if [[ "$dis_cat_cat" != "coding" ]]; then
  PASS=$((PASS+1))
  printf "  PASS: %-50s (got category=%s)\n" "disabled by category removes all coding" "$dis_cat_cat"
else
  FAIL=$((FAIL+1))
  printf "  FAIL: %-50s (still got coding category)\n" "disabled by category"
fi

# -----------------------------------------------
echo ""
echo "=== 9. Presets: Learning vs Strict ==="
# Learning preset lowers threshold (more permissive)
r_default=$(run_match 'review my code' "$NO_CTX" "$NO_RULES" "0")
r_learning=$(run_match 'review my code' "$NO_CTX" "$NO_RULES" "-0.10")
r_strict=$(run_match 'review my code' "$NO_CTX" "$NO_RULES" "0.05")
check "default threshold" "inject" "$r_default"
check "learning threshold (-0.10)" "inject" "$r_learning"
check "strict threshold (+0.05)" "inject" "$r_strict"

# -----------------------------------------------
echo ""
echo "=== 10. Domain Synonyms ==="
# "scaffold" is a web-domain synonym for "create"
check "scaffold (web context)" "inject_or_defer" "$(run_match 'scaffold a new component' "$TS_NEXT" "$NO_RULES")"
# "provision" is a devops-domain synonym for "create"
check "provision (devops ctx)" "inject_or_defer" "$(run_match 'provision a new server instance' "$GO_CTX" "$NO_RULES")"
# "troubleshoot" is a base synonym for "debug"
check "troubleshoot the bug" "inject_or_defer" "$(run_match 'troubleshoot the bug in production' "$NO_CTX" "$NO_RULES")"
# "audit" is a base synonym for "review"
check "audit the codebase" "inject_or_defer" "$(run_match 'audit the codebase for security issues' "$NO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 11. Complexity Scoring ==="
# Trivial prompt should still work (no regression)
check "2-word: fix bug" "inject_or_defer" "$(run_match 'fix bug' "$NO_CTX" "$NO_RULES")"
check "3-word: review my code" "inject" "$(run_match 'review my code' "$NO_CTX" "$NO_RULES")"
# Medium prompt
check "medium: 20-word prompt" "inject" "$(run_match 'I need to fix the authentication bug in the login page where users get a 403 error when trying to sign in' "$NO_CTX" "$NO_RULES")"
# Long expert prompt
check "long: detailed request" "inject" "$(run_match 'review the entire authentication module including the JWT token refresh logic the session management middleware and the OAuth2 integration with Google and ensure there are no security vulnerabilities or race conditions in the concurrent session handling especially around the token rotation mechanism' "$NO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 12. Real Daniel-Style Prompts ==="
check "review checkout changes"  "inject" "$(run_match 'review the changes I made to the checkout flow' "$TS_NEXT" "$NO_RULES")"
check "fix the 403"             "inject" "$(run_match 'fix the 403 error on the login page' "$TS_NEXT" "$NO_RULES")"
check "make it faster"          "inject_or_defer" "$(run_match 'make the product listing page load faster' "$TS_NEXT" "$NO_RULES")"
check "add dark mode"           "inject_or_defer" "$(run_match 'add dark mode support to the settings page' "$TS_NEXT" "$NO_RULES")"
check "test the auth"           "inject_or_defer" "$(run_match 'write tests for the authentication module' "$TS_NEXT" "$NO_RULES")"
check "deploy check (skip)"    "skip" "$(run_match 'deploy to production' "$TS_NEXT" "$NO_RULES")"
check "verify it (skip)"       "skip" "$(run_match 'verify it works' "$TS_NEXT" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "=== 13. Mixed/Edge Cases ==="
check "conversational: looks good" "skip" "$(run_match 'looks good to me' "$NO_CTX" "$NO_RULES")"
check "conversational: sounds right" "skip" "$(run_match 'sounds right' "$NO_CTX" "$NO_RULES")"
check "question: how does X work" "inject_or_defer" "$(run_match 'how does the caching layer work in this app' "$NO_CTX" "$NO_RULES")"
check "vague: look at this" "inject_or_defer" "$(run_match 'can you look at this code and tell me if there are any issues' "$NO_CTX" "$NO_RULES")"

# -----------------------------------------------
echo ""
echo "========================================"
printf "TOTAL: %d passed, %d failed\n" "$PASS" "$FAIL"
echo "========================================"
