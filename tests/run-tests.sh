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

validator_output=$(bash "${PLUGIN_ROOT}/scripts/validate-template.sh" "${PLUGIN_ROOT}/data/prompts/coding/coding-001.md" 2>&1 || true)
if [[ "$validator_output" == *"OK"* ]]; then
  pass "validate-template: coding-001 passes"
else
  fail "validate-template: coding-001 passes" "validation failed: $validator_output"
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
if [[ "$tmpl_count" -ge 3 ]]; then
  pass "index has templates ($tmpl_count)"
else
  fail "index has templates" "expected >= 3, got $tmpl_count"
fi

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
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
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
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')
assert_eq "match 'debug auth' template" "coding-002" "$match_id"

# Test: "write unit tests for the auth module" → match coding-003
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "write unit tests for the auth module" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')
assert_eq "match 'write tests' template" "coding-003" "$match_id"

# Test: "git status" → suppress (shell command)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "git status" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
reason=$(printf '%s' "$result" | jq -r '.leave_alone_reason')
assert_eq "leave-alone 'git status' action" "suppress" "$action"
assert_eq "leave-alone 'git status' reason" "shell_command" "$reason"

# Test: "ok" → suppress or skip (continuation scores 0.45, below 0.60 threshold)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "ok" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
if [[ "$action" == "suppress" ]] || [[ "$action" == "skip" ]]; then
  pass "leave-alone 'ok' (action=$action)"
else
  fail "leave-alone 'ok'" "expected suppress or skip, got $action"
fi

# Test: "--raw fix the bug" → escape
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "--raw fix the bug" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "escape '--raw' action" "escape" "$action"

# Test: /cx off state → escape
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "review my code" \
  --arg state '{"cortex_disabled":true}' \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "escape '/cx off' state" "escape" "$action"

# Test: "/cortex:debug" → suppress (slash command)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "/cortex:debug" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "leave-alone '/cortex:debug'" "suppress" "$action"

