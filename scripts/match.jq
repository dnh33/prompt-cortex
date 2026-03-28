# match.jq — Core matching engine for prompt-cortex
# Input: index.json (via file)
# Arguments:
#   $prompt  — the user's raw prompt text
#   $state   — JSON string of current session state (or "null")
#   $cwd     — current working directory (or "")
#   $context              — JSON object of detected project context (or {})
#   $project_rules        — JSON object of boost/suppress/disabled rules (or {})
#   $min_confidence_adjust — string number from preset (default "0"), capped +/-0.10
#   $min_tier  — minimum quality tier: "gold"|"silver"|"all" (--arg)
#   $intents   — intents.json data (--slurpfile, array wrapped)
#
# Output: JSON with matching result
#   { "action": "inject"|"defer"|"suppress"|"skip"|"escape",
#     "confidence": <float>,
#     "best_match": { template object } | null,
#     "candidates": [ { id, confidence } ],
#     "leave_alone_score": <float>,
#     "leave_alone_reason": "<reason>",
#     "preprocessed": { inferred_action, inferred_object, cleaned_terms, pattern_matched },
#     "compound_intent": { detected: bool, intents: [string] } }

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

def morph_map: intents_data.morphological_map // {};

def is_action_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    (morph_map[$word] // $word) as $norm_word |
    ($i.action_synonyms[$canonical] // $i.action_synonyms[($canonical | ascii_upcase)] // []) |
    map(ascii_downcase) |
    any(. as $syn |
        (morph_map[$syn] // $syn) as $norm_syn |
        $syn == $word or
        $norm_word == $norm_syn or
        (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
         (($word | startswith($syn)) or ($syn | startswith($word))) and
         (([($word | length), ($syn | length)] | min) / ([($word | length), ($syn | length)] | max) >= 0.75)))
  end;

def is_object_synonym($word; $canonical):
  intents_data as $i |
  if $i == null then false
  else
    (morph_map[$word] // $word) as $norm_word |
    ($i.object_synonyms[$canonical] // $i.object_synonyms[($canonical | ascii_upcase)] // []) |
    map(ascii_downcase) |
    any(. as $syn |
        (morph_map[$syn] // $syn) as $norm_syn |
        $syn == $word or
        $norm_word == $norm_syn or
        (($syn | contains(" ") | not) and ($word | length) >= 4 and ($syn | length) >= 4 and
         (($word | startswith($syn)) or ($syn | startswith($word))) and
         (([($word | length), ($syn | length)] | min) / ([($word | length), ($syn | length)] | max) >= 0.75)))
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
           (($word | startswith($syn)) or ($syn | startswith($word))) and
           (([($word | length), ($syn | length)] | min) / ([($word | length), ($syn | length)] | max) >= 0.75)))
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
           (($word | startswith($syn)) or ($syn | startswith($word))) and
           (([($word | length), ($syn | length)] | min) / ([($word | length), ($syn | length)] | max) >= 0.75)))
    end
  end;

# ===== Preprocessor: Conversational intent extraction =====
def strip_articles:
  gsub("(^| )(the|a|an|this|that|my|our|your|its) "; " ") | gsub("^ +| +$"; "") | gsub(" +"; " ");

def preprocess_prompt:
  ($prompt | ascii_downcase | gsub("^\\s+|\\s+$"; "")) as $raw |
  ($raw |
    gsub("something's"; "something is") |
    gsub("what's"; "what is") | gsub("what're"; "what are") |
    gsub("there's"; "there is") |
    gsub("it's"; "it is") | gsub("that's"; "that is") |
    gsub("won't"; "will not") | gsub("can't"; "cannot") |
    gsub("isn't"; "is not") | gsub("aren't"; "are not") |
    gsub("doesn't"; "does not") | gsub("don't"; "do not") |
    gsub("didn't"; "did not") |
    gsub("i'm"; "i am") | gsub("we're"; "we are") |
    gsub("you're"; "you are") | gsub("they're"; "they are") |
    gsub("he's"; "he is") | gsub("she's"; "she is") |
    gsub("couldn't"; "could not") | gsub("wouldn't"; "would not") |
    gsub("shouldn't"; "should not") |
    gsub("hasn't"; "has not") | gsub("haven't"; "have not")
  ) as $p |

  intents_data as $i |
  ($i.adjective_actions // {}) as $adj_map |
  ($i.verb_fix_map // {}) as $vfm |
  ($i.actions // []) as $actions |

  # P1: "something is wrong" / diagnostic complaint → debug
  if ($p | test("^(something (is |seems |looks |appears )?(wrong|broken|off|weird|messed up|not right)|there (is|are|seems to be) (a |an |some )?(problem|issue|bug|error)|(it|this|that) (is |keeps |will not stop )(not )?(working|running|loading|compiling|building|failing|crashing|breaking|erroring|responding|connecting)|what (is|went) wrong)"))
  then
    ($p | capture("(?:with|in|on) (?:the |my |our |this |that )?(?<obj>.+)$") // {}) as $cap |
    { inferred_action: "debug", inferred_object: ($cap.obj // null), cleaned_terms: (["debug"] + (if $cap.obj then [$cap.obj | split(" ")[]] else [] end)), pattern_matched: "something_wrong" }

  # P2: "why is X failing" → debug (with problem indicator)
  elif ($p | test("^why (is|are|does|do|did|is not|are not|does not|do not|did not|will not|cannot|could not) ")) and ($p | test("(not |n't |wrong|broken|fail|crash|miss|slow|error|bug|hang|freeze|timeout|exception|undefined|null|stuck)"))
  then
    ($p | gsub("^why (?:is|are|does|do|did|is not|are not|does not|do not|did not|will not|cannot|could not) "; "") | split(" ") | map(select(length > 2 and (. as $w | ["the","not","and","but","for","with"] | index($w) == null)))) as $subject_words |
    ($subject_words | first // null) as $obj |
    { inferred_action: "debug", inferred_object: $obj, cleaned_terms: (["debug"] + $subject_words), pattern_matched: "why_is_x" }

  # P3a: "make X more Y" → adjective-to-action (must precede P3b to avoid "make the X more Y" mis-parsing)
  elif ($p | test("^make .+ more .+$"))
  then
    ($p | capture("^make (?<subj>.+) more (?<adj>.+)$") // {}) as $cap |
    ($adj_map[$cap.adj] // null) as $mapped |
    if $mapped != null then
      { inferred_action: $mapped, inferred_object: ($cap.subj | strip_articles), cleaned_terms: [$mapped, ($cap.subj | strip_articles)], pattern_matched: "make_x_more_y" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  # P3b: "make it/the X-er" → adjective-to-action
  elif ($p | test("^make (it|this|that|the|my|our|your|a|an) "))
  then
    ($p | capture("^make (?:it|this|that|the|my|our|your|a|an) (?<rest>.+)$") // {}) as $cap |
    ($cap.rest // "" | split(" ") | reverse) as $words_rev |
    ([$words_rev[] | . as $w | $adj_map[$w] // $vfm[$w] // null | select(. != null)] | first // null) as $mapped |
    if $mapped != null then
      (($cap.rest // "") | split(" ")) as $rest_words |
      ($rest_words | to_entries | map(select(.value as $w | $adj_map[$w] // $vfm[$w] // null | . != null)) | last // null) as $match_entry |
      (if $match_entry != null and $match_entry.key > 0
       then ($rest_words[0:$match_entry.key] | join(" ") | strip_articles)
       else null end) as $obj |
      (if $obj != null and ($obj | length) > 0 and ($obj | split(" ") | map(select(. as $w | ["lot","very","really","so","too","just","quite","pretty","rather"] | index($w) == null)) | length > 0)
       then ($obj | split(" ") | map(select(. as $w | ["lot","very","really","so","too","just","quite","pretty","rather"] | index($w) == null)) | join(" "))
       else null end) as $final_obj |
      { inferred_action: $mapped, inferred_object: $final_obj, cleaned_terms: ([$mapped] + (if $final_obj then [$final_obj] else [] end)), pattern_matched: "make_it_xer" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  # P4: "how does X work" → explain
  elif ($p | test("^how (does|do|did|would|should|could) .+ (work|operate|run|execute|behave)$"))
  then
    ($p | capture("^how (?:does|do|did|would|should|could) (?<subj>.+) (?:work|operate|run|execute|behave)$") // {}) as $cap |
    { inferred_action: "explain", inferred_object: ($cap.subj | strip_articles),
      cleaned_terms: (["explain"] + (($cap.subj | strip_articles) | split(" "))),
      pattern_matched: "how_does_x_work" }

  # P5: "what is/are X" → explain (with first-person guard)
  elif ($p | test("^what (is|are|was|were) "))
  then
    ($p | capture("^what (?:is|are|was|were) (?<rest>.+)$") // {}) as $cap |
    ($cap.rest // "") as $remainder |
    (["write","create","build","review","debug","fix","test","refactor","optimize","design","document"]) as $action_verbs |
    ([$action_verbs[] | . as $v | select($remainder | test("(^|[^a-zA-Z])" + $v + "([^a-zA-Z]|$)"))] | first // null) as $found_verb |
    ($remainder | test("(^|[^a-zA-Z])(i|my|we|our|you)([^a-zA-Z]|$)")) as $has_first_person |
    ($remainder | test("(^|[^a-zA-Z])(should|need to|want to|have to|going to)([^a-zA-Z]|$)")) as $has_imperative |
    if $found_verb != null and ($has_first_person or $has_imperative) then
      ($remainder | split(" ") | map(. as $w | (morph_map[$w] // $w)) |
       map(select(. as $w | $actions | index($w) != null)) | first // null) as $object_action |
      (if $object_action != null then $object_action else $found_verb end) as $resolved |
      { inferred_action: $resolved, inferred_object: ($remainder | strip_articles),
        cleaned_terms: ([$resolved] + ($remainder | strip_articles | split(" "))),
        pattern_matched: "what_is_guard" }
    else
      { inferred_action: "explain", inferred_object: ($remainder | strip_articles),
        cleaned_terms: (["explain"] + ($remainder | strip_articles | split(" "))),
        pattern_matched: "what_is_x" }
    end

  # P6: "[action] the Y I made/wrote" → filler stripping
  elif ($p | split(" ") | .[0]) as $first_word |
       ($actions | index($first_word) != null) or
       ($actions | any(. as $act | is_action_synonym($first_word; $act)))
  then
    ($p | split(" ") | .[0]) as $first_word |
    ($actions | map(select(. as $act | ($act == $first_word) or is_action_synonym($first_word; $act))) | first // $first_word) as $canonical_action |
    ($p | gsub("\\s+(?:that )?(?:i|we|you) (?:have )?(?:made|wrote|changed|created|built|modified|updated|added|fixed|pushed|committed|submitted|drafted).*"; "")) as $cleaned |
    if $cleaned != $p then
      { inferred_action: $canonical_action, inferred_object: null, cleaned_terms: ($cleaned | split(" ")), pattern_matched: "filler_strip" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  # P7: "can/could/would/will you X" → prefix strip
  elif ($p | test("^(can|could|would|will) you "))
  then
    ($p | gsub("^(can|could|would|will) you (please )?(help (me |us )?(to |with )?)?"; "")) as $remainder |
    ($remainder | split(" ") | map(select(length > 2)) | length) as $token_count |
    if $token_count >= 2 then
      { inferred_action: null, inferred_object: null, cleaned_terms: ($remainder | split(" ") | map(select(length > 0))), pattern_matched: "can_you_x" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  # P8: "I need to X" → prefix strip
  elif ($p | test("^i need to "))
  then
    ($p | gsub("^i need to "; "")) as $remainder |
    ($remainder | split(" ") | map(select(length > 2)) | length) as $token_count |
    if $token_count >= 2 then
      { inferred_action: null, inferred_object: null, cleaned_terms: ($remainder | split(" ") | map(select(length > 0))), pattern_matched: "i_need_to_x" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  # P9: "help me X" → prefix strip
  elif ($p | test("^help (me |us )?(to )?(with )?"))
  then
    ($p | gsub("^help (me |us )?(to )?(with )?"; "")) as $remainder |
    ($remainder | split(" ") | map(select(length > 2)) | length) as $token_count |
    if $token_count >= 2 then
      { inferred_action: null, inferred_object: null, cleaned_terms: ($remainder | split(" ") | map(select(length > 0))), pattern_matched: "help_me_x" }
    else
      { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
    end

  else
    { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null }
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
  ([$adj, 0.10] | min) as $capped_high |
  0.70 + ([$capped_high, -0.10] | max);

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
    (if ($p | test("^(git|npm|yarn|pnpm|pip|cargo|docker|kubectl|cd|ls|cat|mkdir|mv|cp|rm|chmod|curl|wget|ssh|scp)\\s")) then { score: 0.60, reason: "shell_command" }
     elif ($p | test("^make\\s+(test|install|build|clean|all|deploy|lint|dist|run|check|help|format)(\\s|$)")) then { score: 0.60, reason: "shell_command" }
     elif ($p | test("^make\\s+(-[a-zA-Z]|[A-Z_]+=)")) then { score: 0.60, reason: "shell_command" }
     else null end),

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

    # Code snippet detection (high programming punctuation density, no question mark)
    (($p | [scan("[;{}()\\[\\]=<>]")] | length) as $punct_count |
     if $punct_count > 0 and ($wc > 0) and
        ($punct_count / $wc > 0.125) and
        ($p | test("\\?") | not)
     then { score: 0.40, reason: "code_snippet" }
     else null end),

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

def keyword_candidates_enhanced($pp):
  prompt_words as $words |
  prompt_bigrams as $bigrams |
  ($pp.cleaned_terms // []) as $extra |
  .inverted_index as $idx |
  morph_map as $mm |

  ([$words[] | . as $w |
    (($idx[$w] // []) + ($idx[($mm[$w] // "")] // [])) | .[]] +
   [$bigrams[] | . as $b | $idx[$b] // [] | .[]] +
   [$extra[] | . as $e | $idx[$e] // [] | .[]]) |

  group_by(.) |
  map({ id: .[0], hits: length }) |
  sort_by(-.hits);

# ===== Phase 2: Score candidates against prompt =====

def score_candidate($tmpl; $pp):
  prompt_lower as $p |
  prompt_words as $words |
  prompt_bigrams as $bigrams |
  ($tmpl.action | ascii_downcase) as $action |
  ($tmpl.object | ascii_downcase) as $object |

  # --- Action matching (with simple plural/suffix handling) ---
  (if ($words | index($action)) != null then 0.45
   elif ($words | index($action + "s")) != null then 0.45
   elif ($words | index($action + "es")) != null then 0.45
   elif ($words | index($action + "ing")) != null then 0.40
   elif ($bigrams | map(select(test("(^|\\s)" + $action + "(s|es|ing)?(\\s|$)"))) | length > 0) then 0.20
   elif ($words | any(. as $w | is_action_synonym($w; $action))) then 0.35
   elif ($words | any(. as $w | is_domain_action_synonym($w; $action))) then 0.30
   else 0 end) as $action_score |

  # --- Object matching (with simple plural handling) ---
  (if ($words | index($object)) != null then 0.35
   elif ($words | index($object + "s")) != null then 0.35
   elif ($words | index($object + "es")) != null then 0.35
   elif ($bigrams | map(select(test("(^|\\s)" + $object + "(s|es)?(\\s|$)"))) | length > 0) then 0.15
   elif ($words | any(. as $w | is_object_synonym($w; $object))) then 0.25
   elif ($words | any(. as $w | is_domain_object_synonym($w; $object))) then 0.20
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
   # v1.3: unconditional -0.30 for ultra-short prompts (<3 words)
   if $wc < 3 then -0.30
   else
     (if $wc < 6 then "trivial"
      elif $wc < 15 then "low"
      elif $wc < 40 then "medium"
      elif $wc < 80 then "high"
      else "expert" end) as $prompt_complexity |
     ({"trivial": 1, "low": 2, "medium": 3, "high": 4, "expert": 5}) as $levels |
     ($levels[$prompt_complexity] // 3) as $prompt_level |
     ($levels[$tmpl.min_complexity // "low"] // 2) as $tmpl_level |
     if ($tmpl_level - $prompt_level) > 2 then -0.15
     elif ($prompt_level - $tmpl_level) > 2 then -0.05
     else 0 end
   end) as $complexity_penalty |

  # --- Code snippet penalty (v1.3 F6) ---
  ((prompt_lower | [scan("[;{}()\\[\\]=<>]")] | length) as $pc |
   if $pc > 0 and (prompt_word_count > 0) and
      ($pc / prompt_word_count > 0.125) and
      (prompt_lower | test("\\?") | not)
   then -0.20
   else 0 end) as $code_snippet_penalty |

  # --- Multi-turn suppression ---
  (if recently_injected($tmpl.id) then -0.40
   else 0 end) as $suppression_penalty |

  # --- Inferred action bonus (v1.3 preprocessor) ---
  (if ($pp.inferred_action != null) and ($pp.inferred_action == $action)
   then 0.30
   else 0 end) as $inferred_action_score |

  # --- Inferred object bonus (v1.3 preprocessor) ---
  (if ($pp.inferred_object != null) and
      (($pp.inferred_object | ascii_downcase) as $io |
       ($io == $object) or (is_object_synonym($io; $object)))
   then 0.20
   else 0 end) as $inferred_object_score |

  # --- Total ---
  {
    id: $tmpl.id,
    name: $tmpl.name,
    action: $action,
    confidence: ([([($action_score), ($inferred_action_score)] | max) + ([($object_score), ($inferred_object_score)] | max) + $keyword_score + $signal_boost + $negative_penalty + $complexity_penalty + $code_snippet_penalty + $suppression_penalty, 0] | max),
    breakdown: {
      action: $action_score,
      object: $object_score,
      keyword: $keyword_score,
      signal_boost: $signal_boost,
      negative: $negative_penalty,
      complexity: $complexity_penalty,
      code_snippet: $code_snippet_penalty,
      suppression: $suppression_penalty,
      inferred_action: $inferred_action_score,
      inferred_object: $inferred_object_score
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
  # Build O(1) lookup index once (avoids O(n) scan per candidate per filter)
  ($all_templates | map({(.id): .}) | add // {}) as $tmpl_idx |

  # 1. Language filter — skip when lang is unknown/empty (no false exclusions)
  (if ($ctx.lang // "unknown") == "unknown" or ($ctx.lang // "") == "" then $scored
   else [ $scored[] |
    . as $entry |
    ($tmpl_idx[$entry.id] // {}) as $tmpl |
    if (($tmpl.requires // {}).language // []) | length > 0 then
      if (($tmpl.requires.language | map(ascii_downcase)) | index($ctx.lang | ascii_downcase)) != null then $entry
      else empty end
    else $entry end
  ] end) |

  # 2. Framework filter — skip when framework is unknown/empty
  (if ($ctx.framework // "unknown") == "unknown" or ($ctx.framework // "") == "" then .
   else [ .[] |
    . as $entry |
    ($tmpl_idx[$entry.id] // {}) as $tmpl |
    if (($tmpl.requires // {}).framework // []) | length > 0 then
      if (($tmpl.requires.framework | map(ascii_downcase)) | index($ctx.framework | ascii_downcase)) != null then $entry
      else empty end
    else $entry end
  ] end) |

  # 3. Boost/suppress rules from project.json + project-context.json
  [ .[] |
    . as $entry |
    ($tmpl_idx[$entry.id] // {}) as $tmpl |
    (if ($rules.boost // []) | any(. as $b |
        ($tmpl.category == $b) or ($tmpl.action == $b) or ($tmpl.id == $b))
     then .confidence = .confidence + 0.05
     else . end) |
    (if ($rules.suppress // []) | any(. as $s |
        ($tmpl.category == $s) or ($tmpl.action == $s) or ($tmpl.id == $s))
     then .confidence = .confidence - 0.15
     else . end) |
    (if ($rules.disabled // []) | any(. as $d |
        ($d == $entry.id) or ($d == $tmpl.category) or ($d == $tmpl.action) or ($d == "*"))
     then empty
     else . end)
  ] |

  # 4. Project affinity boost (+0.05 per matching affinity, max +0.10)
  [ .[] |
    . as $entry |
    ($tmpl_idx[$entry.id] // {}) as $tmpl |
    (($tmpl.project_affinity // []) |
     map(select(. as $aff |
       ($ctx.lang == $aff) or ($ctx.framework == $aff) or
       (($ctx.lang // "") | ascii_downcase) == ($aff | ascii_downcase) or
       (($ctx.framework // "") | ascii_downcase) == ($aff | ascii_downcase)
     )) | length) as $affinity_hits |
    if $affinity_hits > 0 then
      .confidence = .confidence + ([$affinity_hits * 0.05, 0.10] | min)
    else . end
  ] |

  # 5. Git branch context boost (+0.03 for matching action types)
  [ .[] |
    . as $entry |
    ($tmpl_idx[$entry.id] // {}) as $tmpl |
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
    leave_alone_score: 1.0, leave_alone_reason: "raw_flag",
    preprocessed: { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null },
    compound_intent: { detected: false, intents: [] } }
elif cortex_disabled then
  { action: "escape", confidence: 0, best_match: null, candidates: [],
    leave_alone_score: 1.0, leave_alone_reason: "cx_off",
    preprocessed: { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null },
    compound_intent: { detected: false, intents: [] } }
else

  # 1. Leave-it-alone detector
  leave_it_alone as $lia |

  if $lia.score >= 0.60 then
    { action: "suppress", confidence: 0, best_match: null, candidates: [],
      leave_alone_score: $lia.score, leave_alone_reason: $lia.reason,
      preprocessed: { inferred_action: null, inferred_object: null, cleaned_terms: [], pattern_matched: null },
      compound_intent: { detected: false, intents: [] } }
  else

    # Preprocessor: extract intent from conversational phrasing
    preprocess_prompt as $pp |

    # 2. Get candidate templates from inverted index
    keyword_candidates_enhanced($pp) as $candidates |

    if ($candidates | length) == 0 then
      { action: "skip", confidence: 0, best_match: null, candidates: [],
        leave_alone_score: $lia.score, leave_alone_reason: $lia.reason,
        preprocessed: $pp,
        compound_intent: { detected: false, intents: [] } }
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

      [($candidate_templates[] | score_candidate(.; $pp))] |
      sort_by(-.confidence) as $scored |

      # Apply context filter
      context_filter($scored; $all_templates) as $filtered |

      # Compound intent detection (telemetry only, uses pre-filter scores)
      (if ($scored | length) >= 2 and
          ($scored[0].confidence > 0.50) and ($scored[1].confidence > 0.50) and
          ($scored[0].action != $scored[1].action)
       then { detected: true, intents: [$scored[0].action, $scored[1].action] }
       else { detected: false, intents: [] }
       end) as $compound |

      # 4. Determine action based on confidence
      if ($filtered | length) == 0 then
        { action: "skip", confidence: 0, best_match: null, candidates: [],
          leave_alone_score: $lia.score, leave_alone_reason: $lia.reason,
          preprocessed: $pp,
          compound_intent: $compound }
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
            leave_alone_reason: $lia.reason,
            preprocessed: $pp,
            compound_intent: $compound }
        elif $best.confidence >= 0.40 then
          { action: "defer",
            confidence: $best.confidence,
            best_match: $best,
            candidates: ($filtered | .[0:3] | map({id: .id, confidence: .confidence})),
            leave_alone_score: $lia.score,
            leave_alone_reason: $lia.reason,
            preprocessed: $pp,
            compound_intent: $compound }
        else
          { action: "skip",
            confidence: $best.confidence,
            best_match: null,
            candidates: ($filtered | .[0:3] | map({id: .id, confidence: .confidence})),
            leave_alone_score: $lia.score,
            leave_alone_reason: $lia.reason,
            preprocessed: $pp,
            compound_intent: $compound }
        end
      end

    end
  end
end
