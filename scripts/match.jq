# match.jq — Core matching engine for prompt-cortex
# Input: index.json (via file)
# Arguments:
#   $prompt  — the user's raw prompt text
#   $state   — JSON string of current session state (or "null")
#   $cwd     — current working directory (or "")
#   $context              — JSON object of detected project context (or {})
#   $project_rules        — JSON object of boost/suppress/disabled rules (or {})
#   $min_confidence_adjust — string number from preset (default "0"), capped +/-0.10
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

# Parse state from string (--arg passes strings, not objects)
def parsed_state:
  if $state == null or $state == "null" or $state == "" then null
  elif ($state | type) == "object" then $state
  else (try ($state | fromjson) catch null)
  end;

# Check if state has recent injections of a template
def recently_injected($tmpl_id):
  parsed_state as $s |
  if $s == null then false
  else
    ($s.recentInjections // []) |
    map(select(.template == $tmpl_id)) |
    length >= 3
  end;

# Synonym expansion
def intents_data:
  ($intents // null) | if . == null then null elif type == "array" then .[0] else . end;

def is_action_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    ($i.action_synonyms[$canonical] // []) |
    map(ascii_downcase) |
    any(. as $syn |
        $syn == $word or
        (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
         (($word | startswith($syn)) or ($syn | startswith($word)))))
  end;

def is_object_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    ($i.object_synonyms[$canonical] // []) |
    map(ascii_downcase) |
    any(. as $syn |
        $syn == $word or
        (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
         (($word | startswith($syn)) or ($syn | startswith($word)))))
  end;

# Domain synonym resolution
def active_domain:
  intents_data as $i |
  if $i == null then null
  else
    ($context // {}) as $ctx |
    (if ($ctx.framework // "") != "" then
       ($i.framework_domain_override[$ctx.framework] // null)
     else null end) as $fw_domain |
    if $fw_domain != null then $fw_domain
    elif ($ctx.lang // "") != "" then
      ($i.domain_map[$ctx.lang] // null)
    else null end
  end;

def is_domain_action_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    active_domain as $domain |
    if $domain == null then false
    else
      (($i.domain_synonyms[$domain] // {}).action_synonyms[$canonical] // []) |
      map(ascii_downcase) |
      any(. as $syn |
          $syn == $word or
          (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
           (($word | startswith($syn)) or ($syn | startswith($word)))))
    end
  end;

def is_domain_object_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    active_domain as $domain |
    if $domain == null then false
    else
      (($i.domain_synonyms[$domain] // {}).object_synonyms[$canonical] // []) |
      map(ascii_downcase) |
      any(. as $syn |
          $syn == $word or
          (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
           (($word | startswith($syn)) or ($syn | startswith($word)))))
    end
  end;

# Check if cortex is disabled via /cx off
def cortex_disabled:
  parsed_state as $s |
  if $s == null then false
  else ($s.cortex_disabled // false)
  end;

def effective_min_tier:
  if $min_tier == null or $min_tier == "" then "silver"
  else $min_tier end;

def effective_threshold:
  (($min_confidence_adjust // "0") | tonumber) as $adj |
  0.70 + ([[$adj, 0.10] | min, -0.10] | max);

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
      else null end),

    # Reject-signal boost
    (parsed_state as $s |
     if $s == null then null
     else
       ($s.recentRejections // 0) as $rej |
       if $rej >= 2 then
         { score: ([($rej * 0.10), 0.25] | min), reason: "reject_boost" }
       else null end
     end)
  ] |

  # Remove nulls and compute max-of-top-2
  map(select(. != null)) |
  sort_by(-.score) |
  if length == 0 then { score: 0, reason: "none" }
  elif length == 1 then .[0]
  else
    # score = min(1.0, top_1 + top_2 * 0.3)
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

  # --- Action matching (with simple plural/suffix handling) ---
  (if ($words | index($tmpl.action)) != null then 0.45
   elif ($words | index($tmpl.action + "s")) != null then 0.45
   elif ($words | index($tmpl.action + "es")) != null then 0.45
   elif ($words | index($tmpl.action + "ing")) != null then 0.40
   elif ($bigrams | map(select(test("(^|\\s)" + $tmpl.action + "(s|es|ing)?(\\s|$)"))) | length > 0) then 0.20
   elif ($words | any(. as $w | is_action_synonym($w; $tmpl.action))) then 0.35
   elif ($words | any(. as $w | is_domain_action_synonym($w; $tmpl.action))) then 0.30
   else 0 end) as $action_score |

  # --- Object matching (with simple plural handling) ---
  (if ($words | index($tmpl.object)) != null then 0.35
   elif ($words | index($tmpl.object + "s")) != null then 0.35
   elif ($words | index($tmpl.object + "es")) != null then 0.35
   elif ($bigrams | map(select(test("(^|\\s)" + $tmpl.object + "(s|es)?(\\s|$)"))) | length > 0) then 0.15
   elif ($words | any(. as $w | is_object_synonym($w; $tmpl.object))) then 0.25
   elif ($words | any(. as $w | is_domain_object_synonym($w; $tmpl.object))) then 0.20
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

  # --- Complexity mismatch penalty (full range) ---
  (prompt_word_count as $wc |
   (if $wc < 6 then "trivial"
    elif $wc < 15 then "low"
    elif $wc < 40 then "medium"
    elif $wc < 80 then "high"
    else "expert" end) as $prompt_complexity |
   ({"trivial": 1, "low": 2, "medium": 3, "high": 4, "expert": 5}) as $levels |
   ($levels[$prompt_complexity] // 3) as $prompt_level |
   ($levels[$tmpl.min_complexity // "low"] // 2) as $tmpl_level |
   if $prompt_level < $tmpl_level then -0.15
   elif $prompt_level > ($tmpl_level + 2) then -0.05
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

# ===== Phase 3: Context filter =====
# Filters and re-scores candidates based on project context.
# $context: { lang, framework, testing, branch_type, preset }
# $project_rules: { boost, suppress, disabled }
# Receives $scored array and $all_templates from main pipeline.

def context_filter($scored; $all_templates):
  ($context // {}) as $ctx |
  ($project_rules // {}) as $rules |

  # 1. Language filter — remove templates requiring a different language
  [ $scored[] |
    . as $entry |
    ($all_templates | map(select(.id == $entry.id)) | .[0]) as $tmpl |
    if (($tmpl.requires // {}).language // []) | length > 0 then
      if (($tmpl.requires.language | map(ascii_downcase)) | index($ctx.lang // "")) != null then $entry
      else empty end
    else $entry end
  ] |

  # 2. Framework filter — remove templates requiring a different framework
  [ .[] |
    . as $entry |
    ($all_templates | map(select(.id == $entry.id)) | .[0]) as $tmpl |
    if (($tmpl.requires // {}).framework // []) | length > 0 then
      if (($tmpl.requires.framework | map(ascii_downcase)) | index($ctx.framework // "")) != null then $entry
      else empty end
    else $entry end
  ] |

  # 3. Boost/suppress rules from project.json + project-context.json
  [ .[] |
    . as $entry |
    ($all_templates | map(select(.id == $entry.id)) | .[0]) as $tmpl |
    # Boost matching categories, actions, or template IDs
    (if ($rules.boost // []) | any(. as $b |
        ($tmpl.category == $b) or ($tmpl.action == $b) or ($tmpl.id == $b))
     then .confidence = .confidence + 0.05
     else . end) |
    # Suppress matching categories, actions, or template IDs
    (if ($rules.suppress // []) | any(. as $s |
        ($tmpl.category == $s) or ($tmpl.action == $s) or ($tmpl.id == $s))
     then .confidence = .confidence - 0.15
     else . end) |
    # Disabled templates — remove entirely (matches category, action, or ID)
    (if ($rules.disabled // []) | any(. as $d |
        ($d == $entry.id) or ($d == $tmpl.category) or ($d == $tmpl.action) or ($d == "*"))
     then empty
     else . end)
  ] |

  # 4. Project affinity boost (+0.05 per matching affinity, max +0.10)
  [ .[] |
    . as $entry |
    ($all_templates | map(select(.id == $entry.id)) | .[0]) as $tmpl |
    (($tmpl.project_affinity // []) |
     map(select(. as $aff |
       ($ctx.lang == $aff) or ($ctx.framework == $aff) or
       (($ctx.lang // "") | ascii_downcase | test($aff; "i") // false) or
       (($ctx.framework // "") | ascii_downcase | test($aff; "i") // false)
     )) | length) as $affinity_hits |
    if $affinity_hits > 0 then
      .confidence = .confidence + ([$affinity_hits * 0.05, 0.10] | min)
    else . end
  ] |

  # 5. Git branch context boost (+0.03 for matching action types)
  [ .[] |
    . as $entry |
    ($all_templates | map(select(.id == $entry.id)) | .[0]) as $tmpl |
    (if ($ctx.branch_type // "") == "feature" and ($tmpl.action == "design" or $tmpl.action == "create")
     then .confidence = .confidence + 0.03
     elif ($ctx.branch_type // "") == "fix" and ($tmpl.action == "debug" or $tmpl.action == "fix" or $tmpl.action == "test")
     then .confidence = .confidence + 0.03
     elif ($ctx.branch_type // "") == "refactor" and ($tmpl.action == "refactor" or $tmpl.action == "review")
     then .confidence = .confidence + 0.03
     else . end)
  ] |

  # Re-sort by confidence
  sort_by(-.confidence);

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

      # --- Tier filtering ---
      ($all_templates | map(select(
        .quality_tier as $t |
        effective_min_tier as $mt |
        if ($mt == "gold") then ($t == "gold")
        elif ($mt == "silver") then ($t == "gold" or $t == "silver")
        else true end
      ))) as $tier_filtered |

      ($candidates | .[0:10] | map(.id)) as $candidate_ids |

      ($tier_filtered | map(select(.id as $tid | $candidate_ids | index($tid) != null))) as $candidate_templates |

      [($candidate_templates[] | score_candidate(.))] |
      sort_by(-.confidence) as $scored |

      # Apply context filter
      context_filter($scored; $all_templates) as $filtered |

      # 4. Determine action based on confidence
      if ($filtered | length) == 0 then
        { action: "skip", confidence: 0, best_match: null, candidates: [],
          leave_alone_score: $lia.score, leave_alone_reason: $lia.reason }
      else
        $filtered[0] as $best |

        # Check per-template min_confidence
        ($all_templates | map(select(.id == $best.id)) | .[0].min_confidence // 0.7) as $min_conf |

        if $best.confidence >= ([effective_threshold, $min_conf] | max) then
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
