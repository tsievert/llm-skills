#!/usr/bin/env bash
# Hook for the R2 "context-clue" skill undertrigger (see
# github-skill-maintenance/references/skill-trigger-hook.md and
# research/skill-trigger-hooks-ledger.md section 6). Complements skill-trigger-hook.sh (R1,
# the explicit-instruction case) with a best-effort, NON-BLOCKING nudge for the case where
# content seen mid-task matches a skill's declared signal, but no skill has been loaded yet
# and nothing in the user's own words asked for one. Two content channels, same nudge/escalate
# mechanics, declared separately per skill since they key off different fields:
#   `metadata.file_signals`  -- tool output (read/grep/bash results) looks like the skill's domain.
#   `metadata.prompt_signals` -- the user's own prompt wording suggests the skill's domain
#                                 (added 2026-10-28 for staged-assistant-workflow; see
#                                 research/staged-assistant-workflow-ledger.md section 9).
#
# Handles three events, configured in ~/.posit/assistant/settings.json:
#   PostToolUse (matcher "skill")
#     - marks a skill as loaded for this session, so it is never nudged for afterward.
#   PostToolUse (matcher "read|grep|bash")
#     - for every skill in this repo that declares `metadata.file_signals` in its own
#       SKILL.md frontmatter (a single '|'-separated regex-alternation string -- see
#       hpc-job-scripts and deeplabcut-hpc for the two seeded examples), checks the
#       tool_response against the pattern. On the *first* match for a skill not yet loaded
#       this session, emits a non-blocking `hookSpecificOutput.additionalContext` naming the
#       skill. Never blocks and never calls `skill()` itself: the false-positive cost is one
#       ignorable extra line of context, not a forced action (see the ledger's section 6.4
#       for why that was judged acceptable where a *blocking* version was not, and section
#       6.3 for two independent community hooks that do the same thing).
#     - On a *second* match for the same still-unloaded skill in the same session (the first
#       nudge was visible in the transcript and not acted on), writes an escalation marker
#       (`$sid.pending.fs.<skill>`) instead of a second identical nudge. This script still
#       never emits `decision:"block"` itself (that invariant is unchanged, see below and
#       check_sync_setup()'s guard for it); skill-trigger-hook.sh's `Stop` handler looks for
#       these markers and blocks once, naming the skill(s), the same way it already does for
#       an explicit dropped instruction. Added 2026-10-26 after a real session
#       (dlc-pig-method-paper) in which two different skills were each nudged once, visibly,
#       and ignored both times -- see research/skill-trigger-hooks-ledger.md section 8.
#   UserPromptSubmit
#     - identical nudge/escalate logic, but against the whole raw payload (prompt text may
#       contain embedded quotes, same reasoning as skill-trigger-hook.sh) and keyed on each
#       skill's `metadata.prompt_signals` instead of `file_signals`. Shares the same
#       `$sid.nudged.<skill>` / `$sid.loaded.<skill>` / `$sid.pending.fs.<skill>` marker
#       namespace as the file-signal channel, so a skill already nudged via one channel this
#       session is not nudged again via the other, and a second ignored hit on *either*
#       channel escalates to the same `skill-trigger-hook.sh` `Stop` block.
#
# Both `file_signals` and `prompt_signals` are deliberately opt-in and scoped to skills with a
# strong, low-ambiguity signal (do not add either speculatively to every skill -- see ledger
# section 6.5, step 1, and the live false-positive class found 2026-10-28, ledger section 9.1:
# a skill-authoring conversation that merely *discusses* another skill's signal text as prose
# can trip the same match as a real occurrence. No mitigation for that class is built yet.
#
# Always exits 0 (fail open). Local state only: ~/.posit/skill-triggers/state/ (shared
# directory with skill-trigger-hook.sh, disjoint filenames: *.loaded.* / *.nudged.* here vs
# *.pending / *.reminded there). Nothing leaves the machine; no file content or user text is
# stored, only session/skill/timestamp markers.
#
# Debug: touch ~/.posit/skill-triggers/state/DEBUG to dump raw payloads to
# state/debug-payloads.jsonl (may contain private content; delete the file afterwards).