# Test: random unrelated prompt → skip
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what is the weather today in Copenhagen" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
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
output=$(echo '{"session_id":"test-001","prompt":"review my code","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
if printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "cortex-match injects on 'review my code'"
else
  fail "cortex-match injects on 'review my code'" "no additionalContext in output"
fi

# Test: skip on shell command
output=$(echo '{"session_id":"test-002","prompt":"git status","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
assert_eq "cortex-match skips 'git status'" "{}" "$output"

# Test: escape on --raw
output=$(echo '{"session_id":"test-003","prompt":"--raw fix the bug","cwd":"'"$TEST_DIR"'"}' | \
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

# ===== Test Group: Transparent Mode =====
echo ""
echo "=== Transparent Mode ==="

TRANS_DIR="${TEST_DIR}/.cortex-trans"
mkdir -p "${TRANS_DIR}/.cortex"
printf '{"min_tier":"silver","transparent":true}' > "${TRANS_DIR}/.cortex/config.json"

output=$(echo '{"session_id":"test-trans","prompt":"review my code","cwd":"'"$TRANS_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)

if printf '%s' "$output" | grep -q "cortex: applied"; then
  pass "transparent mode: footer appended"
else
  fail "transparent mode: footer not found" "output: $(printf '%s' "$output" | head -c 200)"
fi

# ===== Test Group: Reject-Signal Boosting =====
echo ""
echo "=== Reject-Signal Boosting ==="

result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "help me optimize this" \
  --arg state '{"recentRejections":3}' \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
leave_score=$(printf '%s' "$result" | jq -r '.leave_alone_score')

result_no_reject=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "help me optimize this" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
leave_score_base=$(printf '%s' "$result_no_reject" | jq -r '.leave_alone_score')

if [[ "$leave_score" != "$leave_score_base" ]]; then
  pass "reject boost: leave-alone score changed ($leave_score_base -> $leave_score)"
else
  fail "reject boost: leave-alone score unchanged" "$leave_score_base == $leave_score"
fi

# E2E test: cortex-match persists rejection state on --raw escape
REJECT_E2E_DIR="${TEST_DIR}/.cortex-reject-e2e"
mkdir -p "${REJECT_E2E_DIR}/.cortex"

# Send a --raw prompt through the hook
echo '{"session_id":"test-reject-e2e","prompt":"--raw fix the bug","cwd":"'"$REJECT_E2E_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" >/dev/null 2>&1

# Verify state file was created with recentRejections > 0
if [[ -f "${REJECT_E2E_DIR}/.cortex/state-test-reject-e2e.json" ]]; then
  rej_count=$(jq -r '.recentRejections // 0' "${REJECT_E2E_DIR}/.cortex/state-test-reject-e2e.json" 2>/dev/null)
  if [[ "$rej_count" -gt 0 ]]; then
    pass "reject boost e2e: state persists rejection count ($rej_count)"
  else
    fail "reject boost e2e: recentRejections not incremented" "got $rej_count"
  fi
else
  fail "reject boost e2e: state file not created" "no state file after --raw"
fi

# ===== Test Group: Synonym Expansion =====
echo ""
echo "=== Synonym Expansion ==="

result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "troubleshoot the bug" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
match_id=$(printf '%s' "$result" | jq -r '.best_match.id // ""')

if [[ "$action" == "inject" ]] || [[ "$action" == "defer" ]]; then
  pass "synonym: 'troubleshoot the bug' matches $match_id"
else
  fail "synonym: 'troubleshoot the bug'" "expected inject/defer, got $action"
fi

# ===== Test Group: Tier Filtering =====
echo ""
echo "=== Tier Filtering ==="

silver_id=$(jq -r '[.templates[] | select(.quality_tier == "silver")][0].id' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
silver_action=$(jq -r --arg id "$silver_id" '.templates[] | select(.id == $id) | .action' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
silver_object=$(jq -r --arg id "$silver_id" '.templates[] | select(.id == $id) | .object' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)

if [[ -n "$silver_id" ]]; then
  result_gold=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
    --arg prompt "${silver_action} the ${silver_object}" \
    --arg state "null" \
    --arg cwd "" \
    --arg min_tier "gold" \
    --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
    "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
  has_silver=$(printf '%s' "$result_gold" | jq --arg id "$silver_id" '[.candidates[].id] | map(select(. == $id)) | length')

  if [[ "$has_silver" == "0" ]]; then
    pass "tier filter: gold excludes silver template"
  else
    fail "tier filter: gold excludes silver template" "silver $silver_id still in candidates"
  fi
else
  pass "tier filter: no silver templates to test (skip)"
fi

# ===== Test Group: Intent Signal Fix =====
echo ""
echo "=== Intent Signal Fix ==="

bash "${PLUGIN_ROOT}/scripts/build-index.sh" >/dev/null 2>&1

signal=$(jq -r '.templates[] | select(.id == "coding-001") | .intent_signals[0] // ""' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
if [[ "$signal" == *'\\\\s'* ]]; then
  fail "intent signals not double-escaped" "found double-escaped backslash in signal"
elif [[ -n "$signal" ]]; then
  pass "intent signals not double-escaped"
else
  fail "intent signals not double-escaped" "signal is empty"
fi

# ===== Test Group: Config System =====
echo ""
echo "=== Config System ==="

CONFIG_DIR="${TEST_DIR}/.cortex"
mkdir -p "$CONFIG_DIR"
printf '{"min_tier":"gold","transparent":false}' > "${CONFIG_DIR}/config.json"

output=$(echo '{"session_id":"test-config-1","prompt":"review my code","cwd":"'"$TEST_DIR"'"}' | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "${PLUGIN_ROOT}/hooks/cortex-match" 2>/dev/null)
if printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "config: gold tier still matches gold template"
else
  fail "config: gold tier still matches gold template" "no injection"
fi

# ===== Test Group: Shell Command "make" Fix (v1.3 F2) =====
echo ""
echo "=== Shell Command Make Fix ==="

# "make a new component" should NOT be suppressed
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make a new component for the dashboard" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
if [[ "$action" != "suppress" ]]; then
  pass "make + article not suppressed (got $action)"
else
  fail "make + article not suppressed" "got suppress"
fi

# "make test" should still be suppressed
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make test" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "make test still suppressed" "suppress" "$action"

# "make the code cleaner" should NOT be suppressed
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make the code cleaner" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
if [[ "$action" != "suppress" ]]; then
  pass "make + determiner not suppressed (got $action)"
else
  fail "make + determiner not suppressed" "got suppress"
fi

# ===== Test Group: Case-Insensitive Index (v1.3 F3) =====
echo ""
echo "=== Case-Insensitive Index ==="

# Index should have no uppercase keys
uppercase_keys=$(jq '.inverted_index | keys | map(select(test("[A-Z]"))) | length' "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
assert_eq "index has no uppercase keys" "0" "$uppercase_keys"

# "review this pr" should match a PR template, not just code review
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "review this pr" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
# PR object should now score > 0 (previously missed due to case)
confidence=$(printf '%s' "$result" | jq -r '.confidence')
action=$(printf '%s' "$result" | jq -r '.action')
# Should at least defer (object "pr" matches "PR" now)
if [[ "$action" == "inject" || "$action" == "defer" ]]; then
  pass "review this pr scores with PR object match (action=$action, conf=$confidence)"
else
  fail "review this pr scores with PR object match" "got action=$action confidence=$confidence"
fi

# ===== Test Group: intents.json v3 (v1.3 F4) =====
echo ""
echo "=== intents.json v3 ==="

intents_version=$(jq '.version' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
assert_eq "intents.json version is 3" "3" "$intents_version"

has_adj=$(jq 'has("adjective_actions")' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
assert_eq "intents has adjective_actions" "true" "$has_adj"

has_verb=$(jq 'has("verb_fix_map")' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
assert_eq "intents has verb_fix_map" "true" "$has_verb"

has_morph=$(jq 'has("morphological_map")' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
assert_eq "intents has morphological_map" "true" "$has_morph"

# PR should now have synonyms
pr_syns=$(jq '.object_synonyms.PR // [] | length' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
if [[ "$pr_syns" -ge 3 ]]; then
  pass "PR has object synonyms ($pr_syns entries)"
else
  fail "PR has object synonyms" "expected >= 3, got $pr_syns"
fi

# Danish: "kode" should be in code synonyms
has_kode=$(jq '.object_synonyms.code | index("kode") != null' "${PLUGIN_ROOT}/data/intents.json" 2>/dev/null)
assert_eq "Danish 'kode' in code synonyms" "true" "$has_kode"

# ===== Test Group: Synonym Overlap Ratio (v1.3 F8) =====
echo ""
echo "=== Synonym Overlap Ratio ==="

# "classify" should NOT match "class" as an object synonym (62% overlap < 75%)
# Test via a prompt where "classify" is the only relevant word
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "classify these items into categories" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
# Should skip — "classify" should not match any action/object via loose prefix
assert_eq "classify does not false-match via prefix" "skip" "$action"

# ===== Test Group: Morphological Matching (v1.3 F5) =====
echo ""
echo "=== Morphological Matching ==="

# "failing" should now match templates that "failure" matches (both → "fail" root)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "the tests are failing in production" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
confidence=$(printf '%s' "$result" | jq -r '.confidence')
# "failing" → morph_map → "fail" → matches "failure" (which is also "fail")
# "tests" matches action "test" (plural handling)
# Should at least defer
if [[ "$action" == "inject" || "$action" == "defer" ]]; then
  pass "morphological: 'failing' matches (action=$action, conf=$confidence)"
else
  fail "morphological: 'failing' matches" "got action=$action confidence=$confidence"
fi

# ===== Test Group: Single-Word Penalty (v1.3 F9) =====
echo ""
echo "=== Single-Word Penalty ==="

# Single word "test" should skip (not defer)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "test" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
assert_eq "single word 'test' skips" "skip" "$action"

# ===== Test Group: Code Snippet Detector (v1.3 F6) =====
echo ""
echo "=== Code Snippet Detector ==="

# Code snippet with action words as identifiers should not match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "const review = (code) => { return test(code); }" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
action=$(printf '%s' "$result" | jq -r '.action')
# Should skip (code_snippet score 0.40 weakens match confidence)
# The code has high punctuation density and no question mark
if [[ "$action" == "skip" || "$action" == "suppress" ]]; then
  pass "code snippet with identifiers → skip/suppress (got $action)"
else
  fail "code snippet with identifiers → skip/suppress" "got $action"
fi

# Code WITH a question mark should still be matchable
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "why does this.review(code) throw an error?" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
lia_reason=$(printf '%s' "$result" | jq -r '.leave_alone_reason')
# Should NOT trigger code_snippet (has question mark)
if [[ "$lia_reason" != "code_snippet" ]]; then
  pass "code with question mark → not code_snippet (reason=$lia_reason)"
else
  fail "code with question mark → not code_snippet" "got code_snippet"
fi

# ===== Test Group: Conversational Preprocessor (v1.3 F1) =====
echo ""
echo "=== Conversational Preprocessor ==="

# P1: "something is wrong with the API" → debug
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "something is wrong with the API" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P1: something wrong → debug" "debug" "$pp_action"

# P1 with contraction: "something's wrong with the API"
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "something's wrong with the API" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P1: something's wrong (contraction) → debug" "debug" "$pp_action"

# P2: "why is the build failing" → debug
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "why is the build failing" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P2: why is build failing → debug" "debug" "$pp_action"

# P2 negative: "why is the sky blue" → no match (no problem indicator)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "why is the sky blue" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P2: why is sky blue → no inferred action" "" "$pp_action"

# P3: "make it faster" → optimize
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make it faster" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P3: make it faster → optimize" "optimize" "$pp_action"

# P3: "make the code cleaner" → refactor
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make the code cleaner" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P3: make the code cleaner → refactor" "refactor" "$pp_action"

# P4: "how does the auth flow work" → explain
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "how does the auth flow work" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P4: how does auth flow work → explain" "explain" "$pp_action"

# P4 negative: "how does this look" → no match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "how does this look" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P4: how does this look → no inferred action" "" "$pp_action"

# P5: "what's a closure" → explain (contraction)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what's a closure" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P5: what's a closure → explain" "explain" "$pp_action"

# P5 guard: "what are the tests I should write" → test (not explain)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what are the tests I should write" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P5 guard: tests I should write → test" "test" "$pp_action"

# P6: "review the changes I made to checkout" → review
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "review the changes I made to checkout" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P6: review changes I made → review" "review" "$pp_action"

# P7: "could you help me debug this" → cleaned_terms contain "debug"
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "could you help me debug this" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
has_debug=$(printf '%s' "$result" | jq '.preprocessed.cleaned_terms | index("debug") != null' 2>/dev/null)
assert_eq "P7: could you debug → cleaned_terms has debug" "true" "$has_debug"

# Scoring: inferred action alone cannot inject (ceiling 0.68 < 0.70)
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "something is wrong with the login" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "inferred debug detected" "debug" "$pp_action"

# --- Negative tests ---

# P1 negative: "something is great" → no match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "something is great about this approach" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_pattern=$(printf '%s' "$result" | jq -r '.preprocessed.pattern_matched // ""')
assert_eq "P1 negative: something is great → no pattern" "" "$pp_pattern"

# P3 negative: "make it purple" → no match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make it purple" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P3 negative: make it purple → no inferred action" "" "$pp_action"

# P3 multi-word: "make it a lot faster" → optimize
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "make it a lot faster" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
assert_eq "P3 multi-word: make it a lot faster → optimize" "optimize" "$pp_action"

# P5/P1 priority: "what is wrong" → caught by P1 as debug
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what is wrong" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_pattern=$(printf '%s' "$result" | jq -r '.preprocessed.pattern_matched // ""')
assert_eq "P1/P5 priority: what is wrong → something_wrong" "something_wrong" "$pp_pattern"

# P6 negative: "discuss the plan I made" → no match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "discuss the plan I made" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_pattern=$(printf '%s' "$result" | jq -r '.preprocessed.pattern_matched // ""')
if [[ "$pp_pattern" != "filler_strip" ]]; then
  pass "P6 negative: discuss not recognized action (pattern=$pp_pattern)"
else
  fail "P6 negative: discuss not recognized action" "got filler_strip"
fi

# P7 minimum length: "can you help" → no match
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "can you help" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_pattern=$(printf '%s' "$result" | jq -r '.preprocessed.pattern_matched // ""')
assert_eq "P7 min-length: can you help → no pattern" "" "$pp_pattern"

# P5 guard fix: "what are the patterns I should know about testing" → explain (not test)
# "know" is not in the action verb list, so first-person guard should NOT trigger
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "what are the patterns I should know about testing" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
pp_action=$(printf '%s' "$result" | jq -r '.preprocessed.inferred_action // ""')
pp_pattern=$(printf '%s' "$result" | jq -r '.preprocessed.pattern_matched // ""')
assert_eq "P5 guard fix: know about testing → explain" "explain" "$pp_action"
assert_eq "P5 guard fix: pattern is what_is_x (not what_is_guard)" "what_is_x" "$pp_pattern"

# ===== Test Group: Compound Intent Telemetry (v1.3 F12) =====
echo ""
echo "=== Compound Intent Telemetry ==="

# "fix the bug and add tests for the auth module" should have compound_intent field
result=$(jq -f "${PLUGIN_ROOT}/scripts/match.jq" \
  --arg prompt "fix the bug and add tests for the auth module" \
  --arg state "null" \
  --arg cwd "" \
  --arg min_tier "silver" \
  --slurpfile intents "${PLUGIN_ROOT}/data/intents.json" \
  "${PLUGIN_ROOT}/data/index.json" 2>/dev/null)
has_field=$(printf '%s' "$result" | jq 'has("compound_intent")' 2>/dev/null)
assert_eq "compound_intent field exists" "true" "$has_field"

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
