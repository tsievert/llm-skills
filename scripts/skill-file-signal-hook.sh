#!/usr/bin/env bash
# Hook for the R2 "context-clue" skill undertrigger (see
# github-skill-maintenance/references/skill-trigger-hook.md and
# research/skill-trigger-hooks-ledger.md section 6). Complements skill-trigger-hook.sh (R1,
# the explicit-instruction case) with a best-effort, NON-BLOCKING nudge for the case where file
# content read mid-task matches a skill's declared `metadata.file_signals` pattern, but no
# skill has been loaded yet and nothing in the user's own words asked for one.
#
# Handles two events, configured in ~/.posit/assistant/settings.json:
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
#
# `file_signals` is deliberately opt-in and scoped to skills with a strong, low-ambiguity file
# signature (do not add it to every skill speculatively -- see ledger section 6.5, step 1).
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

# A skill's declared file_signals is a single string under its own frontmatter's `metadata:`
# map. Restrict the search to the block between the first two '---' lines, so a mention of the
# literal word "file_signals" in a skill's prose body (e.g. this very file being discussed) is
# never picked up as a declaration.
file_signals() {
  awk '/^---$/{c++; next} c==1' "$1" 2>/dev/null \
    | grep -E '^[[:space:]]*file_signals:' | head -n1 \
    | sed -E "s/^[^:]*:[[:space:]]*//" \
    | sed -E "s/^'(.*)'\$/\1/; s/^\"(.*)\"\$/\1/"
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
      [ -f "$STATE/$sid.loaded.$cand" ] && continue
      pat=$(file_signals "$skill_md")
      [ -n "$pat" ] || continue
      if printf '%s' "$response" | grep -qE -- "$pat"; then
        if [ -f "$STATE/$sid.nudged.$cand" ]; then
          # Already nudged once this session for this skill and still not loaded: escalate
          # instead of repeating the same ignorable line. skill-trigger-hook.sh's Stop
          # handler looks for this marker; this script still never blocks itself.
          touch "$STATE/$sid.pending.fs.$cand" 2>/dev/null
        else
          touch "$STATE/$sid.nudged.$cand" 2>/dev/null
          ctx="${ctx}File content just read matches the $cand skill's declared file signal; if this task is in its domain, consider loading it before continuing. "
        fi
      fi
    done
    [ -n "$ctx" ] || exit 0
    esc=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
    # Housekeeping: drop per-session state older than 30 days.
    find "$STATE" -maxdepth 1 -type f -name '*.*' -mtime +30 -delete 2>/dev/null
    ;;
esac
exit 0