TRIGGER_DIR="${SKILL_TRIGGER_DIR:-$HOME/.posit/skill-triggers}"
STATE="$TRIGGER_DIR/state"
REPO_DIR="${LLM_SKILLS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

payload=$(cat 2>/dev/null) || exit 0
mkdir -p "$STATE" 2>/dev/null || exit 0

jstr() { printf '%s' "$payload" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n1; }

event=$(jstr hook_event_name)
sid=$(jstr session_id)
[ -n "$sid" ] || exit 0

[ -f "$STATE/DEBUG" ] && printf '%s\n' "$payload" >> "$STATE/debug-payloads.jsonl"

# A skill's declared file_signals/prompt_signals is a single string under its own frontmatter's
# `metadata:` map. Restrict the search to the block between the first two '---' lines, so a
# mention of the literal field name in a skill's prose body (e.g. this very file, or a research
# ledger, describing the mechanism) is never picked up as a declaration.
signal_field() {
  awk '/^---$/{c++; next} c==1' "$1" 2>/dev/null \
    | grep -E "^[[:space:]]*$2:" | head -n1 \
    | sed -E "s/^[^:]*:[[:space:]]*//" \
    | sed -E "s/^'(.*)'\$/\1/; s/^\"(.*)\"\$/\1/"
}
file_signals()   { signal_field "$1" file_signals; }
prompt_signals() { signal_field "$1" prompt_signals; }

# Shared nudge/escalate logic for one (skill, pattern, content) triple. Appends to the global
# $ctx on a first match; writes an escalation marker (read by skill-trigger-hook.sh's Stop
# handler) on a second, still-ignored match. Never blocks itself.
check_signal() {
  local cand=$1 pat=$2 content=$3 label=$4
  [ -f "$STATE/$sid.loaded.$cand" ] && return 0
  [ -n "$pat" ] || return 0
  printf '%s' "$content" | grep -qE -- "$pat" || return 0
  if [ -f "$STATE/$sid.nudged.$cand" ]; then
    touch "$STATE/$sid.pending.fs.$cand" 2>/dev/null
  else
    touch "$STATE/$sid.nudged.$cand" 2>/dev/null
    ctx="${ctx}$label matched the $cand skill's declared signal; if this task is in its domain, consider loading it before continuing. "
  fi
}

emit_and_exit() {
  [ -n "$ctx" ] || exit 0
  esc=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$esc"
  # Housekeeping: drop per-session state older than 30 days.
  find "$STATE" -maxdepth 1 -type f -name '*.*' -mtime +30 -delete 2>/dev/null
  exit 0
}

case "$event" in
  PostToolUse)
    tool=$(jstr tool_name)
    if [ "$tool" = "skill" ]; then
      loaded_name=$(jstr skill)
      [ -n "$loaded_name" ] && touch "$STATE/$sid.loaded.$loaded_name" 2>/dev/null
      exit 0
    fi
    # Only read/grep/bash results can reveal file content worth matching.
    case "$tool" in read|grep|bash) ;; *) exit 0 ;; esac
    response=${payload#*\"tool_response\"}
    [ -n "$response" ] || exit 0
    ctx=""
    for dir in "$REPO_DIR"/*/; do
      skill_md="$dir/SKILL.md"
      [ -f "$skill_md" ] || continue
      cand=$(basename "$dir")
      check_signal "$cand" "$(file_signals "$skill_md")" "$response" "File content just read"
    done
    emit_and_exit "PostToolUse"
    ;;
  UserPromptSubmit)
    # Scan the whole raw payload, not an extracted "prompt" field: a single-capture sed on a
    # JSON string breaks on embedded quotes, which free user text will contain (same reasoning
    # as skill-trigger-hook.sh). The other UserPromptSubmit fields (session_id, transcript_path,
    # cwd, hook_event_name, permission_mode) cannot plausibly contain a prompt_signals match.
    ctx=""
    for dir in "$REPO_DIR"/*/; do
      skill_md="$dir/SKILL.md"
      [ -f "$skill_md" ] || continue
      cand=$(basename "$dir")
      check_signal "$cand" "$(prompt_signals "$skill_md")" "$payload" "Your message"
    done
    emit_and_exit "UserPromptSubmit"
    ;;
esac
exit 0
